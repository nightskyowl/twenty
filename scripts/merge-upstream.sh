#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# HQ-CRM: Merge upstream twentyhq/twenty safely
#
# This script:
# 1. Configures the "ours" merge driver (keeps our version)
# 2. Fetches upstream
# 3. Merges upstream/main into current branch
# 4. Cleans up files we don't want
# 5. Commits the merge
#
# Usage:
#   bash scripts/merge-upstream.sh          # merge latest upstream/main
#   bash scripts/merge-upstream.sh v0.40.0  # merge a specific tag
# ============================================================

UPSTREAM_REF="${1:-upstream/main}"

echo "=== HQ-CRM Upstream Merge ==="
echo "Merging: $UPSTREAM_REF"
echo ""

# --- Step 0: Ensure clean working tree ---
if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: Working tree is dirty. Commit or stash changes first."
  exit 1
fi

# --- Step 1: Configure the 'ours' merge driver ---
# This makes .gitattributes merge=ours actually work.
# It tells git: "to merge this file, just keep ours unchanged."
git config merge.ours.driver true
echo "Configured merge.ours driver"

# --- Step 2: Fetch upstream ---
if ! git remote get-url upstream &>/dev/null; then
  echo "Adding upstream remote..."
  git remote add upstream https://github.com/twentyhq/twenty.git
fi

echo "Fetching upstream..."
git fetch upstream

# --- Step 3: Merge ---
echo ""
echo "Merging $UPSTREAM_REF ..."
echo "Files marked 'merge=ours' in .gitattributes will keep our version automatically."
echo ""

if ! git merge "$UPSTREAM_REF" --no-edit; then
  echo ""
  echo "=== Merge conflicts detected ==="
  echo ""
  echo "Conflicts in files we own (auto-resolving to ours):"

  # Auto-resolve conflicts in files we explicitly own
  OUR_FILES=(
    "CLAUDE.md"
    "AGENTS.md"
    ".gitattributes"
    ".mcp.json"
  )

  for f in "${OUR_FILES[@]}"; do
    if git diff --name-only --diff-filter=U | grep -q "^${f}$"; then
      echo "  -> $f (keeping ours)"
      git checkout --ours "$f"
      git add "$f"
    fi
  done

  # Auto-resolve .agent/ directory
  git diff --name-only --diff-filter=U | grep "^\.agent/" | while read -r f; do
    echo "  -> $f (keeping ours)"
    git checkout --ours "$f"
    git add "$f"
  done

  # Auto-resolve deleted dirs we don't want
  DELETED_DIRS=(".cursor" ".vscode")
  for dir in "${DELETED_DIRS[@]}"; do
    git diff --name-only --diff-filter=U | grep "^${dir}/" | while read -r f; do
      echo "  -> $f (removing)"
      git rm -f "$f" 2>/dev/null || true
      git add "$f" 2>/dev/null || true
    done
  done

  # Check if there are remaining conflicts
  REMAINING=$(git diff --name-only --diff-filter=U 2>/dev/null || true)
  if [ -n "$REMAINING" ]; then
    echo ""
    echo "=== Remaining conflicts (need manual resolution) ==="
    echo "$REMAINING"
    echo ""
    echo "Resolve these manually, then run:"
    echo "  git add <resolved-files>"
    echo "  git commit"
    exit 1
  fi
fi

# --- Step 4: Clean up files we don't want ---
CLEANUP_DIRS=(".cursor" ".vscode")
CHANGED=false

for dir in "${CLEANUP_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    echo "Removing $dir/ (not needed in our fork)"
    git rm -rf "$dir" 2>/dev/null || true
    CHANGED=true
  fi
done

# --- Step 5: Finalize ---
if [ "$CHANGED" = true ]; then
  # Amend the merge commit to include cleanup, or create separate commit
  if git diff --cached --quiet; then
    echo "No additional cleanup needed."
  else
    git commit -m "chore(hq): clean up unwanted upstream files after merge"
  fi
fi

echo ""
echo "=== Merge complete ==="
echo ""
git log --oneline -3
echo ""
echo "Review the merge, then push when ready:"
echo "  git push origin main"
