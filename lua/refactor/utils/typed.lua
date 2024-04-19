---@class refactor.utils.typed
local M = {}

---@generic T
---@param ... T?
---@return T
function M.if_nil(...)
  local values = { ... }
  for _, value in ipairs(values) do
    if value ~= nil and value ~= vim.NIL then
      return value
    end
  end
  ---@diagnostic disable-next-line missing-return
  assert(false, "All values are nil")
end

---@generic T
---@param value T?
---@param builder fun(): T
---@return T
function M.if_nil_with(value, builder)
  if value == nil or value == vim.NIL then
    return builder()
  end
  return value
end

return M
