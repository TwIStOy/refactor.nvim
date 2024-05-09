---@class refactor.actions
local M = {}

---@type refactor.actions.cpp
M.Cpp = require("refactor.actions.cpp")

---@type refactor.actions.nix
M.Nix = require("refactor.actions.nix")

---@class refactor.actions.ActionContext
---@field name string
---@field do_refactor fun(): nil
---@field available fun(): boolean

local ft_to_actions = {
  nix = M.Nix,
  cpp = M.Cpp,
}

function M.create_context(ft)
  local creater = ft_to_actions[ft]
  if creater == nil then
    return {}
  end
  return creater.create_context()
end

return M
