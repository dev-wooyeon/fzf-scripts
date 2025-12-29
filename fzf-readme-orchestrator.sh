#!/usr/bin/env bash
# ==============================================================================
# README Generator with fzf + Codex CLI
#
# 기능
#   - 지정된 workspace 아래의 git repository 자동 탐색
#   - fzf로 다중 repo 선택 (README 미리보기 포함)
#   - Codex용 README 프롬프트 생성
#   - 선택적으로 Codex 자동 실행
#
# 요구 사항
#   - bash 4+
#   - fzf
#   - codex (optional)
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

# Workspace root (우선순위: ENV > CLI arg > $HOME/workspace)
ROOT_DIR="${ROOT_DIR:-${1:-$HOME/workspace}}"

# Max depth to search for git repositories
MAX_DEPTH="${MAX_DEPTH:-4}"

# Script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Template for README generation
TEMPLATE_PATH="${TEMPLATE_PATH:-$SCRIPT_DIR/readme-template.md}"

# Codex-related paths (relative to repo root)
PROMPT_FILENAME="${PROMPT_FILENAME:-.codex/README.prompt.md}"
LOG_FILENAME="${LOG_FILENAME:-.codex/README.codex.log}"

# Codex behavior
AUTO_RUN_CODEX="${AUTO_RUN_CODEX:-1}"
CODEX_FLAGS="${CODEX_FLAGS:---full-auto}"

# ------------------------------------------------------------------------------
# Preconditions
# ------------------------------------------------------------------------------

command -v fzf >/dev/null 2>&1 || {
  echo "fzf not found on PATH."
  exit 1
}

[ -f "$TEMPLATE_PATH" ] || {
  echo "Template not found: $TEMPLATE_PATH"
  exit 1
}

[ -d "$ROOT_DIR" ] || {
  echo "Workspace not found: $ROOT_DIR"
  exit 1
}

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

run_codex() {
  local repo="$1"
  local prompt_path="$2"
  local log_path="$3"

  command -v codex >/dev/null 2>&1 || {
    echo "codex not found on PATH. Skipping: $repo"
    return
  }

  echo "Running Codex for: $repo"
  echo "Log: $log_path"

  (
    cd "$repo"
    mkdir -p "$(dirname "$log_path")"

    printf "\n--- codex run start (%s) ---\n" "$(date)" >> "$log_path"

    codex exec $CODEX_FLAGS - < "$prompt_path" \
      --output-last-message "$repo/README.md" \
      2>&1 | tee -a "$log_path"

    printf "\n--- codex run end (%s) ---\n" "$(date)" >> "$log_path"
  )
}

create_prompt() {
  local repo="$1"
  local prompt_path="$2"

  local prompt_dir
  prompt_dir="$(dirname "$prompt_path")"
  mkdir -p "$prompt_dir"

  local top_files
  top_files="$(find "$repo" -maxdepth 2 -type f \
    ! -path "*/.git/*" \
    | sed "s|^$repo/||" \
    | sort)"

  {
    echo "# README update task"
    echo
    echo "Repository: $repo"
    echo
    echo "Instructions:"
    echo "Update README.md using the template below."
    echo "Inspect the repository to fill in accurate details."
    echo "Do not invent facts. If unknown, write TBD."
    echo "Keep the output in Markdown."
    echo "If the current README.md is boilerplate or incorrect, overwrite it."
    echo "Write README.md to the repository root."
    echo "Respond with only the final README content."
    echo
    echo "Template:"
    echo '```markdown'
    cat "$TEMPLATE_PATH"
    echo '```'
    echo
    echo "Project files (depth <= 2):"
    echo "$top_files"
  } > "$prompt_path"
}

# ------------------------------------------------------------------------------
# Discover Git Repositories
# ------------------------------------------------------------------------------

repo_list="$(find "$ROOT_DIR" -maxdepth "$MAX_DEPTH" -type d -name .git -prune -print \
  | sed 's|/.git$||' \
  | sort)"

[ -n "$repo_list" ] || {
  echo "No git repositories found under: $ROOT_DIR"
  exit 0
}

# ------------------------------------------------------------------------------
# Select Repositories via fzf
# ------------------------------------------------------------------------------

selected_repos="$(
  printf '%s\n' "$repo_list" | fzf --multi --layout=reverse \
    --prompt="Select repositories > " \
    --preview '
      echo "== Repository ==";
      echo {};
      echo;
      if [ -f {}/README.md ]; then
        echo "== README.md (first 120 lines) ==";
        sed -n "1,120p" {}/README.md;
      else
        echo "README.md not found";
      fi;
      echo;
      echo "== Git Status ==";
      git -C {} status --short --branch 2>/dev/null || true
    '
)"

[ -n "$selected_repos" ] || {
  echo "No repositories selected."
  exit 0
}

# ------------------------------------------------------------------------------
# Main Loop
# ------------------------------------------------------------------------------

while IFS= read -r repo; do
  [ -z "$repo" ] && continue

  prompt_path="$repo/$PROMPT_FILENAME"
  log_path="$repo/$LOG_FILENAME"

  create_prompt "$repo" "$prompt_path"
  echo "Prompt created: $prompt_path"

  if [ "$AUTO_RUN_CODEX" = "1" ]; then
    run_codex "$repo" "$prompt_path" "$log_path"
  fi
done <<< "$selected_repos"

echo
echo "Done."
echo "Next step: review generated README.md files."
