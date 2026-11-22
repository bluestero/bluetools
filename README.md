# bluetools

A layer for [unikit](https://github.com/bluestero/unikit): the work tools in `tk`. okcli for Okta
AWS profiles, with what it runs on, and Bluetooth earbuds that behave on calls.
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
| `okta-aws-cli` part | okta-aws-cli from GitHub in `~/.local/bin`: okcli signs in with it |
| `aws-cli` part | AWS CLI v2 in `~/.local/aws-cli`: `okcli whoami`, kx's EKS sign-in |
| `direnv` part | direnv in `~/.local/bin`: `okcli pin` switches the profile per folder |
| `bt-audio` part | Bluetooth earbuds keep music mode after reconnecting, and switch to Handsfree while a call has the mic (PipeWire + WirePlumber 0.4, `audio/`) |
| `bt-notify` part | a short notification when earbuds switch mode (`audio/bin/k-bt-notify`, a systemd user service) |

`shell/init.sh` sets okta-aws-cli's defaults, hooks direnv in and loads okcli's shell hook.

## Tests

`tests/cases/<tool>.py`, run by unikit's runner: `<unikit>/tests/run.sh okcli`.
