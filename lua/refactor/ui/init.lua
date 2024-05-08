---@class refactor.ui
local M = {}

local n = require("nui-components")

---@param ctxs refactor.actions.ActionContext[]
function M.open_ui(ctxs)
  local width = 0
  for _, ctx in ipairs(ctxs) do
    width = math.max(width, #ctx.name)
  end
  width = math.max(width, 20)
  local height = #ctxs

  local renderer = n.create_renderer {
    width = width + 2,
    height = height + 2,
  }

  local body = function()
    local nodes = {}
    for i, ctx in ipairs(ctxs) do
      nodes[#nodes + 1] = n.node {
        ctx = ctx,
        idx = i,
      }
    end

    return n.tree {
      autofocus = true,
      border_label = {
        text = "Refacator This",
        align = "center",
      },
      data = nodes,
      ---@diagnostic disable-next-line: unused-local
      on_select = function(ctx, component)
        ctx.ctx.do_refactor()
        renderer:close()
      end,
      ---@diagnostic disable-next-line: unused-local
      prepare_node = function(ctx, line, component)
        local text = ("%s. %s"):format(ctx.idx, ctx.ctx.name)
        if ctx.ctx.available() then
          line:append(text, "String")
        else
          line:append(text, "Comment")
        end
        return line
      end,
    }
  end

  renderer:render(body)
end

return M
