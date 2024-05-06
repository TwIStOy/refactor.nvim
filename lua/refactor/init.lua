---@class refactor
local M = {}

---@type refactor.config
M.config = require("refactor.config")

---@param opts refactor.config.SetupOptions
function M.setup(opts)
  M.config.setup(opts)
end

function M.test()
  ---@type refactor.actions
  local Actions = require("refactor.actions")
  Actions.Nix.expand_binding.expand_binding()
end

return M
