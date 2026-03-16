# DarkPath — Project Instructions

## Key Documents
- `docs/GDD.md` — Game design rules. Read relevant sections before implementing any feature.
- `docs/PLAN.md` — Phased development plan with TDD workflow. Update task status after completion.
- `docs/tests/P{N}_*.md` — Test specifications per phase. These define WHAT to test (not HOW).
- `docs/SCRATCHPAD.md` — Plan complex tasks here before coding (>3 files).
- `docs/ITERATIONS.md` — Iteration log. Updated by `/checkpoint`.

## Execution Modes

### Autonomous Mode (`/run-phase`)
When triggered by `/run-phase P{N}`:
- Skip approval steps — execute directly per PLAN.md
- Follow TDD cycle: write tests (RED) → implement (GREEN) → fix until all pass
- Call `/checkpoint` after each Task completes with all tests green
- Stop and report if blocked (see Error Recovery)

### Supervised Mode (default)
All other interactions:
- Describe approach before writing code, wait for approval
- Ask clarifying questions if requirements are ambiguous
- If a task requires changes to more than 3 files, stop and break it into smaller tasks first

---

## Tech Stack
- **Engine**: Godot 4.x (v4.6.1)
- **Godot Path**: `/opt/homebrew/bin/godot` (installed via `brew install --cask godot`)
- **Language**: GDScript
- **Test Framework**: GUT (Godot Unit Test)
- **Platform**: macOS (dev) / Windows (target export)
- **Data Format**: Godot Resources (.tres)

## GDScript Coding Conventions

### Naming
- Functions / variables: `snake_case`
- Classes / Nodes: `PascalCase`
- Constants / enums: `UPPER_SNAKE_CASE`
- Signals: `snake_case` (past tense: `card_played`, `turn_ended`)
- File names: `snake_case.gd` matching the class name (e.g., `CombatState` → `combat_state.gd`)

### File Organization
- One class per file
- Logic scripts in `scripts/` (no UI dependencies)
- Scene scripts in `scenes/` (can reference Nodes)
- Resource definitions in `resources/`

### Resource Pattern
```gdscript
# resources/cards/card_data.gd
class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var card_type: String  # "Attack", "Skill", "Power"
@export var rarity: String     # "Common", "Uncommon", "Rare"
@export var base_damage: int
@export var base_block: int
@export var effect_text: String
@export var keywords: Array[String]  # ["Exhaust", "Innate", etc.]
@export var is_upgraded: bool = false
```

### Architecture Constraint (CRITICAL)
> All game logic MUST be implemented as **pure functions** in `scripts/core/`.
> These functions accept data parameters and return data results.
> They MUST NOT reference Node, Scene tree, or any UI element.

```gdscript
# ✅ CORRECT — pure function, testable
static func calculate_damage(base: int, strength: int, is_vulnerable: bool, is_weak: bool) -> int:
    var dmg = base + strength
    if is_weak:
        dmg = int(dmg * 0.75)
    if is_vulnerable:
        dmg = int(dmg * 1.5)
    return dmg

# ❌ WRONG — depends on Node tree, untestable
func deal_damage():
    var dmg = $Card.damage + $Player.strength
    $Enemy.hp -= dmg
```

---

## TDD Rules

### Test File Naming
- File: `tests/test_{module}.gd` (e.g., `tests/test_damage_calc.gd`)
- Class: `extends GutTest`
- Function: `func test_{scenario}_{expected}():`

### GUT Test Pattern
```gdscript
extends GutTest

func test_base_damage_no_modifiers():
    var result = CombatCalc.calculate_damage(6, 0, false, false)
    assert_eq(result, 6, "Base damage should equal card value")

func test_strength_adds_to_damage():
    var result = CombatCalc.calculate_damage(6, 3, false, false)
    assert_eq(result, 9, "Damage should be base + strength")
```

### Workflow
1. Read test specification from `docs/tests/P{N}_*.md`
2. Write test code FIRST (all tests should FAIL initially)
3. Implement feature code until tests PASS
4. Run ALL existing tests (regression) — must ALL pass
5. Never modify a test to make it pass (unless the test spec itself is wrong)

### Test Execution
```bash
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

---

## Error Recovery

| Situation | Action |
|-----------|--------|
| Test fails after implementation | Log attempt to `docs/SCRATCHPAD.md` → analyze error → fix code → re-run |
| Same test fails with same error 3 times in a row | STOP. Log `### STOPPED` to SCRATCHPAD.md. Wait for human input. |
| Error changes between retries | Continue — different errors indicate progress. No fixed retry limit. |
| Architecture conflict (need Node in logic) | STOP. Do not bypass. Report the conflict and suggest refactoring. |
| Test spec appears wrong | STOP. Report to user. Do NOT modify test spec without approval. |
| Task requires >3 new files | Plan in `docs/SCRATCHPAD.md` first, then implement incrementally. |
| Session resumes after interruption | Read SCRATCHPAD.md error log first. Do NOT repeat already-failed approaches. |

---

## Data Value Authority

> When game values (damage, HP, costs, etc.) appear in multiple places, the **single source of truth** priority is:
> 1. `docs/GDD.md` — highest authority
> 2. `docs/tests/P{N}_*.md` — must match GDD
> 3. Resource `.tres` files — must match GDD
>
> If you discover a discrepancy, update the lower-priority source to match GDD. If GDD itself seems wrong, STOP and ask the user.

---

## Anti-Patterns (NEVER do these)

- Skip writing tests and implement directly
- Modify test expectations to make failing tests pass
- Reference Node/Scene tree in `scripts/core/` logic files
- Use `@onready` or `$NodePath` in logic classes
- Commit code with failing tests
- Push to remote with failing tests
- Create files not specified in the current Task scope
- Add features not in the current Phase's test specification

---

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/run-phase P{N}` | Autonomous TDD cycle for an entire phase |
| `/test` | Run all tests and report results |
| `/checkpoint` | Record iteration + commit + push |
| `/commit [msg]` | Auto-generate commit message from diff, commit + push |
| `/spec-review [P{N}]` | Audit all docs for consistency (read-only). Optional phase filter. |

---

## Rules from User Feedback
- When I say something is wrong, ask clarifying questions before rewriting
- Every time I correct you, add a new rule to this file so it never happens again
- When there's a bug, start by writing a test that reproduces it, then fix it until the test passes
