---@class refactor.actions.cpp.inline_typedef
local M = {}

---@type refactor.core
local Core = require("refactor.core")
---@type refactor.utils
local Utils = require("refactor.utils")

local bind_query = [[
[
((qualified_identifier))
] @refactor
]]

local selector = Core.selector.select_bigest_range

local finder = Core.finder.find_capture

---@param root TSNode
---@return TSNode[]
local function get_all_topest_qualified_identifier(root)
  local ret = {}

  ---@param node TSNode
  local function visit(node)
    if node:type() == "qualified_identifier" then
      ret[#ret + 1] = node
      return
    end
    for child in node:iter_children() do
      visit(child)
    end
  end

  visit(root)

  return ret
end

---@return refactor.actions.ActionContext
function M.create_context()
  local captures = finder {
    query = bind_query,
    query_lang = "cpp",
  }
  local matches = selector(captures)
  local buf = vim.api.nvim_get_current_buf()

  local available = function()
    return Utils.treesitter.not_empty_matches(matches, "refactor")
  end

  local do_refactor = function()
    assert(matches ~= nil)
    local refactor = matches["refactor"][1]
    local full_typename = vim.treesitter.get_node_text(refactor, buf)
    vim.ui.input({
      prompt = "Enter the new name: ",
      default = full_typename:gsub("::", "_"),
    }, function(input)
      if input == nil then
        return
      end

      local tree = Utils.treesitter.root_at_cursor()
      if tree == nil then
        return
      end
      local root = tree:root()

      ---@type TSNode[]
      local occurrences = vim
        .iter(get_all_topest_qualified_identifier(root))
        :filter(function(node)
          return vim.treesitter.get_node_text(node, buf) == full_typename
        end)
        :totable()
      table.sort(occurrences, function(a, b)
        local a_start_row, a_start_col, _, _ = a:range()
        local b_start_row, b_start_col, _, _ = b:range()
        return a_start_row < b_start_row
          or (a_start_row == b_start_row and a_start_col < b_start_col)
      end)

      ---@type lsp.TextEdit[]
      local edits = {}

      for _, node in ipairs(occurrences) do
        local start_row, start_col, end_row, end_col = node:range()
        edits[#edits + 1] = {
          newText = input,
          range = {
            start = { line = start_row, character = start_col },
            ["end"] = { line = end_row, character = end_col },
          },
        }
      end

      -- add the `using` statement on the top of the first occurrence
      if #occurrences > 0 then
        local first_occurrence = occurrences[1]

        local start_row, _, _, _ = first_occurrence:range()
        local line =
          vim.api.nvim_buf_get_lines(buf, start_row, start_row + 1, false)[1]
        local leading_spaces = line:match("^%s*")
        edits[#edits + 1] = {
          newText = ("%susing %s = %s;\n"):format(
            leading_spaces,
            input,
            full_typename
          ),
          range = {
            start = { line = start_row, character = 0 },
            ["end"] = { line = start_row, character = 0 },
          },
        }
      end

      vim.lsp.util.apply_text_edits(edits, buf, "utf-8")
    end)
  end

  return {
    name = "Inline Typedef",
    available = available,
    do_refactor = do_refactor,
  }
end

return M
