---@class refactor.core.finder
local M = {}

---@type refactor.core.finder.simple
local Simple = require("refactor.core.finder.simple")

---@type refactor.core.finder.capture
local Capture = require("refactor.core.finder.capture")

M.find_first_parent = Simple.find_first_parent
M.find_topmost_parent = Simple.find_topmost_parent
M.find_capture = Capture.find_capture

return M
