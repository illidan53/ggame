You are performing a checkpoint after a successful iteration. Follow these steps exactly:

## Step 1: Run all tests
Run the full test suite:
```
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```
If any test fails, STOP and report the failures. Do NOT proceed with the checkpoint.

## Step 2: Determine iteration info
- Read `docs/ITERATIONS.md` to find the last iteration number (e.g., I-003 → next is I-004)
- Identify: which Phase and Task was just completed, what files were changed, how many tests pass now
- Get today's date

## Step 3: Update ITERATIONS.md
Prepend a new entry at the top of `docs/ITERATIONS.md` (after the header, before existing entries):

```
## [I-{next_number}] P{phase}-T{task}: {short description} — {YYYY-MM-DD}
- **Phase**: P{N} (Task {M})
- **Changes**: {1-2 sentence summary of what was implemented}
- **Files**: {list of changed/new files}
- **Tests**: {X new tests added}, {Y/Z total passing}
- **Commit**: `{will be filled after commit}`

---
```

## Step 4: Update PLAN.md
Mark the completed task(s) as ✅ in `docs/PLAN.md`.

## Step 5: Git commit
Stage relevant files and commit (do NOT use `git add -A` blindly):
```
git add scripts/ tests/ resources/ scenes/ docs/ CLAUDE.md project.godot addons/ .gitignore .gutconfig.json .claudeignore
git commit -m "P{N}-T{M}: {short description}"
```
Note: Only stage files in the project directories. Review `git status` before committing to avoid including unintended files.
Commit message format: `P{phase}-T{task}: {imperative verb} {what}` (e.g., "P0-T3: implement damage calculation")

## Step 6: Update commit hash
After committing, get the commit hash with `git rev-parse --short HEAD` and update the `**Commit**` field in the ITERATIONS.md entry you just created.
Then amend the commit to include this update:
```
git add docs/ITERATIONS.md
git commit --amend --no-edit
```

## Step 7: Push (if remote configured)
Check if a remote exists: `git remote -v`
If remote exists: `git push origin main`
If no remote: skip and inform the user.

## Step 8: Report
Output a brief summary:
- Iteration number
- What was committed
- Test status
- Whether push succeeded
