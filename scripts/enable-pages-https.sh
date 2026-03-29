#!/usr/bin/env bash
# Enable GitHub Pages "Enforce HTTPS" via gh once the custom-domain cert exists.
# Usage: ./scripts/enable-pages-https.sh [owner/repo] [max_attempts] [sleep_seconds]
set -euo pipefail

REPO="${1:-InquiryInstitute/xapi}"
MAX="${2:-120}"
SLEEP="${3:-30}"

need_gh() {
  command -v gh >/dev/null 2>&1 || {
    echo "Install GitHub CLI: https://cli.github.com/" >&2
    exit 1
  }
  gh auth status >/dev/null 2>&1 || {
    echo "Run: gh auth login" >&2
    exit 1
  }
}

need_gh

for ((i = 1; i <= MAX; i++)); do
  err=$(gh api "repos/${REPO}/pages" -X PUT --input - <<< '{"https_enforced": true}' 2>&1) && {
    echo "HTTPS enforcement enabled for ${REPO}."
    gh api "repos/${REPO}/pages" --jq '{https_enforced, cname, html_url}'
    exit 0
  }
  if [[ "$err" == *"certificate does not exist"* ]]; then
    echo "[${i}/${MAX}] Certificate not ready yet; sleeping ${SLEEP}s..."
    sleep "$SLEEP"
  else
    echo "$err" >&2
    exit 1
  fi
done

echo "Timed out after $((MAX * SLEEP))s waiting for certificate." >&2
exit 1
