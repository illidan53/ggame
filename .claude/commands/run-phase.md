You are executing an autonomous TDD development phase. The argument is a Phase identifier (e.g., "P0", "P1").

## Step 1: Read Phase Context

1. Read `docs/PLAN.md` to find the Phase section and its Tasks
2. Confirm the Phase is not already completed (has unchecked Tasks)
3. Read the corresponding test specification: `docs/tests/P{N}_*.md`
4. Read relevant sections of `docs/GDD.md` for game rules referenced by the test spec

## Step 2: Execute Each Task

For each unchecked Task in the Phase (in order):

### 2a. Plan (if task touches >3 files)
- Write implementation approach to `docs/SCRATCHPAD.md`
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

### 2d. Fix Loop (max 5 attempts)
If tests fail after implementation:
1. Read the test failure output carefully
2. Identify the root cause (logic error, wrong formula, missing case)
3. Fix the implementation (NOT the test)
4. Run `/test` again
5. Repeat up to 5 times total

If still failing after 5 attempts:
- Log the problem to `docs/SCRATCHPAD.md` with:
  - Which test(s) fail
  - Error messages
  - What you've tried
- STOP execution and report to the user

### 2e. Checkpoint
When ALL tests pass (including regression from previous phases):
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
- If a Task's scope is unclear, read GDD.md for clarification — do NOT guess
