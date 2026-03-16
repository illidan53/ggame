You are performing a quick commit for non-phase changes. The optional argument is a custom commit message. Follow these steps exactly:

## Step 1: Review changes

Run `git status` and `git diff --stat` to understand what changed.
Then run `git diff` (including staged and unstaged) to read the actual content.

If there are no changes to commit, report "Nothing to commit" and STOP.

## Step 2: Generate commit message

If the user provided a custom message as argument, use that directly.

Otherwise, analyze the diff and generate a message in conventional commit format:
- `docs: ...` — documentation changes
- `chore: ...` — config, tooling, gitignore, etc.
- `feat: ...` — new feature code
- `fix: ...` — bug fix
- `refactor: ...` — code restructuring
- `test: ...` — test additions/changes
- `style: ...` — formatting only

Message rules:
- Imperative mood ("add", not "added")
- Max 72 characters for the first line
- No period at the end
- If multiple types of changes, use the dominant one

## Step 3: Stage files

Review `git status` output carefully. Stage files selectively:
```
git add <specific files>
```

NEVER use `git add -A` or `git add .`.
NEVER stage files matching: `.env*`, `*credentials*`, `*secret*`, `*.key`, `*.pem`.
Skip `.claude/plans/`, `.claude/settings.local.json`.

## Step 4: Commit

```
git commit -m "<generated or user-provided message>"
```

## Step 5: Push

Check if remote exists: `git remote -v`
If remote exists: `git push origin main`
If no remote: skip and inform the user.

## Step 6: Report

Output:
- Commit message used
- Files committed (list)
- Commit hash (`git rev-parse --short HEAD`)
- Push status (success / skipped / failed)
