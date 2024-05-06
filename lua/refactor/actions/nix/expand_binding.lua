---@class refactor.actions.nix.expand_binding
local M = {}

---@type refactor.core
local Core = require("refactor.core")

local bind_query = [[
[
((binding
  attrpath: (_) @attrpath
  expression: (_) @expr
)) 
] @refactor
]]

local selector = Core.selector.select_smallest_range

local finder = Core.finder.find_capture

function M.do_refactor()
  local captures = finder {
    query = bind_query,
    query_lang = "nix",
  }

  local matches = selector(captures)

  if matches == nil then
    return
  end

  local expr = matches["expr"]
  if expr == nil or #expr == 0 then
    return
  end

  local attrpath = matches["attrpath"]
  if attrpath == nil or #attrpath == 0 then
    return
  end

  local refactor = matches["refactor"]
  if refactor == nil or #refactor == 0 then
    return
  end

  local attr_nodes = attrpath[1]:field("attr")
  local attrs = {}
  for _, attr in ipairs(attr_nodes) do
    attrs[#attrs + 1] = vim.treesitter.get_node_text(attr, 0)
  end

  local generate_bindings = function(first, attr, previous)
    if first then
      return ("%s = %s;"):format(attr, previous)
    else
      return ("%s = { %s };"):format(attr, previous)
    end
  end

  local ret = vim.treesitter.get_node_text(expr[1], 0)
  for j = #attrs, 1, -1 do
    ret = generate_bindings(j == #attrs, attrs[j], ret)
  end

  local lines = vim.split(ret, "\n")
  Core.replace_node_text(refactor[1], lines)
end

return M
