---@class refactor.utils.treesitter
local M = {}

---@type refactor.utils.typed
local Typed = require("refactor.utils.typed")

---@param buf? number
---@return string
function M.buf_get_lang(buf)
  buf = Typed.if_nil(buf, 0)
  local ft = vim.api.nvim_get_option_value("filetype", {
    buf = buf,
  })
  return Typed.if_nil(vim.treesitter.language.get_lang(ft), ft)
end

return M
