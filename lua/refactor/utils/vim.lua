---@class refactor.utils.vim
local M = {}

---@class refactor.utils.vim.Position0
---@field row integer
---@field col integer

---Returns the current cursor position in the current buffer.
---Both line and column are 0-indexed.
---@return refactor.utils.vim.Position0
function M.current_cursor0()
  local c = vim.api.nvim_win_get_cursor(0)
  c[1] = c[1] - 1
  return {
    row = c[1],
    col = c[2],
  }
end

---Returns whether the cursor is in the range.
---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
---@param pos? refactor.utils.vim.Position0
---@return boolean
function M.in_range(start_row, start_col, end_row, end_col, pos)
  if pos == nil then
    pos = M.current_cursor0()
  end
  local start_status = (start_row < pos.row)
    or (start_row == pos.row and start_col <= pos.col)
  local end_status = (end_row > pos.row)
    or (end_row == pos.row and end_col >= pos.col)
  return start_status and end_status
end

---@param arr string[]
---@return table<string, boolean>
function M.as_index_table(arr)
  local ret = {}
  for _, v in ipairs(arr) do
    ret[v] = true
  end
  return ret
end

return M
