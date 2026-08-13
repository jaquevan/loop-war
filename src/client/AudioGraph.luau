--!strict
--[[
    AudioGraph — builds the mixer once, at session start.

    The current Roblox audio API is a wire graph:
        AudioPlayer -> Wire -> [effects] -> AudioDeviceOutput

    Build the structure once and reuse it. Creating instances per note causes
    audible hitching and burns memory.

    Per track:  AudioPlayer pool -> AudioPitchShifter -> AudioFader -> master
    Master:     AudioFader -> AudioLimiter -> AudioDeviceOutput

    The limiter is not optional. A dozen simultaneous samples with no limiting
    will clip.
]]

local ContentProvider = game:GetService("ContentProvider")
local Constants = require(game:GetService("ReplicatedStorage").Shared.Constants)

local AudioGraph = {}
AudioGraph.__index = AudioGraph

local function wire(source: Instance, target: Instance): Wire
    local w = Instance.new("Wire")
    w.SourceInstance = source
    w.TargetInstance = target
    w.Parent = target
    return w
end

function AudioGraph.new(parent: Instance)
    local self = setmetatable({}, AudioGraph)

    self._root = Instance.new("Folder")
    self._root.Name = "AudioGraph"
    self._root.Parent = parent

    self._output = Instance.new("AudioDeviceOutput")
    self._output.Parent = self._root

    self._masterLimiter = Instance.new("AudioLimiter")
    self._masterLimiter.Parent = self._root

    self._masterFader = Instance.new("AudioFader")
    self._masterFader.Parent = self._root

    wire(self._masterFader, self._masterLimiter)
    wire(self._masterLimiter, self._output)

    self._tracks = {}

    return self
end

--[[
    Creates a track.

    `voices` is how many hits can overlap on this track. One AudioPlayer cannot
    play two overlapping notes, so the pool is what stops a fast hi-hat roll
    from cutting itself off. Long tails (808s, crashes, pads) need more voices
    than closed hats.
]]
function AudioGraph:CreateTrack(index: number, assetId: string, voices: number?)
    local voiceCount = voices or 4

    local folder = Instance.new("Folder")
    folder.Name = "Track" .. index
    folder.Parent = self._root

    local fader = Instance.new("AudioFader")
    fader.Parent = folder

    local pitch = Instance.new("AudioPitchShifter")
    pitch.Parent = folder

    wire(pitch, fader)
    wire(fader, self._masterFader)

    local players = {}
    for i = 1, voiceCount do
        local player = Instance.new("AudioPlayer")
        player.Asset = assetId
        player.Parent = folder
        wire(player, pitch)
        players[i] = player
    end

    self._tracks[index] = {
        folder = folder,
        fader = fader,
        pitch = pitch,
        players = players,
        nextVoice = 1,
        muted = false,
        volume = 1,
    }

    return self._tracks[index]
end

--[[
    Fires a note.

    `semitones` is the offset from the card's root note; nil or 0 plays the
    sample as recorded. `atTime` is an os.clock() timestamp from the Transport —
    if it's in the future, the note is delayed to land on it.
]]
function AudioGraph:PlayNote(trackIndex: number, semitones: number?, atTime: number?)
    local track = self._tracks[trackIndex]
    if not track or track.muted then
        return
    end

    local function fire()
        local shift =
            math.clamp(semitones or 0, -Constants.MAX_SEMITONE_SHIFT, Constants.MAX_SEMITONE_SHIFT)
        track.pitch.Pitch = 2 ^ (shift / 12)

        local player = track.players[track.nextVoice]
        track.nextVoice = (track.nextVoice % #track.players) + 1

        player.TimePosition = 0
        player:Play()
    end

    if atTime then
        local delay = atTime - os.clock()
        if delay > 0.001 then
            task.delay(delay, fire)
            return
        end
    end

    fire()
end

--[[
    Preload every voice before a round starts. First-play latency is much worse
    than subsequent plays, and you do not want that on the downbeat.
]]
function AudioGraph:Warm()
    local assets = {}
    for _, track in self._tracks do
        for _, player in track.players do
            table.insert(assets, player)
        end
    end

    task.spawn(function()
        pcall(function()
            ContentProvider:PreloadAsync(assets)
        end)
    end)
end

function AudioGraph:SetTrackVolume(trackIndex: number, volume: number)
    local track = self._tracks[trackIndex]
    if track then
        track.volume = math.clamp(volume, 0, 1)
        track.fader.Volume = track.volume
    end
end

function AudioGraph:SetTrackMuted(trackIndex: number, muted: boolean)
    local track = self._tracks[trackIndex]
    if track then
        track.muted = muted
        track.fader.Volume = if muted then 0 else track.volume
    end
end

--[[
    Silences a track whose asset was moderated away, without erroring. See
    DATA_MODEL.md — a removed sound must never break a saved beat.
]]
function AudioGraph:MarkUnavailable(trackIndex: number)
    self:SetTrackMuted(trackIndex, true)
end

function AudioGraph:Destroy()
    self._root:Destroy()
    self._tracks = {}
end

return AudioGraph
