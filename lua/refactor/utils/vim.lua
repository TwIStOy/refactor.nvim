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
