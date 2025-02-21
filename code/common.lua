local module = {}

---Returns a table with keys and values swapped.
---@generic k, v
---@param T table<k, v>
---@return table<v, k>
module.kvSwap = function (T)
	local new = {}
	for k, v in pairs(T) do new[v] = k end
	return new
end

---Find an item's index in a list
---@param L list
---@param v any
---@return integer
module.findInList = function(L, v)
	return module.kvSwap(L)[v]
end

---Check whether a table has a value
---@param T table
---@param v any
---@return boolean
module.hasValue = function (T, v)
	for _, w in pairs(T) do if w == v then return true end end
	return false
end

---Checks whether a dictionary is empty.
---@param D dictionary
---@return boolean
module.dictEmpty = function (D)
	return next(D) == nil
end

return module