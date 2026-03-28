---
description: One-click upstream sync — merges twentyhq/twenty updates, protects our files, pushes, and reports what changed
---

You are syncing this fork (nightskyowl/twenty) with upstream (twentyhq/twenty).
This project is HQ-CRM — a vertical CRM for Vietnamese industrial real estate built on Twenty.

IMPORTANT: This workflow is FULLY AUTONOMOUS. Do NOT pause for approval, do NOT ask the user questions mid-process, do NOT show intermediate results. Run everything silently and only speak to the user ONCE at the very end with a summary.

IMPORTANT: Our customized files must NEVER be overwritten. `.gitattributes` protects them with `merge=ours`.

## Step 1: Pre-flight checks

```bash
# Ensure clean working tree
if [ -n "$(git status --porcelain)" ]; then
  echo "DIRTY"
else
  echo "CLEAN"
fi
```
// turbo

If DIRTY, tell the user: "Working tree has uncommitted changes. Please commit or stash first, then re-run /sync-upstream." and STOP. Do not continue.

If CLEAN, continue silently.

## Step 2: Fetch and check for updates

```bash
# Ensure upstream remote exists
git remote get-url upstream &>/dev/null || git remote add upstream https://github.com/twentyhq/twenty.git

# Fetch upstream
git fetch upstream

# Count new commits
BEHIND=$(git rev-list --count HEAD..upstream/main)
echo "BEHIND=$BEHIND"
```
// turbo

If BEHIND=0, tell the user: "Already up to date with upstream. No changes to merge." and STOP.

If BEHIND>0, continue silently. Save the count for the final report.

## Step 3: Capture pre-merge state for reporting

```bash
# Save commit count
echo "=== NEW COMMITS ==="
git log --oneline HEAD..upstream/main

echo ""
echo "=== PACKAGES CHANGED ==="
git diff --stat HEAD..upstream/main -- packages/twenty-front packages/twenty-server packages/twenty-shared packages/twenty-ui packages/twenty-emails 2>/dev/null

echo ""
echo "=== NOTABLE AREAS ==="
git diff --name-only HEAD..upstream/main | grep -cE "^packages/twenty-server/src/database" || echo "0"
echo " migration files"

git diff --name-only HEAD..upstream/main | grep -cE "^packages/twenty-front/" || echo "0"
echo " frontend files"

git diff --name-only HEAD..upstream/main | grep -cE "^packages/twenty-server/" || echo "0"
echo " server files"
```
// turbo

Save this output for the final report. Do NOT show it to the user yet. Continue silently.

## Step 4: Merge upstream

```bash
# Configure ours merge driver (makes .gitattributes merge=ours work)
git config merge.ours.driver true

# Merge
git merge upstream/main --no-edit
```
// turbo

If the merge succeeds cleanly, continue to Step 5.

If there are conflicts, resolve them automatically:

```bash
# Auto-resolve: files we own → keep ours
for f in CLAUDE.md AGENTS.md .gitattributes .mcp.json; do
  if git diff --name-only --diff-filter=U | grep -q "^${f}$"; then
    git checkout --ours "$f" && git add "$f"
  fi
done

# Auto-resolve: .agent/ directory → keep ours
git diff --name-only --diff-filter=U | grep "^\.agent/" | while read -r f; do
  git checkout --ours "$f" && git add "$f"
done

# Auto-resolve: directories we deleted → remove
for dir in .cursor .vscode; do
  git diff --name-only --diff-filter=U | grep "^${dir}/" | while read -r f; do
    git rm -f "$f" 2>/dev/null || true
  done
done

# Check for remaining conflicts
REMAINING=$(git diff --name-only --diff-filter=U 2>/dev/null)
if [ -n "$REMAINING" ]; then
  echo "UNRESOLVED"
  echo "$REMAINING"
else
  echo "ALL_RESOLVED"
  git commit --no-edit 2>/dev/null || true
fi
```
// turbo

If UNRESOLVED: tell the user which files have conflicts and STOP. Do not push.
If ALL_RESOLVED: continue silently.

## Step 5: Post-merge cleanup

```bash
# Remove directories that should not exist in our fork
CHANGED=false
for dir in .cursor .vscode; do
  if [ -d "$dir" ]; then
    git rm -rf "$dir" 2>/dev/null || true
    CHANGED=true
  fi
done

if [ "$CHANGED" = true ] && ! git diff --cached --quiet; then
  git commit -m "chore(hq): clean up unwanted upstream files after merge"
fi

echo "CLEANUP_DONE"
```
// turbo

## Step 6: Verify protected files

```bash
echo "=== CLAUDE.md ===" && head -1 CLAUDE.md
echo "=== AGENTS.md ===" && head -1 AGENTS.md
echo "=== .agent/rules/ ===" && ls .agent/rules/
echo "=== .gitattributes ===" && head -1 .gitattributes
echo "=== .mcp.json ===" && head -1 .mcp.json
```
// turbo

If any file is missing or shows upstream content instead of ours, STOP and alert the user. Otherwise continue silently.

## Step 7: Push to origin

```bash
git push origin main
```
// turbo

## Step 8: Final report

Now — and ONLY now — speak to the user. Provide a single, clear summary:

```
✅ Upstream sync complete

Commits merged: [number]
Packages updated: [list which ones changed and rough scope]
Notable changes: [new features, bug fixes, breaking changes, dependency bumps — based on commit messages]
New migrations: [yes/no — if yes, remind user to run: npx nx database:reset twenty-server]
Protected files: All intact (CLAUDE.md, AGENTS.md, .agent/, .gitattributes, .mcp.json)
Cleaned up: [.cursor/.vscode removed, or "nothing to clean"]
Pushed to: origin/main ✓

If dependency changes were included, run: yarn install
If new migrations exist, run: npx nx database:reset twenty-server
```

Do NOT add any other commentary. Do NOT ask follow-up questions. The sync is done.
