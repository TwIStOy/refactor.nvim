---@class refactor.actions
local M = {}

---@type refactor.actions.cpp
M.Cpp = require("refactor.actions.cpp")

---@type refactor.actions.nix
M.Nix = require("refactor.actions.nix")

return M
