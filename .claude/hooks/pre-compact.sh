#!/bin/bash
# PreCompact hook: Remind to preserve critical state before context compression
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
WARN=""
if [[ "$DIRTY" -gt 0 ]]; then
  WARN=" WARNING: ${DIRTY} uncommitted file(s)."
fi

python3 -c "
import json
msg = 'BEFORE COMPACTING: Preserve current phase/task, active errors from SCRATCHPAD, key decisions, modified files.${WARN}'
print(json.dumps({'systemMessage': msg}))
"
