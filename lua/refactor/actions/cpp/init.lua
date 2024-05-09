---@class refactor.actions.cpp
local M = {}

---@type refactor.actions.cpp.inline_typedef
M.inline_typedef = require("refactor.actions.cpp.inline_typedef")

M.create_context = function()
  local ret = {}

  ret[#ret + 1] = M.inline_typedef.create_context()

  return ret
end

return M
