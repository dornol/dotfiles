local opt = vim.opt

opt.relativenumber = true
opt.scrolloff = 8
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.colorcolumn = "120"
opt.wrap = false
opt.clipboard = "unnamedplus"

-- undo 파일 저장 (재시작해도 undo 가능)
opt.undofile = true
opt.undolevels = 1000
