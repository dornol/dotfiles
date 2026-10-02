import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DotfilesTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        # A copy isolates Stow and lockfile writes from the checkout.
        self.repo = self.base / 'repo with spaces'
        shutil.copytree(ROOT, self.repo, ignore=shutil.ignore_patterns('.git', '__pycache__'))
        self.home = self.base / 'home'
        self.home.mkdir()
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        self.env = dict(os.environ, HOME=str(self.home),
                        XDG_CACHE_HOME=str(self.home / '.cache'),
                        XDG_CONFIG_HOME=str(self.home / '.config'),
                        XDG_DATA_HOME=str(self.home / '.local/share'),
                        PATH=str(self.bin) + ':' + os.environ['PATH'],
                        GIT_CONFIG_NOSYSTEM='1')
        for key in ('ZDOTDIR', 'GIT_CONFIG_GLOBAL', 'GIT_CONFIG_COUNT', 'WSL_DISTRO_NAME'):
            self.env.pop(key, None)
        self.stub('starship', 'printf "# test prompt init\\n"\n')

    def stub(self, name, body):
        path = self.bin / name
        path.write_text('#!/bin/bash\n' + body)
        path.chmod(0o755)

    def run_command(self, *args, success=True, **kwargs):
        result = subprocess.run(args, env=self.env, cwd=self.home, text=True,
                                capture_output=True, **kwargs)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def apply(self, *args):
        return self.run_command('bash', str(self.repo / 'bin/dotfiles-apply'), *args)

    def test_apply_reapply_remove_preserves_user_settings(self):
        if not shutil.which('stow'):
            self.skipTest('stow required')
        gitconfig = self.home / '.gitconfig'
        original_git = '[user]\n name = Machine User\n[core]\n pager = less\n'
        gitconfig.write_text(original_git)
        zshrc = self.home / '.zshrc'
        zshrc.write_text('export USER_LOCAL_SETTING=kept\n')
        claude = self.home / '.claude'
        claude.mkdir()
        settings = claude / 'settings.json'
        user_hook = {'matcher': 'custom', 'hooks': [{'type': 'command', 'command': 'echo custom'}]}
        settings.write_text(json.dumps({'language': 'english', 'custom': True,
                                       'hooks': {'Notification': [user_hook]}}))
        self.apply()
        first_git = gitconfig.read_text()
        first_zsh = zshrc.read_text()
        first_settings = settings.read_text()
        self.apply()
        self.assertEqual(gitconfig.read_text(), first_git)
        self.assertEqual(zshrc.read_text(), first_zsh)
        self.assertEqual(settings.read_text(), first_settings)
        self.assertEqual(self.run_command('git', 'config', '--global', '--includes', '--get', 'user.name').stdout.strip(), 'Machine User')
        self.assertEqual(self.run_command('git', 'config', '--global', '--includes', '--get', 'core.pager').stdout.strip(), 'less')
        merged = json.loads(settings.read_text())
        self.assertEqual(merged['language'], 'english')
        self.assertEqual(len(merged['hooks']['Notification']), 2)
        self.assertTrue((self.home / '.config/nvim/init.lua').is_symlink())
        self.assertTrue((self.home / '.local/bin/dotfiles').is_symlink())
        self.assertFalse((self.home / 'tests').exists())
        self.assertFalse((self.home / '.github').exists())
        doctor = self.run_command(str(self.home / '.local/bin/dotfiles'), 'doctor', success=False)
        self.assertIn('OK   Git 공통 설정 include', doctor.stdout)
        self.assertNotIn('관리 링크 없음', doctor.stdout)
        self.apply('--remove', '--purge')
        self.assertEqual(gitconfig.read_text(), original_git)
        self.assertIn('USER_LOCAL_SETTING=kept', zshrc.read_text())
        self.assertNotIn('# >>> dotfiles >>>', zshrc.read_text())
        self.assertEqual(json.loads(settings.read_text()), {'language': 'english', 'custom': True, 'hooks': {'Notification': [user_hook]}})
        self.assertFalse((self.home / '.config/nvim/init.lua').exists())
        self.apply('--remove', '--purge')

    def test_python_merge_and_purge(self):
        source = (self.repo / 'bin/dotfiles-apply').read_text()
        functions = source[source.index('merge_claude_settings()'):source.index('\nremove_dotfiles_link()')]
        # Force the Python fallback, regardless of jq availability on the host.
        command = '''command() {
          if [[ "$1" == -v && "$2" == jq ]]; then return 1; fi
          builtin command "$@"
        }
        ''' + functions + '\nmerge_claude_settings\nremove_claude_settings\n'
        settings = self.home / '.claude/settings.json'
        settings.parent.mkdir()
        initial = {'language': 'english', 'hooks': {'Notification': [{'custom': True}]}}
        settings.write_text(json.dumps(initial))
        self.env['DOTFILES_DIR'] = str(self.repo)
        self.run_command('bash', '-ec', command)
        self.assertEqual(json.loads(settings.read_text()), initial)

    def test_uninstall_preserves_current_files_and_restores_missing(self):
        if not shutil.which('stow'):
            self.skipTest('stow required')
        current = self.home / '.wezterm.lua'
        current.write_text('new user settings')
        backup = self.home / '.wezterm.lua.bak.20260101'
        backup.write_text('old settings')
        missing_backup = self.home / '.tmux.conf.bak.20260101'
        missing_backup.write_text('original tmux config')
        self.run_command('bash', str(self.repo / 'uninstall.sh'))
        self.assertEqual(current.read_text(), 'new user settings')
        self.assertEqual(backup.read_text(), 'old settings')
        self.assertEqual((self.home / '.tmux.conf').read_text(), 'original tmux config')

    def test_nvim_update_failures_and_success(self):
        target = self.base / 'opt/nvim'
        (target / 'bin').mkdir(parents=True)
        old = target / 'bin/nvim'
        old.write_text('#!/bin/sh\necho old\n')
        old.chmod(0o755)
        link = self.base / 'nvim-link'
        link.symlink_to(old)
        helper = str(self.repo / 'bin/dotfiles-install-nvim')
        self.stub('curl', 'exit 22\n')
        result = self.run_command('bash', helper, 'unused', str(target), str(link), success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('old', old.read_text())
        archive = self.base / 'nvim.tar.gz'
        package = self.base / 'package/bin'
        package.mkdir(parents=True)
        new = package / 'nvim'
        self.stub('curl', f'while [[ "$1" != -o ]]; do shift; done\ncp "{archive}" "$2"\n')
        for valid in (False, True):
            new.write_text('#!/bin/sh\n' + ('echo new\n' if valid else 'exit 1\n'))
            new.chmod(0o755)
            with tarfile.open(archive, 'w:gz') as tar:
                tar.add(package.parent, arcname='nvim-linux-test')
            result = self.run_command('bash', helper, 'unused', str(target), str(link), success=valid)
            if not valid:
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('old', old.read_text())
            else:
                self.assertIn('new', old.read_text())
                self.assertEqual(link.resolve(), old)
        old.write_text('#!/bin/sh\necho old\n')
        real_mv = shutil.which('mv')
        self.stub('mv', f'if [[ "$1" == -fT ]]; then exit 1; fi\nexec "{real_mv}" "$@"\n')
        result = self.run_command('bash', helper, 'unused', str(target), str(link), success=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('old', old.read_text())
        self.assertEqual(link.resolve(), old)
        self.assertFalse(list(target.parent.glob('.dotfiles-nvim.*')))

    def test_syntax_and_lockfile(self):
        scripts = list(self.repo.glob('*.sh')) + list((self.repo / 'bin').iterdir()) + list((self.repo / '.local/bin').iterdir()) + [self.repo / '.claude/hooks/notify.sh']
        for script in scripts:
            self.run_command('bash', '-n', str(script))
        if shutil.which('zsh'):
            for script in (self.repo / '.config/zsh').iterdir():
                self.run_command('zsh', '-n', str(script))
        lock = json.loads((self.repo / '.config/nvim/lazy-lock.json').read_text())
        self.assertIn('LazyVim', lock)


if __name__ == '__main__':
    unittest.main()
