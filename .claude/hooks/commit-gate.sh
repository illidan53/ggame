#!/bin/bash
# PreToolUse hook: Block git commit if tests are failing

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)

# Only gate actual git commits
if [[ "$COMMAND" != git\ commit* ]]; then
  exit 0
fi

# Run tests
RESULT=$(/opt/homebrew/bin/godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit 2>&1)
FAIL_COUNT=$(echo "$RESULT" | grep -o "Failing Tests *[0-9]*" | grep -o "[0-9]*")

if [[ -n "$FAIL_COUNT" && "$FAIL_COUNT" -gt 0 ]]; then
  python3 -c "import json; print(json.dumps({'hookSpecificOutput':{'hookEventName':'PreToolUse','permissionDecision':'deny','permissionDecisionReason':'COMMIT BLOCKED: ${FAIL_COUNT} tests failing.'}}))"
else
  python3 -c "import json; print(json.dumps({'hookSpecificOutput':{'hookEventName':'PreToolUse','permissionDecision':'allow','permissionDecisionReason':'All tests passing.'}}))"
fi
