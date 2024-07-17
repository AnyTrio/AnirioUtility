--!strict
-- Timer Class Module

-- A class to fire signals/events at regular intervals
-- Includes features such as pausing the timer and changing the time function

-- Note: Either `os.clock` or `time` can be the default time function, though time() can't be used for plugins
-- Plan: Account for the elapsed time's floating-point error that accumlates over large number of ticks

---------- Module ----------
local Timer = {}
Timer.__index = Timer

---------- Services ----------

local RunService = game:GetService("RunService")

---------- Imports ----------

local AnirioReplicated = script.Parent

local Packages = AnirioReplicated
local Signal = require(Packages.Signal)
local Trove = require(Packages.Trove)

---------- Types ----------

-- Define module data with potential properties
type TimerData = {
	-- Declare properties here
	_signalTrove: Trove.Trove,
	ticked: Signal.Signal<number, number>,

	_tickIntervalSeconds: number,
	_allowDrift: boolean,
	_time: () -> number,
	_updateSignal: RBXScriptSignal | Signal.Signal<>,

	_startTime: number,
	_lastUnpausedTime: number,
	_pausedRunningTime: number,
	_totalTickTime: number,
	_tickCount: number,
	_isRunning: boolean,
}

-- Define module type
export type TimerType = typeof(setmetatable({} :: TimerData, Timer)) & {
	destroy: (self: TimerType) -> (),
}

---------- Variables ----------

local precisionEpsilon = 5e-4

local defaultTimeFunction = os.clock
local defaultUpdateSignal = RunService.Heartbeat

---------- Module functions ----------

-- Constructor

-- Create a new Timer; configure it using "set" functions and call `start()` to start the timer
function Timer.new(intervalSeconds: number): TimerType
	-- New object
	local self = setmetatable({} :: TimerData, Timer) :: TimerType

	-- Attributes
	-- Initialize attributes here

	local signalTrove = Trove.new()

	self._signalTrove = signalTrove
	self.ticked = signalTrove:Add(Signal.new())
	self._allowDrift = true
	self._time = defaultTimeFunction
	self._updateSignal = defaultUpdateSignal
	self._isRunning = false

	-- Methods
	-- Call methods to set up the object here

	self:setTickInterval(intervalSeconds)
	self:reset()
	self:_setUpSignals()

	-- Return object
	return self
end

-- Set
-- Define set methods here

-- Modify the interval (in seconds) at which the timer ticks; must be nonnegative
function Timer.setTickInterval(self: TimerType, intervalSeconds: number)
	assert(intervalSeconds >= 0, "Interval must be a nonnegative number")
	self._tickIntervalSeconds = intervalSeconds
end

-- Set whether the tick signals drift
function Timer.setAllowDrift(self: TimerType, allowDrift: boolean)
	self._allowDrift = allowDrift
end

-- Modify the function used to give the timer's time; an example is a function that returns `Sound.TimePosition`
function Timer.setTimeFunction(self: TimerType, newTimeFunction: () -> number)
	if not self._isRunning then
		-- Change time function
		self._time = newTimeFunction
	else
		-- Save time by pausing first then unpausing later
		self:pause()
		self._time = newTimeFunction
		self:unpause()
	end
end

-- Modify the update signal at which the timer calculates the time and ticks
function Timer.setUpdateSignal(self: TimerType, newUpdateSignal: RBXScriptSignal | Signal.Signal<>)
	-- Update the signal
	self._updateSignal = newUpdateSignal
	self:_setUpSignals()
end

-- Reset the timer's elapsed time
function Timer.reset(self: TimerType)
	self._startTime = self._time()
	self._lastUnpausedTime = self._startTime
	self._pausedRunningTime = 0
	self._totalTickTime = 0
	self._tickCount = 0
end

-- Start the timer with reset time; optionally fires a timer tick; use `unpause()` to not reset the time
function Timer.start(self: TimerType, tickImmediately: boolean)
	-- Validate not running
	if self._isRunning then
		return
	end

	-- Reset time
	self:reset()

	-- Tick once if needed
	if tickImmediately then
		self:_fireTick()
	end

	-- Start
	self._isRunning = true
end

-- Pause the timer
function Timer.pause(self: TimerType)
	-- Validate running
	if not self._isRunning then
		return
	end

	-- Pause
	self._pausedRunningTime += self._time() - self._lastUnpausedTime
	self._isRunning = false
end

-- Unpause the timer
function Timer.unpause(self: TimerType)
	-- Validate paused
	if self._isRunning then
		return
	end

	-- Unpause
	self._lastUnpausedTime = self._time()
	self._isRunning = true
end

-- Get
-- Define get methods here

-- Get the elapsed time since `start()` or `reset()`
function Timer.getElapsedTime(self: TimerType)
	local sessionRunningTime = (self._isRunning and (self._time() - self._lastUnpausedTime)) or 0
	return sessionRunningTime + self._pausedRunningTime
end

-- Get the elapsed time since the last timer tick
function Timer.getElapsedTimeSinceTick(self: TimerType)
	local totalElapsedTime = self:getElapsedTime()
	return totalElapsedTime - self._totalTickTime
end

-- Get the number of ticks since `start()` or `reset()`
function Timer.getTickCount(self: TimerType)
	return self._tickCount
end

-- Check whether the timer is currently running
function Timer.isRunning(self: TimerType)
	return self._isRunning
end

-- Signals
-- Define signal handling methods here

-- (Internal) Fire tick signals and increase the timer's tick count
function Timer._fireTick(self: TimerType, tickCount: number?)
	-- Get tick info
	local elapsedTimeSinceTick = self:getElapsedTimeSinceTick()

	-- Calculate added ticks
	local addedTicks = tickCount or math.sign(elapsedTimeSinceTick)
	if addedTicks == 0 then
		addedTicks = 1
	end

	-- Fire signal
	self._tickCount += addedTicks
	self.ticked:Fire(self._tickCount, addedTicks)
end

-- (Internal) Set up signals
function Timer._setUpSignals(self: TimerType)
	self._signalTrove:Destroy()
	self._signalTrove:Add(self._updateSignal:Connect(function()
		-- Validate running
		if not self._isRunning then
			return
		end

		-- Ticked signal
		local elapsedTimeSinceTick = self:getElapsedTimeSinceTick()
		if math.abs(elapsedTimeSinceTick) + precisionEpsilon >= self._tickIntervalSeconds then
			-- print(`ETST: {elapsedTimeSinceTick}`)
			if self._allowDrift then
				-- Drift: the next tick will be at least interval seconds later
				self._totalTickTime += elapsedTimeSinceTick
				self:_fireTick()
			else
				-- No drift: ticks are fired according to the time function
				-- May tick multiple times per update signal
				local realEpsilon = precisionEpsilon * math.sign(elapsedTimeSinceTick)
				local tickCount = (elapsedTimeSinceTick + realEpsilon) / self._tickIntervalSeconds
				if tickCount ~= tickCount then
					-- nan
					self._totalTickTime += elapsedTimeSinceTick
					self:_fireTick()
				elseif math.abs(tickCount) == math.huge then
					-- ±inf
					self._totalTickTime += elapsedTimeSinceTick
					self:_fireTick()
				else
					-- Normal number
					tickCount = (math.modf(tickCount))
					self._totalTickTime += self._tickIntervalSeconds * tickCount
					self:_fireTick(tickCount)
				end
			end
		end
	end))
end

-- Clean up
-- Define cleanup methods here

-- Clean up the object
function Timer.destroy(self: TimerType)
	self._signalTrove:Destroy()
	self:pause()
	self:reset()
end

---------- Return module ----------
return Timer
