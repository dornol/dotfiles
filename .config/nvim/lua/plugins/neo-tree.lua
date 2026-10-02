return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = false, -- Press H in the tree to show filtered files.
        hide_dotfiles = true,
        hide_gitignored = true,
      },
    },
  },
}
