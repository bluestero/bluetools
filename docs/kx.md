# kx

Kubernetes contexts **per shell**: switching in one terminal never moves another. Namespaces, a
global default, and EKS contexts linked to okcli profiles. Also a friendly front to kubectl.

## Commands

| Command | What it does |
|---|---|
| `kx` | pick a context for this shell (ctrl-x ignores the one under the cursor) |
| `kx <context>` | switch this shell to it |
| `kx ns <namespace>` | switch this shell's namespace |
| `kx default <context>` | the cluster new terminals start on |
| `kx sync` | find the EKS clusters your AWS roles can see, tick which to keep |
| `kx ignore` | what `kx sync` skips; `kx ignore <context\|cluster\|account>` hides one, `kx ignore edit` edits the list |
| `kx unignore <name>` | brings one back |
| `kx rm <context>` | removes it, but lets sync offer it again |
| `kx tidy` | short names, and links each cluster to its `eks-<cluster>-read/admin` role |
| `kx link <ctx> <profile>` | changes which AWS profile a context signs in with |
| `kx doctor` | checks kx and its shell hook |
| `kx pods`, `why`, `logs`, `shell`, `deploys`, `configs`, `secrets`, `services`, `forward`, `events`, `top`, `get` | the everyday kubectl jobs, as pickers (`kx help` has them all) |

## Pin, switch, default (AWS and Kubernetes work the same way)

| Level | AWS | Kubernetes | Scope |
|---|---|---|---|
| pin | `okcli pin shop-dev` | — | this repo (direnv `.envrc`) |
| switch | `okcli shop-dev-ro` | `kx shop-dev`, `kx ns kube-system` | this shell only |
| default | `okcli default shop-dev` | `kx default shop-dev` | new terminals |

Making a prod profile or cluster the default asks for confirmation. Pickers open on a non-prod entry.

## First run

```bash
okcli sync              # every account+role you have, named <account>-<role>; tick and save
kx sync                 # tick accounts -> finds their EKS clusters -> tick which to keep
                        # (unticked accounts/clusters go in ~/.config/kx/ignore and are skipped next time)
kx tidy                 # short names, link each cluster to its eks-<cluster>-read/admin role
kx default shop-dev     # global default off prod
kx doctor
```

## Changing your mind later

- Run `kx sync` again: untick an added cluster to remove it, tick an ignored one to add it back.
- `kx ignore shop-poc` / `kx ignore <account>` / `kx unignore <name>`, or edit the list with `kx ignore edit`.
- `ctrl-x` in the `kx` picker.
- `kx rm <context>`: remove, but let sync offer it again.

## Linked contexts

Linked contexts sign in with their own AWS profile (`AWS_PROFILE` in the kubeconfig exec
credentials), so `kubectl` on `shop-prod` uses `prod-ro` even while your shell is on `shop-dev`.
Change a link with `kx link <ctx> <profile>`.
