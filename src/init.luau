--!strict
-- Services
-- Packages
local Option = require("@wally/Option")
local Error = require("@wally/Error")
-- Modules
-- Types
type Option<V> = Option.Option<V>
type VecImpl<V> = {
	__index: VecImpl<V>,
	__tostring: (self: Vec<V>) -> string,
	__len: (self: Vec<V>) -> number,
	__iter: (self: Vec<V>) -> (typeof(next), { V }),
	drain: (self: Vec<V>) -> { V },
	get: (self: Vec<V>, index: number) -> Option<V>,
	contains: (self: Vec<V>, value: V) -> boolean,
	isEmpty: (self: Vec<V>) -> boolean,
	isMut: (self: Vec<V>) -> false,
	asMut: (self: Vec<V>) -> MutVec<V>,
}

type MutVecImpl<V> = {
	__index: MutVecImpl<V>,
	__tostring: (self: MutVec<V>) -> string,
	__len: (self: MutVec<V>) -> number,
	__iter: (self: MutVec<V>) -> (typeof(next), { V }),
	append: (self: MutVec<V>, vec: Vec<V>) -> (),
	drain: (self: Vec<V>) -> { V },
	clear: (self: MutVec<V>) -> (),
	dedup: (self: MutVec<V>) -> (),
	dedupBy: (self: MutVec<V>, predicate: (a: V, b: V) -> boolean) -> (),
	dedupAll: (self: MutVec<V>) -> (),
	extend: (self: MutVec<V>, slice: { V }) -> (),
	insert: (self: MutVec<V>, index: number, value: V) -> (),
	remove: (self: MutVec<V>, index: number) -> V,
	retain: (self: MutVec<V>, predicate: (value: V) -> boolean) -> (),
	push: (self: MutVec<V>, value: V) -> (),
	pop: (self: MutVec<V>) -> Option<V>,
	sort: (self: MutVec<V>, comparator: (a: V, b: V) -> boolean) -> () & (self: MutVec<V>) -> (),
	popIf: (self: MutVec<V>, predicate: (value: V) -> boolean) -> Option<V>,
	isMut: (self: MutVec<V>) -> true,
	freeze: (self: MutVec<V>) -> Vec<V>,
}
export type Vec<V> = typeof(setmetatable(
	{} :: {
		_array: { V },
	},
	{} :: VecImpl<V>
))
export type MutVec<V> = typeof(setmetatable(
	{} :: {
		_array: { V },
	},
	{} :: MutVecImpl<V>
)) & Vec<V>
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Vec = {} :: VecImpl<any>
Vec.__index = Vec

local MutVec = {} :: MutVecImpl<any>
MutVec.__index = MutVec
setmetatable(MutVec, Vec)

function Vec.__tostring(self: Vec<any>): string
	return "Vec(" .. Error.displayAsJson(self) .. ")"
end
function Vec.__len(self: Vec<any>): number
	return #self._array
end
function Vec.__iter(self: Vec<any>)
	return next :: any, self._array
end

function Vec:get(index: number): Option<any>
	return Option.from(self._array[index])
end

function Vec:drain(): { any }
	return self._array
end

function Vec:contains(value: any): boolean
	return table.find(self._array, value) ~= nil
end

function Vec:isEmpty(): boolean
	return #self._array == 0
end

function Vec:isMut(): false
	return (not table.isfrozen(self._array)) :: false
end

function Vec:asMut(): MutVec<any>
	local out = setmetatable({
		_array = table.clone(self._array),
	}, MutVec) :: any
	table.freeze(out)
	return out
end

function MutVec.__tostring(self: MutVec<any>): string
	return "MutVec(" .. table.concat(self._array, ", ") .. ")"
end
function MutVec.__len(self: MutVec<any>): number
	return #self._array
end
function MutVec.__iter(self: MutVec<any>)
	return next :: any, self._array
end

function MutVec:append(vec: Vec<any>)
	for i, v in vec do
		table.insert(self._array, v)
	end
end

function MutVec:extend(array: { any })
	for i, v in ipairs(array) do
		table.insert(self._array, v)
	end
end

function MutVec:clear()
	table.clear(self._array)
end

function MutVec:dedup()
	local prior: any? = nil
	local i = 1
	while i <= #self._array do
		local v = self._array[i]
		if v == prior then
			table.remove(self._array, i)
		else
			prior = v
			i += 1
		end
	end
end

function MutVec:dedupBy(predicate: (a: any, b: any) -> boolean)
	local prior: any? = nil
	local i = 1
	while i <= #self._array do
		local v = self._array[i]
		if prior ~= nil and predicate(prior, v) then
			table.remove(self._array, i)
		else
			prior = v
			i += 1
		end
	end
end

function MutVec:dedupAll()
	local seen: { [any]: true? } = {}
	local i = 1
	while i <= #self._array do
		local v = self._array[i]
		if seen[v] then
			table.remove(self._array, i)
		else
			seen[v] = true
			i += 1
		end
	end
end

function MutVec:drain(): { any }
	return table.clone(self._array)
end

function MutVec:insert(index: number, value: any)
	assert(
		index >= 1 and index <= #self._array + 1,
		`insert index {index} out of bounds for vector of size {#self._array}`
	)
	table.insert(self._array, index, value)
end

function MutVec:remove(index: number): any
	assert(
		index >= 1 and index <= #self._array,
		`remove index {index} out of bounds for vector of size {#self._array}`
	)
	return table.remove(self._array, index)
end

function MutVec:retain(predicate: (value: any) -> boolean)
	local i = 1
	while i <= #self._array do
		local v = self._array[i]
		if not predicate(v) then
			table.remove(self._array, i)
		else
			i += 1
		end
	end
end

function MutVec:push(value: any)
	table.insert(self._array, value)
end

function MutVec:pop(): Option<any>
	return Option.from(table.remove(self._array, #self._array))
end

function MutVec:popIf(predicate: (value: any) -> boolean): Option<any>
	local target = Option.from(self._array[#self._array])
	return target:map(function(v)
		if predicate(v) then
			return self:pop()
		else
			return Option.none()
		end
	end)
end

function MutVec:sort(comparator: ((a: any, b: any) -> boolean)?)
	if comparator then
		table.sort(self._array, comparator)
	else
		table.sort(self._array)
	end
end

function MutVec:freeze(): Vec<any>
	local selfFrozen = setmetatable({
		_array = table.freeze(table.clone(self._array)),
	}, Vec)
	table.freeze(selfFrozen)
	return selfFrozen
end

return {
	emptyMut = function<V>(): MutVec<V>
		local self = setmetatable({
			_array = {},
		}, MutVec) :: any
		table.freeze(self)
		return self
	end,
	empty = function<V>(): Vec<V>
		local self = setmetatable({
			_array = table.freeze({}),
		}, Vec)
		table.freeze(self)
		return self
	end,
	from = function<V>(initial: { V }): Vec<V>
		local array: { V } = if table.isfrozen(initial) then initial else table.clone(initial)
		if not table.isfrozen(array) then
			table.freeze(array)
		end
		local self = setmetatable({
			_array = array,
		}, Vec)
		table.freeze(self)
		return self
	end,
	fromMut = function<V>(initial: { V }): MutVec<V>
		local self = setmetatable({
			_array = table.clone(initial),
		}, MutVec) :: any
		table.freeze(self)
		return self
	end,
	isVec = function(value: unknown?): boolean
		if typeof(value) == "table" then
			return getmetatable(value :: any) == Vec
		end
		return false
	end,
	isMutVec = function(value: unknown?): boolean
		if typeof(value) == "table" then
			return getmetatable(value :: any) == MutVec
		end
		return false
	end,
}
