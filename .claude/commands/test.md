Run the full GUT test suite and report results.

## Step 1: Execute Tests

Run the test command:
```bash
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

If the `addons/gut/` directory does not exist, report that GUT is not installed and stop.

## Step 2: Parse Output

From the test output, extract:
- Total tests run
- Tests passed
- Tests failed
- For each failure: test name, file, line number, error message

## Step 3: Report

Output a structured summary:

```
Test Results: {passed}/{total} passed, {failed} failed

✅ Passing: {list of passing test files}

❌ Failing:
  - test_name (file:line): error message
  - ...
```

If all tests pass, output:
```
Test Results: {total}/{total} passed ✅ ALL GREEN
```

## Notes
- Do NOT modify any code based on test results — just report
- If the command fails to run (godot not found, etc.), report the error
- Timeout: allow up to 120 seconds for test execution
