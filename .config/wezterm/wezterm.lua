local Config = require("utils.class.config"):new()

require "events.update-status"
require "events.augment-command-palette"

return Config:add("config"):add "mappings"
