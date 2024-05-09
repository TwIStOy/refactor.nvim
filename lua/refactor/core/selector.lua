---@class refactor.core.selector
local M = {}

---@param captures {[1]: table<string, TSNode>, [2]: TSNode}[]?
---@return table<string, TSNode>?
function M.select_smallest_range(captures)
  if captures == nil or #captures == 0 then
    return nil
  end
  local ret_matches
  local start_row, start_col
  for _, capture in ipairs(captures) do
    local matches, node = unpack(capture)
    if start_row == nil then
      start_row, start_col = node:range()
      ret_matches = matches
    else
      local cur_start_row, cur_start_col = node:range()
      if cur_start_row > start_row then
        start_row, start_col = cur_start_row, cur_start_col
        ret_matches = matches
      elseif cur_start_row == start_row and cur_start_col > start_col then
        start_row, start_col = cur_start_row, cur_start_col
        ret_matches = matches
      end
    end
  end
  return ret_matches
end

---@param captures {[1]: table<string, TSNode>, [2]: TSNode}[]?
---@return table<string, TSNode>?
function M.select_bigest_range(captures)
  if captures == nil or #captures == 0 then
    return nil
  end
  local ret_matches
  local start_row, start_col
  for _, capture in ipairs(captures) do
    local matches, node = unpack(capture)
    if start_row == nil then
      start_row, start_col = node:range()
      ret_matches = matches
    else
      local cur_start_row, cur_start_col = node:range()
      if cur_start_row < start_row then
        start_row, start_col = cur_start_row, cur_start_col
        ret_matches = matches
      elseif cur_start_row == start_row and cur_start_col < start_col then
        start_row, start_col = cur_start_row, cur_start_col
        ret_matches = matches
      end
    end
  end
  return ret_matches
end

return M
