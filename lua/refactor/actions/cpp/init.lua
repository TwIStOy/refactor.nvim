---@class refactor.actions.cpp
local M = {}

---@type refactor.actions.cpp.inline_typedef
M.inline_typedef = require("refactor.actions.cpp.inline_typedef")

---@type refactor.actions.cpp.enum_presentation
M.enum_presentation = require("refactor.actions.cpp.enum_presentation")

M.create_context = function()
  local ret = {}

  ret[#ret + 1] = M.inline_typedef.create_context()
  ret[#ret + 1] = M.enum_presentation.create_context()

  return ret
end

return M
