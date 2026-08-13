# Roadmap

Timeboxes assume part-time work and no prior Roblox experience. They're for
sequencing, not deadlines.

## Phase 0 — Learn the tools (2-3 weeks)

Don't start the real project. Ship three throwaways:

1. A part that changes color when clicked — client/server split, RemoteEvents
2. A GUI with a button and a countdown — UI layout, state, tweening
3. Four sounds on four keys — `UserInputService`, `AudioPlayer`, `Wire`

Then set up Rojo + Git and redo #3 in this repo. If you can do it with a clean
client/server split, you're ready.

Skip tutorials older than about two years; the audio API changed.

**Exit criteria:** four sounds, four keys, code organized, committed to git.

## Phase 1 — The toy (3-4 weeks)

**One player, one screen, makes a beat that loops and sounds good.**

- Transport clock with lookahead scheduler (`Transport.luau`)
- Audio graph with pooled voices and a master limiter (`AudioGraph.luau`)
- Grid: tracks down the side, 16 steps across, click to place, click to delete
- 8 stock sounds
- Play / stop / BPM select from the locked list

**Exit criteria:** hand it to someone who has never made music. They make
something and play it back twice without being asked. If this isn't fun, stop
and fix it — everything downstream is built on it.

## Phase 2 — The match (3-4 weeks)

- Round state machine (prompt -> draft -> build -> playback -> vote -> result)
- 1v1 matchmaking
- Draft with category guarantees
- Pattern replication and synchronized playback
- Voting with the tally rules in `GAME_RULES.md`
- Results, ELO, rematch

**Exit criteria:** two people play five rounds with no rules explained to them.

## Phase 3 — Depth and retention (3-4 weeks)

- Save / load with a real DataStore wrapper
- Live record mode with quantize toggle and custom keybinds
- Piano roll: drag notes, set lengths, off-grid offsets
- Card inventory and unlocks through play
- Profiles: saved beats, favorites, rank, record
- Spectator scrub and rewind

**Exit criteria:** someone comes back the next day unprompted.

## Phase 4 — Soft launch

Publish without advertising. Get 20-50 real players. Instrument everything:
where do people quit, which phase is too long, do people finish before the
timer, what percentage ever touch level 2 of the editor.

Fix the top three drop-offs. Repeat.

## Phase 5 — Monetization

In order, lowest regulatory risk first:

1. Cosmetics — editor themes, booth skins, name effects, win emotes
2. Convenience — extra save slots
3. Direct sound purchases — named packs, contents visible, fixed price
4. Free For All mode access to your own collection
5. Random packs — only after 1-4 exist, with full odds tables and
   `PolicyService` gating, and every card also buyable directly

The free stock library must be big enough to win with. Target 60-80 sounds.

## Phase 6 — Scale and community

- Triple Draft (3 players) and Community mode (4-12)
- Sound search: tags, descriptions, creator pages
- Custom sound program: application, external upload site, human review,
  Open Cloud pipeline, revenue share
- Tournaments and cross-server voting events

## Explicitly not now

MIDI, self-serve uploads, loot packs, song arrangement, free play mode, custom
tempos, sample trimming, automation, marketplace. All reasonable eventually.
None make v1 more likely to find players.

## Risks

**Scope.** This is four products: an editor, a card game, a voting system, and
a creator marketplace. The phases above ship one at a time, each playable alone.

**The editor not being fun.** Tested in Phase 1, before anything is built on it.

**Terms of service.** Custom sounds are the exposure. Phase 6 for a reason —
by then there's a game worth protecting and a reason to invest in review.
