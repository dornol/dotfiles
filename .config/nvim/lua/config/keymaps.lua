local map = vim.keymap.set

-- 버퍼 이동
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

-- 창 크기 조절
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- 라인 이동 (visual mode)
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move Line Down" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move Line Up" })

-- 검색 결과 중앙 정렬
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- 붙여넣기 시 레지스터 보호
map("x", "<leader>p", [["_dP]], { desc = "Paste Without Yanking" })

-- insert 모드 undo 브레이크포인트 (특수문자 입력 시 undo 단위 분리)
map("i", ",", ",<C-g>u")
map("i", ".", ".<C-g>u")
map("i", "!", "!<C-g>u")
map("i", "?", "?<C-g>u")

-- 복사 모드 토글: 좌측 chrome 다 끄기 (그냥 드래그로 깔끔 복사용)
local copy_mode = false
local saved_statuscolumn = nil
local saved_mouse = nil
map("n", "<leader>uc", function()
  copy_mode = not copy_mode
  if copy_mode then
    saved_statuscolumn = vim.opt.statuscolumn:get()
    saved_mouse = vim.opt.mouse:get()
    vim.opt.number = false
    vim.opt.relativenumber = false
    vim.opt.signcolumn = "no"
    vim.opt.foldcolumn = "0"
    vim.opt.statuscolumn = ""
    vim.opt.colorcolumn = ""
    vim.opt.mouse = ""
    pcall(function() Snacks.indent.disable() end)
  else
    vim.opt.number = false
    vim.opt.relativenumber = false
    vim.opt.signcolumn = "no"
    vim.opt.foldcolumn = "0"
    vim.opt.statuscolumn = saved_statuscolumn or ""
    vim.opt.colorcolumn = "120"
    vim.opt.mouse = saved_mouse or "a"
    pcall(function() Snacks.indent.enable() end)
  end
  vim.notify("Copy mode: " .. (copy_mode and "ON" or "OFF"))
end, { desc = "Toggle copy mode" })

-- Harpoon
local ok, harpoon = pcall(require, "harpoon")
if ok then
  map("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon Add" })
  map("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon Menu" })
  map("n", "<C-1>", function() harpoon:list():select(1) end, { desc = "Harpoon 1" })
  map("n", "<C-2>", function() harpoon:list():select(2) end, { desc = "Harpoon 2" })
  map("n", "<C-3>", function() harpoon:list():select(3) end, { desc = "Harpoon 3" })
  map("n", "<C-4>", function() harpoon:list():select(4) end, { desc = "Harpoon 4" })
end
