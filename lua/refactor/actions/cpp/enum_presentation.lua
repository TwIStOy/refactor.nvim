---@class refactor.actions.cpp.enum_presentation
local M = {}

---@type refactor.core
local Core = require("refactor.core")
---@type refactor.utils
local Utils = require("refactor.utils")

local bind_query = [[
[
(enum_specifier
  name: (_) @enum_name
  body: (_
  	(enumerator
    	name: (_) @enumerators
    )
  )
)
] @refactor
]]

local selector = Core.selector.select_smallest_range

local finder = Core.finder.find_capture

---@class refactor.actions.cpp.enum_presentation.SupportFunctions
local support_functions = {
  {
    id = "IntoString",
    title = "Into String",
    ---@param enum_name string
    ---@param enumerators string[]
    callback = function(enum_name, enumerators)
      local lines = {}
      lines[#lines + 1] = ("std::string ToString(%s value) {"):format(enum_name)
      lines[#lines + 1] = "   switch (value) {"
      for _, enumerator in ipairs(enumerators) do
        lines[#lines + 1] = ([[     case %s::%s: return "%s";]]):format(
          enum_name,
          enumerator,
          enumerator
        )
      end
      lines[#lines + 1] = "  }"
      lines[#lines + 1] = "}"
      return lines
    end,
  },
  {
    id = "FromString",
    title = "From String",
    ---@param enum_name string
    ---@param enumerators string[]
    callback = function(enum_name, enumerators)
      local lines = {}
      lines[#lines + 1] = ("%s %sFromString(const std::string& str) {"):format(
        enum_name,
        enum_name
      )
      for _, enumerator in ipairs(enumerators) do
        lines[#lines + 1] = ([[  if (str == "%s") { return %s::%s; } ]]):format(
          enumerator,
          enum_name,
          enumerator
        )
      end
      lines[#lines + 1] = "  assert(0);"
      lines[#lines + 1] = "}"
      return lines
    end,
  },
  {
    id = "SerdeJSON",
    title = "JSON Serde (nlohmann/json)",
    ---@param enum_name string
    ---@param enumerators string[]
    callback = function(enum_name, enumerators)
      local lines = {}
      lines[#lines + 1] = "namespace nlohmann {"
      lines[#lines + 1] = "template<>"
      lines[#lines + 1] = ("struct adl_serializer<%s> {"):format(enum_name)
      lines[#lines + 1] = ("  static %s from_json(const json& j) {"):format(
        enum_name
      )
      lines[#lines + 1] = "    std::string str = j.template get<std::string>();"
      for _, enumerator in ipairs(enumerators) do
        lines[#lines + 1] = ([[    if (str == "%s") { return %s::%s; }    ]]):format(
          enumerator,
          enum_name,
          enumerator
        )
      end
      lines[#lines + 1] =
        [[    throw std::invalid_argument("Invalid enum value");   ]]
      lines[#lines + 1] = "  }"

      lines[#lines + 1] = ("  static void to_json(json& j, %s t) {"):format(
        enum_name
      )
      lines[#lines + 1] = "    switch (t) {"
      for _, enumerator in ipairs(enumerators) do
        lines[#lines + 1] = ([[      case %s::%s: j = "%s"; break;]]):format(
          enum_name,
          enumerator,
          enumerator
        )
      end
      lines[#lines + 1] = "    }"
      lines[#lines + 1] = "  }"
      lines[#lines + 1] = "};"

      return lines
    end,
  },
}

local function get_output_func(id)
  if type(id) == "table" then
    id = id.id
  end
  for _, value in ipairs(support_functions) do
    if value.id == id then
      return value.callback
    end
  end
  return nil
end

local function select_functions(enum_name, enumerators, callback)
  local n = require("nui-components")

  local signal = n.create_signal {
    selected = {
      "IntoString",
    },
  }

  local options = {}
  for _, value in ipairs(support_functions) do
    options[#options + 1] = n.option(value.title, { id = value.id })
  end

  local renderer = n.create_renderer {
    width = 40,
    height = 10,
  }

  renderer:add_mappings {
    {
      mode = "n",
      key = "q",
      handler = function()
        renderer:close()
      end,
    },
  }

  renderer:render(function()
    local component = n.select {
      autofocus = true,
      border_label = "Select functions",
      selected = signal.selected,
      data = options,
      multiselect = true,
      on_select = function(nodes)
        signal.selected = nodes
      end,
      prepare_node = function(is_selected, node)
        local Line = require("nui.line")
        local line = Line()
        if is_selected then
          line:append("✔", "String")
        else
          line:append("◻", "Comment")
        end
        line:append(" ")
        line:append(node.text)

        return line
      end,
    }

    function component:mappings()
      local function action(key)
        return function()
          local actions = self:get_actions()
          actions[key]()
        end
      end
      local mode = { "i", "n", "v" }

      return {
        {
          mode = mode,
          key = { "<Space>" },
          handler = action("on_select"),
        },
        {
          mode = mode,
          key = { "j", "<Down>" },
          handler = action("on_focus_next"),
        },
        {
          mode = mode,
          key = { "k", "<Up>" },
          handler = action("on_focus_prev"),
        },
        {
          mode = "n",
          key = "<CR>",
          handler = function()
            renderer:close()

            local lines = {}
            for _, selected in ipairs(signal.selected:get_value()) do
              lines = vim.list_extend(
                lines,
                get_output_func(selected)(enum_name, enumerators)
              )
            end

            if #lines > 0 then
              callback(lines)
            end
          end,
        },
      }
    end

    return component
  end)
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
    return Utils.treesitter.not_empty_matches(
      matches,
      "refactor",
      "enum_name",
      "enumerators"
    )
  end

  local do_refactor = function()
    assert(matches ~= nil)
    ---@type TSNode
    local refactor = matches["refactor"][1]
    ---@type string[]
    local enumerators = vim
      .iter(matches["enumerators"])
      :map(function(node)
        return vim.treesitter.get_node_text(node, buf)
      end)
      :totable()
    local enum_name = vim.treesitter.get_node_text(matches["enum_name"][1], buf)

    local _, _, end_row, _ = refactor:range()
    local range = {
      start = { line = end_row + 1, character = 0 },
      ["end"] = { line = end_row + 1, character = 0 },
    }

    select_functions(enum_name, enumerators, function(lines)
      vim.lsp.util.apply_text_edits({
        {
          newText = table.concat(lines, "\n"),
          range = range,
        },
      }, buf, "utf-8")
    end)
  end

  return {
    name = "Enum Presentation",
    available = available,
    do_refactor = do_refactor,
  }
end

return M
