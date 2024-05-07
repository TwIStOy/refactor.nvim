---@class refactor
local M = {}

---@type refactor.config
M.config = require("refactor.config")

---@param opts refactor.config.SetupOptions
function M.setup(opts)
  M.config.setup(opts)
end

function M.test()
  ---@type refactor.ui
  local Ui = require("refactor.ui")
  ---@type refactor.actions
  local Actions = require("refactor.actions")

  local ctxs = Actions.Nix.create_context()
  Ui.open_ui(ctxs)
end

return M
