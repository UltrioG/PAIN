--[[
	A library of common functions.
--]]

local common = {}

---Runs a function for each item in the table
---@generic IndexType, ValueType, ReturnType
---@param f fun(i: IndexType, v: ValueType): ReturnType?
---@param T table<IndexType, ValueType>
---@param nonparallel boolean? Whether the map should be ran in parallel
---@return table<IndexType, ReturnType>
common.map = function(f, T, nonparallel)
	local output = {}
	local toRun = {}
	for k, v in pairs(T) do table.insert(toRun, function() output[k] = f(k, v) end) end
	if not nonparallel then
		parallel.waitForAll(table.unpack(toRun))
	else
		for _, v in pairs(toRun) do v() end
	end
	return output
end

---Find the key of a certain item in a table.
---@generic K, T
---@param T table<K, any>
---@param equality T
---@return K?
common.findk = function(T, equality)
	local output = nil
	for k, v in pairs(T) do
		if type(equality) == "function" and equality(v) or v == equality then output = k break end
	end
	return output
end

---Find an item in a table which matches a predicate.
---@generic K, T
---@param T table<K, any>
---@param pred fun(item: T): boolean
---@return T
common.findPred = function(T, pred)
	local output = nil
	for _, v in pairs(T) do
		if pred(v) then output = v break end
	end
	return output
end

---Find an item in a table which matches a predicate, and return its key.
---@generic K, T
---@param T table<K, any>
---@param pred fun(item: T): boolean
---@return T
common.findPredk = function(T, pred)
	local output = nil
	for k, v in pairs(T) do
		if pred(v) then output = k break end
	end
	return output
end

---Find all items in a table which matches a predicate.
---@generic K
---@param T table<K, any>
---@param pred fun(item: any): boolean
---@return K[]
common.findAll = function(T, pred)
	local output = {}
	for _, v in pairs(T) do
		if pred(v) then table.insert(output, v) break end
	end
	return output
end

---Find all items in a table which matches a predicate, and return their keys.
---@generic K
---@param T table<K, any>
---@param pred fun(item: any): boolean
---@return K[]
common.findAllk = function(T, pred)
	local output = {}
	for k, v in pairs(T) do
		if pred(v) then table.insert(output, k) break end
	end
	return output
end

--- Sums the numbers in the table
---@param T number[]
---@return number
common.sumTable = function (T)
	local x = 0
	common.map(function(_, v) x = x + v end, T)
	return x
end

--- Multiplies the numbers in the table
---@param T number[]
---@return number
common.productTable = function (T)
	local x = 1
	common.map(function(_, v) x = x * v end, T)
	return x
end

common.concatTable = function (...)
	local c = {}
	for _, T in ipairs({...}) do
		for _, v in ipairs(T) do
			table.insert(c, v)
		end
	end
	return c
end

---Compares whether all elements of two tables are equal.
---@param A table
---@param B table
---@return boolean
common.tableShallowEqual = function (A, B)
	for k, _ in pairs(A) do if not B[k] then return false end if B[k] ~= A[k] then return false end end
	return true
end

---Compares whether all elements of two tables are equal, including the children tables.\
---Answer generously stolen from igv on StackOverflow
---@param A table
---@param B table
---@return boolean
common.tableSuperShallowEqual = function (A, B)
	local o1, o2 = A, B
	if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end
	
	local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or common.tableSuperShallowEqual(value1, value2) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end

---Makes a shallow clone of the table:\
--- That is, changing values in the new table does not change the values in the original table.\
--- Note that subtables are not shallow cloned. For that, use `common.deepCloneTable`.
---@param T table
---@return table
common.cloneTable = function (T)
	local new = {}
	for k, v in pairs(T) do new[k] = v end
	return new
end

---Makes a shallow clone of the table:\
--- That is, changing values in the new table does not change the values in the original table.\
--- Note that subtables are also deep shallow cloned.
---@param T any
---@return any
common.deepCloneTable = function (T)
	if type(T) ~= "table" then return T end
	local new = {}
	for k, v in pairs(T) do new[k] = common.deepCloneTable(v) end
	return new
end

return common