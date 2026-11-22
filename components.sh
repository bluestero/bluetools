# bluetools' installer parts. unikit's lib/components.sh sources this after its own, so its
# helpers are here: ask, ok, skip, warn, fail, dry, linked, link_file, unlink_file, set_block,
# apt_install, and the release helpers get_tool, gh_tool, tool_state, drop_tool (docs/LAYERS.md).

COMPONENTS+=(okta-aws-cli aws-cli direnv)

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
