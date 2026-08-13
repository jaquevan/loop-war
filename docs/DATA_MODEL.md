# Data model

## The key insight

**Save the pattern, not the audio.**

A beat is a list of which card fired on which step at which pitch. A few hundred
bytes. Playback is deterministic: same pattern + same cards = same beat, on
every client, forever.

This makes saving, sharing, spectating, scrubbing, share codes, and player
profiles all essentially free. No rendering, no audio storage, and patterns
replicate over the network as plain tables.

## Pattern format

```lua
type Note = {
    step: number,      -- 1..steps
    note: number?,     -- semitone offset from card rootNote; nil for one-shots
    vel: number?,      -- 0..1, defaults to 1
    offset: number?,   -- ms nudge off the grid, for un-quantized placement
    length: number?,   -- in steps, for sustained melodic notes
}

type Track = {
    cardId: string,
    notes: { Note },
    volume: number,    -- 0..1
    muted: boolean,
    effect: string?,   -- "echo" | "pitch" | "filter" | nil
    effectAmount: number?,
}

type Pattern = {
    version: number,   -- bump on format change; migrate on load
    bpm: number,       -- must be one of the locked BPMs
    steps: number,     -- default 16, customizable
    swing: number,     -- 0..1
    tracks: { Track },
}
```

`offset` is what makes "move things precisely if you don't want the grid" work.
Clamp it to something musically meaningful (±half a step) rather than allowing
arbitrary values — see `CONSTRAINTS.md` #6 on real timing resolution.

Version the format from day one. You will change it, and players will have saved
beats when you do.

## Card schema

```lua
type Card = {
    id: string,
    assetId: string,          -- Roblox audio asset
    displayName: string,
    category: Category,       -- see Constants.CATEGORIES
    kind: "oneshot" | "loop",
    bpm: number?,             -- required when kind == "loop"
    rootNote: number?,        -- required for melodic categories
    rarity: "common" | "rare" | "epic" | "legendary",
    source: "stock" | "premium" | "community",

    -- community cards only
    creatorUserId: number?,
    tags: { string }?,        -- player text: must be filtered
    description: string?,     -- player text: must be filtered
    licenseRef: string,       -- assets/licenses/<id>.md
    available: boolean,       -- false if moderated away; play silence
}
```

Categories: `kick`, `snare`, `hat`, `perc`, `bass808`, `piano`, `synth`, `pad`,
`lead`, `vocal`, `fx`.

**Rarity affects draft frequency, never power.** Enforce this as a review rule,
not just an intention — no legendary card should be objectively louder,
cleaner, or more versatile than its common equivalent.

## Custom sound distribution

Per the brief: a creator's own sounds are freely available to them, but it is
*extremely rare* for an opponent to be dealt someone else's custom sound.

```
Draft pool composition (per pack slot):
  stock         ~85%
  premium        ~13%
  community       ~2%   <- of which the creator's own are excluded
```

The 2% is the creator's payoff — their sound occasionally appearing in a
stranger's match — without letting the competitive pool fill with unvetted
audio. Tune the number after launch; start conservative.

In Free For All, a player's own collection is fully available with no rarity
gating.

## Save data

```lua
type PlayerData = {
    version: number,
    inventory: { [string]: boolean },     -- cardId -> owned
    beats: { [string]: SavedBeat },       -- slotId -> beat
    favorites: { string },                -- beat ids shown on profile
    elo: number,
    wins: number,
    losses: number,
    cosmetics: { equipped: string, owned: { string } },
    currency: number,
    keybinds: { [string]: string },       -- action -> KeyCode name
}

type SavedBeat = {
    pattern: Pattern,
    title: string,      -- filtered before storage
    createdAt: number,
    mode: string,
}
```

Use a proven DataStore wrapper (ProfileStore / ProfileService or similar) rather
than raw `DataStoreService`. Session locking prevents the duplication bugs that
would otherwise eat the economy.

Cap save slots (start ~25). Extra slots are a clean, non-random monetization
lever.

## Share codes

Serialize a `Pattern` compactly, base64 it, prefix with a version byte. Players
copy and paste. This is the closest thing to "download your beat" that Roblox
allows — see `CONSTRAINTS.md` #10.

## Integrity rules

- The server owns inventory. A client asking to place card X does not prove
  ownership — check it.
- Validate every submitted pattern: track count, step bounds, note range,
  offset range, BPM in the allowed list, and every `cardId` real and legitimately
  available to that player in that mode.
- Filter beat titles, tags, and descriptions **before storage**, and store the
  filtered version.
- Never let a removed asset break a saved beat's load path. Flag `available =
  false`, play silence on that track, show "sound unavailable" in the editor.
