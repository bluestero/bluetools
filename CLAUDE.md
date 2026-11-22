# bluetools: a unikit layer, notes for Claude

This repo is a **layer** for unikit (the `uk` / `tk` / `fk` shell toolkit). unikit clones it into
`<unikit>/layers/bluetools/` and finds everything in it by its place; nothing is registered.
The full contract is unikit's `docs/LAYERS.md`; read it before changing the shape of this repo.

## What goes where

- `bin/<command>`: commands, on PATH after unikit's own. A name unikit has never runs here.
- `shell/init.sh`: sourced by every bash and zsh. Settings and aliases only; fast and quiet.
- `components.sh`: installer parts (`COMPONENTS+=(…)` plus `label_ title_ detail_ state_
  install_ uninstall_`, and `touches_` for what a part changes). A new part's name starts with
  the layer's name; the ones that came from unikit (okta-aws-cli, aws-cli, direnv, kubectl, eks-clusters, twingate, gh, clipboard, zed, vscode, repos, claude-hook, claude-guard) keep theirs.
- `tools`: `name|group|what it does|program it needs[|kit]`, one per command.
- `kit`: `tk` (what you work with) or `fk` (how it looks): where its parts go.
- `requires`: other layers it needs. Needing only unikit is the default; keep it that way if you can.
- `claude/skills/<skill>/SKILL.md`: Claude skills, next to the command they document.
- `docs/<tool>.md`: a tool's own page.
- `tests/cases/<tool>.py`: its tests, run by unikit's runner (`<unikit>/tests/run.sh <tool>`);
  the shared fixtures (`Sandbox`, `Term`, `worlds`) are unikit's `tests/lib`.
- A command finds unikit's `lib/` by walking up from itself to the folder with `lib/ui.sh`.

## Rules

- Use unikit's helpers (`ask`, `link_file`, `unlink_file`, `set_block`, …) and its UI (`lib/ui.sh`:
  `ui_fzf`, `confirm`, `ui_ask`). Every choice is a picker; never a typed y/N.
- Every install asks before changing anything, does nothing when already done, and its uninstall
  puts back what was there. `--dry-run` changes nothing.
- Never redefine unikit's functions or another layer's; prefix your own with the layer's name.
- Before pushing: `uk layer check .` (well formed, no clashes with unikit or the layers there).
- People who add this layer see the code that changed in each update before it runs: keep
  commits small and say what they change.
