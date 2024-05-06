---@class refactor.core.finder.capture
local M = {}

---@type refactor.utils.treesitter
local Treesitter = require("refactor.utils.treesitter")
---@type refactor.utils.typed
local Typed = require("refactor.utils.typed")
---@type refactor.utils.vim
local Vim = require("refactor.utils.vim")

---@class refactor.core.finder.capture.VLine
---@field start_row integer
---@field end_row integer

---@class refactor.core.finder.capture.Visual
---@field start_pos refactor.utils.vim.Position0
---@field end_pos refactor.utils.vim.Position0

---@class refactor.core.finder.CaptureOption
---@field query? string
---@field query_name? string
---@field query_lang? string
---@field match_captures? string|string[]
---@field mode? refactor.core.finder.capture.VLine|refactor.core.finder.capture.Visual|refactor.utils.vim.Position0

---@param opts refactor.core.finder.CaptureOption
local function validate_capture_opts(opts)
  if opts.query == nil and opts.query_name == nil then
    error("Expect either query or query_name to be provided")
  end
  if opts.query ~= nil and opts.query_name ~= nil then
    error("Expect only one of query or query_name to be provided")
  end
  if type(opts.match_captures) == "table" and #opts.match_captures == 0 then
    error("Expect match_captures to be a non-empty array")
  end
end

---@param mode refactor.core.finder.capture.VLine|refactor.core.finder.capture.Visual|refactor.utils.vim.Position0
---@return function(node: TSNode): boolean
local function generate_tsnode_filter(mode)
  if mode.start_row ~= nil then
    -- node should in range
    return function(node)
      local start_row, _, end_row, _ = node:range()
      return mode.start_row <= start_row and mode.end_row >= end_row
    end
  end
  if mode.start_pos ~= nil then
    return function(node)
      local start_row, start_col, end_row, end_col = node:range()
      return mode.start_pos.row <= start_row
        and mode.start_pos.col <= start_col
        and mode.end_pos.row >= end_row
        and mode.end_pos.col >= end_col
    end
  end
  return function(node)
    local start_row, start_col, end_row, end_col = node:range()
    return Vim.in_range(start_row, start_col, end_row, end_col)
  end
end

---@param opts refactor.core.finder.CaptureOption
---@return vim.treesitter.Query?, string[], function(node:TSNode): boolean
local function normalize_capture(opts)
  local lang = Typed.if_nil_with(opts.query_lang, Treesitter.buf_get_lang)
  local mode = Typed.if_nil_with(opts.mode, function()
    return Vim.current_cursor0()
  end)
  ---@type vim.treesitter.Query
  local query
  if opts.query ~= nil then
    query = vim.treesitter.query.parse(lang, opts.query)
  else
    query = vim.treesitter.query.get(lang, opts.query_name or "refactor")
  end
  local matches
  if opts.match_captures == nil then
    matches = {}
  elseif type(opts.match_captures) == "string" then
    matches = { opts.match_captures }
  else
    matches = opts.match_captures --[[@as string[] ]]
  end
  matches[#matches + 1] = "refactor"
  return query, matches, generate_tsnode_filter(mode)
end

---@param opts refactor.core.finder.CaptureOption
---@return {[1]: table<string, TSNode>, [2]: TSNode}[]?
function M.find_capture(opts)
  validate_capture_opts(opts)
  local query, captures, filter = normalize_capture(opts)
  if query == nil then
    return nil
  end
  local tree = Treesitter.root_at_cursor()
  if tree == nil then
    return nil
  end
  local root = tree:root()
  local root_from_line, _, root_to_line, _ = root:range()
  local ret = {}
  for match, nodes in
    Treesitter.make_capture_iter(
      captures,
      query,
      query:iter_matches(
        root,
        0,
        root_from_line,
        root_to_line + 1,
        { all = true }
      )
    )
  do
    for _, node in ipairs(nodes) do
      if filter(node) then
        print(Treesitter.inspect_matches(match))
        print(Treesitter.inspect_node(node))
        ret[#ret + 1] = { match, node }
      end
    end
  end
  return ret
end

return M
