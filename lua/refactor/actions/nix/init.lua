---@class refactor.actions.nix
local M = {}

---@type refactor.actions.nix.expand_binding
M.expand_binding = require("refactor.actions.nix.expand_binding")

M.create_context = function()
  local ret = {}

  ret[#ret + 1] = M.expand_binding.create_context()

  return ret
end

return M
