--!strict
--[[
    Constants shared between client and server.

    BPMs are locked deliberately. Roblox cannot time-stretch audio, so every
    loop asset must be authored at a tempo we support. See docs/CONSTRAINTS.md
]]

local Constants = {}

Constants.BPMS = { 90, 120, 140, 160 }
Constants.DEFAULT_BPM = 140

Constants.DEFAULT_STEPS = 16
Constants.MIN_STEPS = 8
Constants.MAX_STEPS = 64
Constants.SOFT_TRACK_LIMIT = 12 -- raise if performance allows; see roadmap

-- Scheduler tuning. Lookahead buys tolerance for frame hitches; the tick
-- interval must be comfortably shorter than the lookahead window.
Constants.SCHEDULE_LOOKAHEAD = 0.1
Constants.SCHEDULE_INTERVAL = 0.025

-- Off-grid nudge range, in milliseconds. Clamped because the engine cannot
-- deliver finer resolution reliably. See CONSTRAINTS.md #6.
Constants.MAX_NOTE_OFFSET_MS = 120

Constants.BUILD_TIMER_OPTIONS = { 60, 90, 120, 180 }
Constants.DEFAULT_BUILD_TIMER = 90
Constants.DRAFT_PICKS = 4
Constants.DRAFT_PACK_SIZE = 3
Constants.DRAFT_PICK_TIMEOUT = 10

Constants.MODES = {
    DRAFT = "draft", -- 1v1, pick one pass two
    TRIPLE_DRAFT = "triple_draft", -- 3 players, pack and pass
    COMMUNITY = "community", -- 4-12, identical kit
    FREE_FOR_ALL = "ffa", -- own collection, no draft
    PRIVATE = "private", -- host configured
}

Constants.RANKED_MODES = { Constants.MODES.DRAFT, Constants.MODES.COMMUNITY }

Constants.CATEGORIES = {
    KICK = "kick",
    SNARE = "snare",
    HAT = "hat",
    PERC = "perc",
    BASS_808 = "bass808",
    PIANO = "piano",
    SYNTH = "synth",
    PAD = "pad",
    LEAD = "lead",
    VOCAL = "vocal",
    FX = "fx",
}

-- Categories that are played chromatically via AudioPitchShifter and therefore
-- require a rootNote on the card.
Constants.MELODIC_CATEGORIES = {
    Constants.CATEGORIES.BASS_808,
    Constants.CATEGORIES.PIANO,
    Constants.CATEGORIES.SYNTH,
    Constants.CATEGORIES.PAD,
    Constants.CATEGORIES.LEAD,
}

-- Every player must finish the draft holding at least one of each of these,
-- plus at least one melodic card, or the hand is unplayable.
Constants.GUARANTEED_CATEGORIES = {
    Constants.CATEGORIES.KICK,
    Constants.CATEGORIES.SNARE,
    Constants.CATEGORIES.HAT,
}

-- Draft pool composition. Community sounds appear rarely on purpose: a
-- creator's payoff is their sound occasionally showing up in a stranger's
-- match, without filling the competitive pool with unvetted audio.
Constants.POOL_WEIGHTS = {
    stock = 0.85,
    premium = 0.13,
    community = 0.02,
}

-- Rarity changes how often a card appears. It never changes how good it is.
Constants.RARITY_WEIGHTS = {
    common = 0.60,
    rare = 0.25,
    epic = 0.12,
    legendary = 0.03,
}

Constants.MAX_SEMITONE_SHIFT = 12
Constants.DEFAULT_SAVE_SLOTS = 25

-- Standard producer typing layout. Anyone from FL Studio or Ableton already
-- has this in their fingers. Overridable per player; see PlayerData.keybinds.
Constants.PIANO_KEYS = {
    Z = 0, X = 2, C = 4, V = 5, B = 7, N = 9, M = 11, -- lower white
    S = 1, D = 3, G = 6, H = 8, J = 10, -- lower black
    Q = 12, W = 14, E = 16, R = 17, T = 19, Y = 21, U = 23, -- upper white
    Two = 13, Three = 15, Five = 18, Six = 20, Seven = 22, -- upper black
}

Constants.VOTE_MIN = 1
Constants.VOTE_MAX = 5

table.freeze(Constants)

return Constants
