"""ctx: Tab completion from its help page (unikit's shell/complete.sh reads bluetools' tools file)."""
import subprocess

from fixture import REPO

BIN = f"{REPO}/layers/bluetools/bin"


def test_first_word_comes_from_the_help_page(sb):
    script = f'''
_work_root={REPO}
PATH="{BIN}:$PATH"
complete -p ctx >/dev/null 2>&1 && complete -r ctx
. "{REPO}/shell/complete.sh"
COMP_WORDS=(ctx ""); COMP_CWORD=1; COMPREPLY=()
$(complete -p ctx | sed -n 's/.*-F \\([^ ]*\\).*/\\1/p')
printf '%s\\n' "${{COMPREPLY[@]}}"'''
    out = subprocess.run(["bash", "-c", script], env=sb.env, capture_output=True, text=True, timeout=30)
    assert out.stdout.split() == ["plain", "help"], out.stdout + out.stderr


def test_plain_names_each_part_without_a_box(sb):
    out = subprocess.run([f"{BIN}/ctx", "plain"], env=sb.env, cwd=sb.home, capture_output=True, text=True, timeout=30)
    assert out.returncode == 0, out.stderr
    assert "╭" not in out.stdout and "GitHub:" in out.stdout, out.stdout
