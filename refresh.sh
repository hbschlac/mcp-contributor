#!/usr/bin/env bash
# refresh.sh — detect drift in MCP source pages, find new pages in llms.txt,
# track coverage of gap-high pages, and lint sources.yml.
# Run manually or schedule weekly.
#
# Usage:
#   ./refresh.sh                # full audit
#   ./refresh.sh --quiet        # only print if drift/gap detected
#
# Outputs:
#   hashes.json        — current hash (content-only) of every covered URL
#   refresh-report.md  — human-readable drift + gap + coverage report
#
# Exit codes:
#   0  clean (no drift, no new pages, no lint errors)
#   1  drift, new pages, or high-priority gaps present
#   2  fetch error or lint error

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

QUIET=${1:-}
REPORT="refresh-report.md"
HASHES_NEW=$(mktemp)
HASHES_OLD="hashes.json"
DRIFT_COUNT=0
NEW_PAGE_COUNT=0
FETCH_ERRORS=0
LINT_ERRORS=0
GAP_HIGH_COUNT=0

have() { command -v "$1" >/dev/null 2>&1; }

# macOS shasum fallback
if ! have sha256sum; then
  if have shasum; then
    sha256sum() { shasum -a 256 "$@"; }
    export -f sha256sum
  else
    echo "missing sha256sum / shasum" >&2; exit 2
  fi
fi
for bin in curl yq; do
  have "$bin" || { echo "missing $bin — install via brew install $bin" >&2; exit 2; }
done

[[ -f sources.yml ]] || { echo "sources.yml not found" >&2; exit 2; }

# ───────── Hash normalization ─────────
# Strip volatile Mintlify/CDN garbage so hashes reflect real content.
# Remove: query-params in URLs (CDN tokens), timestamps, whitespace runs,
# script/style blocks, HTML comments.
normalize() {
  # $1 = raw html
  echo "$1" \
    | sed -E 's/\?[^"<> ]+//g' \
    | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.Z+-]+//g' \
    | sed -E 's/<script[^>]*>.*<\/script>//g' \
    | sed -E 's/<style[^>]*>.*<\/style>//g' \
    | sed -E 's/<!--[^>]*-->//g' \
    | tr -s '[:space:]' ' '
}

# ───────── Lint sources.yml ─────────
lint_errors=()
# Check for duplicate URLs
dup_urls=$(yq -r '.sources[].url' sources.yml | sort | uniq -d || true)
if [[ -n "$dup_urls" ]]; then
  while IFS= read -r u; do
    lint_errors+=("duplicate URL: $u")
    ((LINT_ERRORS+=1))
  done <<< "$dup_urls"
fi
# Check for unknown status values
valid_statuses="covered gap-high gap-med gap-low sep-ref gap-auth-required"
while IFS= read -r status; do
  [[ -z "$status" ]] && continue
  if ! grep -qw "$status" <<< "$valid_statuses"; then
    lint_errors+=("unknown status: $status")
    ((LINT_ERRORS+=1))
  fi
done < <(yq -r '.sources[].status' sources.yml | sort -u)

if (( LINT_ERRORS > 0 )); then
  printf 'lint error: %s\n' "${lint_errors[@]}" >&2
fi

# ───────── Anchor validation ─────────
# For each covered source, verify its anchor (§X.Y) substring exists in SKILL.md.
# Cheap check — catches silent heading renames.
anchor_misses=()
while IFS=$'\t' read -r url anchor; do
  [[ -z "$url" || -z "$anchor" ]] && continue
  # Extract "Step N.N.N" tokens (one per line) and verify each appears in a SKILL.md heading.
  # Use while+read so spaces inside matches (e.g. "Step 5.5.3") are preserved.
  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    if ! grep -Eq "^## ${ref}[: ]" SKILL.md 2>/dev/null; then
      anchor_misses+=("$ref (referenced by $url)")
    fi
  done < <(grep -oE 'Step [0-9]+(\.[0-9]+)*[a-z]?' <<< "$anchor")
done < <(yq -r '.sources[] | select(.status == "covered") | [.url, (.anchor // "")] | @tsv' sources.yml)

# ───────── Hash each covered URL ─────────
covered_urls=$(yq -r '.sources[] | select(.status == "covered") | .url' sources.yml)
echo "{" > "$HASHES_NEW"
first=1
drift_urls=()
while IFS= read -r url; do
  [[ -z "$url" ]] && continue
  raw=$(curl -fsSL --max-time 20 "$url" 2>/dev/null) || { ((FETCH_ERRORS+=1)); continue; }
  normalized=$(normalize "$raw")
  hash=$(printf '%s' "$normalized" | sha256sum | awk '{print $1}')
  [[ $first -eq 0 ]] && echo "," >> "$HASHES_NEW"
  printf '  "%s": "%s"' "$url" "$hash" >> "$HASHES_NEW"
  first=0

  if [[ -f "$HASHES_OLD" ]]; then
    old=$(yq -r ".\"$url\" // \"\"" "$HASHES_OLD" 2>/dev/null || echo "")
    if [[ -n "$old" && "$old" != "$hash" ]]; then
      drift_urls+=("$url")
      ((DRIFT_COUNT+=1))
    fi
  fi
done <<< "$covered_urls"
echo "" >> "$HASHES_NEW"
echo "}" >> "$HASHES_NEW"

# ───────── Coverage check — count gap-high ─────────
GAP_HIGH_COUNT=$(yq -r '.sources[] | select(.status == "gap-high") | .url' sources.yml | wc -l | tr -d ' ')
gap_high_urls=$(yq -r '.sources[] | select(.status == "gap-high") | .url' sources.yml)

# ───────── llms.txt new-page detection ─────────
new_pages=()
if remote_index=$(curl -fsSL --max-time 20 https://modelcontextprotocol.io/llms.txt 2>/dev/null); then
  remote_urls=$(echo "$remote_index" | grep -oE 'https://modelcontextprotocol\.io/[^ ]+\.md' | sed 's/\.md$//' | sort -u)
  known_urls=$(yq -r '.sources[].url' sources.yml | sort -u)
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    if ! grep -qxF "$url" <<< "$known_urls"; then
      new_pages+=("$url")
      ((NEW_PAGE_COUNT+=1))
    fi
  done <<< "$remote_urls"
fi

# ───────── Write report ─────────
{
  echo "# mcp-contributor refresh report"
  echo
  echo "Run: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo
  echo "## Summary"
  echo "- Drift on covered pages: **$DRIFT_COUNT**"
  echo "- New pages in llms.txt: **$NEW_PAGE_COUNT**"
  echo "- Gap-high pages (un-ingested, contributor-critical): **$GAP_HIGH_COUNT**"
  echo "- Fetch errors: **$FETCH_ERRORS**"
  echo "- sources.yml lint errors: **$LINT_ERRORS**"
  echo "- Anchor misses (SKILL.md heading drift): **${#anchor_misses[@]}**"
  echo

  if (( LINT_ERRORS > 0 )); then
    echo "## sources.yml lint errors"
    for e in "${lint_errors[@]}"; do echo "- $e"; done
    echo
  fi

  if (( DRIFT_COUNT > 0 )); then
    echo "## Content drift — covered pages that changed"
    for u in "${drift_urls[@]}"; do echo "- $u"; done
    echo
    echo "→ Re-ingest these pages. Update \`fetched\` dates in sources.yml."
    echo
  fi

  if (( NEW_PAGE_COUNT > 0 )); then
    echo "## New pages in llms.txt (not in sources.yml)"
    for u in "${new_pages[@]}"; do echo "- $u"; done
    echo
    echo "→ Triage: add to sources.yml as covered / gap-high / gap-med / gap-low / sep-ref."
    echo
  fi

  if (( GAP_HIGH_COUNT > 0 )); then
    echo "## Gap-high — ingest these next"
    while IFS= read -r u; do [[ -n "$u" ]] && echo "- $u"; done <<< "$gap_high_urls"
    echo
  fi

  if [[ ${#anchor_misses[@]} -gt 0 ]]; then
    echo "## Anchor misses — sources.yml references § that no longer exist in SKILL.md"
    for a in "${anchor_misses[@]}"; do echo "- $a"; done
    echo
    echo "→ Fix either the heading in SKILL.md or the anchor in sources.yml."
    echo
  fi

  if (( DRIFT_COUNT == 0 && NEW_PAGE_COUNT == 0 && FETCH_ERRORS == 0 && LINT_ERRORS == 0 && GAP_HIGH_COUNT == 0 && ${#anchor_misses[@]} == 0 )); then
    echo "## Clean run — no action needed."
  fi
} > "$REPORT"

# ───────── Promote new hashes ─────────
mv "$HASHES_NEW" "$HASHES_OLD"

# ───────── Output ─────────
if [[ "$QUIET" != "--quiet" ]] || (( DRIFT_COUNT > 0 || NEW_PAGE_COUNT > 0 || LINT_ERRORS > 0 || GAP_HIGH_COUNT > 0 || ${#anchor_misses[@]} > 0 )); then
  cat "$REPORT"
fi

if (( LINT_ERRORS > 0 )); then exit 2; fi
if (( DRIFT_COUNT > 0 || NEW_PAGE_COUNT > 0 || GAP_HIGH_COUNT > 0 || ${#anchor_misses[@]} > 0 )); then exit 1; fi
exit 0
