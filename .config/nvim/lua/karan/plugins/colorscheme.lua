return {
  "navarasu/onedark.nvim",
  priority = 1000, -- make sure to load this before all the other start plugins
  config = function()
    local onedark = require 'onedark'
    onedark.setup {
      transparent = false,
    }

    require('onedark').load()
  end
}
