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
  local ctx = Actions.Nix.expand_binding.create_context()
  if ctx.available() then
    ctx.do_refactor()
  end
end

return M
