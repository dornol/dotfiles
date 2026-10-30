"""Network integration check; never reads or modifies the user's Neovim profile."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
CHECK = '''
local config = require("lazy.core.config")
for _, item in ipairs(config.spec.notifs) do
  if item.level >= vim.log.levels.ERROR then
    error(item.msg)
  end
end
for name, plugin in pairs(config.plugins) do
  if require("lazy.core.plugin").has_errors(plugin) then
    error("Plugin task failed: " .. name)
  end
end
if vim.v.errmsg ~= "" then error(vim.v.errmsg) end
'''


def main():
    with tempfile.TemporaryDirectory(prefix='dotfiles-nvim-') as directory:
        home = Path(directory)
        config = home / '.config/nvim'
        shutil.copytree(ROOT / '.config/nvim', config)
        env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / '.config'),
                   XDG_DATA_HOME=str(home / '.local/share'),
                   XDG_STATE_HOME=str(home / '.local/state'),
                   XDG_CACHE_HOME=str(home / '.cache'))
        for key in ('NVIM_APPNAME', 'VIMINIT', 'EXINIT', 'VIMRUNTIME'):
            env.pop(key, None)
        lazy = home / '.local/share/nvim/lazy/lazy.nvim'
        subprocess.run(['git', 'clone', '--filter=blob:none',
                        'https://github.com/folke/lazy.nvim.git', str(lazy)],
                       env=env, check=True, timeout=120)
        commit = json.loads((config / 'lazy-lock.json').read_text())['lazy.nvim']['commit']
        subprocess.run(['git', '-C', str(lazy), 'checkout', commit],
                       env=env, check=True, timeout=60)
        check = home / 'check.lua'
        check.write_text('local ok, err = pcall(function()\n' + CHECK + '''
end)
if not ok then
  io.stderr:write(tostring(err) .. "\\n")
  vim.cmd("cquit 1")
end
''')
        # Restore waits for plugin tasks; the second process checks a fresh startup.
        for commands in (['+Lazy! restore'], []):
            subprocess.run(['nvim', '--headless', *commands,
                            '+luafile ' + str(check), '+qa!'],
                           cwd=home, env=env, check=True, timeout=600)

        # Verify the check fails for the same missing-extra class of regression.
        settings = config / 'lua/config/lazy.lua'
        settings.write_text(settings.read_text().replace(
            'spec = {',
            'spec = { { import = "lazyvim.plugins.extras.lang.dotfiles_missing_extra" },', 1))
        result = subprocess.run(['nvim', '--headless', '+luafile ' + str(check), '+qa!'],
                                cwd=home, env=env, text=True, capture_output=True, timeout=60)
        if result.returncode == 0 or 'dotfiles_missing_extra' not in result.stderr:
            raise RuntimeError('Neovim check did not detect the missing extra: ' + result.stderr)
        print('Neovim restore, startup, and missing-extra detection passed.')


if __name__ == '__main__':
    main()
