# Game rules

Precise specification. The brief is the vision; this is the implementation
contract.

## Modes

| Mode | Players | Sound source | Notes |
|---|---|---|---|
| **Draft** | 1v1 | Shared pool, pick-one-pass-two | The flagship mode |
| **Triple Draft** | 3 | Shared pool, pack-and-pass | Scales the same tension |
| **Community** | 4-12 | Identical kit for everyone | Randomness removed so the vote measures skill |
| **Free For All** | Any | Player's own collection | Any owned or free sounds, no draft |
| **Private** | Any | Host's choice of the above | Friends only, host sets timer and BPM |

Free For All is where purchased and custom sounds pay off. Ranked play runs
Draft and Community only — otherwise the ladder measures collection size.

## Draft (1v1)

```
Pool: filtered by round prompt (genre, BPM), category-balanced
Rounds: 4

for i = 1, 4 do
    dealer = (i % 2 == 1) and playerA or playerB
    pack = dealPack(3)
    picked = dealer:choose(pack)
    dealer.deck += picked
    other.deck += (pack - picked)
end
```

Each player ends with 4 chosen + 8 passed = 12 cards.

**Category guarantee.** Before dealing each pack, check what each player still
lacks from the required set (kick, snare, hat, and at least one melodic
category). If a player is one pack away from being unable to fill a slot, force
that category into the pack. A hand with no kick isn't a hard hand, it's a
broken one.

**Information.** Both players see the full pack. The decision is always: take
what I want, or deny what they want.

**Timer.** ~10s per pick, auto-picks a random card on timeout.

## Triple Draft (3 players)

Each player opens a pack of 3, picks 1, passes the remainder clockwise. Repeat
until packs are empty, then open new packs. Four packs each.

## Community rounds

Everyone gets the identical kit. Beats become directly comparable, which is
exactly what makes a large-lobby vote meaningful. Randomness can be layered on
later once the baseline works.

## Voting

**Format:** 1-5 stars per beat. Every player rates every beat except their own.

**Rules, per the brief:**

1. **No self-voting.** Enforced server-side; the player's own beat is not
   presented to them for rating.
2. **Abstention is neutral.** A beat's score is the *mean* of the ratings it
   received, not a sum. A player who doesn't vote simply isn't in the
   denominator — no penalty to anyone.
3. **Silent 1-star filtering.** A voter whose ratings show no discrimination —
   every beat rated at or near the floor — has their ballot dropped for that
   round. They see their vote register normally and receive no indication it
   was discarded. See `VoteTally.luau` for the detection rule.
4. **Nothing is hidden.** Player names, beat titles, and ranks are all visible
   during playback and voting. This is a deliberate reversal of the usual
   anonymize-to-reduce-bias approach — see the note below.
5. **No rewards without voting.** Rating rewards are how you keep spectators
   engaged and stop AFK farming.

### Note on visible authorship

Showing names and ranks during voting means votes will partly track reputation
rather than the beat alone. That is a real tradeoff and it is worth accepting
deliberately, not by accident:

*What you gain:* social stakes, rivalries, recognition for good players, and a
reason to build a rank worth showing. Beating a high-ranked player in front of
a lobby is a moment. Anonymous voting has no such moment.

*What you lose:* some measure of pure-merit signal, especially at the top of
the ladder where a known name accumulates halo votes.

*If it becomes a problem*, the lever to pull first is weighting — count votes
from higher-ranked players more heavily in ranked modes — before reaching for
anonymity, which would cost the social layer entirely.

### Abuse vectors to plan for

| Vector | Mitigation |
|---|---|
| Alt-account vote stacking | Minimum account age + playtime to vote in ranked |
| Friend group coordination | Rating variance analysis across sessions; flag correlated ballots |
| Rating everything 1 star | Silent ballot drop (rule 3) |
| Rating everything 5 stars | Same detection, same treatment — no discrimination is no signal |
| AFK vote farming | No rewards without a full ballot |
| Troll beats winning on comedy | Allow it. It makes clips. |

## Scoring and rank

- Round score = mean rating across valid ballots
- Match result = higher mean wins
- Rank = ELO, adjusted on match result, not raw score
- Matchmaking pairs similar ranks in ranked modes
- Rank is displayed publicly on profiles and during rounds

## Prompts

A prompt is genre + BPM + a modifier. Modifiers add constraint, which is what
makes a short timer creative rather than stressful.

Examples: *Trap, 140, make it menacing* · *Lo-fi, 90, only four sounds* ·
*Drill, 140, half-time* · *House, 120, no 808*

Constraint modifiers must be validated server-side if they affect scoring.

## Timers

| Phase | Default | Host-configurable |
|---|---|---|
| Prompt | 5s | No |
| Draft | ~10s per pick | No |
| Build | 90s | Yes — 60 / 90 / 120 / 180 |
| Playback | ~20s per beat | No |
| Vote | 10s | No |
| Result | 10s | No |
