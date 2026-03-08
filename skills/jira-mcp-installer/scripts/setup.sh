#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}[ok]${NC}   $*"; }
warn() { echo -e "  ${YELLOW}[warn]${NC} $*"; }
fail() { echo -e "  ${RED}[fail]${NC} $*"; }
info() { echo -e "  ${BLUE}[info]${NC} $*"; }
hdr()  { echo -e "\n${BOLD}==> $*${NC}"; }

usage() {
  cat <<'EOF'
Usage: setup.sh [--client claude|codex|both] [--dry-run] [--persist-env] [--source-shell-rc]

Installs jira-mcp from the repo root, registers MCP entries, and runs offline smoke checks.

Required env:
  JIRA_BASE_URL
  JIRA_EMAIL
  JIRA_API_TOKEN

Optional env:
  CONFLUENCE_BASE_URL

Flags:
  --persist-env      Write credentials to ~/.jira-mcp.env
  --source-shell-rc  Also add 'source ~/.jira-mcp.env' to ~/.zshrc or ~/.bashrc
EOF
}

CLIENT="both"
DRY_RUN=false
PERSIST_ENV=false
SOURCE_SHELL_RC=false
TOKEN_URL="https://id.atlassian.com/manage-profile/security/api-tokens"
ENV_FILE="$HOME/.jira-mcp.env"

while [ $# -gt 0 ]; do
  case "$1" in
    --client)
      CLIENT="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --persist-env)
      PERSIST_ENV=true
      shift
      ;;
    --source-shell-rc)
      PERSIST_ENV=true
      SOURCE_SHELL_RC=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

case "$CLIENT" in
  claude|codex|both) ;;
  *)
    fail "--client must be one of: claude, codex, both"
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$SKILL_DIR/../.." && pwd)"
cd "$REPO_DIR"

FULL_SERVER_PATH="$REPO_DIR/dist/index.js"
JIRA_MIN_PATH="$REPO_DIR/scripts/minimal-server.mjs"
CONFLUENCE_MIN_PATH="$REPO_DIR/scripts/confluence-minimal-server.mjs"
REPORTS_MIN_PATH="$REPO_DIR/scripts/report-minimal-server.mjs"

run_cmd() {
  if [ "$DRY_RUN" = true ]; then
    printf '  [dry-run] '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

prompt_value() {
  local prompt="$1"
  local default_value="${2:-}"
  local secret="${3:-false}"
  local value=""

  if [ "$secret" = true ]; then
    printf "%s: " "$prompt"
    read -r -s value
    printf "\n"
  else
    if [ -n "$default_value" ]; then
      printf "%s [%s]: " "$prompt" "$default_value"
    else
      printf "%s: " "$prompt"
    fi
    read -r value
  fi

  if [ -z "$value" ]; then
    value="$default_value"
  fi

  printf "%s" "$value"
}

require_cmd() {
  local cmd="$1"
  local label="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$label: $(command -v "$cmd")"
  else
    fail "$label not found on PATH"
    exit 1
  fi
}

collect_credentials() {
  local interactive=false

  if [ -t 0 ]; then
    interactive=true
  fi

  if [ -n "${JIRA_BASE_URL:-}" ] && [ -n "${JIRA_EMAIL:-}" ] && [ -n "${JIRA_API_TOKEN:-}" ]; then
    CONFLUENCE_BASE_URL="${CONFLUENCE_BASE_URL:-$JIRA_BASE_URL/wiki}"
    return 0
  fi

  if [ "$interactive" = false ]; then
    fail "Missing Jira credentials in a non-interactive session."
    echo "  Set JIRA_BASE_URL, JIRA_EMAIL, and JIRA_API_TOKEN before running the installer."
    echo "  Create an Atlassian API token at: $TOKEN_URL"
    exit 1
  fi

  hdr "Collecting Jira credentials"
  if [ -z "${JIRA_BASE_URL:-}" ]; then
    JIRA_BASE_URL="$(prompt_value "Jira base URL (example: https://your-site.atlassian.net)")"
  fi
  if [ -z "${JIRA_EMAIL:-}" ]; then
    JIRA_EMAIL="$(prompt_value "Atlassian email")"
  fi
  if [ -z "${JIRA_API_TOKEN:-}" ]; then
    info "Create an Atlassian API token at: $TOKEN_URL"
    JIRA_API_TOKEN="$(prompt_value "Atlassian API token" "" true)"
  fi

  if [ -z "${JIRA_BASE_URL:-}" ] || [ -z "${JIRA_EMAIL:-}" ] || [ -z "${JIRA_API_TOKEN:-}" ]; then
    fail "Jira base URL, email, and API token are required."
    exit 1
  fi

  CONFLUENCE_BASE_URL="${CONFLUENCE_BASE_URL:-$JIRA_BASE_URL/wiki}"
}

persist_env_file() {
  if [ "$DRY_RUN" = true ]; then
    info "would write credentials to $ENV_FILE"
    return 0
  fi

  cat > "$ENV_FILE" <<EOF
# jira-mcp installer managed file
export JIRA_BASE_URL="$JIRA_BASE_URL"
export JIRA_EMAIL="$JIRA_EMAIL"
export JIRA_API_TOKEN="$JIRA_API_TOKEN"
export CONFLUENCE_BASE_URL="$CONFLUENCE_BASE_URL"
EOF
  chmod 600 "$ENV_FILE"
  ok "stored credentials in $ENV_FILE"
}

detect_shell_rc() {
  local shell_name=""
  shell_name="$(basename "${SHELL:-}")"

  case "$shell_name" in
    zsh)
      printf "%s" "$HOME/.zshrc"
      ;;
    bash)
      printf "%s" "$HOME/.bashrc"
      ;;
    *)
      if [ -f "$HOME/.zshrc" ]; then
        printf "%s" "$HOME/.zshrc"
      else
        printf "%s" "$HOME/.bashrc"
      fi
      ;;
  esac
}

ensure_shell_source() {
  local rc_file="$1"
  local source_line='[ -f "$HOME/.jira-mcp.env" ] && source "$HOME/.jira-mcp.env"'

  if [ "$DRY_RUN" = true ]; then
    info "would ensure $rc_file sources $ENV_FILE"
    return 0
  fi

  touch "$rc_file"
  if grep -Fq "$source_line" "$rc_file"; then
    ok "$rc_file already sources $ENV_FILE"
    return 0
  fi

  {
    printf "\n# jira-mcp installer\n"
    printf "%s\n" "$source_line"
  } >> "$rc_file"
  ok "updated $rc_file to source $ENV_FILE"
}

maybe_persist_credentials() {
  local rc_file=""
  local reply=""

  if [ "$PERSIST_ENV" = false ] && [ -t 0 ]; then
    printf "Store credentials in %s for future runs? [y/N]: " "$ENV_FILE"
    read -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      PERSIST_ENV=true
    fi
  fi

  if [ "$PERSIST_ENV" = false ]; then
    return 0
  fi

  persist_env_file

  if [ "$SOURCE_SHELL_RC" = false ] && [ -t 0 ]; then
    rc_file="$(detect_shell_rc)"
    printf "Add 'source %s' to %s? [y/N]: " "$ENV_FILE" "$rc_file"
    read -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      SOURCE_SHELL_RC=true
    fi
  fi

  if [ "$SOURCE_SHELL_RC" = true ]; then
    rc_file="$(detect_shell_rc)"
    ensure_shell_source "$rc_file"
  fi
}

claude_mcp() {
  CLAUDECODE= claude mcp "$@"
}

add_claude_stdio_server() {
  local name="$1"
  local server_path="$2"
  shift 2

  run_cmd claude_mcp add "$name" -s user "$@" -- node "$server_path"
}

remove_claude_server() {
  local name="$1"
  run_cmd claude_mcp remove -s local "$name" >/dev/null 2>&1 || true
  run_cmd claude_mcp remove -s project "$name" >/dev/null 2>&1 || true
  run_cmd claude_mcp remove -s user "$name" >/dev/null 2>&1 || true
}

remove_codex_server() {
  local name="$1"
  run_cmd codex mcp remove "$name" >/dev/null 2>&1 || true
}

verify_tools() {
  local server_path="$1"
  local expected_json="$2"
  local mode="$3"

  if [ "$DRY_RUN" = true ]; then
    info "skip smoke check for $mode in dry-run mode"
    return 0
  fi

  node --input-type=module -e '
    import { Client } from "@modelcontextprotocol/sdk/client/index.js";
    import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

    const serverPath = process.argv[1];
    const expected = JSON.parse(process.argv[2]);
    const transport = new StdioClientTransport({
      command: process.execPath,
      args: [serverPath],
      cwd: process.cwd(),
      env: process.env,
      stderr: "pipe",
    });

    const client = new Client({ name: "jira-mcp-installer-smoke", version: "0.1.0" });
    await client.connect(transport);
    const tools = (await client.listTools()).tools.map((tool) => tool.name);
    await transport.close();

    if (JSON.stringify(tools) !== JSON.stringify(expected)) {
      console.error(JSON.stringify({ expected, actual: tools }, null, 2));
      process.exit(1);
    }

    console.log(JSON.stringify({ server: serverPath, tools }));
  ' "$server_path" "$expected_json"
  ok "$mode tool list verified"
}

hdr "Checking prerequisites"
require_cmd node "node"
require_cmd npm "npm"
collect_credentials
ok "repo root: $REPO_DIR"
ok "jira base URL: $JIRA_BASE_URL"
ok "confluence base URL: $CONFLUENCE_BASE_URL"

if [ "$CLIENT" = "claude" ] || [ "$CLIENT" = "both" ]; then
  require_cmd claude "claude"
fi

if [ "$CLIENT" = "codex" ] || [ "$CLIENT" = "both" ]; then
  require_cmd codex "codex"
fi

maybe_persist_credentials

hdr "Installing dependencies"
run_cmd npm install

hdr "Building"
run_cmd npm run build

hdr "Registering MCP servers"

if [ "$CLIENT" = "claude" ] || [ "$CLIENT" = "both" ]; then
  info "registering for Claude Code"
  remove_claude_server "jira-mcp"
  remove_claude_server "jira-min"
  remove_claude_server "confluence-min"
  remove_claude_server "reports-min"

  add_claude_stdio_server jira-mcp "$FULL_SERVER_PATH" \
    -e "JIRA_BASE_URL=$JIRA_BASE_URL" \
    -e "JIRA_EMAIL=$JIRA_EMAIL" \
    -e "JIRA_API_TOKEN=$JIRA_API_TOKEN" \
    -e "CONFLUENCE_BASE_URL=$CONFLUENCE_BASE_URL"

  add_claude_stdio_server jira-min "$JIRA_MIN_PATH" \
    -e "JIRA_BASE_URL=$JIRA_BASE_URL" \
    -e "JIRA_EMAIL=$JIRA_EMAIL" \
    -e "JIRA_API_TOKEN=$JIRA_API_TOKEN" \
    -e "CONFLUENCE_BASE_URL=$CONFLUENCE_BASE_URL"

  add_claude_stdio_server confluence-min "$CONFLUENCE_MIN_PATH" \
    -e "CONFLUENCE_BASE_URL=$CONFLUENCE_BASE_URL" \
    -e "ATLASSIAN_EMAIL=$JIRA_EMAIL" \
    -e "ATLASSIAN_API_TOKEN=$JIRA_API_TOKEN"

  add_claude_stdio_server reports-min "$REPORTS_MIN_PATH" \
    -e "JIRA_BASE_URL=$JIRA_BASE_URL" \
    -e "JIRA_EMAIL=$JIRA_EMAIL" \
    -e "JIRA_API_TOKEN=$JIRA_API_TOKEN" \
    -e "CONFLUENCE_BASE_URL=$CONFLUENCE_BASE_URL" \
    -e "ATLASSIAN_EMAIL=$JIRA_EMAIL" \
    -e "ATLASSIAN_API_TOKEN=$JIRA_API_TOKEN"

  if [ "$DRY_RUN" = false ]; then
    claude_mcp list
  fi
fi

if [ "$CLIENT" = "codex" ] || [ "$CLIENT" = "both" ]; then
  info "registering for Codex"
  remove_codex_server "jira-mcp"
  remove_codex_server "jira-min"
  remove_codex_server "confluence-min"
  remove_codex_server "reports-min"

  run_cmd codex mcp add jira-mcp \
    --env "JIRA_BASE_URL=$JIRA_BASE_URL" \
    --env "JIRA_EMAIL=$JIRA_EMAIL" \
    --env "JIRA_API_TOKEN=$JIRA_API_TOKEN" \
    --env "CONFLUENCE_BASE_URL=$CONFLUENCE_BASE_URL" \
    -- node "$FULL_SERVER_PATH"

  run_cmd codex mcp add jira-min \
    --env "JIRA_BASE_URL=$JIRA_BASE_URL" \
    --env "JIRA_EMAIL=$JIRA_EMAIL" \
    --env "JIRA_API_TOKEN=$JIRA_API_TOKEN" \
    --env "CONFLUENCE_BASE_URL=$CONFLUENCE_BASE_URL" \
    -- node "$JIRA_MIN_PATH"

  run_cmd codex mcp add confluence-min \
    --env "CONFLUENCE_BASE_URL=$CONFLUENCE_BASE_URL" \
    --env "ATLASSIAN_EMAIL=$JIRA_EMAIL" \
    --env "ATLASSIAN_API_TOKEN=$JIRA_API_TOKEN" \
    -- node "$CONFLUENCE_MIN_PATH"

  run_cmd codex mcp add reports-min \
    --env "JIRA_BASE_URL=$JIRA_BASE_URL" \
    --env "JIRA_EMAIL=$JIRA_EMAIL" \
    --env "JIRA_API_TOKEN=$JIRA_API_TOKEN" \
    --env "CONFLUENCE_BASE_URL=$CONFLUENCE_BASE_URL" \
    --env "ATLASSIAN_EMAIL=$JIRA_EMAIL" \
    --env "ATLASSIAN_API_TOKEN=$JIRA_API_TOKEN" \
    -- node "$REPORTS_MIN_PATH"

  if [ "$DRY_RUN" = false ]; then
    codex mcp list
  fi
fi

hdr "Offline smoke checks"
verify_tools "$FULL_SERVER_PATH" '["jira_list_issues","jira_list_projects","jira_get_issue","jira_issue_relationships","jira_get_changelog","confluence_get_page","jira_issue_confluence_links","confluence_page_jira_links","confluence_search_pages","jira_dependency_analysis","jira_find_similar_tickets"]' "full server"
verify_tools "$JIRA_MIN_PATH" '["jira_list_issues","jira_list_projects","jira_list_boards","jira_board_issues","jira_get_issue","jira_issue_relationships","jira_get_changelog","confluence_get_page","jira_issue_confluence_links","confluence_page_jira_links","jira_find_similar_tickets","jira_dependency_analysis"]' "jira-min"
verify_tools "$CONFLUENCE_MIN_PATH" '["confluence_search_pages"]' "confluence-min"
verify_tools "$REPORTS_MIN_PATH" '["ops_daily_brief","ops_shift_delta","ops_jira_review_radar"]' "reports-min"

echo ""
ok "jira-mcp install complete"
echo "  servers: jira-mcp, jira-min, confluence-min, reports-min"
echo "  Atlassian token URL: $TOKEN_URL"
echo "  if the MCPs do not appear immediately, restart Claude Code or Codex"
