# ws, twin, ctx and the Claude skills

The smaller tools. okcli, kx and hat have their own pages: [okcli.md](okcli.md), [kx.md](kx.md), [hat.md](hat.md).

## ws

Open workspaces in your IDE.

| In the picker | Does |
|---|---|
| ↑↓ | pick |
| ←→ | switch IDE (● = already open there, gets focused) |
| tab | ticks several |
| ctrl-x | closes the window (needs the `bluetools-window-calls` part) |

| Command | What it does |
|---|---|
| `ws <name>` | opens one |
| `ws close <name>` | closes it |
| `ws ls` | lists them, with each one's hat |
| `ws default [ide]` | the IDE it opens in |
| `ws edit` | your list: `~/.config/ws/workspaces`, which can include your layers' shared lists |

The list's format is unikit's: see [its COMMANDS.md](https://github.com/bluestero/unikit/blob/main/docs/COMMANDS.md#your-workspace-list).

## twin

Twingate exit nodes: a picker, `twin gb`, `twin off`. The codes come from the node names.

## ctx

Checks what this terminal points at: AWS profile, Kubernetes context, Twingate, GitHub account.

## Claude Code

| | What it does |
|---|---|
| `bluetools` skill | teaches Claude Code these tools: which account and cluster, what to ask first (`claude/skills/`) |
| `working-style` skill | how Claude writes what you'll send on (Slack-ready messages); optional, untick it in `uk skills` |
| PROD guard | Claude asks you before a command that changes PROD (`tk __guard`, run by the `claude-guard` part's hook) |
| start hook | every Claude Code session starts with `ctx plain` (the `claude-hook` part) |
