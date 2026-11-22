"""hat: its panel asks in the list; a wrong typed answer comes back with the reason."""
import os

from term import Term
from bluetools_worlds import HAT


def start(sb):
    proj = sb.path("~/code/proj")
    os.makedirs(proj)
    t = Term([HAT], sb.env, cwd=proj)
    t.wait_for("~/code/proj")
    t.settle()
    return t


def test_add_a_folder_that_isnt_there_asks_again(sb):
    t = start(sb)
    t.key("alt-a")
    t.wait_for("Folder to give a hat?")
    t.key("ctrl-u", "/nowhere-xyz", "enter")
    t.wait_for("there's no folder")
    assert "/nowhere-xyz" in (t.line_with("folder:") or ""), "the typed text should be kept to fix"
    t.key("esc")
    t.wait_gone("Folder to give a hat?")
    assert t.alive(), "esc on the question goes back to the list"
    t.key("esc")
    assert t.wait_exit() == 0


def test_quit_with_unsaved_change_asks(sb):
    sb.write("~/.aws/config", "[profile shop-dev]\n[profile shop-prod]\n")
    t = start(sb)
    t.key("alt-right", "alt-right")              # to the AWS column
    t.settle()
    t.key("right")                               # change it
    t.wait_for("shop-")
    t.settle()
    t.key("esc")
    t.wait_for("Quit and drop 1 unsaved change?")
    t.key("n")
    t.wait_gone("Quit and drop 1 unsaved change?")
    assert t.alive(), "no keeps the panel open"
    t.key("esc")
    t.wait_for("Quit and drop 1 unsaved change?")
    t.key("y")
    assert t.wait_exit() == 0
    assert not os.path.exists(sb.path("~/code/proj/.envrc")), "nothing should have been saved"


def words(sb, *typed):
    """What Tab offers for hat after the typed words, with unikit's completion and hat's hook loaded."""
    import subprocess
    from fixture import REPO
    layer = os.path.join(REPO, "layers/bluetools")
    script = f'''
_work_root={REPO}
PATH="{layer}/bin:$PATH"
. "{layer}/shell/hat.sh"
. "{REPO}/shell/complete.sh"
COMP_WORDS=("$@"); COMP_CWORD=$(( $# - 1 )); COMPREPLY=()
$(complete -p hat | sed -n 's/.*-F \\([^ ]*\\).*/\\1/p')
printf '%s\\n' "${{COMPREPLY[@]}}"'''
    out = subprocess.run(["bash", "-c", script, "_", *typed], env=sb.env, capture_output=True, text=True, timeout=30)
    return [w for w in out.stdout.splitlines() if w]


def test_tab_offers_each_word_once_then_accounts(sb):
    w = words(sb, "hat", "")
    assert "github" in w and len(w) == len(set(w)), w
    assert words(sb, "hat", "github", "") == ["add", "rm", "login"]
    sb.write("~/.config/hat/github/me.gitconfig", "[user]\n\temail = me@x.io\n")
    assert words(sb, "hat", "github", "login", "") == ["me"]
