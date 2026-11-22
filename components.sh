# bluetools' installer parts. unikit's lib/components.sh sources this after its own, so its
# helpers are here: ask, ok, skip, warn, fail, dry, linked, link_file, unlink_file, set_block,
# apt_install, and the release helpers get_tool, gh_tool, tool_state, drop_tool (docs/LAYERS.md).

bluetools_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENTS+=(okta-aws-cli aws-cli direnv kubectl eks-clusters twingate gh clipboard)
GROUP_ABOUT[Cloud]="What okcli, kx and twin run on: Okta sign-in for AWS, the aws command, kubectl, your EKS clusters, Twingate."

# ------------------------------------------------------------- okcli ---
# okta-aws-cli and the AWS CLI (okcli), direnv (okcli pin): the newest release for this CPU,
# in ~/.local (no sudo). One that's already installed some other way (apt, brew, by hand)
# counts and is left alone.
group_okta_aws_cli() { echo Cloud; }
requires_okta_aws_cli() { echo linux; }
label_okta_aws_cli() { echo "okta-aws-cli"; }
title_okta_aws_cli() { echo "okta-aws-cli, so okcli can sign you in to AWS through Okta"; }
detail_okta_aws_cli() { echo "latest okta-aws-cli from GitHub (sha256-checked) in ~/.local/bin"; }
state_okta_aws_cli() { tool_state okta-aws-cli; }
doctor_okta_aws_cli() {   # tk doctor: okcli's own checks, and its shell hook
  type -P okcli >/dev/null && okcli doctor
  [[ -n ${OKCLI_SHELL:-} ]] && echo "✓ shell hook" || echo "! okcli's shell hook isn't loaded — tk install bash"
}
install_okta_aws_cli() { get_tool okta-aws-cli "okcli signs in to AWS with it" "about 10 MB" fetch_okta_aws_cli; }
fetch_okta_aws_cli() { gh_tool okta/okta-aws-cli "okta-aws-cli_{v}_linux_$(dl_arch).tar.gz" okta-aws-cli; }
uninstall_okta_aws_cli() { drop_tool okta-aws-cli; }

# AWS's own installer, into ~/.local/aws-cli with aws and aws_completer in ~/.local/bin.
# AWS publishes no checksum for it (only a PGP signature); it comes over HTTPS from AWS.
awscli_dir="$HOME/.local/aws-cli"
group_aws_cli() { echo Cloud; }
requires_aws_cli() { echo linux; }
label_aws_cli() { echo "AWS CLI v2"; }
title_aws_cli() { echo "The aws command: okcli whoami, kx's EKS sign-in and kx sync need it"; }
detail_aws_cli() { echo "latest AWS CLI v2 from awscli.amazonaws.com in ${awscli_dir/#$HOME/\~}, aws and aws_completer in ~/.local/bin"; }
state_aws_cli() { tool_state aws; }
install_aws_cli() {
  type -P aws >/dev/null || type -P unzip >/dev/null || { skip "unzip is needed to unpack it (sudo apt install unzip)"; return; }
  get_tool aws "okcli and kx's EKS sign-in use it" "about 60 MB" fetch_aws_cli
}
fetch_aws_cli() {
  local arch tmp rc=1
  case "$(dl_arch)" in amd64) arch=x86_64 ;; arm64) arch=aarch64 ;; esac
  tmp=$(mktemp -d)
  if curl -fsSL --retry 2 -o "$tmp/aws.zip" "https://awscli.amazonaws.com/awscli-exe-linux-$arch.zip" 2>>"$log_file"; then
    unzip -q "$tmp/aws.zip" -d "$tmp" 2>>"$log_file" &&
      "$tmp/aws/install" -i "$awscli_dir" -b "$HOME/.local/bin" --update >>"$log_file" 2>&1 && rc=0
  else warn "couldn't download the AWS CLI (offline?)"; fi
  rm -rf "$tmp"
  return "$rc"
}
uninstall_aws_cli() {
  if [[ -d $awscli_dir ]]; then
    rm -rf "$awscli_dir" "$HOME/.local/bin/aws" "$HOME/.local/bin/aws_completer"; ok "removed the AWS CLI"
  else drop_tool aws; fi
}

requires_direnv() { echo linux; }
label_direnv() { echo "direnv"; }
title_direnv() { echo "direnv, so okcli pin switches the AWS profile when you cd into a folder"; }
detail_direnv() { echo "latest direnv from GitHub (sha256-checked) in ~/.local/bin; bluetools' shell setup hooks it in"; }
state_direnv() { tool_state direnv; }
install_direnv() { get_tool direnv "okcli pin needs it" "about 10 MB" fetch_direnv; }
fetch_direnv() { gh_tool direnv/direnv "direnv.linux-$(dl_arch)" direnv; }
uninstall_direnv() { drop_tool direnv; }

# ---------------------------------------------------------------- kx ---
# kubectl (kx), and the EKS clusters kx shows.
group_kubectl() { echo Cloud; }
requires_kubectl() { echo linux; }
ver_kubectl() { "$1" version --client; }
label_kubectl() { echo "kubectl"; }
title_kubectl() { echo "kubectl, which kx runs on"; }
detail_kubectl() { echo "latest stable kubectl from dl.k8s.io (sha256-checked) in ~/.local/bin"; }
state_kubectl() { tool_state kubectl; }
doctor_kubectl() {   # tk doctor: kx's own checks, and its shell hook
  type -P kx >/dev/null && kx doctor
  [[ -n ${KX_SHELL:-} ]] && echo "✓ shell hook" || echo "! kx's shell hook isn't loaded — tk install bash"
}
install_kubectl() { get_tool kubectl "kx runs on it" "about 60 MB" fetch_kubectl; }
fetch_kubectl() {
  local v url sum tmp rc=1
  v=$(curl -fsS -m 10 https://dl.k8s.io/release/stable.txt 2>>"$log_file") || { warn "couldn't find the latest kubectl (offline?)"; return 1; }
  url="https://dl.k8s.io/release/$v/bin/linux/$(dl_arch)/kubectl"
  sum=$(curl -fsS -m 10 "$url.sha256" 2>>"$log_file") || { warn "couldn't get kubectl's checksum"; return 1; }
  tmp=$(mktemp -d)
  fetch_checked "$url" "$sum" "$tmp/kubectl" && mkdir -p "$HOME/.local/bin" &&
    install -m 755 "$tmp/kubectl" "$HOME/.local/bin/kubectl" && rc=0
  rm -rf "$tmp"
  (( rc )) || logf "kubectl $v installed to ~/.local/bin"
  return "$rc"
}
uninstall_kubectl() { drop_tool kubectl; }

# -------------------------------------------------------- eks-clusters ---
# Runs kx sync: tick the AWS accounts to search, then the clusters to add.
# Unticked ones go in ~/.config/kx/ignore, so later syncs skip them.
kx_ignore_file="${XDG_CONFIG_HOME:-$HOME/.config}/kx/ignore"
eks_contexts() { KUBECONFIG="${KX_BASE_KUBECONFIG:-$HOME/.kube/config}" kubectl config get-contexts -o name 2>/dev/null | grep -c .; }
group_eks_clusters() { echo Cloud; }
NEEDS[eks-clusters]="kubectl aws-cli"
label_eks_clusters() { echo "EKS clusters"; }
title_eks_clusters() { echo "Pick which AWS accounts and EKS clusters kx shows"; }
detail_eks_clusters() { echo "runs kx sync: ticked clusters go in ~/.kube/config, unticked ones in ~/.config/kx/ignore (kx ignore / kx sync to change later)"; }
state_eks_clusters() {
  local n; NOTE=""
  type -P kubectl >/dev/null && type -P aws >/dev/null || { STATE=n/a; NOTE="needs kubectl and the aws CLI"; return; }
  n=$(eks_contexts)
  if (( n )) || [[ -e $kx_ignore_file ]]; then STATE=installed; NOTE="$n context(s) · kx sync / kx ignore to change"
  else STATE=missing; fi
}
install_eks_clusters() {
  (( $(eks_contexts) )) && { ok "already set up ${D}(kx sync / kx ignore to change)${R}"; return; }
  if dry; then say "      ${D}would run kx sync: tick AWS accounts, then the clusters to add${R}"; return; fi
  if ! "$bluetools_root/bin/okcli" __profiles 2>/dev/null | grep -q .; then
    warn "okcli has no AWS profiles yet: run ${B}okcli sync${R}, then ${B}kx sync${R}"; return
  fi
  [[ $mode == yes ]] && { skip "pick them yourself: kx sync"; return; }
  ask "Pick your EKS clusters now? (tick accounts, then clusters; unticked ones are skipped from now on)" || { skip "later: kx sync"; return; }
  if "$bluetools_root/bin/kx" sync </dev/tty >/dev/tty 2>&1; then ok "done ${D}(kx ignore shows what's skipped)${R}"
  else warn "kx sync didn't finish; run it again with: kx sync"; fi
}
uninstall_eks_clusters() {
  ok "your clusters stay in ~/.kube/config (kx rm <context> removes one); the skip list stays in ${kx_ignore_file/#$HOME/\~}"
}

# -------------------------------------------------------------- twin ---
# Twingate's own installer: adds its apt source and installs the client (sudo).
group_twingate() { echo Cloud; }
requires_twingate() { echo apt; }
label_twingate() { echo "Twingate"; }
title_twingate() { echo "The Twingate client, which twin switches on and off"; }
detail_twingate() { echo "Twingate's installer (binaries.twingate.com, adds its apt source; sudo); then sudo twingate setup, once"; }
state_twingate() { tool_state twingate; }
doctor_twingate() {
  if [[ "$(twingate status -d 2>/dev/null | head -n1)" == online ]]; then echo "✓ connected"
  else echo "! Twingate isn't connected — open the Twingate app"; fi
}
install_twingate() {
  type -P twingate >/dev/null && { ok "twingate is already installed"; return; }
  ask "Install the Twingate client? (Twingate's installer adds its apt source; sudo may ask for your password)" || { skip; return; }
  dry && return
  local tmp; tmp=$(mktemp)
  if ! curl -fsSL --retry 2 -o "$tmp" https://binaries.twingate.com/client/linux/install.sh 2>>"$log_file"; then
    rm -f "$tmp"; fail "couldn't download Twingate's installer (offline?)"; return
  fi
  say "      ${D}sudo may ask for your password${R}"
  if as_root bash "$tmp" >>"$log_file" 2>&1 && type -P twingate >/dev/null; then
    ok "installed"; say "      ${D}Then, once: sudo twingate setup (it asks for your network's name)${R}"
  else fail "not installed (see $log_file)"; fi
  rm -f "$tmp"
}
uninstall_twingate() { apt_drop twingate Twingate; }

# --------------------------------------------------------------- hat ---
# gh, from GitHub's release (the tar.gz holds gh_<v>_linux_<arch>/bin/gh)
group_gh() { echo Apps; }
requires_gh() { echo linux; }
label_gh() { echo "GitHub CLI (gh)"; }
title_gh() { echo "The gh command: hat signs it in per GitHub account, for PRs and the API"; }
detail_gh() { echo "latest gh from GitHub (sha256-checked) in ~/.local/bin"; }
state_gh() { tool_state gh; }
install_gh() { get_tool gh "hat signs it in to your GitHub accounts" "about 15 MB" fetch_gh; }
fetch_gh() {
  local tmp d rc=1
  gh_latest cli/cli "gh_{v}_linux_$(dl_arch).tar.gz" || { warn "couldn't find the latest gh (offline?)"; return 1; }
  tmp=$(mktemp -d) d="gh_${GH_VER}_linux_$(dl_arch)"
  fetch_checked "$GH_URL" "$GH_SHA" "$tmp/dl" && tar xzf "$tmp/dl" -C "$tmp" "$d/bin/gh" 2>>"$log_file" &&
    mkdir -p "$HOME/.local/bin" && install -m 755 "$tmp/$d/bin/gh" "$HOME/.local/bin/gh" && rc=0
  rm -rf "$tmp"
  (( rc )) || logf "gh $GH_VER installed to ~/.local/bin"
  return "$rc"
}
uninstall_gh() { drop_tool gh; }

# wl-copy on Wayland, xclip on X11
clip_pkg() { [[ ${XDG_SESSION_TYPE:-} == x11 ]] && echo xclip || echo wl-clipboard; }
group_clipboard() { echo Apps; }
requires_clipboard() { echo apt; }
label_clipboard() { echo "Clipboard tool"; }
title_clipboard() { echo "wl-copy (xclip on X11), so hat can copy keys and sign-in codes for you"; }
detail_clipboard() { echo "$(clip_pkg) (apt) if neither wl-copy nor xclip is installed"; }
state_clipboard() { NOTE=""; if type -P wl-copy >/dev/null || type -P xclip >/dev/null; then STATE=installed; else STATE=missing; fi; }
install_clipboard() {
  type -P wl-copy >/dev/null || type -P xclip >/dev/null && { ok "already installed"; return; }
  ask "Install $(clip_pkg)? (apt, needs sudo)" || { skip; return; }
  dry || { apt_install "$(clip_pkg)" && ok "installed" || fail "apt failed (see $log_file)"; }
}
uninstall_clipboard() { apt_drop "$(clip_pkg)" "$(clip_pkg)"; }

# ------------------------------------------------------- Bluetooth audio ---
btl="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENTS+=(bt-audio bt-notify)
group_bt_audio() { echo "Desktop (GNOME)"; }; group_bt_notify() { echo "Desktop (GNOME)"; }
requires_bt_audio() { echo linux; }; requires_bt_notify() { echo linux; }

# ------------------------------------------------------------ bt-audio ---
# Bluetooth earbuds on PipeWire + WirePlumber 0.4 (Ubuntu 24.04). Two settings files, linked in:
#  - the laptop only sends audio over Bluetooth: earbuds that also advertise "Audio Source" otherwise
#    open a backwards music link when they reconnect, and Headset (music) mode never shows up;
#  - browser, Slack, Discord and Teams mics count as calls, so WirePlumber switches the earbuds to
#    Handsfree while one is open and back to Headset when it closes (it does so already for apps
#    that say they are a call, and a few browsers by name).
bta_roles="$HOME/.config/wireplumber/bluetooth.lua.d/51-unikit-roles.lua"; bta_roles_src="$btl/audio/wireplumber/51-unikit-roles.lua"
bta_calls="$HOME/.config/pipewire/pipewire-pulse.conf.d/51-unikit-calls.conf"; bta_calls_src="$btl/audio/51-unikit-calls.conf"
bta_wp() { wireplumber --version 2>/dev/null | sed -n 's/.*libwireplumber \([0-9.]*\).*/\1/p'; }
label_bt_audio() { echo "Bluetooth earbuds"; }
title_bt_audio() { echo "earbuds keep music mode after reconnecting, and switch to Handsfree while a call (browser, Slack) has the mic"; }
detail_bt_audio() { echo "${bta_roles/#$HOME/\~} -> bluetools/audio/wireplumber/51-unikit-roles.lua, ${bta_calls/#$HOME/\~} -> bluetools/audio/51-unikit-calls.conf; takes effect at the next login"; }
touches_bt_audio() { echo "$bta_roles"; echo "$bta_calls"; }
state_bt_audio() { NOTE=""
  local v; v=$(bta_wp)
  [[ -n $v ]] || { STATE=unsupported; NOTE="needs PipeWire with WirePlumber"; return; }
  [[ $v == 0.4.* ]] || { STATE=unsupported; NOTE="needs WirePlumber 0.4 (this is $v)"; return; }
  local n=0
  linked "$bta_roles" "$bta_roles_src" && (( n++ ))
  linked "$bta_calls" "$bta_calls_src" && (( n++ ))
  if (( n == 2 )); then STATE=installed; elif (( n )); then STATE=partial; else STATE=missing; fi; }
install_bt_audio() {
  if linked "$bta_roles" "$bta_roles_src" && linked "$bta_calls" "$bta_calls_src"; then ok "already installed"; return; fi
  ask "Keep Bluetooth earbuds in music mode after they reconnect, and switch them to Handsfree during calls?" || { skip; return; }
  dry && return 0
  link_file "$bta_roles" "$bta_roles_src" || return 1
  link_file "$bta_calls" "$bta_calls_src" || return 1
  warn "log out and back in once (restarting audio now would leave open apps without sound)"
}
uninstall_bt_audio() {
  unlink_file "$bta_roles" "$bta_roles_src"
  unlink_file "$bta_calls" "$bta_calls_src"
}

# ----------------------------------------------------------- bt-notify ---
# A short notification when earbuds switch mode on their own (bluetools/audio/bin/k-bt-notify), started at
# login by a systemd user service. It sleeps on PipeWire's change feed: no polling, no cost when idle.
btn_unit="$HOME/.config/systemd/user/k-bt-notify.service"
btn_body() { printf '%s\n' "[Unit]" "Description=unikit: notify when Bluetooth earbuds switch mode" \
  "After=pipewire.service" "" "[Service]" "ExecStart=$btl/audio/bin/k-bt-notify" "Restart=on-failure" "RestartSec=5" \
  "" "[Install]" "WantedBy=default.target"; }
btn_on() { systemctl --user is-enabled k-bt-notify.service >/dev/null 2>&1; }
label_bt_notify() { echo "Earbud mode notifications"; }
title_bt_notify() { echo "a short notification when earbuds switch to Handsfree (mic on) and back to Headset (music)"; }
detail_bt_notify() { echo "${btn_unit/#$HOME/\~} runs bluetools/audio/bin/k-bt-notify at login (systemd user service)"; }
state_bt_notify() { NOTE=""
  type -P pw-dump >/dev/null || { STATE=unsupported; NOTE="needs PipeWire"; return; }
  local n=0
  [[ $(cat "$btn_unit" 2>/dev/null) == "$(btn_body)" ]] && (( n++ ))
  btn_on && (( n++ ))
  if (( n == 2 )); then STATE=installed; elif (( n )) || [[ -e $btn_unit ]]; then STATE=partial; else STATE=missing; fi; }
install_bt_notify() {
  if [[ $(cat "$btn_unit" 2>/dev/null) == "$(btn_body)" ]] && btn_on; then ok "already installed"; return; fi
  ask "Show a short notification when earbuds switch between Headset and Handsfree?" || { skip; return; }
  dry && return 0
  mkdir -p "${btn_unit%/*}" && btn_body >"$btn_unit" || return 1
  systemctl --user daemon-reload >>"$log_file" 2>&1
  systemctl --user enable --now k-bt-notify.service >>"$log_file" 2>&1 && ok "on (uninstall bt-notify to turn it off)" ||
    { fail "systemctl could not start it (see $log_file)"; return 1; }
}
uninstall_bt_notify() {
  [[ -e $btn_unit ]] || return 0
  systemctl --user disable --now k-bt-notify.service >>"$log_file" 2>&1
  rm -f "$btn_unit"; systemctl --user daemon-reload >>"$log_file" 2>&1
  ok "removed"
}
