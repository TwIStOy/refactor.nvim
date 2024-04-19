---@class refactor.utils
local M = {}

---@type refactor.utils.treesitter
M.treesitter = require("refactor.utils.treesitter")

---@type refactor.utils.typed
M.typed = require("refactor.utils.typed")

---@type refactor.utils.vim
M.vim = require("refactor.utils.vim")

return M
