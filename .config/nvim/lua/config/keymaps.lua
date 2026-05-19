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

-- 라인넘버 토글 (signcolumn, foldcolumn 같이 처리)
map("n", "<leader>ul", function()
  if vim.opt.number:get() then
    vim.opt.number = false
    vim.opt.relativenumber = false
    vim.opt.signcolumn = "no"
    vim.opt.foldcolumn = "0"
  else
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.signcolumn = "yes"
    vim.opt.foldcolumn = "1"
  end
end, { desc = "Toggle line numbers" })

-- 마우스 토글
map("n", "<M-m>", function()
  if vim.opt.mouse:get()["a"] then
    vim.opt.mouse = ""
    vim.notify("Mouse: OFF")
  else
    vim.opt.mouse = "a"
    vim.notify("Mouse: ON")
  end
end, { desc = "Toggle mouse" })


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
