---@module "events.augment-command-palette"
---@author sravioli
---@license GNU-GPLv3

---@diagnostic disable: undefined-field
local wt = require "wezterm"

wt.on("augment-command-palette", function(_, _)
  return {
    {
      brief = "Colorscheme picker",
      icon = "md_palette",
      action = require("picker.colorscheme"):pick(),
    },
    {
      brief = "Font picker",
      icon = "md_format_font",
      action = require("picker.font"):pick(),
    },
    {
      brief = "Font size picker",
      icon = "md_format_font_size_decrease",
      action = require("picker.font-size"):pick(),
    },
    {
      brief = "Font leading picker",
      icon = "fa_text_height",
      action = require("picker.font-leading"):pick(),
    },
  }
end)
