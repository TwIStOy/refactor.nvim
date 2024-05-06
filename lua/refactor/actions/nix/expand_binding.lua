---@class refactor.actions.nix.expand_binding
local M = {}

---@type refactor.core
local Core = require("refactor.core")
---@type refactor.utils
local Utils = require("refactor.utils")

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

---@return refactor.actions.ActionContext
function M.create_context()
  local captures = finder {
    query = bind_query,
    query_lang = "nix",
  }
  local matches = selector(captures)
  local buf = vim.api.nvim_get_current_buf()

  local available = function()
    return Utils.treesitter.not_empty_matches(
      matches,
      "expr",
      "attrpath",
      "refactor"
    )
  end

  local do_refactor = function()
    assert(matches ~= nil)
    local expr = matches["expr"][1]
    local attrpath = matches["attrpath"][1]
    local refactor = matches["refactor"][1]

    local attr_nodes = attrpath:field("attr")
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

    local ret = vim.treesitter.get_node_text(expr, buf)
    for j = #attrs, 1, -1 do
      ret = generate_bindings(j == #attrs, attrs[j], ret)
    end

    local lines = vim.split(ret, "\n")
    Core.replace_node_text(refactor, lines)
  end

  ---@type refactor.actions.ActionContext
  return {
    name = "Expand Binding",
    available = available,
    do_refactor = do_refactor,
  }
end

return M
