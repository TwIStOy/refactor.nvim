---@class refactor.core
local M = {}

---@type refactor.core.finder
M.finder = require("refactor.core.finder")

---@type refactor.core.selector
M.selector = require("refactor.core.selector")

---@param node TSNode
---@param lines string[]
function M.replace_node_text(node, lines)
  local start_row, start_col, end_row, end_col = node:range()
  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, lines)
end

return M
