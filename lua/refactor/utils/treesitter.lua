---@class refactor.utils.treesitter
local M = {}

---@type refactor.utils.typed
local Typed = require("refactor.utils.typed")

---@type refactor.utils.vim
local Vim = require("refactor.utils.vim")

---@param buf? number
---@return string
function M.buf_get_lang(buf)
  buf = Typed.if_nil(buf, 0)
  local ft = vim.api.nvim_get_option_value("filetype", {
    buf = buf,
  })
  return Typed.if_nil(vim.treesitter.language.get_lang(ft), ft)
end

---@param buf? number
---@return vim.treesitter.LanguageTree
function M.buf_get_parser(buf)
  buf = Typed.if_nil(buf, 0)
  local lang = M.buf_get_lang(buf)
  return vim.treesitter.get_parser(buf, lang)
end

---Returns the smallest named node at current cursor. Parse the buffer is needed.
---@return TSNode?
function M.node_under_cursor()
  -- assume current buffer has been parsed
  local lang_tree = M.buf_get_parser()
  if lang_tree:is_valid() then
    lang_tree:parse()
  end
  local row, col = Vim.current_cursor0()
  local range = { row, col, row, col }
  return lang_tree:named_node_for_range(range, { ignore_injections = false })
end

return M
