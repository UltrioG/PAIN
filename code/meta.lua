---@meta

---@generic T
---@alias list table<integer, T>

---@generic T
---@alias dictionary table<string, T>

---@alias InventoryPeripheralWrapped {size:(fun(): size:integer), list:(fun(): items:list<table?>), getItemDetail:(fun(slot: integer): info:table?), getItemLimit:(fun(slot: integer): limit:integer), pushItems:(fun(toName: string, fromSlot: integer, limit: integer?, toSlot: integer?): transferred:integer), pullItems:(fun(fromName: string, fromSlot: integer, limit: integer?, toSlot: integer?): transferred:integer)}

---@alias slot integer
---@alias count integer
---@alias slotList {[slot]: count}

---@alias ResourceType
---| "null"
---| "item"
---| "fluid"
---| "energy"

---@alias Flags table<string, boolean>