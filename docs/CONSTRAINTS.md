# Platform constraints

Read this before designing anything. Every item here has killed a feature
someone assumed was easy.

## 1. Players cannot upload audio from inside a Roblox experience

There is no runtime API for it. Audio upload happens through the Creator
Dashboard or the Open Cloud Assets API, both of which need an account and an
API key.

Limits at time of writing:

- Non-ID-verified accounts: ~10 audio uploads per 30 days
- ID-verified accounts: ~100 per 30 days
- Max 7 minutes; mp3 or ogg
- Everything passes through moderation before it is usable
- Uploads default to private; other experiences need explicit permission grants

**For the custom sounds feature:** it runs as external web app -> your backend
-> Open Cloud Assets API, uploading under your account or group. Your quota,
your moderation queue, your liability. Curated program, not a self-serve
button. Charging Robux for the upload does not change any of this — it just
adds a refund obligation when moderation rejects the file.

Practical caps to enforce at submission: file size, duration (target 10s or
less for one-shots), and a hard requirement that the uploader attests to
owning the work.

## 2. Copyright is the top ToS risk

Uploading audio you do not own violates ToS, and assets can be muted or removed
*after* upload — potentially breaking beats players have already saved. A
library of player-uploaded samples is an infringement magnet, and repeated
violations put the whole experience at risk, not just the asset.

Mitigations:
- Human review of every community submission before it enters the catalog
- Ownership attestation logged with userId and timestamp
- A takedown path and a ban path for repeat offenders
- Store a silent fallback so removed assets degrade instead of erroring
- `assets/licenses/` record for every stock sound

## 3. Paid random items are heavily regulated

If a pack is bought with Robux — directly, or via in-game currency purchasable
with Robux — then:

- Every possible outcome and its numerical probability must be shown as a
  percentage, summing to 100%, before purchase
- Same for keys, re-roll tokens, spin tickets, and anything that improves odds
  (odds must update dynamically when a booster is active)
- `PolicyService:GetPolicyInfoForPlayerAsync()` must be checked for
  `ArePaidRandomItemsRestricted`; restricted players cannot interact with the
  generator at all and need an alternative treatment

Consequence: **every sound must be purchasable directly.** Randomness is a
layer on top, never the only route to a card.

Rewards earned purely through gameplay with no Robux in the chain don't require
disclosure. Disclose anyway.

## 4. All player-authored text must be filtered

Beat titles, profile text, sound names, tags, descriptions — anything typed.
Server-side `TextService:FilterStringAsync()` wrapped in `pcall`, then
`GetNonChatStringForBroadcastAsync()`. If the pcall fails, display nothing.

Experiences that display unfiltered text get removed until fixed. Note this
applies to the **sound search feature** too: creator-supplied descriptions and
tags are player text.

## 5. No MIDI

Roblox has no MIDI API. `UserInputService` gives keyboard, mouse, touch, and
gamepad only. Third-party MIDI-to-QWERTY bridges emulate a physical keyboard at
the OS level, add latency, cap simultaneous keys, and cannot be supported by
you.

Design QWERTY-first with the standard producer typing layout. Custom keybinds
are in scope; MIDI is not.

## 6. Timing is not sample-accurate

No sample-accurate scheduler exists. Use the lookahead pattern web DAWs use:

- Transport clock from `os.clock()`
- Scheduler ticks every ~25ms, queues everything due in the next ~100ms
- Preload and warm every `AudioPlayer` before a round; first-play latency is
  much worse than subsequent plays

Expect tens of milliseconds of jitter.

**On off-grid placement:** the brief asks for precise placement when the player
doesn't want quantize. This is supported — each note carries a millisecond
offset from its step — but be honest in the UI about the resolution. Sub-10ms
micro-timing will not be reliably audible. Offer offsets in musically useful
increments (e.g. 1/64 note or ±50ms in 5ms steps) rather than implying
sample-level precision the engine cannot deliver.

## 7. No time-stretching

`AudioPitchShifter` changes pitch without changing speed. Nothing changes speed
cleanly without changing pitch.

**Lock the game to a small set of BPMs** (90 / 120 / 140 / 160). Every loop is
authored at one of them. One-shots are tempo-agnostic and should be the
majority of the catalog. Individual modes can lock to a single BPM.

## 8. Pitch shifting is the asset budget cheat code

One melodic sample + `AudioPitchShifter` = a chromatic instrument. Never upload
24 notes per instrument. Tag each melodic card with a `rootNote`. Cap the range
around ±12 semitones; the effect works in the frequency domain and gets ugly at
extremes.

## 9. The audio graph is a wire graph

`AudioPlayer` -> `Wire` -> effects -> `AudioDeviceOutput`. Build the mixer once
at session start (per-track fader and effect slot -> master limiter -> output).
Do not create instances per note; pool voices instead.

The limiter is not optional — eight simultaneous samples with no limiting will
clip.

## 10. There is no way to export audio from Roblox

The brief asks whether players can download their beats. Not as audio files —
Roblox has no audio export or file write API.

What *is* possible, and is nearly as good:

- **Share codes.** A beat is a small data structure (see `DATA_MODEL.md`).
  Encode it as a short string players can copy, paste, and load. Costs nothing.
- **Profiles.** Saved beats live on a player profile others can visit and play.
- **Off-platform export** would require the external web app: player requests
  an export, the backend renders the pattern using the same source audio, and
  serves an mp3. Only viable for stock sounds you have distribution rights to,
  and it is a v3+ feature.

Set expectations in the UI: "save and share", not "download".

## 11. Storage limits are real

DataStore values cap around 4MB per key and requests are rate-limited per
player. Saving patterns rather than audio keeps beats in the hundreds-of-bytes
range, so a generous save-slot limit is cheap. Still cap it — 20-50 slots,
expandable as a monetized convenience.
