---@class refactor.core.finder
local M = {}

---@type refactor.core.finder.simple
local Simple = require("refactor.core.finder.simple")

M.find_first_parent = Simple.find_first_parent
M.find_topmost_parent = Simple.find_topmost_parent

return M
