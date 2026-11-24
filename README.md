# bluetools

A layer for [unikit](https://github.com/bluestero/unikit): the work tools in `tk`. okcli for Okta
AWS profiles, kx for Kubernetes contexts, twin for Twingate exit nodes, ctx and hat (where am I, which account), ws (workspaces in your IDE), with what they run on, and Bluetooth earbuds that behave on calls.
(This first paragraph is what `uk layers` shows on its about card.)

## Add it

```bash
uk layer add git@github.com:bluestero/bluetools.git bluetools
```

unikit shows what of it runs on your machine and asks first; then it offers to set up its parts
(`tk install --layer=bluetools`). `uk update` keeps it current.

## What's in it

| Command | What it does |
|---|---|
| `okcli` | Okta AWS profiles: picker, refresh-all, per-shell switch, global default, repo pins. See [docs/okcli.md](docs/okcli.md). |
| `kx` | Kubernetes contexts **per shell** (switching in one terminal never moves another), namespaces, global default, EKS contexts linked to okcli profiles. Also a friendly front to kubectl: `kx pods`, `why`, `logs`, `shell`, `deploys`, `configs`, `secrets`, `services`, `forward`, `events`, `top`, `get` (see `kx help`). |
| `twin` | Twingate exit nodes: picker, `twin gb`, `twin off`. Codes come from the node names. |
| `ws` | Open workspaces in your IDE. Picker: ↑↓ pick, ←→ switch IDE (● = already open there, gets focused), tab ticks several, ctrl-x closes the window (needs `bluetools-window-calls`). `ws <name>`, `ws close <name>`, `ws ls`, `ws default [ide]`, `ws edit` (your list: `~/.config/ws/workspaces`, which can include your layers' shared lists). |
| `hat` | Which Claude profile, GitHub account and AWS profile a folder uses, for every repo under it. `hat` is one table of every folder wearing a hat, edited in place: ↑↓ folder, alt-←→ column, ←→ change the cell (tab searches the choices beside the table), enter saves them all; alt-a adds a folder, ctrl-x takes its hats off, alt-c / alt-g list the Claude profiles and GitHub accounts (add, remove). Questions open inside the table. `hat set ~/code claude=personal github=me`, `hat ls`, `hat show`, `hat exec -- <cmd>` (one command as the folder's hat: its AWS pin, and `gh` signed in as its account; for scripts and AI agents. In your shell `gh` already follows the folder's account by itself), `hat github add <account>` (added only once GitHub knows its key; then it offers to sign the `gh` command in as it too), `hat github login <account>` (that `gh` sign-in on its own; in the accounts list, enter does it without leaving the list and the GH column flags accounts without it). `ws ls` shows each workspace's. See [Hats](#hats-claude-github-and-aws-per-folder). |
| `ctx` | check what this terminal points at |
| `tk __guard` | Claude Code's PROD guard (`tk/__guard`, run by the claude-guard part's hook) |
| `bluetools` skill | teaches Claude Code these tools: which account and cluster, what to ask first (`claude/skills/`) |
| `working-style` skill | how Claude writes what you'll send on (Slack-ready messages); optional, untick it in `uk skills` |

| Part (`tk install`) | What it sets up |
|---|---|
| `okta-aws-cli` part | okta-aws-cli from GitHub in `~/.local/bin`: okcli signs in with it |
| `aws-cli` part | AWS CLI v2 in `~/.local/aws-cli`: `okcli whoami`, kx's EKS sign-in |
| `direnv` part | direnv in `~/.local/bin`: `okcli pin` switches the profile per folder |
| `kubectl` part | kubectl from dl.k8s.io in `~/.local/bin`: kx runs on it |
| `eks-clusters` part | runs `kx sync`: tick the AWS accounts, then the EKS clusters kx shows |
| `twingate` part | the Twingate client (its installer, sudo; then `sudo twingate setup` once) |
| `gh` part | the GitHub CLI from GitHub in `~/.local/bin`: hat signs it in per account |
| `clipboard` part | wl-copy (xclip on X11), so hat can copy keys and sign-in codes |
| `zed`, `vscode` parts | the editors ws opens workspaces in |
| `bluetools-window-calls` part | the Window Calls GNOME extension, so ws can close and focus windows (shared with another layer's part for it, if any) |
| `repos` part | clones the repos your workspace list names |
| `claude-hook` part | every Claude Code session starts with `ctx plain` (a SessionStart hook in each profile) |
| `claude-guard` part | Claude asks you before a command that changes PROD (a PreToolUse hook: `tk __guard`) |
| `bt-audio` part | Bluetooth earbuds keep music mode after reconnecting, and switch to Handsfree while a call has the mic (PipeWire + WirePlumber 0.4, `audio/`) |
| `bt-notify` part | a short notification when earbuds switch mode (`audio/bin/k-bt-notify`, a systemd user service) |

`shell/init.sh` sets okta-aws-cli's defaults, hooks direnv in and loads the shell hooks of okcli, kx, twin, hat and ws (its `gh` wrapper and completion too).

## Start

| Command | Does |
|---|---|
| `okcli sync` | sign in to Okta once, tick the AWS account and role pairs to keep (your Okta org comes from your layer, or `export OKTA_AWSCLI_ORG_DOMAIN=… OKTA_AWSCLI_OIDC_CLIENT_ID=…`) |
| `okcli default <profile>` | what new terminals start on (pick a dev one) |
| `kx sync` | find the EKS clusters your AWS roles can see, tick which to keep (unticked ones are skipped from then on) |
| `kx ignore` | what `kx sync` skips; `kx ignore <context\|cluster\|account>` hides one, `kx unignore <name>` brings it back |
| `kx default <context>` | the cluster new terminals start on |
| `ws edit` | your workspace list: add your own folders and repos |
| `ctx` | check what this terminal points at |
| `tk` | everything else: a picker of every command |

Your workspace list (`ws edit`) is unikit's: see its README.

## Hats: Claude, GitHub and AWS per folder

Not an installer step: set it up when you need it, with `hat`.

| | Where it goes | Covers |
|---|---|---|
| Claude profile | `export CLAUDE_CONFIG_DIR=…` in the folder's `.envrc` (direnv); profiles are `~/.claude-profiles/<name>` | everything under the folder |
| AWS profile | `export AWS_PROFILE=…` in the `.envrc`, the same line `okcli pin` writes | everything under the folder |
| GitHub account | `[includeIf "gitdir:<folder>/"]` in `~/.gitconfig` → `~/.config/hat/github/<account>.gitconfig` | every repo under the folder |

A GitHub account is its commit name and email plus its SSH key. Its own small ssh config
offers only that key to GitHub, so plain `git@github.com:` remotes sign in as that account;
the agent still holds it, so a key with a passphrase asks once, as usual, and every other
host reads your own `~/.ssh/config`. An account is added only when `ssh -T git@github.com`
with its key answers with its name. `.envrc`
files hat writes start with `source_up_if_exists`, so a repo's own `.envrc` doesn't drop its
parent folder's hat. A hat on a folder inside another one wins there.

`hat` lists every folder wearing a hat, however it got it (hat, `okcli pin`, or an `.envrc`
you wrote). In `hat ls` and `ws ls`: `↑` from a parent folder, `⇄` set in the repo itself
(its own git config), `–` the default.

## Pin, switch, default (AWS and Kubernetes work the same way)

| Level | AWS | Kubernetes | Scope |
|---|---|---|---|
| pin | `okcli pin shop-dev` | — | this repo (direnv `.envrc`) |
| switch | `okcli shop-dev-ro` | `kx shop-dev`, `kx ns kube-system` | this shell only |
| default | `okcli default shop-dev` | `kx default shop-dev` | new terminals |

Making a prod profile/cluster the default asks for confirmation. Pickers open on a non-prod entry.

## First run with kx

```bash
okcli sync              # every account+role you have, named <account>-<role>; tick and save
kx sync                 # tick accounts -> finds their EKS clusters -> tick which to keep
                        # (unticked accounts/clusters go in ~/.config/kx/ignore and are skipped next time)
kx tidy                 # short names, link each cluster to its eks-<cluster>-read/admin role
kx default shop-dev     # global default off prod
kx doctor
```

Changing your mind later: run `kx sync` again (untick an added cluster to remove it, tick an
ignored one to add it back), or `kx ignore shop-poc` / `kx ignore <account>` / `kx unignore <name>`,
`ctrl-x` in the `kx` picker, `kx rm <context>` (remove, but let sync offer it again), or edit the
list with `kx ignore edit`.

Linked contexts authenticate with their own AWS profile (`AWS_PROFILE` in the kubeconfig
exec credentials), so `kubectl` on `shop-prod` uses `prod-ro` even while your shell is on
`shop-dev`. Change a link with `kx link <ctx> <profile>`.

## Tests

`tests/cases/<tool>.py`, run by unikit's runner: `<unikit>/tests/run.sh okcli`. Their shared sandboxes
(AWS profiles, clusters) are in `tests/lib/bluetools_worlds.py`; `speed_tools` times the pickers and
commands against unikit's budgets (run by name only).
