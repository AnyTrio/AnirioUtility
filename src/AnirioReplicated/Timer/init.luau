--!strict
-- Timer Class Module

-- Plan: either os.clock() or time() can be the default time function

---------- Module ----------
local Timer = {}
Timer.__index = Timer

---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---------- Imports ----------

local Signal = require(ReplicatedStorage["Sleitnick's"].Signal)
local Trove = require(ReplicatedStorage["Sleitnick's"].Trove)

---------- Types ----------

type TimerData = {
	_trove: Trove.Trove,
	ticked: Signal.Signal<>,
	_tickIntervalSeconds: number,
	_startTime: number,
	_pausedDurationSeconds: number,
	_totalTickTime: number,
	_isRunning: boolean,
	_time: () -> number,
}
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
	self._time = defaultTimeFunction

	-- Methods
	-- Call methods to set up the object here

	self:reset()
	self:_setUpSignals()

	-- Return object
	return self
end

-- Set
function Timer.setTickInterval(self: TimerType, intervalSeconds: number)
	self._tickIntervalSeconds = intervalSeconds
end

function Timer.reset(self: TimerType)
	self._startTime = self._time()
	self._pausedDurationSeconds = 0
	self._totalTickTime = 0
	self._isRunning = false
end

function Timer.start(self: TimerType, tickImmediately: boolean)
	-- Validate not running
	if self._isRunning then
		return
	end

	-- Tick once if needed
	if tickImmediately then
		self.ticked:Fire()
	end

	-- Unpause
	self:unpause()
end

function Timer.pause(self: TimerType)
	-- Validate running
	if not self._isRunning then
		return
	end
	
	-- Pause
	self._pausedDurationSeconds += self._time() - self._startTime
	self._isRunning = false
end

function Timer.unpause(self: TimerType)
	-- Validate paused
	if self._isRunning then
		return
	end
	
	-- Unpause
	self._startTime = self._time()
	self._isRunning = true
end

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
function Timer.getElapsedTime(self: TimerType)
	local sessionRunningTime = (self._isRunning and (self._time() - self._startTime)) or 0
	return sessionRunningTime + self._pausedDurationSeconds
end

function Timer.getElapsedTimeSinceTick(self: TimerType)
	local totalElapsedTime = self:getElapsedTime()
	return totalElapsedTime - self._totalTickTime
end

function Timer.isRunning(self: TimerType)
	return self._isRunning
end

-- Signals
function Timer._setUpSignals(self: TimerType)
	self._trove:Add(RunService.Heartbeat:Connect(function()
		-- Finished
		if self._isRunning and (self:getElapsedTimeSinceTick() >= self._tickIntervalSeconds) then
			self._totalTickTime += self._tickIntervalSeconds
			self.ticked:Fire()
		end
	end))
end

-- Clean up
function Timer.destroy(self: TimerType)
	self._trove:Destroy()
end

---------- Return module ----------
return Timer
