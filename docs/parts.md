# Parts, shell and tests

## What `tk install` sets up

| Part | What it sets up |
|---|---|
| `okta-aws-cli` | okta-aws-cli from GitHub in `~/.local/bin`: okcli signs in with it |
| `aws-cli` | AWS CLI v2 in `~/.local/aws-cli`: `okcli whoami`, kx's EKS sign-in |
| `direnv` | direnv in `~/.local/bin`: `okcli pin` switches the profile per folder |
| `kubectl` | kubectl from dl.k8s.io in `~/.local/bin`: kx runs on it |
| `eks-clusters` | runs `kx sync`: tick the AWS accounts, then the EKS clusters kx shows. Uninstall offers to remove those clusters and the skip list (default No; `kx rm` backs `~/.kube/config` up first) |
| `twingate` | the Twingate client (its installer, sudo; then `sudo twingate setup` once) |
| `gh` | the GitHub CLI from GitHub in `~/.local/bin`: hat signs it in per account |
| `clipboard` | wl-copy (xclip on X11), so hat can copy keys and sign-in codes |
| `zed`, `vscode` | the editors ws opens workspaces in |
| `bluetools-window-calls` | the Window Calls GNOME extension, so ws can close and focus windows (shared with another layer's part for it, if any) |
| `repos` | clones the repos your workspace list names |
| `claude-hook` | every Claude Code session starts with `ctx plain` (a SessionStart hook in each profile) |
| `claude-guard` | Claude asks you before a command that changes PROD (a PreToolUse hook: `tk __guard`) |
| `bt-audio` | Bluetooth earbuds keep music mode after reconnecting, and switch to Handsfree while a call has the mic (PipeWire + WirePlumber 0.4, `audio/`) |
| `bt-notify` | a short notification when earbuds switch mode (`audio/bin/k-bt-notify`, a systemd user service) |

A program that was already on the machine (from apt, say) isn't the toolkit's: uninstall leaves it
and says so. The tools in `~/.local/bin` it put there are removed.

## The shell

`shell/init.sh` sets okta-aws-cli's defaults, hooks direnv in and loads the shell hooks of okcli, kx,
twin, hat and ws (its `gh` wrapper and completion too).

## Tests

`tests/cases/<tool>.py`, run by unikit's runner: `<unikit>/tests/run.sh okcli`. Their shared sandboxes
(AWS profiles, clusters) are in `tests/lib/bluetools_worlds.py`; `speed_tools` times the pickers and
commands against unikit's budgets (run by name only).
