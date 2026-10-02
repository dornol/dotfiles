local opt = vim.opt

opt.number = false
opt.relativenumber = false
opt.signcolumn = "no"
opt.foldcolumn = "0"
opt.scrolloff = 8
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.colorcolumn = ""
opt.mouse = ""
opt.showcmd = false
opt.wrap = false
-- Keep LazyVim's clipboard default: unnamedplus locally, no automatic sync on SSH.

-- tab 문자를 보이지 않게 (LazyVim 기본값 override)
opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }

-- undo 파일 저장 (재시작해도 undo 가능)
opt.undofile = true
opt.undolevels = 1000
