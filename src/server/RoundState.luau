--!strict
--[[
    RoundState — the authoritative match state machine.

    The server owns the clock, the draft, the votes, and pattern validation.
    The client owns nothing. Every phase transition happens here and is
    broadcast; clients render what they are told.

    Skeleton. Phase handlers are stubs — filled in during Phase 2 of the
    roadmap. The validation and voting logic below is real, because those are
    the parts that must not be built loosely.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)
local VoteTally = require(script.Parent.VoteTally)

local RoundState = {}
RoundState.__index = RoundState

export type Phase = "waiting" | "prompt" | "draft" | "build" | "playback" | "vote" | "result"

local PHASE_DURATIONS: { [string]: number } = {
    prompt = 5,
    playback = 20,
    vote = 10,
    result = 10,
}

function RoundState.new(players: { Player }, mode: string)
    local self = setmetatable({}, RoundState)

    self.players = players
    self.mode = mode
    self.phase = "waiting" :: Phase
    self.phaseEndsAt = 0

    self.prompt = nil
    self.decks = {} -- [userId] = { cardId }
    self.patterns = {} -- [userId] = Pattern
    self.ballots = {} -- [userId] = VoteTally.Ballot
    self.buildDuration = Constants.DEFAULT_BUILD_TIMER

    return self
end

function RoundState:_setPhase(phase: Phase)
    self.phase = phase

    local duration = if phase == "build"
        then self.buildDuration
        elseif phase == "draft" then Constants.DRAFT_PICK_TIMEOUT * Constants.DRAFT_PICKS * 2
        else PHASE_DURATIONS[phase]

    self.phaseEndsAt = os.clock() + (duration or 0)
    -- TODO: broadcast phase change to clients
end

function RoundState:Start()
    self:_setPhase("prompt")
    -- TODO: generate prompt (genre + bpm + modifier), then advance to draft
end

--[[
    Server-side pattern validation. Never trust a submitted pattern.

    Checks structure, bounds, and — the one that actually matters — that every
    referenced card is legitimately available to this player in this mode.
]]
function RoundState:ValidatePattern(userId: number, pattern: any): boolean
    if type(pattern) ~= "table" or type(pattern.tracks) ~= "table" then
        return false
    end
    if not table.find(Constants.BPMS, pattern.bpm) then
        return false
    end
    if
        type(pattern.steps) ~= "number"
        or pattern.steps < Constants.MIN_STEPS
        or pattern.steps > Constants.MAX_STEPS
    then
        return false
    end
    if #pattern.tracks > Constants.SOFT_TRACK_LIMIT then
        return false
    end

    -- In draft modes the deck is the whitelist. In free-for-all it's the
    -- player's inventory instead — resolved by the caller and passed in as the
    -- deck for this round.
    local allowed = self.decks[userId]
    if not allowed then
        return false
    end

    for _, track in pattern.tracks do
        if type(track.cardId) ~= "string" or not table.find(allowed, track.cardId) then
            return false
        end
        if type(track.notes) ~= "table" then
            return false
        end

        for _, note in track.notes do
            if type(note.step) ~= "number" or note.step < 1 or note.step > pattern.steps then
                return false
            end
            if note.note and math.abs(note.note) > Constants.MAX_SEMITONE_SHIFT then
                return false
            end
            if note.offset and math.abs(note.offset) > Constants.MAX_NOTE_OFFSET_MS then
                return false
            end
        end
    end

    return true
end

--[[
    Records a ballot.

    A player is never presented with their own beat, and the self-vote is
    stripped here as a backstop. Nothing about ballot filtering is communicated
    back — see VoteTally for why.
]]
function RoundState:SubmitBallot(voterUserId: number, ratings: { [number]: number }): boolean
    if self.phase ~= "vote" then
        return false
    end
    if self.ballots[voterUserId] then
        return false
    end

    local cleaned: { [number]: number } = {}
    for targetUserId, rating in ratings do
        if targetUserId ~= voterUserId and self.patterns[targetUserId] then
            cleaned[targetUserId] =
                math.clamp(math.round(rating), Constants.VOTE_MIN, Constants.VOTE_MAX)
        end
    end

    self.ballots[voterUserId] = {
        voterUserId = voterUserId,
        ratings = cleaned,
    }

    return true
end

--[[
    Resolves the round.

    Scores are means, so abstaining costs nobody anything. Dropped voters are
    returned for logging only and must never reach a client.
]]
function RoundState:Resolve(histories: { [number]: VoteTally.VoterHistory })
    local ballots = {}
    for _, ballot in self.ballots do
        table.insert(ballots, ballot)
    end

    local scores, dropped = VoteTally.tally(ballots, histories)

    for _, ballot in ballots do
        histories[ballot.voterUserId] =
            VoteTally.updateHistory(histories[ballot.voterUserId], ballot)
    end

    self:_setPhase("result")
    -- TODO: apply ELO, grant rewards (voters only), broadcast results
    return scores, dropped
end

return RoundState
