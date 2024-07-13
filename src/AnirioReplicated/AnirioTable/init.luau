--!strict
-- Anirio Table Class Module

-- Extension class intended for faster table accessing and removing

---------- Module ----------
local AnirioTable = {}
AnirioTable.__index = AnirioTable

---------- Types ----------

-- Define module data with potential properties
type TableData<T> = {
	-- Declare properties here
	_tableArray: {T},
	_tableValueState: {[T]: number}
}

-- Define module type
export type TableType<T> = typeof(setmetatable({} :: TableData<T>, AnirioTable)) & {
	destroy: (self: TableType<T>) -> (),
}

---------- Local functions ----------

local function valueIsTypeOf(value, typeOfValue: string?): boolean
	if typeOfValue then
		return (typeof(value) == typeOfValue)
	else
		-- No type given
		return true
	end
end

local function valueIsA(value, className: string?): boolean
	if className then
		if (typeof(value) == "Instance") then
			return value:IsA(className)
		else
			-- Not instance
			return false
		end
	else
		-- No class given
		return true
	end
end

local function changeTableValueBy(table: {[any]: number}, key: any, delta: number)
	-- Validate delta
	if delta == 0 then
		return
	end

	-- Change value
	if typeof(table[key]) == "number" then
		table[key] += delta
		if table[key] == 0 then
			table[key] = nil
		end
	else
		table[key] = delta
	end
end

local function getTableValueNumber(table: {[any]: number}, key: any): number
	local value = table[key]
	return (valueIsTypeOf(value, "number") and value) or 0
end

---------- Module functions ----------

-- Constructor
function AnirioTable.new<T>(): TableType<T>
	-- New object
	local self = setmetatable({} :: TableData<T>, AnirioTable) :: TableType<T>

	-- Attributes
	-- Initialize attributes here

	self._tableArray = {}
	self._tableValueState = {}

	-- Methods
	-- Call methods to set up the object here

	-- Return object
	return self
end

-- Set
-- Define set methods here

-- Insert values from the given table into the stored table; repeated values won't be inserted
function AnirioTable.insertUnique<T>(self: TableType<T>, values: {T}, validateTypeOf: string?, validateIsA: string?)
	-- Look through inserted values
	for _, value in values do
		-- Validate type of value
		if not valueIsTypeOf(value, validateTypeOf) then
			continue
		end

		-- Validate roblox class type
		if not valueIsA(value, validateIsA) then
			continue
		end

		-- Validate unique value
		if self:isValueStored(value) then
			return
		end

		-- Insert value
		table.insert(self._tableArray, value)
		changeTableValueBy(self._tableValueState, value, 1)
	end
end

-- Insert all values from the given table into the stored table
function AnirioTable.insertAll<T>(self: TableType<T>, values: {T}, validateTypeOf: string?, validateIsA: string?)
	-- Look through inserted values
	for _, value in values do
		-- Validate type of value
		if not valueIsTypeOf(value, validateTypeOf) then
			continue
		end

		-- Validate roblox class type
		if not valueIsA(value, validateIsA) then
			continue
		end

		-- Insert value
		table.insert(self._tableArray, value)
		changeTableValueBy(self._tableValueState, value, 1)
	end
end

-- Remove values in the given table from the stored table
function AnirioTable.removeValues<T>(self: TableType<T>, values: {T}, validateTypeOf: string?, validateIsA: string?)
	-- Set up removing state
	local removingState: {[T]: number} = {}
	for _, value in values do
		-- Validate type of value
		if not valueIsTypeOf(value, validateTypeOf) then
			continue
		end

		-- Validate roblox class type
		if not valueIsA(value, validateIsA) then
			continue
		end

		-- Set removing state
		changeTableValueBy(removingState, value, 1)
	end

	-- Initialize new values
	local newValues: {T} = {}

	-- Look through old values
	for _, value in self._tableArray do
		-- Check removing value
		if removingState[value] then
			-- Remove value state
			self._tableValueState[value] = nil
			changeTableValueBy(removingState, value, -1)
		else
			-- Add to new values
			table.insert(newValues, value)
		end
	end

	-- Update values
	self._tableArray = newValues
end

-- Clear the stored table
function AnirioTable.clear<T>(self: TableType<T>)
	table.clear(self._tableArray)
	table.clear(self._tableValueState)
end

-- Get
-- Define get methods here

-- Access the stored values table
function AnirioTable.getArray<T>(self: TableType<T>): {T}
	return self._tableArray
end

-- Access the state of a value
function AnirioTable.getValueState<T>(self: TableType<T>, value: T): number
	return getTableValueNumber(self._tableValueState, value)
end

-- Check whether a value is stored
function AnirioTable.isValueStored<T>(self: TableType<T>, value: T): boolean
	local count = self._tableValueState[value]
	return (count and count > 0) or false
end

-- Compare the stored table with the given table, returning the added and removed values as two tables
function AnirioTable.compareTableChanges<T>(self: TableType<T>, newTable: {T}): ({T}, {T})
	-- Initialize added
	local addedValues: {T} = {}

	-- Find added values
	local newValueState: {[T]: number} = {}
	for _, newValue in newTable do
		-- Set new value state
		changeTableValueBy(newValueState, newValue, 1)

		-- Validate added value
		if not (getTableValueNumber(newValueState, newValue) > self:getValueState(newValue)) then
			continue
		end

		-- Store added value
		table.insert(addedValues, newValue)
	end

	-- Initialize removed
	local removedValues: {T} = {}
	local removedValueState: {[T]: number} = {}

	-- Find removed values
	for _, value in self:getArray() do
		-- Validate removed value
		if not (getTableValueNumber(newValueState, value) < self:getValueState(value)) then
			continue
		end

		-- Set removed value state
		changeTableValueBy(removedValueState, value, 1)

		-- Store removed value
		table.insert(removedValues, value)
	end

	-- Return changes
	return addedValues, removedValues
end

-- Clean up
-- Define cleanup methods here

function AnirioTable.destroy<T>(self: TableType<T>)
	self:clear()
end

---------- Return module ----------
return AnirioTable
