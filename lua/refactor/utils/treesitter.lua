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

---@return TSTree?
function M.root_at_cursor()
  -- assume current buffer has been parsed
  local lang_tree = M.buf_get_parser()
  if lang_tree:is_valid() then
    lang_tree:parse()
  end
  local row, col = Vim.current_cursor0()
  local range = { row, col, row, col }
  return lang_tree:tree_for_range(range, { ignore_injections = false })
end

---@class refactor.utils.treesitter.ValidateNodeFullOption
---@field node any
---@field expect_types? string[]
---@field valid_fn? fun(node: TSNode): boolean

---@class refactor.utils.treesitter.ValidateNodeShortArray
---@field [1] any
---@field [2] string[]
---@field [3]? fun(node: TSNode): boolean

---@alias refactor.utils.treesitter.ValidateNodeOption refactor.utils.treesitter.ValidateNodeFullOption|refactor.utils.treesitter.ValidateNodeShortArray

---@param opt refactor.utils.treesitter.ValidateNodeOption
---@return refactor.utils.treesitter.ValidateNodeFullOption
local function normalize_validate_node_option(opt)
  if vim.tbl_islist(opt) and #opt == 2 then
    return {
      node = opt[1],
      expect_types = opt[2],
      valid_fn = opt[3],
    }
  end
  return opt --[[@as refactor.utils.treesitter.ValidateNodeFullOption]]
end

---@param opts table<string, refactor.utils.treesitter.ValidateNodeOption>
function M.validate_nodes(opts)
  for arg, opt in pairs(opts) do
    opt = normalize_validate_node_option(opt)
    local node = opt.node
    local expect_types = Typed.if_nil(opt.expect_types, {})
    local valid_fn = Typed.if_nil(opt.valid_fn, function()
      return true
    end)
    if node == nil then
      error(("Expect a non-nil node for arg %s"):format(arg))
    end
    local succ, node_type = pcall(node.type, node)
    if not succ then
      error(
        ("Expect a valid node for arg %s, got type: %s"):format(arg, type(node))
      )
    end
    if #expect_types > 0 and not vim.tbl_contains(expect_types, node_type) then
      error(
        ("Expect node type to be one of [%s], got %s"):format(
          table.concat(expect_types, ", "),
          node_type
        )
      )
    end
    if not valid_fn(node) then
      error(("Node validation failed for arg %s"):format(arg))
    end
  end
end

return M
