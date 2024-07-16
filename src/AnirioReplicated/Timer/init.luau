--!strict
-- Timer Class Module

-- A class to fire signals/events at regular intervals
-- Includes features such as pausing the timer and changing the time function

-- Note: Either os.clock() or time() can be the default time function
-- Plan: Add functionality for allow-drift timers as seen in sleitnick's timer

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
	_trove: Trove.Trove,
	ticked: Signal.Signal<>,

	_tickIntervalSeconds: number,
	_startTime: number,
	_lastUnpausedTime: number,
	_pausedRunningTime: number,
	_totalTickTime: number,
	_isRunning: boolean,
	_time: () -> number,
}

-- Define module type
export type TimerType = typeof(setmetatable({} :: TimerData, Timer)) & {
	destroy: (self: TimerType) -> (),
}

---------- Variables ----------

local defaultTimeFunction = os.clock

---------- Module functions ----------

-- Constructor
function Timer.new(intervalSeconds: number): TimerType
	-- New object
	local self = setmetatable({} :: TimerData, Timer) :: TimerType

	-- Attributes
	-- Initialize attributes here

	local trove = Trove.new()

	self._trove = trove
	self.ticked = trove:Add(Signal.new())
	self._tickIntervalSeconds = intervalSeconds
	self._isRunning = false
	self._time = defaultTimeFunction

	-- Methods
	-- Call methods to set up the object here

	self:reset()
	self:_setUpSignals()

	-- Return object
	return self
end

-- Set
-- Define set methods here

-- Set the interval (in seconds) at which the timer ticks
function Timer.setTickInterval(self: TimerType, intervalSeconds: number)
	self._tickIntervalSeconds = intervalSeconds
end

-- Reset the timer's elapsed time
function Timer.reset(self: TimerType)
	self._startTime = self._time()
	self._lastUnpausedTime = self._startTime
	self._pausedRunningTime = 0
	self._totalTickTime = 0
end

-- Start the timer with reset time; optionally fires a timer tick
function Timer.start(self: TimerType, tickImmediately: boolean)
	-- Validate not running
	if self._isRunning then
		return
	end

	-- Tick once if needed
	if tickImmediately then
		self.ticked:Fire()
	end

	-- Reset time
	self:reset()

	-- Start
	self._isRunning = true
end

-- Pause the timer; the elapsed time will not change and no ticks will fire
function Timer.pause(self: TimerType)
	-- Validate running
	if not self._isRunning then
		return
	end

	-- Pause
	self._pausedRunningTime += self._time() - self._lastUnpausedTime
	self._isRunning = false
end

-- Unpause the timer, allowing it to tick
function Timer.unpause(self: TimerType)
	-- Validate paused
	if self._isRunning then
		return
	end

	-- Unpause
	self._lastUnpausedTime = self._time()
	self._isRunning = true
end

-- Modify the function used to give the timer's time; an example is a function that returns `Sound.TimePosition`
function Timer.setTimeFunction(self: TimerType, newTimeFunction: () -> number)
	if not self._isRunning then
		-- Change time function
		self._time = newTimeFunction
	else
		-- Save time by pausing
		self:pause()
		self._time = newTimeFunction
		self:unpause()
	end
end

-- Get
-- Define get methods here

-- Get the overall elapsed time since `start()` or `reset()`
function Timer.getElapsedTime(self: TimerType)
	local sessionRunningTime = (self._isRunning and (self._time() - self._lastUnpausedTime)) or 0
	return sessionRunningTime + self._pausedRunningTime
end

-- Get the elapsed time since the last timer tick
function Timer.getElapsedTimeSinceTick(self: TimerType)
	local totalElapsedTime = self:getElapsedTime()
	return totalElapsedTime - self._totalTickTime
end

-- Check whether the timer is currently running
function Timer.isRunning(self: TimerType)
	return self._isRunning
end

-- Signals
-- Define signal handling here

-- Set up signals
function Timer._setUpSignals(self: TimerType)
	self._trove:Add(RunService.Heartbeat:Connect(function()
		-- Ticked signal
		if self._isRunning and (self:getElapsedTimeSinceTick() >= self._tickIntervalSeconds) then
			self._totalTickTime += self._tickIntervalSeconds
			self.ticked:Fire()
		end
	end))
end

-- Clean up
-- Define cleanup methods here

-- Clean up the object
function Timer.destroy(self: TimerType)
	self._trove:Destroy()
	self:pause()
	self:reset()
end

---------- Return module ----------
return Timer
