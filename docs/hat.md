# hat: Claude, GitHub and AWS per folder

Which Claude profile, GitHub account and AWS profile a folder uses, for every repo under it. Not an
installer step: set it up when you need it, with `hat`.

## The table

`hat` is one table of every folder wearing a hat, edited in place:

| Key | Does |
|---|---|
| ↑↓ | folder |
| alt-←→ | column |
| ←→ | change the cell (tab searches the choices beside the table) |
| enter | saves them all |
| alt-a | adds a folder |
| ctrl-x | takes its hats off |
| alt-c / alt-g | list the Claude profiles / GitHub accounts (add, remove) |

Questions open inside the table. In the accounts list, enter signs `gh` in without leaving the list,
and the GH column flags accounts without that sign-in.

## Commands

| Command | What it does |
|---|---|
| `hat set ~/code claude=personal github=me` | sets a folder's hats |
| `hat ls`, `hat show` | lists them; what this folder wears |
| `hat exec -- <cmd>` | one command as the folder's hat: its AWS pin, and `gh` signed in as its account. For scripts and AI agents; in your shell `gh` already follows the folder's account by itself |
| `hat github add <account>` | adds an account, only once GitHub knows its key; then offers to sign the `gh` command in as it too |
| `hat github login <account>` | that `gh` sign-in on its own |

`ws ls` shows each workspace's hat.

## Where each hat goes

| | Where it goes | Covers |
|---|---|---|
| Claude profile | `export CLAUDE_CONFIG_DIR=…` in the folder's `.envrc` (direnv); profiles are `~/.claude-profiles/<name>` | everything under the folder |
| AWS profile | `export AWS_PROFILE=…` in the `.envrc`, the same line `okcli pin` writes | everything under the folder |
| GitHub account | `[includeIf "gitdir:<folder>/"]` in `~/.gitconfig` → `~/.config/hat/github/<account>.gitconfig` | every repo under the folder |

## How it works

- **A GitHub account** is its commit name and email plus its SSH key. Its own small ssh config offers
  only that key to GitHub, so plain `git@github.com:` remotes sign in as that account. The agent still
  holds it, so a key with a passphrase asks once, as usual, and every other host reads your own
  `~/.ssh/config`. An account is added only when `ssh -T git@github.com` with its key answers with
  its name.
- **`.envrc` files** hat writes start with `source_up_if_exists`, so a repo's own `.envrc` doesn't
  drop its parent folder's hat.
- **Nesting.** A hat on a folder inside another one wins there.
- **Every hat shows.** `hat` lists every folder wearing a hat, however it got it (hat, `okcli pin`,
  or an `.envrc` you wrote). In `hat ls` and `ws ls`: `↑` from a parent folder, `⇄` set in the repo
  itself (its own git config), `–` the default.
