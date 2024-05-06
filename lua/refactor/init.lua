---@class refactor
local M = {}

---@type refactor.config
M.config = require("refactor.config")

---@param opts refactor.config.SetupOptions
function M.setup(opts)
  M.config.setup(opts)
end

function M.test()
  ---@type refactor.core
  local Core = require("refactor.core")

  local bind_query = [[
[
((binding
  expression: (_) @expr
)) 
] @refactor
]]

  return Core.finder.find_capture {
    query = bind_query,
    query_lang = "nix",
  }
end

return M
