--!strict
-- Anirio Table Class Module

-- A class to simplify and optimize table accessing, inserting, and removing
-- Implements a set/multiset-like data structure for indexing values

-- Note: Lazy evaluation is used to optimize removeValues()

---------- Module ----------
local AnirioTable = {}
AnirioTable.__index = AnirioTable

---------- Types ----------

-- Define module data with potential properties
type TableData<T> = {
	-- Declare properties here
	_tableArray: {T},
	_tableValueState: {[T]: number},

	_useLazy: boolean,
	_lazyData: {
		_removingState: {[T]: number},
	},
}

-- Define module type
export type TableType<T> = typeof(setmetatable({} :: TableData<T>, AnirioTable)) & {
	destroy: (self: TableType<T>) -> (),
}

---------- Local functions ----------

-- Check whether value is a specific type; true if no type given
local function valueIsTypeOf(value, typeOfValue: string?): boolean
	if typeOfValue then
		return (typeof(value) == typeOfValue)
	else
		-- No type given
		return true
	end
end

-- Check whether value is a roblox class type; true if no class name given
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

-- A combination of `valueIsTypeOf()` and `valueIsA()`
local function valueIs(value, typeOfValue: string?, className: string?): boolean
	return valueIsTypeOf(value, typeOfValue) and valueIsA(value, className)
end

-- Change the value at the specified table index by a given amount; non-numbers are considered 0
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

-- Get the numerical value at the specified table index; non-numbers are considered 0
local function getTableValueNumber(table: {[any]: number}, key: any): number
	local value = table[key]
	return (valueIsTypeOf(value, "number") and value) or 0
end

-- Check whether a given table is empty
local function isTableEmpty(table: {[any]: any})
	return next(table) == nil
end

---------- Module functions ----------

-- Constructor

-- Create a new empty AnirioTable
function AnirioTable.new<T>(): TableType<T>
	-- New object
	local self = setmetatable({} :: TableData<T>, AnirioTable) :: TableType<T>

	-- Attributes
	-- Initialize attributes here

	self._tableArray = {}
	self._tableValueState = {}

	self._useLazy = true
	self._lazyData = {
		_removingState = {}
	}

	-- Methods
	-- Call methods to set up the object here

	-- Return object
	return self
end

-- Set
-- Define set methods here

-- (Internal) Evaluate delayed `removeValues()` operations
function AnirioTable._evaluateLazyRemove<T>(self: TableType<T>)
	-- Validate lazy data
	local removingState = self._lazyData._removingState
	if isTableEmpty(removingState) then
		return
	end

	-- Initialize new values
	local newValues: {T} = {}

	-- Look through old values
	for _, value in self._tableArray do
		-- Check removing value
		if removingState[value] then
			-- Remove value state
			changeTableValueBy(self._tableValueState, value, -1)
			changeTableValueBy(removingState, value, -1)
		else
			-- Add to new values
			table.insert(newValues, value)
		end
	end

	-- Update values
	self._tableArray = newValues

	-- Clear lazy data
	table.clear(self._lazyData._removingState)
end

-- (Internal) Keep the table up to date by evaluating delayed operations
function AnirioTable._update<T>(self: TableType<T>)
	self:_evaluateLazyRemove()
end

-- Modify whether the table delays evaluating `removeValues()`
function AnirioTable.setLazy<T>(self: TableType<T>, useLazy: boolean)
	-- Validate different state
	if self._useLazy == useLazy then
		return
	end

	-- Modify lazy state
	self._useLazy = useLazy

	-- Update if no longer using lazy
	if not useLazy then
		self:_update()
	end
end

-- Insert values from the given table into the stored table; already-stored values won't be inserted
function AnirioTable.insertUnique<T>(self: TableType<T>, values: {T}, validateTypeOf: string?, validateIsA: string?)
	-- Update
	self:_update()

	-- Look through inserted values
	for _, value in values do
		-- Validate value type
		if not valueIs(value, validateTypeOf, validateIsA) then
			continue
		end

		-- Validate unique value
		if self:contains(value) then
			continue
		end

		-- Insert value
		table.insert(self._tableArray, value)
		changeTableValueBy(self._tableValueState, value, 1)
	end
end

-- Insert all values from the given table into the stored table
function AnirioTable.insertAll<T>(self: TableType<T>, values: {T}, validateTypeOf: string?, validateIsA: string?)
	-- Update
	self:_update()

	-- Look through inserted values
	for _, value in values do
		-- Validate value type
		if not valueIs(value, validateTypeOf, validateIsA) then
			continue
		end

		-- Insert value
		table.insert(self._tableArray, value)
		changeTableValueBy(self._tableValueState, value, 1)
	end
end

-- Remove values in the given table from the stored table
function AnirioTable.removeValues<T>(self: TableType<T>, values: {T}, validateTypeOf: string?, validateIsA: string?)
	-- Update removing state
	local removingState = self._lazyData._removingState
	for _, value in values do
		-- Validate value type
		if not valueIs(value, validateTypeOf, validateIsA) then
			continue
		end

		-- Set removing state
		changeTableValueBy(removingState, value, 1)
	end

	-- Evaluate immediately if not using lazy
	if not self._useLazy then
		self:_evaluateLazyRemove()
	end
end

-- Get
-- Define get methods here

-- Access the stored values table
function AnirioTable.getArray<T>(self: TableType<T>): {T}
	-- Update
	self:_update()

	-- Return
	return self._tableArray
end

-- Access the state of a value; usually equivalent to the count of the value in the stored table
function AnirioTable.getValueState<T>(self: TableType<T>, value: T): number
	-- Update
	self:_update()

	-- Return
	return getTableValueNumber(self._tableValueState, value)
end

-- Check whether a value is found in the stored table
function AnirioTable.contains<T>(self: TableType<T>, value: T): boolean
	-- Update
	self:_update()

	-- Return
	local count = getTableValueNumber(self._tableValueState, value)
	return (count > 0)
end

-- Compare the stored table with the given table, returning the added and removed values as two tables
function AnirioTable.compareTableChanges<T>(self: TableType<T>, newTable: {T}): ({T}, {T})
	-- Update
	self:_update()

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

-- Clear the stored table
function AnirioTable.clear<T>(self: TableType<T>)
	table.clear(self._tableArray)
	table.clear(self._tableValueState)
	table.clear(self._lazyData._removingState)
end

-- Clean up the object
function AnirioTable.destroy<T>(self: TableType<T>)
	self:clear()
end

---------- Return module ----------
return AnirioTable
