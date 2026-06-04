-- 터미널 리사이즈 시 창 비율 자동 조정
vim.api.nvim_create_autocmd("VimResized", {
  callback = function()
    vim.cmd("wincmd =")
  end,
})
