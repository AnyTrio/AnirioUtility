--!strict
-- Class Module Template

-- Template by Panicks28
-- For generic types, check out AnirioReplicated/AnirioTable

---------- Module ----------
local SomeModule = {}
SomeModule.__index = SomeModule

---------- Services ----------

---------- Imports ----------

---------- Types ----------

-- Define module data with potential properties
type SomeData = {
	-- Declare properties here
	a: string,
	b: number,
}

-- Define module type
export type SomeType = typeof(setmetatable({} :: SomeData, SomeModule)) & {
	destroy: (self: SomeType) -> (),
}

---------- Instances ----------

---------- Variables ----------

---------- Local functions ----------

---------- Module functions ----------

-- Constructor
function SomeModule.new(): SomeType
	-- New object
	local self = setmetatable({} :: SomeData, SomeModule) :: SomeType

	-- Attributes
	-- Initialize attributes here

	-- Methods
	-- Call methods to set up the object here

	-- Return object
	return self
end

-- Set
-- Define set methods here

-- Get
-- Define get methods here

-- Combination
-- Define combinations of set and get here

-- Signals
-- Define signal handling here

-- Set up signals
function SomeModule._setUpSignals(self: SomeType)

end

-- Clean up
-- Define cleanup methods here

-- Clean up the object
function SomeModule.destroy(self: SomeType)

end

---------- Calling / connecting functions ----------

---------- Return module ----------
return SomeModule
