"""bluetools' Bluetooth audio parts (bt-audio, bt-notify) and k-bt-notify, in a scratch copy of the
repo with a scratch HOME and faked wireplumber, systemctl, pw-dump and notify-send."""
import json
import os
import shutil
import subprocess

from fixture import REPO


def copy(sb):
    dst = sb.root + "/repo"
    shutil.copytree(REPO, dst, ignore=shutil.ignore_patterns(".git", "layers.lock", "tests", "tasks", "airpr", "*.zip"))
    return dst


def sh(sb, repo, script):
    """Runs bash with the installer's libraries loaded; returns its output."""
    pre = f'repo={repo} mode=yes details=0; . "$repo/lib/setup.sh"; . "$repo/lib/components.sh"\n'
    p = subprocess.run(["bash", "-c", pre + script], env=sb.env, cwd=sb.home, capture_output=True, text=True,
                       timeout=60, stdin=subprocess.DEVNULL)
    return p.stdout + p.stderr


def install(sb, repo, *parts):
    p = subprocess.run([repo + "/install.sh", "--yes", *parts], env=sb.env, cwd=sb.home, capture_output=True,
                       text=True, timeout=60, stdin=subprocess.DEVNULL)
    assert p.returncode == 0, p.stdout + p.stderr
    return p.stdout


def test_bt_audio_links_its_settings_and_puts_yours_back(sb):
    repo = copy(sb)
    sb.fake("wireplumber", 'echo "wireplumber"; echo "Compiled with libwireplumber 0.4.17"')
    calls = "~/.config/pipewire/pipewire-pulse.conf.d/51-unikit-calls.conf"
    sb.write(calls, "# mine\n")                                        # a file of yours is kept
    out = install(sb, repo, "bt-audio")
    assert os.path.realpath(sb.path(calls)) == os.path.realpath(repo + "/layers/bluetools/audio/51-unikit-calls.conf"), out
    assert os.path.realpath(sb.path("~/.config/wireplumber/bluetooth.lua.d/51-unikit-roles.lua")) == \
        os.path.realpath(repo + "/layers/bluetools/audio/wireplumber/51-unikit-roles.lua"), out
    out = sh(sb, repo, 'component_state bt-audio; echo "$STATE"; uninstall_bt_audio >/dev/null; component_state bt-audio; echo "$STATE"')
    assert out.split() == ["installed", "missing"], out
    assert sb.read(calls) == "# mine\n"


def test_bt_audio_needs_wireplumber_0_4(sb):
    repo = copy(sb)
    sb.fake("wireplumber", 'echo "Compiled with libwireplumber 0.5.6"')
    out = sh(sb, repo, 'component_state bt-audio; echo "$STATE|$NOTE"')
    assert out.strip() == "unsupported|needs WirePlumber 0.4 (this is 0.5.6)", out


def test_bt_notify_runs_as_a_user_service(sb):
    repo = copy(sb)
    sb.fake("pw-dump", "exit 0")
    on = sb.path("~/bt-on")
    sb.fake("systemctl", f'case "$*" in *"enable --now"*) touch {on} ;; *"disable --now"*) rm -f {on} ;; '
                         f'*is-enabled*) [ -e {on} ] ;; esac')
    install(sb, repo, "bt-notify")
    unit = sb.read("~/.config/systemd/user/k-bt-notify.service")
    assert f"ExecStart={repo}/layers/bluetools/audio/bin/k-bt-notify" in unit, unit
    assert any("enable --now k-bt-notify.service" in c for c in sb.calls("systemctl"))
    out = sh(sb, repo, 'component_state bt-notify; echo "$STATE"; uninstall_bt_notify >/dev/null; component_state bt-notify; echo "$STATE"')
    assert out.split() == ["installed", "missing"], out
    assert not os.path.exists(sb.path("~/.config/systemd/user/k-bt-notify.service"))


def test_bt_notify_says_each_switch_once(sb):
    """first sight is quiet; a repeated profile, 'off' and other devices say nothing"""
    dev = lambda prof, i=40, api="bluez5": {"id": i, "info": {"props": {"device.api": api, "media.class": "Audio/Device",
                                            "device.description": "Buds"}, "params": {"Profile": [{"name": prof}]}}}
    feed = [[dev("a2dp-sink"), dev("output:analog", 7, "alsa")], [dev("headset-head-unit-msbc")],
            [dev("headset-head-unit-msbc")], [dev("a2dp-sink")], [dev("off")], [dev("a2dp-sink")], [{"id": 40, "info": None}]]
    sb.write("~/feed.json", "".join(json.dumps(a, indent=2) + "\n" for a in feed))
    sb.fake("stdbuf", 'shift; exec "$@"')
    sb.fake("pw-dump", f'cat {sb.path("~/feed.json")}')
    sb.fake("notify-send", "echo 7")
    subprocess.run([REPO + "/layers/bluetools/audio/bin/k-bt-notify"], env=sb.env, timeout=20, check=True)
    notes = [c.split(" -i ", 1)[1] for c in sb.calls("notify-send")]
    assert notes == ["audio-headset Buds Handsfree · mic on", "audio-headphones Buds Headset · music"], notes
    assert "-r 7" in sb.calls("notify-send")[1]                      # the second replaces the first
