# bluetools in every shell (bash and zsh), sourced by unikit's shell/init.sh: each tool's
# settings and shell hook. Fast and quiet: it runs in every new terminal.
_bluetools_shell="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

# okta-aws-cli settings okcli relies on. Your org's domain and Okta app client id
# come from a layer (layers/<name>/shell/init.sh) or your own shell:
#   export OKTA_AWSCLI_ORG_DOMAIN=<your-org>.okta.com
#   export OKTA_AWSCLI_OIDC_CLIENT_ID=<client id>
# Each one here is only a default: anything already set wins.
export OKTA_AWSCLI_FORMAT="${OKTA_AWSCLI_FORMAT:-aws-credentials}"
export OKTA_AWSCLI_CACHE_ACCESS_TOKEN="${OKTA_AWSCLI_CACHE_ACCESS_TOKEN:-true}"
export OKTA_AWSCLI_WRITE_AWS_CREDENTIALS="${OKTA_AWSCLI_WRITE_AWS_CREDENTIALS:-true}"
export OKTA_AWSCLI_EXPIRY_AWS_VARIABLES="${OKTA_AWSCLI_EXPIRY_AWS_VARIABLES:-true}"
export OKTA_AWSCLI_OPEN_BROWSER="${OKTA_AWSCLI_OPEN_BROWSER:-true}"
export OKTA_AWSCLI_SESSION_DURATION="${OKTA_AWSCLI_SESSION_DURATION:-14400}"

# direnv, for okcli pin (a folder's .envrc). It puts its hook first, so a pin is applied
# before okcli's prompt hook reads AWS_PROFILE.
# Quiet: no "direnv: loading / export" lines; the prompt already shows the AWS
# profile. Errors (a blocked .envrc) still show. Set DIRENV_LOG_FORMAT to get them back.
export DIRENV_LOG_FORMAT="${DIRENV_LOG_FORMAT-}"
if command -v direnv >/dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then eval "$(direnv hook zsh)"; else eval "$(direnv hook bash)"; fi
fi

. "$_bluetools_shell/okcli.sh"
. "$_bluetools_shell/kx.sh"
. "$_bluetools_shell/twin.sh"
unset _bluetools_shell
