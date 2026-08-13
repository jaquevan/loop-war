# Setup

## Push this to GitHub

Create the empty repo first at <https://github.com/new>. Name it `loop-war`.
Do **not** let GitHub add a README, .gitignore, or license — this folder already
has them and it will conflict on the first push.

Then from inside this folder:

```bash
git init
git config user.email "jaquevan@bu.edu"
git config user.name "YOUR NAME"

git add .
git commit -m "Initial commit: project structure and design docs"

git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/loop-war.git
git push -u origin main
```

`git config` without `--global` sets the identity for this repo only, so the
address above is attached to these commits regardless of your machine's global
config.

> **Check the email.** The Google Doc came back owned by `jaquevan@bu.edu`,
> which is what's used above. If your GitHub account is registered under a
> different address, use that one instead — otherwise GitHub won't link the
> commits to your profile. Verify with `git config user.email` before pushing.

The commits carry no co-author trailers and no automated attribution.

## Development environment

1. **Roblox Studio** — <https://create.roblox.com>
2. **VS Code** — <https://code.visualstudio.com>
3. **Rokit** — toolchain manager; installs the pinned versions in `rokit.toml`:
   ```bash
   curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
   # restart your terminal, then from inside this folder:
   rokit install
   ```
   (Rokit replaced Aftman, which is no longer maintained.)
4. **Rojo plugin for Studio** — install from the Creator Store inside Studio
5. **VS Code extensions**: `Luau Language Server`, `StyLua`, `Rojo`

On Apple Silicon the Studio installer may ask for Rosetta 2 even though Studio
itself runs natively. Let it install; it's a one-time installer quirk.

## Daily loop

```bash
rojo serve          # leave running
```

Open Studio, click the Rojo plugin, Connect. Edits to `src/` appear in Studio
within milliseconds. Test in Studio, commit from VS Code.

**One trap:** edits made *inside* Studio do not flow back to disk. Treat Studio
as read-only for scripts — all code changes happen in VS Code. Build the world
in Studio, write the code in VS Code.

## Formatting and linting

```bash
stylua src/          # format
```

Run it before committing. It ends style arguments before they start.

## Branching

```bash
git checkout -b feature/step-grid
# work, commit
git push -u origin feature/step-grid
```

Merge to `main` when the feature is playable. `main` should always run.

## First task

`docs/ROADMAP.md` Phase 0. Don't touch the game yet — build the three
throwaways, then come back and make four sounds play on four keys inside this
repo using `Transport.luau` and `AudioGraph.luau`.
