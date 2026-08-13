--!strict
--[[
    VoteTally — scoring a round's ballots.

    Three rules from the brief, all implemented here:

      1. Nobody votes on their own beat.
      2. Abstaining is neutral. Score is the MEAN of ratings received, so a
         player who doesn't vote is simply absent from the denominator and
         costs nobody anything.
      3. A voter who shows no discrimination — everything at the floor, or
         everything at the ceiling — has their ballot silently dropped. They
         get no feedback. As far as they can tell it worked.

    Rule 3 is deliberately quiet. Telling someone their vote was discarded
    teaches them how to evade the filter; letting them believe it landed means
    they keep doing the thing that gets caught.

    NOTE ON SMALL LOBBIES: in a 1v1 a spectator rates at most two beats, which
    is far too little signal for within-round variance analysis. That is why
    `voterHistory` exists — the real detection lives in a rolling window across
    recent rounds. Within-round checks only fire in lobbies of 4+.
]]

local Constants = require(game:GetService("ReplicatedStorage").Shared.Constants)

local VoteTally = {}

export type Ballot = {
    voterUserId: number,
    ratings: { [number]: number }, -- targetUserId -> 1..5
}

export type VoterHistory = {
    recentRatings: { number }, -- rolling window across rounds
    roundsSampled: number,
}

-- How many rounds of history before we trust the cross-round signal.
local HISTORY_MIN_SAMPLES = 12
local HISTORY_WINDOW = 40

-- A ballot with 3+ ratings that never leaves the floor or ceiling is not a
-- judgement, it's a stamp.
local WITHIN_ROUND_MIN_RATINGS = 3

local function mean(values: { number }): number
    if #values == 0 then
        return 0
    end
    local sum = 0
    for _, v in values do
        sum += v
    end
    return sum / #values
end

local function standardDeviation(values: { number }): number
    if #values < 2 then
        return 0
    end
    local m = mean(values)
    local acc = 0
    for _, v in values do
        acc += (v - m) ^ 2
    end
    return math.sqrt(acc / #values)
end

--[[
    Within-round check. Only meaningful in lobbies large enough to produce
    several ratings from one voter.
]]
local function isUndiscriminatingThisRound(ballot: Ballot): boolean
    local values = {}
    for _, rating in ballot.ratings do
        table.insert(values, rating)
    end

    if #values < WITHIN_ROUND_MIN_RATINGS then
        return false
    end

    if standardDeviation(values) > 0 then
        return false -- they varied at all; that's a real opinion
    end

    -- Zero variance. Only suspicious if parked at an extreme — someone who
    -- rates a whole lobby a flat 3 is uninterested, not malicious, and their
    -- ballot is harmless because it shifts nothing relative.
    local value = values[1]
    return value <= Constants.VOTE_MIN or value >= Constants.VOTE_MAX
end

--[[
    Cross-round check. This is the one that catches the 1v1 griefer, who can
    only ever rate one or two beats per round but does it every round.
]]
local function isUndiscriminatingOverall(history: VoterHistory?): boolean
    if not history then
        return false
    end
    if history.roundsSampled < HISTORY_MIN_SAMPLES then
        return false -- not enough evidence; give them the benefit of the doubt
    end

    local sd = standardDeviation(history.recentRatings)
    local avg = mean(history.recentRatings)

    if sd > 0.35 then
        return false
    end

    return avg <= Constants.VOTE_MIN + 0.35 or avg >= Constants.VOTE_MAX - 0.35
end

--[[
    Tallies a round.

    Returns per-beat mean scores plus a list of dropped voters. The dropped
    list is for logging and moderation only — it must never be sent to a
    client, including the voter's own client.
]]
function VoteTally.tally(
    ballots: { Ballot },
    histories: { [number]: VoterHistory }
): ({ [number]: number }, { number })
    local received: { [number]: { number } } = {}
    local dropped: { number } = {}

    for _, ballot in ballots do
        local history = histories[ballot.voterUserId]

        if isUndiscriminatingThisRound(ballot) or isUndiscriminatingOverall(history) then
            table.insert(dropped, ballot.voterUserId)
            continue
        end

        for targetUserId, rating in ballot.ratings do
            -- Rule 1, enforced again here as a backstop. The client should
            -- never have offered them their own beat in the first place.
            if targetUserId == ballot.voterUserId then
                continue
            end

            local clamped = math.clamp(math.round(rating), Constants.VOTE_MIN, Constants.VOTE_MAX)

            received[targetUserId] = received[targetUserId] or {}
            table.insert(received[targetUserId], clamped)
        end
    end

    -- Rule 2: mean, not sum. Abstention costs nobody anything.
    local scores: { [number]: number } = {}
    for userId, ratings in received do
        scores[userId] = mean(ratings)
    end

    return scores, dropped
end

--[[
    Folds a round's ballot into a voter's rolling history. Call this for every
    ballot, including dropped ones — a dropped voter who reforms should be able
    to age out of the filter.
]]
function VoteTally.updateHistory(history: VoterHistory?, ballot: Ballot): VoterHistory
    local updated: VoterHistory = history or { recentRatings = {}, roundsSampled = 0 }

    for _, rating in ballot.ratings do
        table.insert(updated.recentRatings, rating)
    end

    while #updated.recentRatings > HISTORY_WINDOW do
        table.remove(updated.recentRatings, 1)
    end

    updated.roundsSampled += 1
    return updated
end

return VoteTally
