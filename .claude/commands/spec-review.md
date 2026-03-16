You are performing a specification consistency review. The optional argument is a Phase identifier (e.g., "P0", "P3"). If no argument is given, review ALL phases.

## Step 1: Collect Documents

Read ALL of the following files:
- `docs/GDD.md`
- `docs/PLAN.md`
- `CLAUDE.md`

If a specific Phase was given as argument (e.g., "P0"):
- Read only the corresponding test spec: `docs/tests/P{N}_*.md`
- For P4, also read `docs/tests/P4_balance_tests.md`

If no argument was given:
- Read ALL test spec files in `docs/tests/`

If `scripts/core/` or `resources/` directories contain `.gd` or `.tres` files, read those too (for Check 5).

## Step 2: Execute 5 Checks

### Check 1: GDD ↔ Test Spec Value Consistency

Extract every concrete numeric value from GDD and cross-reference with the corresponding test spec's Expected Result column.

Focus areas (GDD Section → Test file):

| Category | GDD Section | Test File |
|----------|------------|-----------|
| Card damage/block/cost | 5.2, 5.3 | P0 |
| Status effect multipliers | 4.3 | P0 T3 |
| Enemy HP, damage, AI patterns | 8.1, 8.2, 8.3 | P0 T6, P4 |
| Relic effects | 6 | P3 T1-T2 |
| Potion effects | 7 | P3 T3 |
| Economy (gold, prices) | 4.6, 10 | P2 T1-T3 |
| Rest site heal % | 3.4 | P2 T4 |
| Boss phase thresholds | 8.3 | P4 T1 |
| Event rewards/penalties | 9 | P3 T4 |

For each value found in BOTH GDD and a test spec:
- If they match: no action needed
- If they differ: flag as **Critical** with exact locations and both values

### Check 2: Test Coverage Completeness

For each rule/mechanic defined in GDD:
1. Identify whether at least one test case covers it
2. Flag GDD rules with **no test coverage** (severity: Warning)
3. Flag test cases that reference behavior NOT defined in GDD (severity: Warning)

Pay special attention to:
- Keywords (Exhaust, Innate, Ethereal) — are they tested?
- Edge cases mentioned in GDD but missing from tests
- New GDD sections added since last review

### Check 3: PLAN.md ↔ Test Spec Alignment

1. For each Task row in PLAN.md, check the "Test Coverage" column
2. Verify those test IDs actually exist in the corresponding test spec file
3. Flag orphan tests (exist in spec but not referenced by any Task)
4. Check Phase status markers (⬜/✅) match actual completion state (compare with `docs/ITERATIONS.md`)

### Check 4: Terminology & Formula Consistency

1. **Damage formula**: Verify GDD's formula matches test expectations
   - Order of operations: `(base + strength)`, then Weak modifier, then Vulnerable modifier
   - Rounding: floor for damage, ceil for healing — is this consistent?
2. **Naming**: Are entity names identical across GDD and test specs?
   - Card names (Strike, Defend, Bash, etc.)
   - Enemy names (Slime, Goblin, etc.)
   - Relic/Potion names
3. **Constants**: Player max HP (80), energy per turn (3), cards drawn (5), starting deck composition

### Check 5: Code ↔ Docs Consistency (conditional)

Only execute if implementation code exists:

1. Check `scripts/core/` for `.gd` files — extract hardcoded values and compare to GDD
2. Check `resources/` for `.tres` files — extract exported values and compare to GDD
3. If NO code files exist yet, report: "⏭️ SKIPPED — No implementation code found"

## Step 3: Generate Report

Output the report directly in the conversation (do NOT write to a file). Use this format:

```
# Spec Review Report — {YYYY-MM-DD}

## Summary
- Checks passed: X/5
- Issues found: Y (Critical: A, Warning: B, Info: C)

## Check 1: GDD ↔ Test Values — {✅ or ⚠️ or ❌}

{If issues found, list each as:}
- ❌ **{Category}**: GDD Sec {X} says `{value}`, but test {TestID} expects `{other_value}`
  - Fix: Update {file} to match GDD

{If all match:}
- All values consistent ✅

## Check 2: Test Coverage Gaps — {✅ or ⚠️}

{If gaps found:}
- ⚠️ GDD Sec {X} rule "{rule}" has no test coverage
- ⚠️ Test {TestID} references behavior not in GDD

## Check 3: PLAN ↔ Test Alignment — {✅ or ⚠️}

{If mismatches:}
- ⚠️ Task {N.M} references {TestID} but it doesn't exist in test spec
- ⚠️ Test {TestID} is orphaned (not referenced by any Task)

## Check 4: Terminology & Formulas — {✅ or ⚠️}

{If inconsistencies:}
- ⚠️ {description of mismatch}

## Check 5: Code ↔ Docs — {✅ or ⏭️ SKIPPED}

{If code exists and mismatches found:}
- ❌ {file}:{line} has `{value}`, GDD says `{expected}`

## Recommended Actions
1. {highest priority fix — what file to change and how}
2. ...
```

## Step 4: Severity Rules

- **Critical** (❌): Numeric value conflict between GDD and test spec or code. Must fix before `/run-phase`.
- **Warning** (⚠️): Missing coverage, orphan tests, naming inconsistency. Should fix but won't break automation.
- **Info** (ℹ️): Style/format suggestions. Optional.

Authority for fixes (per CLAUDE.md Data Value Authority):
1. `docs/GDD.md` — highest authority, do NOT change unless user approves
2. `docs/tests/P{N}_*.md` — update to match GDD
3. Resource `.tres` files — update to match GDD

## Critical Rules

- This skill is **READ-ONLY**. Do NOT modify any files.
- Do NOT skip any of the 5 checks (mark as SKIPPED if not applicable).
- Use `date` command to get the current date for the report header.
- If the report is very long, prioritize Critical issues at the top.
- Get today's date via shell command, do NOT hardcode it.
