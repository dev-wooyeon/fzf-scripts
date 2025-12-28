#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-/Users/eunwoo/workspace}"
MAX_DEPTH="${MAX_DEPTH:-4}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="${TEMPLATE_PATH:-$SCRIPT_DIR/readme-template.md}"
PROMPT_FILENAME="${PROMPT_FILENAME:-.codex/README.prompt.md}"
AUTO_RUN_CODEX="${AUTO_RUN_CODEX:-1}"
LOG_FILENAME="${LOG_FILENAME:-.codex/README.codex.log}"
CODEX_FLAGS="${CODEX_FLAGS:---full-auto}"

if ! command -v fzf >/dev/null 2>&1; then
  echo "fzf not found on PATH."
  exit 1
fi

if [ ! -f "$TEMPLATE_PATH" ]; then
  echo "Template not found: $TEMPLATE_PATH"
  exit 1
fi

repo_list="$(find "$ROOT_DIR" -maxdepth "$MAX_DEPTH" -type d -name .git -prune -print \
  | sed 's|/.git$||' \
  | sort)"

if [ -z "$repo_list" ]; then
  echo "No git repositories found under: $ROOT_DIR"
  exit 1
fi

selected_repos="$(printf '%s\n' "$repo_list" \
  | fzf --multi --prompt="Select repos > " --layout=reverse \
      --preview 'ls -la {} | head -200')"

if [ -z "$selected_repos" ]; then
  echo "No repositories selected."
  exit 0
fi

while IFS= read -r repo; do
  [ -z "$repo" ] && continue

  prompt_path="$repo/$PROMPT_FILENAME"
  log_path="$repo/$LOG_FILENAME"
  prompt_dir="$(dirname "$prompt_path")"
  mkdir -p "$prompt_dir"

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
    echo "- Update README.md using the template below."
    echo "- Inspect the repository to fill in accurate details."
    echo "- Do not invent facts. If unknown, write TBD."
    echo "- Keep the output in Markdown."
    echo "- If the current README.md is a default boilerplate or unrelated to the project,"
    echo "  overwrite it with a correct README."
    echo "- Write README.md in the repository."
    echo "- Respond with only the final README content and then exit."
    echo
    echo "Template:"
    echo '```markdown'
    cat "$TEMPLATE_PATH"
    echo '```'
    echo
    echo "Project files (top level and depth 2):"
    echo "$top_files"
  } > "$prompt_path"

  echo "Prompt created: $prompt_path"

  if [ "$AUTO_RUN_CODEX" = "1" ]; then
    if command -v codex >/dev/null 2>&1; then
      echo "Running Codex for: $repo"
      echo "Streaming log: $log_path"
      (cd "$repo" && \
        printf "\n--- codex run start ---\n" >> "$log_path" && \
        cat "$prompt_path" | codex exec $CODEX_FLAGS - \
          --output-last-message "$repo/README.md" \
          2>&1 | tee -a "$log_path" && \
        printf "\n--- codex run end ---\n" >> "$log_path")
    else
      echo "codex not found on PATH. Skipping automatic run."
    fi
  fi
done <<< "$selected_repos"

echo
echo "Next step:"
if [ "$AUTO_RUN_CODEX" = "1" ]; then
  echo "- Review the Codex output and confirm README.md changes."
else
  echo "- Open each repo with Codex/Cline and use the prompt file to update README.md."
fi
