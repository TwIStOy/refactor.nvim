---@class refactor.core.finder.capture
local M = {}

---@type refactor.utils.treesitter
local Treesitter = require("refactor.utils.treesitter")
---@type refactor.utils.typed
local Typed = require("refactor.utils.typed")

---@class refactor.core.finder.CaptureOption
---@field query? string
---@field query_name? string
---@field query_lang? string
---@field match_captures? string|string[]

---@param opts refactor.core.finder.CaptureOption
function M.validate_capture_opts(opts)
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

---@param opts refactor.core.finder.CaptureOption
---@return TSQuery?, string[]
function M.normalize_capture(opts)
  local lang = Typed.if_nil_with(opts.query_lang, Treesitter.buf_get_lang)
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
  return query, matches
  -- local tree = Treesitter.root_at_cursor()
  -- local root = tree:root()
  --
  -- --  local root = self:root_at({ pos[1], pos[2] - 1 })
  -- -- if root == nil then
  -- -- 	return nil, nil
  -- -- end
  -- -- local root_from_line, _, root_to_line, _ = root:range()
  -- -- root, self.source, root_from_line, root_to_line + 1
  -- query:iter_matches()
end

return M
