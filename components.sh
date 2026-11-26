# bluetools' installer parts. unikit's lib/components.sh sources this after its own, so its
# helpers are here: ask, ok, skip, warn, fail, dry, linked, link_file, unlink_file, set_block,
# apt_install, and the release helpers get_tool, gh_tool, tool_state, drop_tool (docs/LAYERS.md).

bluetools_root="$(cd "${BASH_SOURCE[0]%/*}" && pwd)"
COMPONENTS+=(okta-aws-cli aws-cli direnv kubectl eks-clusters twingate gh clipboard zed vscode bluetools-window-calls repos claude-hook claude-guard)
GROUP_ABOUT[Apps]="Programs the commands use: gh, a clipboard tool, an editor, Window Calls."
GROUP_ABOUT[Workspaces]="Your repos, cloned from your workspace list (ws edit)."
GROUP_ABOUT[Cloud]="What okcli, kx and twin run on: Okta, aws, direnv, kubectl, Twingate."

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
title_aws_cli() { echo "The aws command, for okcli and kx"; }
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

group_direnv() { echo Cloud; }
requires_direnv() { echo linux; }
label_direnv() { echo "direnv"; }
title_direnv() { echo "direnv: okcli pins switch the AWS profile per folder"; }
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
    put_copy -m 755 "$tmp/kubectl" "$HOME/.local/bin/kubectl" && rc=0
  rm -rf "$tmp"
  (( rc )) || logf "kubectl $v installed to ~/.local/bin"
  return "$rc"
}
uninstall_kubectl() { drop_tool kubectl; }

# -------------------------------------------------------- eks-clusters ---
# Runs kx sync: tick the AWS accounts to search, then the clusters to add.
# Unticked ones go in ~/.config/kx/ignore, so later syncs skip them.
kx_ignore_file="${XDG_CONFIG_HOME:-$HOME/.config}/kx/ignore"
# What kx sync adds: EKS contexts (aws eks update-kubeconfig, an arn:aws:eks:… cluster)
eks_context_names() {
  KUBECONFIG="${KX_BASE_KUBECONFIG:-$HOME/.kube/config}" kubectl config view \
    -o jsonpath='{range .contexts[*]}{.name}{"\t"}{.context.cluster}{"\n"}{end}' 2>/dev/null | awk -F'\t' '$2 ~ /^arn:aws:eks:/ { print $1 }'
}
eks_contexts() { eks_context_names | grep -c .; }
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
# Asks before removing them (default no; --yes keeps them): kx rm backs the file up first.
uninstall_eks_clusters() {
  local -a ctxs; mapfile -t ctxs < <(type -P kubectl >/dev/null && eks_context_names)
  local list="" ign=${kx_ignore_file/#$HOME/\~}
  (( ${#ctxs[@]} )) && list="the ${#ctxs[@]} EKS cluster(s) in ~/.kube/config (${ctxs[*]})"
  [[ -e $kx_ignore_file ]] && list+="${list:+ and }kx sync's skip list ($ign)"
  [[ -n $list ]] || { ok "no EKS clusters to remove"; return 0; }
  if [[ $mode != yes ]] && ask "Remove $list? (kx sync can add them back)" n; then
    dry && return 0
    if (( ${#ctxs[@]} )) && ! "$bluetools_root/bin/kx" rm --yes "${ctxs[@]}"; then fail "kx rm failed (see above)"; return 0; fi
    rm -f "$kx_ignore_file"; ok "removed"
  else kept "your clusters stay in ~/.kube/config" "your clusters stay in ~/.kube/config (kx rm <context> removes one); the skip list stays in $ign"; fi
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
title_gh() { echo "The gh command, signed in per account by hat"; }
detail_gh() { echo "latest gh from GitHub (sha256-checked) in ~/.local/bin"; }
state_gh() { tool_state gh; }
install_gh() { get_tool gh "hat signs it in to your GitHub accounts" "about 15 MB" fetch_gh; }
fetch_gh() {
  local tmp d rc=1
  gh_latest cli/cli "gh_{v}_linux_$(dl_arch).tar.gz" || { warn "couldn't find the latest gh (offline?)"; return 1; }
  tmp=$(mktemp -d) d="gh_${GH_VER}_linux_$(dl_arch)"
  fetch_checked "$GH_URL" "$GH_SHA" "$tmp/dl" && tar xzf "$tmp/dl" -C "$tmp" "$d/bin/gh" 2>>"$log_file" &&
    mkdir -p "$HOME/.local/bin" && put_copy -m 755 "$tmp/$d/bin/gh" "$HOME/.local/bin/gh" && rc=0
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
title_clipboard() { echo "A clipboard tool, so hat can copy codes for you"; }
detail_clipboard() { echo "$(clip_pkg) (apt) if neither wl-copy nor xclip is installed"; }
state_clipboard() { NOTE=""; if type -P wl-copy >/dev/null || type -P xclip >/dev/null; then STATE=installed; else STATE=missing; fi; }
install_clipboard() {
  type -P wl-copy >/dev/null || type -P xclip >/dev/null && { ok "already installed"; return; }
  ask "Install $(clip_pkg)? (apt, needs sudo)" || { skip; return; }
  dry || { apt_install "$(clip_pkg)" && ok "installed" || fail "apt failed (see $log_file)"; }
}
uninstall_clipboard() { apt_drop "$(clip_pkg)" "$(clip_pkg)"; }

# ---------------------------------------------------------------- ws ---
# Zed's own installer: ~/.local/zed.app, zed in ~/.local/bin, its launcher entry (no sudo)
group_zed() { echo Apps; }
requires_zed() { echo linux; }
label_zed() { echo "Zed"; }
title_zed() { echo "The Zed editor, which ws opens workspaces in"; }
detail_zed() { echo "Zed's installer (zed.dev): ~/.local/zed.app, zed in ~/.local/bin, a launcher entry; no sudo"; }
state_zed() { tool_state zed; }
install_zed() {
  type -P zed >/dev/null && { ok "zed is already installed"; return; }
  ask "Install Zed? (Zed's installer, into ~/.local; about 150 MB, no sudo)" || { skip; return; }
  dry && return
  local tmp; tmp=$(mktemp)
  if curl -fsSL --retry 2 -o "$tmp" https://zed.dev/install.sh 2>>"$log_file" && sh "$tmp" >>"$log_file" 2>&1 &&
    type -P zed >/dev/null; then ok "installed"
  else fail "not installed (see $log_file)"; fi
  rm -f "$tmp"
}
uninstall_zed() {
  [[ -d $HOME/.local/zed.app ]] || { drop_tool zed; return; }
  ask "Remove Zed? (your Zed settings stay)" n || { kept "you kept it" "Zed stays"; return; }
  dry || { zed --uninstall >>"$log_file" 2>&1 </dev/null || rm -rf "$HOME/.local/zed.app" "$HOME/.local/bin/zed"; ok "removed"; }
}

# Microsoft's .deb (it adds Microsoft's apt source, so apt keeps it up to date)
group_vscode() { echo Apps; }
requires_vscode() { echo apt; }
label_vscode() { echo "VS Code"; }
title_vscode() { echo "VS Code, which ws can open workspaces in"; }
detail_vscode() { echo "Microsoft's .deb from code.visualstudio.com via apt (sudo); it adds Microsoft's apt source"; }
state_vscode() { tool_state code; }
install_vscode() {
  type -P code >/dev/null && { ok "VS Code is already installed"; return; }
  local a; case "$(dl_arch)" in amd64) a=x64 ;; arm64) a=arm64 ;; *) skip "no download for this machine"; return ;; esac
  ask "Install VS Code? (Microsoft's .deb, about 110 MB; apt, needs sudo)" || { skip; return; }
  dry && return
  local tmp; tmp=$(mktemp -d)
  if curl -fsSL --retry 2 -o "$tmp/code.deb" "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-$a" 2>>"$log_file"; then
    chmod 644 "$tmp/code.deb"; chmod 755 "$tmp"   # apt's own user reads it
    say "      ${D}sudo may ask for your password${R}"
    as_root apt-get install -y "$tmp/code.deb" >>"$log_file" 2>&1 && ok "installed" || fail "apt failed (see $log_file)"
  else fail "couldn't download VS Code (offline?)"; fi
  rm -rf "$tmp"
}
uninstall_vscode() { apt_drop code "VS Code"; }

# ---------------------------------------------- bluetools-window-calls ---
# GNOME extension that lets scripts list, focus and close windows over D-Bus.
# ws uses it to close a workspace's window and to read open windows exactly. Another layer may
# bring a part for the same extension (same touches_): the second finds it set up and does
# nothing, and an uninstall leaves it while another layer's part has it set up.
btwc_uuid="window-calls@domandoman.xyz"
btwc_enabled() { gsettings get org.gnome.shell enabled-extensions 2>/dev/null | grep -q "'$btwc_uuid'"; }
btwc_present() { [[ -d "$HOME/.local/share/gnome-shell/extensions/$btwc_uuid" ]]; }
btwc_live() { gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/Windows \
  --method org.gnome.Shell.Extensions.Windows.List >/dev/null 2>&1; }
label_bluetools_window_calls() { echo "Window Calls"; }
title_bluetools_window_calls() { echo "Lets ws focus and close editor windows (log out once)"; }
touches_bluetools_window_calls() { echo "$HOME/.local/share/gnome-shell/extensions/$btwc_uuid"; }
group_bluetools_window_calls() { echo Apps; }
requires_bluetools_window_calls() { echo gnome; }
detail_bluetools_window_calls() { echo "GNOME extension $btwc_uuid from extensions.gnome.org into ~/.local/share/gnome-shell/extensions"; }
state_bluetools_window_calls() {
  NOTE=""
  type -P gnome-shell >/dev/null || { STATE=unsupported; NOTE="needs GNOME"; return; }
  if btwc_present && btwc_enabled; then
    if btwc_live; then STATE=installed; else STATE=partial; NOTE="log out and back in to load it"; fi
  elif btwc_present; then STATE=partial; NOTE="installed, not enabled"
  else STATE=missing; fi
}
install_bluetools_window_calls() {
  local ver url tmp
  if btwc_present && btwc_enabled; then
    btwc_live && ok "already active" || ok "installed; log out and back in once to load it"
    return
  fi
  if ! btwc_present; then
    ask "Download Window Calls from extensions.gnome.org and install it?" || { skip; return; }
    ver=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
    url=$(curl -fsS "https://extensions.gnome.org/extension-info/?uuid=$btwc_uuid&shell_version=$ver" |
      python3 -Ic 'import json,sys; print(json.load(sys.stdin)["download_url"])' 2>/dev/null)
    [[ -n "$url" ]] || { fail "no Window Calls release for GNOME $ver"; return; }
    tmp=$(mktemp --suffix=.zip)
    if curl -fsSL -o "$tmp" "https://extensions.gnome.org$url" && gnome-extensions install --force "$tmp" >>"$log_file" 2>&1; then
      ok "installed"; logf "  from https://extensions.gnome.org$url"
    else rm -f "$tmp"; fail "download or install failed (see the log)"; return; fi
    rm -f "$tmp"
  fi
  # `gnome-extensions enable` can't see it until GNOME reloads, so add it to the list directly
  # (and off the disabled list, where an uninstall leaves it).
  dry || ext_list add "$btwc_uuid"
  ok "enabled"
  warn "log out and back in once (Wayland loads new extensions only at login)"
}
uninstall_bluetools_window_calls() {
  btwc_present || { ok "not installed"; return; }
  shared_keep bluetools-window-calls && return
  gnome-extensions disable "$btwc_uuid" >/dev/null 2>&1
  python3 -I - "$btwc_uuid" <<'PY'
import ast, subprocess, sys
cur = subprocess.run(["gsettings", "get", "org.gnome.shell", "enabled-extensions"], capture_output=True, text=True).stdout.strip()
lst = ast.literal_eval(cur.removeprefix("@as ")) if cur else []
if sys.argv[1] in lst:
    subprocess.run(["gsettings", "set", "org.gnome.shell", "enabled-extensions", str([x for x in lst if x != sys.argv[1]])], check=True)
PY
  if gnome-extensions uninstall "$btwc_uuid" >/dev/null 2>&1 || rm -rf "$HOME/.local/share/gnome-shell/extensions/$btwc_uuid"; then
    ok "removed (ws close stops working; everything else in ws stays)"
  fi
}

# --------------------------------------------------------------- repos ---
# Clones what your workspace list names (lines with a GitHub repo) that isn't there
# yet: the layers' shared lists (layers/*/workspaces) plus your own (~/.config/ws/workspaces),
# through unikit's lib/workspaces.sh.
repos_todo() {   # <path><TAB><owner/repo> for each listed repo not cloned yet
  local p r
  while IFS=$'\t' read -r p r; do
    [[ -n $r && ! -e $p/.git ]] && printf '%s\t%s\n' "$p" "$r"
  done < <(ws_list)
}
group_repos() { echo Workspaces; }
label_repos() { echo "Workspace repos"; }
title_repos() { echo "Clone the workspace repos you don't have yet"; }
detail_repos() { echo "git clone over SSH into the folders your workspace list names; creates ~/.config/ws/workspaces"; }
state_repos() {
  local all todo
  all=$(ws_list | awk -F'\t' '$2 != ""' | wc -l)
  todo=$(repos_todo | grep -c . )
  NOTE=""
  if (( todo == 0 )); then STATE=installed
  elif (( todo < all )); then STATE=partial; NOTE="$((all - todo)) of $all cloned"
  else STATE=missing; fi
}
install_repos() {
  local out p r labels=() todo=() on="" i
  # Your own list, outside the repo (team repos included); edit it with: ws edit
  if [[ ! -e "$(ws_list_file)" ]] && ! dry; then
    ws_personal_init >/dev/null && ok "your workspace list: $(ws_list_file | sed "s|^$HOME|~|") ${D}(ws edit)${R}"
  fi
  # where each group of repos goes ($ACME, ...), asked once while its folder isn't there
  local v vd
  while IFS= read -r v; do
    vd=$(ws_var "$v")
    [[ -n $vd && ! -d $vd ]] && repos_todo | grep -q "^$vd/" && ask_ws_folder "$v" "the repos under \$$v"
  done < <(ws_vars)
  mapfile -t todo < <(repos_todo)
  (( ${#todo[@]} )) || { ok "all cloned"; return; }
  # Check GitHub SSH first: one clear message instead of a failure per repo.
  out=$(ssh -T -o BatchMode=yes -o ConnectTimeout=8 git@github.com 2>&1)
  if [[ $out != *"successfully authenticated"* ]]; then
    fail "GitHub SSH auth isn't working, so skipping repos: $(head -1 <<<"$out")"
    say "      ${D}Check: ssh -T git@github.com · then: ./install.sh repos${R}"
    return
  fi
  ok "GitHub SSH works ($(grep -o 'Hi [^!]*' <<<"$out"))"
  if dry; then
    for i in "${todo[@]}"; do say "      ${D}would clone ${i#*$'\t'} → ${i%%$'\t'*}${R}" | sed "s|$HOME|~|"; done
    return
  fi
  if [[ $mode == ask ]]; then
    for i in "${!todo[@]}"; do
      labels+=("$(basename "${todo[i]%%$'\t'*}")"$'\t'"${todo[i]#*$'\t'}"); on+="$i "
    done
    CHECKLIST_ON=$on checklist "      Missing repos (all ticked; space unticks):" "${labels[@]}" || { skip; return; }
    local picked=(); for i in "${CHECKLIST[@]}"; do picked+=("${todo[i]}"); done
    todo=("${picked[@]}")
    (( ${#todo[@]} )) || { skip "nothing picked"; return; }
  fi
  for i in "${todo[@]}"; do
    p=${i%%$'\t'*}; r=${i#*$'\t'}
    if [[ -e $p ]]; then warn "$(basename "$p"): folder exists but isn't a git repo, left alone"; continue; fi
    mkdir -p "$(dirname "$p")"
    if git clone -q "git@github.com:$r.git" "$p" >>"$log_file" 2>&1; then ok "$(basename "$p")"
    else warn "$(basename "$p"): couldn't clone $r (no access, or it doesn't exist); skipped"; fi
  done
}
# clone_unpushed <dir>: 0 when the clone holds work that isn't on GitHub yet
# (uncommitted, no upstream, or commits not pushed), so it must never be deleted.
clone_unpushed() {
  [[ -n $(git -C "$1" status --porcelain 2>/dev/null) ]] && return 0
  git -C "$1" rev-parse '@{u}' >/dev/null 2>&1 || return 0
  [[ -n $(git -C "$1" log --oneline '@{u}..' 2>/dev/null) ]]
}
uninstall_repos() {
  local p r safe=() kept=() names d n
  while IFS=$'\t' read -r p r; do
    [[ -n $r && -d $p/.git && $p == "$HOME"/?* ]] || continue
    if clone_unpushed "$p"; then kept+=("$p"); else safe+=("$p"); fi
  done < <(ws_list)
  (( ${#safe[@]} + ${#kept[@]} )) || { ok "no cloned workspace repos found"; return 0; }
  for d in "${kept[@]}"; do warn "${d/#$HOME/\~} has work that isn't on GitHub yet (uncommitted or not pushed), so it stays"; done
  (( ${#safe[@]} )) || return 0
  if [[ $mode == yes ]]; then ok "the ${#safe[@]} clones stay (--yes never deletes folders)"; return 0; fi
  n=${#safe[@]}; names=$(printf '%s, ' "${safe[@]:0:4}" | sed "s|$HOME|~|g; s|, \$||")
  (( n > 4 )) && names+=", and $(( n - 4 )) more"
  if ask "Also delete $n workspace clone(s) with nothing unpushed? ($names)" n; then
    dry || { for d in "${safe[@]}"; do rm -rf -- "$d"; done; ok "$n clone(s) deleted"; }
  else ok "the clones stay"; fi
}

# ------------------------------------------------------------ claude ---
# Claude Code's start hook (ctx plain) and PROD guard, in every Claude profile (unikit's
# claude_each / claude_state). The bluetools skill is in claude/skills/: unikit's
# claude-skill part links it.
# The hook is the one SessionStart entry whose command is $ch_cmd (the guard: the one
# PreToolUse entry for Bash whose command is $cgd_cmd). settings.json is edited as
# JSON (python), everything else in it is kept as is.
ch_settings="$claude_dir/settings.json"
ch_cmd="ctx plain 2>/dev/null || true"
ch_json() {   # ch_json has|add|remove [command event matcher]  (add/remove print the new settings)
  python3 -I - "$ch_settings" "${2:-$ch_cmd}" "$1" "${3:-SessionStart}" "${4:-}" <<'PY'
import json, os, sys
path, cmd, op, event, matcher = sys.argv[1:]
d = json.load(open(path)) if os.path.exists(path) and os.path.getsize(path) else {}
ss = d.setdefault("hooks", {}).setdefault(event, [])
mine = lambda g: any(h.get("command") == cmd for h in g.get("hooks", []))
if op == "has":
    sys.exit(0 if any(mine(g) for g in ss) else 1)
ss[:] = [g for g in ss if not mine(g)]
if op == "add":
    ss.append({**({"matcher": matcher} if matcher else {}), "hooks": [{"type": "command", "command": cmd, "timeout": 10}]})
if not ss: del d["hooks"][event]
if not d["hooks"]: del d["hooks"]
print(json.dumps(d, indent=2))
PY
}
ch_write() {   # ch_write add|remove [command event matcher]
  local tmp b; tmp=$(mktemp)
  ch_json "$@" >"$tmp" || { rm -f "$tmp"; fail "couldn't read ${ch_settings/#$HOME/\~} (not valid JSON?)"; return 1; }
  mkdir -p "$claude_dir"; b=$(backup "$ch_settings")
  put_out "$ch_settings" cat "$tmp"; rm -f "$tmp"
  logf "  $1 ${3:-SessionStart} hook in $ch_settings${b:+ (backup: $b)}"
  ok "done${b:+ (backup: ${b/#$HOME/\~})}"
}
ch_has() { ch_json has 2>/dev/null; }
group_claude_hook() { echo "Claude Code"; }
label_claude_hook() { echo "Claude start hook"; }
title_claude_hook() { echo "Claude sessions start knowing your AWS and cluster"; }
detail_claude_hook() { echo "a SessionStart hook in each Claude profile's settings.json that runs: $ch_cmd"; }
state_claude_hook() { claude_state ch_has; }
ch_install() { ch_has && return
  ask "Add the start hook to ${ch_settings/#$HOME/\~}? (runs ${C}ctx plain${R} when a session opens)" && { dry || ch_write add; } || skip; }
install_claude_hook() { claude_each ch_install; }
ch_uninstall() { ch_has || return 0; ch_write remove; }
uninstall_claude_hook() { claude_each ch_uninstall; }

# The guard (tk/__guard, run as `tk __guard`): before each Bash command, has you approve
# one that changes something on PROD or leans on an inherited PROD profile/context.
# With no tk to run, Claude Code lets every command through, so the part says so.
cgd_cmd="tk __guard"
cgd_json() { ch_json "$1" "$cgd_cmd" PreToolUse Bash; }
cgd_has() { cgd_json has 2>/dev/null; }
group_claude_guard() { echo "Claude Code"; }
label_claude_guard() { echo "Claude PROD guard"; }
title_claude_guard() { echo "Claude Code asks you first before changing anything on PROD"; }
detail_claude_guard() { echo "a PreToolUse hook for Bash in each Claude profile's settings.json that runs: $cgd_cmd"; }
state_claude_guard() { claude_state cgd_has
  if [[ $STATE == installed || $STATE == partial ]] && ! type -P tk >/dev/null; then
    STATE=partial NOTE="it can't run: the tk command isn't on PATH (set up commands)${NOTE:+; $NOTE}"
  fi; }
cgd_install() { cgd_has && return
  ask "Add the PROD guard to ${ch_settings/#$HOME/\~}? (Claude asks you before a command that changes PROD)" && { dry || ch_write add "$cgd_cmd" PreToolUse Bash; } || skip; }
install_claude_guard() { claude_each cgd_install
  type -P tk >/dev/null || warn "the guard runs the tk command, which isn't on PATH, so it checks nothing yet: set up ${B}commands${R}"; }
cgd_uninstall() { cgd_has || return 0; ch_write remove "$cgd_cmd" PreToolUse Bash; }
uninstall_claude_guard() { claude_each cgd_uninstall; }

# ------------------------------------------------------- Bluetooth audio ---
btl="$(cd "${BASH_SOURCE[0]%/*}" && pwd)"
COMPONENTS+=(bt-audio bt-notify)
group_bt_audio() { echo "Desktop (GNOME)"; }; group_bt_notify() { echo "Desktop (GNOME)"; }
GROUP_ABOUT["Desktop (GNOME)"]="Bluetooth earbuds: music mode that lasts, Handsfree in calls."
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
title_bt_audio() { echo "Earbuds keep music mode; Handsfree during calls"; }
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
title_bt_notify() { echo "A notification when earbuds switch modes"; }
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
  mkdir -p "${btn_unit%/*}" && put_out "$btn_unit" btn_body || return 1
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
