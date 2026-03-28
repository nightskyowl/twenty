---
description: Check for upstream Twenty CRM updates, merge safely, and report what changed
---

You are syncing this fork (nightskyowl/twenty) with the upstream repo (twentyhq/twenty).
This project is HQ-CRM — a vertical CRM for Vietnamese industrial real estate built on Twenty.

IMPORTANT: Our customized files must NEVER be overwritten. Read `.gitattributes` to see which files are protected with `merge=ours`.

## Step 1: Check current state

Make sure the working tree is clean before doing anything.

```bash
git status --porcelain
```

If there are uncommitted changes, STOP and tell the user to commit or stash first.

## Step 2: Fetch upstream and check for updates

```bash
git fetch upstream
```
// turbo

Then compare our branch with upstream:

```bash
git log --oneline main..upstream/main | head -30
```

If there are no new commits, tell the user "Already up to date" and stop.

Otherwise, show the user how many new commits there are and a summary of what areas changed:

```bash
git diff --stat main..upstream/main
```

## Step 3: Analyze the update before merging

Before merging, check if any upstream changes touch files we care about:

```bash
git diff --name-only main..upstream/main | grep -E "^(CLAUDE\.md|AGENTS\.md|\.agent/|\.cursor/|\.vscode/|\.gitattributes|\.mcp\.json|scripts/)" || echo "No conflicts with our custom files"
```

Also check what packages were updated:

```bash
git diff --stat main..upstream/main -- packages/twenty-front packages/twenty-server packages/twenty-shared packages/twenty-ui
```

Report your findings to the user:
- How many commits behind we are
- Which packages have changes (twenty-front, twenty-server, twenty-shared, etc.)
- Whether any upstream changes touch our protected files (and that they will be auto-excluded)
- Any notable changes (new features, breaking changes, migrations) based on commit messages

## Step 4: Merge upstream safely

Configure the ours merge driver and run the merge:

```bash
git config merge.ours.driver true
```
// turbo

```bash
git merge upstream/main --no-edit
```

If the merge has conflicts:
1. Check if conflicts are in our protected files — resolve those by keeping ours: `git checkout --ours <file> && git add <file>`
2. Check if conflicts are in deleted files (.cursor/, .vscode/) — resolve by removing: `git rm <file>`
3. For any other conflicts, list them clearly and ask the user how to resolve

## Step 5: Clean up unwanted files

After merge, remove any files that should not exist in our fork:

```bash
if [ -d ".cursor" ]; then git rm -rf .cursor && echo "Removed .cursor/"; fi
if [ -d ".vscode" ]; then git rm -rf .vscode && echo "Removed .vscode/"; fi
```

If cleanup removed files, commit:

```bash
git diff --cached --quiet || git commit -m "chore(hq): clean up unwanted upstream files after merge"
```

## Step 6: Verify our custom files are intact

Confirm none of our files were overwritten:

```bash
echo "=== Checking CLAUDE.md ===" && head -5 CLAUDE.md
echo "=== Checking AGENTS.md ===" && head -5 AGENTS.md
echo "=== Checking .agent/rules/ ===" && ls .agent/rules/
echo "=== Checking .mcp.json ===" && head -3 .mcp.json
echo "=== Checking scripts/ ===" && ls scripts/
```

## Step 7: Check for new migrations

```bash
git diff --name-only main@{1}..HEAD -- "packages/twenty-server/src/database" | head -20
```

If new migrations exist, tell the user they may need to run:
```
npx nx database:reset twenty-server
```

## Step 8: Report to the user

Provide a clear summary:

1. **Commits merged:** how many
2. **Packages updated:** which ones and rough scope of changes
3. **Notable changes:** new features, breaking changes, new migrations, dependency updates
4. **How this improves our project:** what we get for free from upstream (bug fixes, new CRM features, performance improvements, etc.)
5. **Excluded/protected:** list any upstream changes to our custom files that were correctly ignored
6. **Action needed:** whether the user needs to run migrations, install dependencies (`yarn install`), or rebuild

End with:
```
Review the merge with: git log --oneline -10
Push when ready: git push origin main
```
