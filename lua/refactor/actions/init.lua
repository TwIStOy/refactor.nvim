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

return M
