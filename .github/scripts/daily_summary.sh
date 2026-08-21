#!/usr/bin/env bash
#
# Collects commits made across all branches in the given time window,
# asks a local Ollama Gemma model to write a human-readable digest, and
# writes the result to summary_body.txt for the email step to send.
#
# Falls back to a plain (non-AI) digest of the raw git log if Ollama is
# unreachable or returns an empty response, so the daily email still goes
# out even when the model call fails.

set -euo pipefail

SINCE="${SINCE:-24 hours ago}"
MODEL="${OLLAMA_MODEL:-gemma2:9b}"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
REPO_NAME="${GITHUB_REPOSITORY:-$(basename "$(pwd)")}"

git fetch --all --prune --quiet || true

LOG=$(git log --all --no-merges --since="${SINCE}" \
  --date=format:'%Y-%m-%d %H:%M' \
  --pretty=format:'---%nCommit: %h%nAuthor: %an%nDate: %ad%nRefs: %D%nMessage: %s%n%b' || true)

if [ -z "$(echo "${LOG}" | tr -d '[:space:]')" ]; then
  echo "No commits or pushes were made to ${REPO_NAME} in the last window (${SINCE})." > summary_body.txt
  echo "No commits found for window: ${SINCE}"
  exit 0
fi

COMMIT_COUNT=$(git log --all --no-merges --since="${SINCE}" --pretty=format:'%h' | wc -l | tr -d ' ')
AUTHORS=$(git log --all --no-merges --since="${SINCE}" --pretty=format:'%an' | sort -u | paste -sd, -)

PROMPT_FILE=$(mktemp)
cat > "${PROMPT_FILE}" <<EOF
You are a helpful engineering assistant. Write a concise, well-organized daily
digest EMAIL BODY (plain text only — no markdown symbols like # or **) that
summarizes the git activity below for the repository "${REPO_NAME}" over the
window "${SINCE}".

Structure it as:
1. A short paragraph giving the high-level picture of what changed and why it
   likely matters.
2. A bulleted list (use "-" for bullets) grouping related commits by
   feature/area, mentioning the author for each.
3. A separate short section calling out anything that looks like a bug fix,
   breaking change, revert, or something that should get extra review.
4. A closing line stating the total commit count (${COMMIT_COUNT}) and the
   contributors (${AUTHORS}).

Only state facts that are grounded in the commit data below — do not invent
details that aren't present in it.

Raw git log (author / date / branch refs / commit message) for the window:
${LOG}
EOF

PROMPT_TEXT=$(cat "${PROMPT_FILE}")

REQUEST_JSON=$(jq -n --arg model "${MODEL}" --arg prompt "${PROMPT_TEXT}" \
  '{model: $model, prompt: $prompt, stream: false}')

set +e
RESPONSE=$(curl -s -m 120 -X POST "${OLLAMA_URL}/api/generate" \
  -H 'Content-Type: application/json' \
  -d "${REQUEST_JSON}")
CURL_EXIT=$?
set -e

AI_TEXT=""
if [ "${CURL_EXIT}" -eq 0 ] && [ -n "${RESPONSE}" ]; then
  AI_TEXT=$(echo "${RESPONSE}" | jq -r '.response // empty' 2>/dev/null || true)
fi

if [ -z "${AI_TEXT}" ]; then
  echo "Ollama summarization failed or returned an empty response; sending raw log instead." >&2
  {
    echo "AI summarization was unavailable, so here is the raw activity for ${REPO_NAME} (window: ${SINCE}):"
    echo ""
    echo "${LOG}"
    echo ""
    echo "Total commits: ${COMMIT_COUNT}"
    echo "Contributors: ${AUTHORS}"
  } > summary_body.txt
else
  echo "${AI_TEXT}" > summary_body.txt
fi

rm -f "${PROMPT_FILE}"
