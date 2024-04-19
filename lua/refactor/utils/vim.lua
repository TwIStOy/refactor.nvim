---@class refactor.utils.vim
local M = {}

---Returns the current cursor position in the current buffer.
---Both line and column are 0-indexed.
---@return integer, integer
function M.current_cursor0()
  local c = vim.api.nvim_win_get_cursor(0)
  c[1] = c[1] - 1
  return c[1], c[2]
end

return M
