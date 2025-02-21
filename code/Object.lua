--
-- Project: lua-object
-- objects for Lua
--
-- Copyright 2015 Alexander Nusov. Licensed under the MIT License.
-- See @license text at http://www.opensource.org/licenses/mit-license.php
--
-- Docstrings added by Ultrio
--

---@class Object
---A basic object.
local Object = {}

function Object:__getinstance()
  local o = setmetatable({___instanceof=self}, self)
  self.__index = self
  return o
end

---Initializes a new instance of the class.
---@param ... any
function Object:init(...)
end

---Creates a new instance of the class.
---@see Object.init
function Object:new(...)
  local o = self:__getinstance()
  o:init(...)
  return o
end

function Object:extend(...)
  local cls = self:__getinstance()
  cls.init = function() end

  for k, f in pairs{...} do
    f(cls, self)
  end
  return cls
end

function Object.isTypeof(instance, class)
  return instance ~= nil and (instance.___instanceof == class)
end

function Object.isInstanceof(instance, class)
  return instance ~= nil and (instance.___instanceof == class or Object.isInstanceof(instance.___instanceof, class))
end

return Object