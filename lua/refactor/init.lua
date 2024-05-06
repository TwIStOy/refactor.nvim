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
  Actions.Nix.expand_binding.do_refactor()
end

return M
