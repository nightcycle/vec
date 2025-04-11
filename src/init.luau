--!strict
-- Services
-- Packages
local Option = require("@pkg/@nightcycle/option")
local Error = require("@pkg/@nightcycle/error")
-- Modules
-- Types
type Option<V> = Option.Option<V>
type VecImpl<V> = {
	-- __index: VecImpl<V>,
	-- __tostring: (self: any) -> string,
	-- __len: (self: any) -> number,
	-- __iter: (self: any) -> (typeof(next), { V }),
	display: (self: any) -> string,
	len: (self: any) -> number,
	drain: (self: any) -> { V },
	get: (self: any, index: number) -> Option<V>,
	contains: (self: any, value: V) -> boolean,
	isEmpty: (self: any) -> boolean,
	isMut: (self: any) -> false,
	asMut: (self: any) -> MutVec<V>,
	forEach: (self: any, callback: (value: V) -> ()) -> (),
	forEachPair: (self: any, callback: (index: number, value: V) -> ()) -> (),
	matchPair: <T>(self: any, callback: (index: number, value: V) -> Option<T>) -> Option<T>,
}

type MutVecImpl<V> = {
	display: (self: any) -> string,
	len: (self: any) -> number,
	get: (self: any, index: number) -> Option<V>,
	contains: (self: any, value: V) -> boolean,
	isEmpty: (self: any) -> boolean,
	isMut: (self: any) -> true,
	forEach: (self: any, callback: (value: V) -> ()) -> (),
	forEachPair: (self: any, callback: (index: number, value: V) -> ()) -> (),
	matchPair: <T>(self: any, callback: (index: number, value: V) -> Option<T>) -> Option<T>,
	-- __index: MutVecImpl<V>,
	-- __tostring: (self: any) -> string,
	-- __len: (self: any) -> number,
	-- __iter: (self: any) -> (typeof(next), { V }),
	append: (self: any, vec: Vec<V>) -> (),
	drain: (self: any) -> { V },
	clear: (self: any) -> (),
	dedup: (self: any) -> (),
	dedupBy: (self: any, predicate: (a: V, b: V) -> boolean) -> (),
	dedupAll: (self: any) -> (),
	extend: (self: any, slice: { V }) -> (),
	insert: (self: any, index: number, value: V) -> (),
	remove: (self: any, index: number) -> V,
	retain: (self: any, predicate: (value: V) -> boolean) -> (),
	push: (self: any, value: V) -> (),
	pop: (self: any) -> Option<V>,
	sort: (self: any, comparator: (a: V, b: V) -> boolean) -> () & (self: any) -> (),
	popIf: (self: any, predicate: (value: V) -> boolean) -> Option<V>,
	freeze: (self: any) -> Vec<V>,
}
export type Vec<V> = VecImpl<V>
-- typeof(setmetatable(
-- 	{} :: {
-- 		_array: { V },
-- 	},
-- 	{} :: VecImpl<V>
-- ))
export type MutVec<V> = MutVecImpl<V>
-- typeof(setmetatable(
-- 	{} :: {
-- 		_array: { V },
-- 	},
-- 	{} :: MutVecImpl<V>
-- )) & Vec<V>
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Vec = {} :: VecImpl<any>
local DeprecatedVec = Vec :: any
DeprecatedVec.__index = Vec

local MutVec = {} :: MutVecImpl<any>
local DeprecatedMutVec = MutVec :: any
DeprecatedMutVec.__index = MutVec
setmetatable(MutVec, Vec)

function DeprecatedVec.__tostring(self): string
	return self:display()
end
function DeprecatedVec.__len(self): number
	return #self._array
end
function Vec:display()
	return "Vec(" .. Error.displayAsJson(self._array) .. ")"
end
function Vec:len()
	return #self._array
end

function Vec:forEach(callback: (value: any) -> ())
	for i, value in ipairs(self._map) do
		callback(value)
	end
end

function Vec:forEachPair(callback: (i: any, value: any) -> ())
	for i, value in ipairs(self._map) do
		callback(i, value)
	end
end

function Vec:matchPair<T>(callback: (i: any, value: any) -> Option<T>): Option<T>
	for i, value in ipairs(self._map) do
		local opt = callback(i, value)
		if opt:isSome() then
			return opt
		end
	end
	return Option.none()
end

function DeprecatedVec.__iter(self)
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

function DeprecatedMutVec.__tostring(self): string
	return self:display()
end
function DeprecatedMutVec.__len(self): number
	return #self._array
end
function DeprecatedMutVec.__iter(self)
	return next :: any, self._array
end

function DeprecatedMutVec:append(vec: Vec<any>)
	for i, v in vec do
		table.insert(self._array, v)
	end
end

function MutVec:display()
	return "MutVec(" .. Error.displayAsJson(self._array) .. ")"
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
	return target:match(function(v)
		if predicate(v) then
			return self:pop()
		else
			return Option.none()
		end
	end, function()
		return Option.none()
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
	return selfFrozen :: any
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
		return self :: any
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
		return self :: any
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
