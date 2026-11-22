"""Speed (unikit's tasks/11): bluetools' pickers and commands against the budgets in unikit's
tests/lib/budget.py. Run by name only: <unikit>/tests/run.sh speed_tools."""
import os

from bluetools_worlds import CTX, HAT, KX, OKCLI, WS, aws, kube
from budget import commands, picker, report  # noqa: F401  (report: the runner calls it)


# ------------------------------------------------------------- set-ups
def okcli_world(sb):
    aws(sb)
    return [OKCLI], "profile>", None


def kx_world(sb):
    kube(sb)
    return [KX], "context>", None


def ws_world(sb):
    for name in ("alpha", "beta", "gamma"):
        os.makedirs(sb.path(f"~/code/{name}"))
    sb.write("~/.config/ws/workspaces", "~/code/alpha\n~/code/beta\n~/code/gamma\n")
    sb.env["WS_EDITOR"] = "code"
    return [WS], "workspace>", None


def hat_world(sb):
    os.makedirs(sb.path("~/code/proj"))
    return [HAT], "hat · folders", sb.path("~/code/proj")


# ------------------------------------------------------------- pickers
def test_okcli(sb):
    picker(sb, okcli_world, "okcli", "enter", "Refresh now?", row="shop-dev")


def test_kx(sb):
    picker(sb, kx_world, "kx", "enter", "Refresh now?", row="shop-dev")


def test_ws(sb):
    picker(sb, ws_world, "ws", "ctrl-x", "Install it now?")


def test_hat(sb):
    picker(sb, hat_world, "hat", "alt-a", "Folder to give a hat?",
           move=("alt-right", "alt-left", "alt-right", "alt-left"))   # one folder: columns move


# ------------------------------------------------------------- commands
def test_commands(sb):
    aws(sb)
    kube(sb)
    os.makedirs(sb.path("~/code/alpha"))
    sb.write("~/.config/ws/workspaces", "~/code/alpha\n")
    commands(sb, [("okcli ls", [OKCLI, "ls"]), ("kx ls", [KX, "ls"]), ("ws ls", [WS, "ls"]),
                  ("hat ls", [HAT, "ls"]), ("ctx", [CTX])])
