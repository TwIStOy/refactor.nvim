---@class refactor.utils.treesitter
local M = {}

---@type refactor.utils.typed
local Typed = require("refactor.utils.typed")

---@type refactor.utils.vim
local Vim = require("refactor.utils.vim")

---@param node TSNode?
function M.inspect_node(node)
  if node == nil then
    return "nil"
  end
  local start_row, start_col, end_row, end_col = node:range()
  local node_type = node:type()
  return ("(%s) %d:%d-%d:%d"):format(
    node_type,
    start_row,
    start_col,
    end_row,
    end_col
  )
end

---@param matches table<any, TSNode>
function M.inspect_matches(matches)
  local lines = {}
  for k, match in pairs(matches) do
    lines[#lines + 1] = ("Match %s:"):format(k)
    for _, node in ipairs(match) do
      lines[#lines + 1] = ("  %s"):format(M.inspect_node(node))
    end
  end
  return table.concat(lines, "\n")
end

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
  local pos = Vim.current_cursor0()
  local range = { pos.row, pos.col, pos.row, pos.col }
  return lang_tree:named_node_for_range(range, { ignore_injections = false })
end

---@return TSTree?
function M.root_at_cursor()
  -- assume current buffer has been parsed
  local lang_tree = M.buf_get_parser()
  if lang_tree:is_valid() then
    lang_tree:parse()
  end
  local pos = Vim.current_cursor0()
  local range = { pos.row, pos.col, pos.row, pos.col }
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
  if vim.islist(opt) and #opt == 2 then
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

---@param captures string[]
---@param query vim.treesitter.Query
---@param match_iter fun(): string, table<number, TSNode>, number
function M.make_capture_iter(captures, query, match_iter)
  local captures_map = Vim.as_index_table(captures)
  local current_match
  local current_capture_id
  local iter
  local pattern

  iter = function()
    -- if there is no current match to continue,
    if not current_match then
      pattern, current_match, _ = match_iter()

      -- occurs once there are no more matches.
      if not pattern then
        return nil
      end
    end
    while true do
      local node
      current_capture_id, node = next(current_match, current_capture_id)
      if not current_capture_id then
        break
      end

      local capture_name = query.captures[current_capture_id]

      if captures_map[capture_name] then
        local ret = {}
        for id, capture in pairs(current_match) do
          ret[query.captures[id]] = capture
        end
        return ret, node
      end
    end

    -- iterated over all captures of the current match, reset it to
    -- retrieve the next match in the recursion.
    current_match = nil

    -- tail-call-optimization! :fingers_crossed:
    return iter()
  end

  return iter
end

---@param matches table?
---@param ... string
---@return boolean
function M.not_empty_matches(matches, ...)
  if matches == nil then
    return false
  end
  local names = { ... }
  for _, field in ipairs(names) do
    if matches[field] == nil or #matches[field] == 0 then
      return false
    end
  end
  return true
end

---@param nodes TSNode[]
---@return TSNode[]
function M.unique_nodes(nodes)
  local seen = {}
  local ret = {}
  for _, node in ipairs(nodes) do
    local key = M.inspect_node(node)
    if not seen[key] then
      seen[key] = true
      ret[#ret + 1] = node
    end
  end
  return ret
end

return M
