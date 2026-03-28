# Fork Safety

This repo is a fork of twentyhq/twenty. Every change must preserve upstream merge compatibility.

## Rules

- Do NOT modify core Twenty files unless absolutely necessary
- Prefer custom objects created via Twenty's UI/API over code changes
- When code changes are unavoidable, isolate them in separate files/modules clearly marked as HQ-specific
- Never rename, move, or delete upstream files
- Never rewrite or delete committed migrations
- Always check if a utility already exists in `twenty-shared` before creating a new one
- Test that `git merge upstream/main` would not conflict with your changes when possible

## If You Must Modify a Core File

1. Keep the diff minimal
2. Add a comment: `// HQ-CRM: [reason]` near the change
3. Prefer additive changes (new cases, new imports) over modifying existing logic
