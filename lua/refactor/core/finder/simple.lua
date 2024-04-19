---@class refactor.core.finder.simple
local M = {}

---@type refactor.utils.typed
local Typed = require("refactor.utils.typed")

---@alias refactor.core.finder.NodeMatcher fun(node: TSNode): boolean

---@param leaf TSNode
---@param matcher refactor.core.finder.NodeMatcher
---@return TSNode?
function M.find_first_parent(leaf, matcher)
  ---@param node TSNode?
  ---@return TSNode?
  local function _impl(node)
    if node == nil then
      return nil
    end
    if matcher == nil or matcher(node) then
      return node
    end
    return _impl(node:parent())
  end

  return _impl(leaf)
end

---@param root TSNode
---@param matcher refactor.core.finder.NodeMatcher
function M.find_topmost_parent(root, matcher)
  ---@param node TSNode?
  ---@return TSNode?
  local function _impl(node)
    if node == nil then
      return nil
    end
    local current = nil
    if matcher == nil or matcher(node) then
      current = node
    end
    return Typed.if_nil(_impl(node:parent()), current)
  end

  return _impl(root)
end

return M
