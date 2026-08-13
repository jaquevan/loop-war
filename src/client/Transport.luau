--!strict
--[[
    Transport — the clock that drives playback.

    Roblox has no sample-accurate audio scheduling, so this uses the pattern web
    DAWs use: a coarse timer wakes often, looks a short distance into the
    future, and fires anything due inside that window. Audio scheduled slightly
    ahead with a known target time sounds far tighter than audio fired on
    whatever frame happens to land.

    The lookahead is also what makes off-grid `offset` values work: a note
    nudged 40ms late is still scheduled ahead of real time, so it lands where
    it was asked to.

    Usage:
        local t = Transport.new(140, 16)
        t.OnStep = function(step, scheduledTime) ... end
        t:Start()
]]

local RunService = game:GetService("RunService")
local Constants = require(game:GetService("ReplicatedStorage").Shared.Constants)

local Transport = {}
Transport.__index = Transport

function Transport.new(bpm: number, steps: number?)
    local self = setmetatable({}, Transport)

    self.bpm = bpm
    self.steps = steps or Constants.DEFAULT_STEPS
    self.swing = 0
    self.playing = false

    -- 16 steps per bar means 16th notes: four steps to a beat.
    self._stepDuration = (60 / bpm) / 4
    self._nextStepTime = 0
    self._currentStep = 0
    self._accumulator = 0
    self._connection = nil

    -- Fires with (step, scheduledTime). scheduledTime is in os.clock() terms
    -- and is slightly in the future — use it to place notes precisely.
    self.OnStep = nil
    self.OnLoop = nil

    return self
end

function Transport:Start()
    if self.playing then
        return
    end

    self.playing = true
    self._currentStep = 0
    self._nextStepTime = os.clock()
    self._accumulator = 0

    self._connection = RunService.Heartbeat:Connect(function(dt: number)
        self._accumulator += dt
        if self._accumulator < Constants.SCHEDULE_INTERVAL then
            return
        end
        self._accumulator = 0
        self:_tick()
    end)
end

function Transport:_tick()
    local horizon = os.clock() + Constants.SCHEDULE_LOOKAHEAD

    while self._nextStepTime < horizon do
        local previous = self._currentStep
        self._currentStep = (self._currentStep % self.steps) + 1

        if previous == self.steps and self.OnLoop then
            self.OnLoop()
        end

        if self.OnStep then
            self.OnStep(self._currentStep, self._nextStepTime + self:_swingOffset())
        end

        self._nextStepTime += self._stepDuration
    end
end

--[[
    Swing delays every other 16th. Zero swing is dead straight.
]]
function Transport:_swingOffset(): number
    if self.swing == 0 or self._currentStep % 2 == 1 then
        return 0
    end
    return self._stepDuration * self.swing * 0.5
end

function Transport:SetBPM(bpm: number)
    self.bpm = bpm
    self._stepDuration = (60 / bpm) / 4
end

function Transport:SetSteps(steps: number)
    self.steps = math.clamp(steps, Constants.MIN_STEPS, Constants.MAX_STEPS)
end

--[[
    Jump to a position. Used by spectator scrub.
]]
function Transport:Seek(step: number)
    self._currentStep = math.clamp(step, 0, self.steps)
    self._nextStepTime = os.clock()
end

function Transport:Stop()
    self.playing = false
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
    self._currentStep = 0
end

function Transport:Destroy()
    self:Stop()
    self.OnStep = nil
    self.OnLoop = nil
end

return Transport
