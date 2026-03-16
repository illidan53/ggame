You are executing an autonomous TDD development phase. The argument is a Phase identifier (e.g., "P0", "P1").

## Step 0: Resume Check

1. Read `docs/SCRATCHPAD.md`
2. If there is an **Active Error Log** for the current Phase/Task:
   - This means a previous session was interrupted or stopped
   - Resume from that Task, taking the error history into account
   - Do NOT repeat fixes that already failed (listed in the error log)
3. If there is a **STOPPED** entry: report to the user and wait for guidance before continuing

## Step 1: Read Phase Context

1. Read `docs/PLAN.md` to find the Phase section and its Tasks
2. Confirm the Phase is not already completed (has unchecked Tasks)
3. Read the corresponding test specification: `docs/tests/P{N}_*.md`
4. Read relevant sections of `docs/GDD.md` for game rules referenced by the test spec

## Step 2: Execute Each Task

For each unchecked Task in the Phase (in order):

### 2a. Plan (if task touches >3 files)
- Write implementation approach to `docs/SCRATCHPAD.md` under `## Implementation Plan: P{N}-T{M}`
- Identify which test cases from the spec map to this Task

### 2b. Write Tests (RED)
- Create or update test file(s) in `tests/` following the naming convention in CLAUDE.md
- Each test case from the spec becomes a test function
- Run `/test` to confirm the new tests FAIL (RED state)
- If tests already pass without implementation, investigate — something may be wrong

### 2c. Implement (GREEN)
- Write the minimal implementation to make the tests pass
- Follow all coding conventions in CLAUDE.md:
  - Pure functions in `scripts/core/` (no Node dependencies)
  - Resource definitions in `resources/`
  - snake_case files, PascalCase classes
- Run `/test` after implementation

### 2d. Fix Loop (smart retry)
If tests fail after implementation:

1. Read the test failure output carefully
2. Identify the root cause (logic error, wrong formula, missing case)
3. **Log the attempt** to `docs/SCRATCHPAD.md` under `## Active Error Log: P{N}-T{M}`:
   ```
   ### Attempt {X} — {YYYY-MM-DD}
   - **Failing test**: {test function name}
   - **Error**: {actual vs expected, or error message}
   - **Fix tried**: {1-sentence description of what you changed}
   ```
4. Fix the implementation (NOT the test)
5. Run `/test` again

**Stop condition — repeated same failure:**
- After each failure, read the Active Error Log in SCRATCHPAD.md
- If the **same test** has failed with the **same error message** for **3 consecutive attempts**:
  - Add a `### STOPPED — {YYYY-MM-DD}` entry with a summary of what was tried
  - STOP execution and report to the user
  - Do NOT continue to the next Task

**Continue condition:**
- If the error is DIFFERENT from the previous attempt (different test, or different error message), the retry counter resets — this indicates progress
- There is NO fixed retry limit as long as errors keep changing

### 2e. On Success — Clear Error Log
When ALL tests pass (including regression from previous phases):
- Remove the `## Active Error Log: P{N}-T{M}` section from `docs/SCRATCHPAD.md`
- Remove any `## Implementation Plan: P{N}-T{M}` section from `docs/SCRATCHPAD.md`
- Execute `/checkpoint` to record the iteration, commit, and push

## Step 3: Phase Complete

After all Tasks in the Phase are done:
1. Verify all Phase tests pass one final time via `/test`
2. Report completion summary:
   - Phase name
   - Number of Tasks completed
   - Total tests passing
   - List of commits made

## Critical Rules

- NEVER skip writing tests before implementation
- NEVER modify test expectations to make tests pass
- NEVER proceed to the next Task if current Task's tests are failing
- ALWAYS run full regression (all phases' tests) before checkpoint
- ALWAYS log failures to SCRATCHPAD.md before attempting a fix
- ALWAYS read SCRATCHPAD.md error history before each retry to avoid repeating failed approaches
- If a Task's scope is unclear, read GDD.md for clarification — do NOT guess
