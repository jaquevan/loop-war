# Loop War — project brief

> Snapshot of the [Google Doc](https://docs.google.com/document/d/1360YlkuQr5S1Hwhcjq7UqHyraTcOEv1ND_YMRs1CX4A/edit),
> which is canonical. Re-sync this file when the Doc changes materially.

## 1. What it is

Loop War is a Roblox game where two players are dealt a hand of sounds, get a
few minutes to build a beat out of them, and then everyone votes on which beat
is better.

The twist is that you don't pick your sounds purely by yourself. You and your
opponent split a shared deck, so every sound you take is one you're denying
them, and every sound you pass is one they get to use against you. It's a
music-making toy wrapped inside a card game.

### Inspiration

**FL Studio** — ranked beat battles with time limits, uploads, and voting.
Wants the drag-and-drop accessibility but with depth that real producers enjoy.
Different UIs for beginners vs experts (sequencer vs piano roll / playlist).

**Clash Royale** — Draft and Triple Draft modes. New decks every time, which
levels the playing field and makes matches purely about skill.
- Draft works better for 1v1
- Triple Draft could work for lobbies of 3
- Large lobbies share sounds; pay Robux to access your own
- Free-for-all: use any sounds you like. Applies to 1v1 too.

**Dress to Impress** — community voting on creations. Other games have good and
bad qualities in how voting works.

## 2. Why build this

Music making on Roblox exists, but competition doesn't. BeatMerger, Make a Beat
& Donate, Street Beats, and Splash are all okay, and they prove the technical
work is possible. But every one is either a sandbox (make whatever you want,
forever, no stakes) or a grind (unlock samples by playing longer).

None of them run a match. No prompt, no timer, no opponent, no vote, no rank.

## 3. What it's like to play

You join, get matched with one other player, and a prompt drops:
*Trap. 140 BPM. Make it menacing.*

Three sound cards appear. You take the one you want — say, a heavy 808 — and
the other two automatically go to your opponent. Then it's their turn to pick
from three, and you get their leftovers. This repeats until you both have a
full kit. You chose about a third of your sounds; your opponent handed you the
rest.

You've got a grid of steps and your sounds down the side. Click squares to
place hits. If you want to go deeper, click record and play the pads live with
your keyboard, or switch a melodic sound into piano mode and play a line.

The game snaps everything to the grid so it stays in time no matter how sloppy
you are. You can also move things precisely if you don't want the grid.

Time's up. Both beats play back to back in random order. Usernames hidden, song
titles shown. Everyone votes. Winner revealed, ranks adjust, rematch button.

Four minutes, start to finish.

## 4. How the pieces work

See `GAME_RULES.md` for the precise specification. In summary:

**Drafting.** 1v1: dealt three, keep one, opponent gets two. Alternate four
rounds each; both end with twelve sounds. Bigger lobbies pass packs around the
circle. Large community rounds give everyone the identical kit (randomness can
be layered in later). A separate mode for all lobby sizes lets players use
sounds they've purchased plus any free sounds they own.

**Editor.** Simple by default, deeper if you want it.
- *Level 1 — Grid.* Tracks (limited only if needed), sixteen steps
  (customizable). Click a square to place, click again to delete.
- *Level 2 — Live record.* Click record, hit keybinds, play the beat by hand.
  Optional quantize. Custom keybinds. Editable on a piano roll.
- *Level 3 — Piano roll.* Melodic sounds become playable instruments using the
  standard producer keyboard layout. Drag notes around.

The rule: a complete beginner should never be forced past level 1, and someone
who already makes music should find levels 2 and 3 waiting for them and easy to
use out of the box.

**Voting.**
- Players cannot vote for themselves
- If a player doesn't vote, it doesn't count against the beat
- If a player votes 1 star on everything, silently disregard their votes for
  that round — they keep the illusion that it worked
- Do **not** hide player names, beat names, or rank

**Sounds.** Every sound is a card with a category (kick, snare, hat, 808, piano,
synth, pad, vocal, FX, lead) and a rarity. Rarity affects how often a card shows
up, never how good it is. A legendary kick is a different kick, not a better
one. The moment rare sounds win rounds, the vote stops measuring skill and
starts measuring spending.

Custom sounds can be used between games by their owner, but it's extremely rare
for an opposing player to receive a sound they didn't make. Players who upload
sounds get a chance at their sound appearing in a game. Custom sounds cost money
(with a path to unlock free ones), have a file size cap, a length cap, and are
bannable if harmful.

## 5. Goals

Someone who has never made music makes a loop, plays it back twice because they
like it, and wants to play again. Everything else is downstream of that.

Players should be able to save beats they like (with a storage limit) and
download them if that's possible.

| Stage | Goal | How we know it worked |
|---|---|---|
| Learn the tools | Play four sounds on four keys with a clean setup | It works and the code is organized |
| The toy | One person makes a beat that loops and sounds good | A non-musician makes something and replays it |
| The match | Two people play a full round | Five rounds played with no rules explained |
| Retention | Saving, unlocks, ranks, profiles | People come back the next day |
| Soft launch | 20–50 players, heavily instrumented | I know exactly where people quit |
| Money | Cosmetics, then direct sound purchases | Revenue without pay-to-win complaints |

## 6. User stories

### Complete beginner
- Make something that sounds decent within my first minute, so I don't feel
  stupid and leave
- Understand the rules without reading anything, so I can jump straight in
- Free sounds good enough to win with, so I don't feel I have to pay to compete
- Play with friends in private games, so we can have fun uninterrupted

### Player who already makes music
- Play notes with my keyboard instead of only clicking, so the game doesn't
  feel like a toy or feel limiting
- Have my skill actually show in the result, so winning feels earned
- Save my beats and show them off, so my time here produces something I keep

### Competitive player
- A draft with real decisions, so matches feel strategic and not random
- A rank that reflects how good I am, that I can show off, matched against
  similarly ranked players
- Votes that are fair and hard to manipulate, so the ranking means something

### Spectator
- Listen to other people's beats and vote while waiting, so waiting isn't boring
- Hear both beats clearly and back to back; rewind and scrub through them
- View the lobby's favorite beats on their profiles, for inspiration

### Sound creator
- Submit my own sounds so my work reaches players and I earn from it
- Know my sounds are reviewed before publishing, so the library stays good
- Have users find my sounds via search, description, or tags

### Developer
- Each phase playable on its own, so I always have something to test rather
  than a half-built everything
- Code in Git from day one, so I can undo mistakes and see my progress

## 7. Future extensions

- External MIDI keyboard support (Roblox has no MIDI API; workarounds are
  third-party, laggy, and unsupportable)
- Player-uploaded sounds as a self-serve feature
- Random loot packs
- Song arrangement: multiple patterns, verses, choruses
- Free play mode — make a beat with no constraints
- Custom tempos, sample trimming, automation, effects
- Tournaments, cross-server events with community voting, a full marketplace

## 8. Constraints

Full detail in `CONSTRAINTS.md`. Headlines:

- Players can't upload audio from inside a Roblox game. Community sounds must
  run through an external site and upload under my account — my quota, my
  review time, my legal exposure. A curated program, not a button.
- Random packs are heavily regulated. Sell sounds directly first, add
  randomness later, never make a random pack the only route to a card.
- Anything a player types must be filtered. Games get taken down for missing it.
- Fixed tempos. Roblox can't stretch audio, so we pick a few BPMs and author
  every looping sound at one of them. Some modes can lock to a single BPM.

## 9. The biggest risk

That the editor itself isn't fun — which is why it gets tested first, before
any competitive structure is built on top of it.

Terms of service is the other big one. Player-uploaded custom sounds are hard
to pull off well and can get the game taken down.
