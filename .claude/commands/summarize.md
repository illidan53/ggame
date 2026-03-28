You are generating a concise summary of the current codebase capabilities. Focus on what the game CAN DO right now, not what's planned.

## Step 1: Gather Context

1. Read `docs/PLAN.md` to see which phases/tasks are complete (✅)
2. Read `docs/ITERATIONS.md` (first 30 lines) for recent activity
3. List files in `scripts/core/` to see implemented systems
4. List files in `resources/cards/` and `resources/enemies/` for game content
5. List files in `scenes/` for playable scenes
6. Run `git log --oneline -10` for recent commit context

## Step 2: Write Summary

Output the summary directly in conversation using this structure:

```
# DarkPath — Current Capabilities

## Playable Features
{What a player can actually DO right now when they run the game}

## Core Systems (implemented + tested)
{Bullet list of working game systems, grouped logically}

## Game Content
{Cards, enemies, and other data assets that exist}

## What's NOT Yet Implemented
{Brief list of planned but missing features, by phase}

## Phase Completion
{Table from PLAN.md Phase Overview showing each phase with its status}
| Phase | Scope | Status |
|-------|-------|--------|
| P0 | ... | ✅ or ⬜ |

## Stats
- Tests: {X passing}
- Scripts: {Y core logic files}
```

## Rules
- Be concise — 1-2 sentences per bullet max
- Lead with player-facing features, not implementation details
- Group related systems together
- Don't list individual test names or function signatures
- Don't read implementation code — use file names and PLAN.md status to infer capabilities
