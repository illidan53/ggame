#!/bin/bash
# SessionStart hook: Inject current project status into conversation context
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

CONTEXT=""

# Current phase status
if [[ -f docs/PLAN.md ]]; then
  PHASES=$(grep -E '^\| P[0-9]' docs/PLAN.md | head -10)
  CONTEXT+="PHASE STATUS:\n${PHASES}\n\n"
fi

# Active errors from SCRATCHPAD
if [[ -f docs/SCRATCHPAD.md ]]; then
  ERRORS=$(sed -n '/^## Active Error Log/,/^---/p' docs/SCRATCHPAD.md 2>/dev/null | grep -v "TEMPLATE" | grep -v "^<!--")
  if [[ -n "$ERRORS" ]]; then
    CONTEXT+="ACTIVE ERRORS:\n${ERRORS}\n\n"
  fi
fi

# Last 3 iterations
if [[ -f docs/ITERATIONS.md ]]; then
  RECENT=$(grep -A3 "^\## \[I-" docs/ITERATIONS.md | head -12)
  CONTEXT+="RECENT ITERATIONS:\n${RECENT}\n\n"
fi

# Uncommitted changes
DIRTY=$(git status --porcelain 2>/dev/null | head -5)
if [[ -n "$DIRTY" ]]; then
  CONTEXT+="UNCOMMITTED CHANGES:\n${DIRTY}\n"
fi

if [[ -n "$CONTEXT" ]]; then
  python3 -c "
import json, sys
ctx = '''$(echo -e "$CONTEXT")'''
print(json.dumps({'hookSpecificOutput':{'hookEventName':'SessionStart','additionalContext':ctx}}))
"
fi
