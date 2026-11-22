# bluetools

A layer for [unikit](https://github.com/bluestero/unikit): the work tools in `tk`. okcli for Okta
AWS profiles, kx for Kubernetes contexts, twin for Twingate exit nodes, ctx and hat (where am I, which account), with what they run on, and Bluetooth earbuds that behave on calls.
(This first paragraph is what `uk layers` shows on its about card.)

## Add it

```bash
uk layer add git@github.com:bluestero/bluetools.git bluetools
```

unikit shows what of it runs on your machine and asks first; then it offers to set up its parts
(`tk install --layer=bluetools`). `uk update` keeps it current.

## What's in it

| | |
|---|---|
| `okcli` | Okta AWS profiles: picker, refresh, per-shell switch, default, folder pins ([docs/okcli.md](docs/okcli.md)) |
| `kx` | Kubernetes contexts and namespaces per terminal, EKS sign-in through okcli's profiles, live lists of pods, deployments, logs (`lib/kx/`) |
| `ctx` | where am I: AWS, Kubernetes, Twingate, GitHub and Claude for this terminal (`ctx plain` for Claude) |
| `hat` | a folder's Claude profile, GitHub account and AWS profile; `gh` runs as the folder's account |
| `twin` | Twingate exit nodes: pick one, switch, off |
| `okta-aws-cli` part | okta-aws-cli from GitHub in `~/.local/bin`: okcli signs in with it |
| `aws-cli` part | AWS CLI v2 in `~/.local/aws-cli`: `okcli whoami`, kx's EKS sign-in |
| `direnv` part | direnv in `~/.local/bin`: `okcli pin` switches the profile per folder |
| `kubectl` part | kubectl from dl.k8s.io in `~/.local/bin`: kx runs on it |
| `eks-clusters` part | runs `kx sync`: tick the AWS accounts, then the EKS clusters kx shows |
| `twingate` part | the Twingate client (its installer, sudo; then `sudo twingate setup` once) |
| `gh` part | the GitHub CLI from GitHub in `~/.local/bin`: hat signs it in per account |
| `clipboard` part | wl-copy (xclip on X11), so hat can copy keys and sign-in codes |
| `bt-audio` part | Bluetooth earbuds keep music mode after reconnecting, and switch to Handsfree while a call has the mic (PipeWire + WirePlumber 0.4, `audio/`) |
| `bt-notify` part | a short notification when earbuds switch mode (`audio/bin/k-bt-notify`, a systemd user service) |

`shell/init.sh` sets okta-aws-cli's defaults, hooks direnv in and loads the shell hooks of okcli, kx, twin and hat (its `gh` wrapper and completion too).

## Tests

`tests/cases/<tool>.py`, run by unikit's runner: `<unikit>/tests/run.sh okcli`.
