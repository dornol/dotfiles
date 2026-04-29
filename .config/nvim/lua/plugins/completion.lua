return {
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        ghost_text = { enabled = false },
      },
      -- 스니펫 소스 제거 (멀티라인 자동완성 방지)
      sources = {
        default = { "lsp", "path", "buffer" },
      },
      -- 완성 수락 시 undo 브레이크포인트 추가
      keymap = {
        ["<CR>"] = {
          function(cmp)
            if cmp.is_visible() then
              vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<C-g>u", true, true, true), "n", false
              )
              return cmp.accept()
            end
          end,
          "fallback",
        },
      },
    },
  },
}
