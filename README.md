# bluetools

Work tools for [unikit](https://github.com/bluestero/unikit)'s `tk`: AWS profiles through Okta, Kubernetes contexts per terminal, Twingate exit nodes, workspaces in your IDE, the right Claude, GitHub and AWS account per folder, and Bluetooth earbuds that behave on calls.

<!-- The paragraph above is what `uk layers` shows on its about card: keep it plain text, first under the title. -->

<br>

## Why you'll like it

- 🪟 **Every terminal is its own.** Switching AWS profile or Kubernetes cluster in one terminal never moves another.
- 🎩 **Folders know who you are.** A *hat* gives a folder its Claude profile, GitHub account and AWS profile, for every repo under it.
- 🚦 **Careful with prod.** Pickers open on a non-prod entry, making prod your default asks first, and Claude asks you before any command that changes PROD.
- ☸️ **kubectl, friendlier.** `kx pods`, `kx why`, `kx logs`, `kx shell`: the everyday jobs, as lists you pick from.
- 🔑 **One sign-in refreshes everything.** `okcli refresh` renews every AWS profile at once.
- 📂 **Your workspaces, one key away.** `ws` opens any project in your IDE, or focuses it if it's already open.
- 🎧 **Earbuds that behave.** Music mode after reconnecting, Handsfree only while a call has the mic.

<br>

## Get it

You need [unikit](https://github.com/bluestero/unikit#get-it) first. Then:

```bash
uk layer add bluetools     # shows what runs here, asks, then offers to set up its parts
```

Or tick it on unikit's first run (`install.sh` offers it). `uk update` keeps it current.

**First run:**

```bash
okcli sync                # sign in to Okta once, tick the AWS account + role pairs to keep
okcli default shop-dev    # what new terminals start on (pick a dev one)
kx sync                   # find the EKS clusters your roles can see, tick which to keep
kx default shop-dev       # the cluster new terminals start on
ws edit                   # add your own folders and repos
ctx                       # check what this terminal points at
```

Your Okta org comes from your own layer, or `export OKTA_AWSCLI_ORG_DOMAIN=… OKTA_AWSCLI_OIDC_CLIENT_ID=…`.

<br>

## The tools

| Command | What it does | More |
|---|---|---|
| `okcli` | AWS profiles through Okta: pick, refresh all, pin to a repo | [docs/okcli.md](docs/okcli.md) |
| `kx` | Kubernetes contexts and namespaces per terminal, plus pods, logs, shells and more | [docs/kx.md](docs/kx.md) |
| `hat` | which Claude profile, GitHub account and AWS profile a folder uses | [docs/hat.md](docs/hat.md) |
| `ws` | open your workspaces in your IDE | [docs/tools.md](docs/tools.md#ws) |
| `twin` | Twingate exit nodes: pick one, `twin gb`, `twin off` | [docs/tools.md](docs/tools.md#twin) |
| `ctx` | what this terminal points at: AWS, cluster, Twingate, GitHub | [docs/tools.md](docs/tools.md#ctx) |
| `tk` | everything else: a picker of every command | |

What `tk install` sets up, and what uninstall puts back: **[docs/parts.md](docs/parts.md)**.

<br>

## Build on it

| You want to | Read |
|---|---|
| change or add a tool here | [CLAUDE.md](CLAUDE.md) (this layer's rules), [docs/parts.md](docs/parts.md#tests) (tests) |
| write a layer of your own | unikit's [docs/LAYERS.md](https://github.com/bluestero/unikit/blob/main/docs/LAYERS.md) |
