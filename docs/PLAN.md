# Development Plan — DarkPath

> TDD-driven phased development · Godot 4.x · GUT test framework

---

## TDD Workflow

Every phase follows the same cycle:

```
1. READ    → docs/tests/PN_xxx_tests.md (test specification)
2. WRITE   → Test code in tests/ directory (all tests RED)
3. IMPLEMENT → Feature code in scripts/ (tests turn GREEN one by one)
4. REGRESS → Run ALL tests from P0 through current phase (must ALL pass)
5. DONE    → Update this file, mark phase complete
```

### Regression Rule
> After completing Phase N, **any future code change** must pass all tests from P0 through PN.

### Test Execution Command
```bash
godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

### Architecture Constraint
> All game logic must be implemented as **pure functions** that accept data parameters and return data results. No direct Node/Scene tree dependencies in logic code. This ensures testability without requiring a running scene tree.

---

## Phase Overview

| Phase | Scope | Test Spec | Status |
|-------|-------|-----------|--------|
| P0 | Core battle system | [P0_battle_tests.md](tests/P0_battle_tests.md) | ⬜ Not started |
| P1 | Map system | [P1_map_tests.md](tests/P1_map_tests.md) | ⬜ Not started |
| P2 | Single-run loop | [P2_loop_tests.md](tests/P2_loop_tests.md) | ⬜ Not started |
| P3 | Relics + potions + events | [P3_depth_tests.md](tests/P3_depth_tests.md) | ⬜ Not started |
| P4 | Boss + elite enemies | [P4_boss_tests.md](tests/P4_boss_tests.md) | ⬜ Not started |
| P4-bal | Balance simulation | [P4_balance_tests.md](tests/P4_balance_tests.md) | ⬜ Not started |
| P5 | Save + UI polish + packaging | [P5_polish_tests.md](tests/P5_polish_tests.md) | ⬜ Not started |

---

## P0 — Core Battle System

**Milestone**: Can complete one full battle (player vs 1-3 enemies)

### Tasks

| # | Task | Test Coverage | Done |
|---|------|--------------|------|
| 0.1 | Set up Godot project + install GUT addon (see detailed steps below) | — | ⬜ |
| 0.2 | Implement combat data models (CombatState, Combatant, CardInstance) | P0-T1~T3 | ⬜ |
| 0.3 | Implement damage/block calculation functions | P0-T1, P0-T2 | ⬜ |
| 0.4 | Implement status effect system (apply, tick, stack) | P0-T3 | ⬜ |
| 0.5 | Implement card pile manager (draw, discard, shuffle, exhaust) | P0-T4 | ⬜ |
| 0.6 | Implement turn flow state machine | P0-T5 | ⬜ |
| 0.7 | Implement enemy AI (pattern cycling, intent) | P0-T6 | ⬜ |
| 0.8 | Implement targeting logic | P0-T7 | ⬜ |
| 0.9 | Create starting deck card resources (Strike, Defend, Bash) | P0-T4 | ⬜ |
| 0.10 | Create enemy resources (Slime, Goblin, Skeleton, Bat Swarm) | P0-T6 | ⬜ |
| 0.11 | Build minimal battle scene (placeholder art) | Manual test | ⬜ |

### Task 0.1 — Detailed Steps

1. **Create `project.godot`** with project name "DarkPath", renderer settings
2. **Create directory structure** per GDD Section 13:
   ```
   scripts/core/    — pure logic (no Node dependencies)
   resources/cards/ — CardData .tres files
   resources/enemies/ — EnemyData .tres files
   resources/relics/
   resources/potions/
   scenes/battle/
   scenes/map/
   scenes/ui/
   tests/           — GUT test files
   addons/gut/      — GUT addon
   assets/sprites/
   assets/audio/
   ```
3. **Install GUT addon** from GitHub:
   ```bash
   curl -L https://github.com/bitwes/Gut/archive/refs/heads/main.zip -o /tmp/gut.zip
   unzip -o /tmp/gut.zip -d /tmp/gut
   mkdir -p addons
   cp -r /tmp/gut/Gut-main/addons/gut addons/gut
   rm -rf /tmp/gut.zip /tmp/gut
   ```
4. **Create `.gutconfig.json`**:
   ```json
   {
     "dirs": ["res://tests/"],
     "should_exit": true,
     "log_level": 1
   }
   ```
5. **Verify**: Run `godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit` — should exit with 0 tests, 0 failures

---

## P1 — Map System

**Milestone**: Can navigate a 10-layer tree map from start to boss node

### Tasks

| # | Task | Test Coverage | Done |
|---|------|--------------|------|
| 1.1 | Implement map data model (MapData, MapNode, MapEdge) | P1-T1 | ⬜ |
| 1.2 | Implement map generator (layer rules, node type placement) | P1-T1, P1-T4 | ⬜ |
| 1.3 | Implement path connectivity validation | P1-T2 | ⬜ |
| 1.4 | Implement node selection logic (legal moves, no backtrack) | P1-T3 | ⬜ |
| 1.5 | Build map scene (node graph rendering, click to select) | Manual test | ⬜ |
| 1.6 | Connect map → battle scene transition | Manual test | ⬜ |

---

## P2 — Single-Run Loop

**Milestone**: Complete run from layer 1 to layer 10 with rewards, shop, rest

### Tasks

| # | Task | Test Coverage | Done |
|---|------|--------------|------|
| 2.1 | Implement RunData (persistent state across nodes) | P2-T4 | ⬜ |
| 2.2 | Implement combat reward generator (gold, card picks, rarity) | P2-T1 | ⬜ |
| 2.3 | Implement shop logic (pricing, purchase, card removal) | P2-T2 | ⬜ |
| 2.4 | Implement rest site logic (heal 30%, upgrade card) | P2-T3 | ⬜ |
| 2.5 | Implement card upgrade system | P2-T3 | ⬜ |
| 2.6 | Create extended warrior card pool resources (~15 cards) | P2-T1 | ⬜ |
| 2.7 | Build reward screen, shop screen, rest site screen | Manual test | ⬜ |
| 2.8 | Build summary screen (victory/defeat) | Manual test | ⬜ |

---

## P3 — Strategic Depth

**Milestone**: Relics, potions, and random events enrich the run

### Tasks

| # | Task | Test Coverage | Done |
|---|------|--------------|------|
| 3.1 | Implement relic system (passive triggers, stacking) | P3-T1, P3-T2 | ⬜ |
| 3.2 | Create relic resources (6 relics) | P3-T1 | ⬜ |
| 3.3 | Implement potion system (use, carry limit 3) | P3-T3 | ⬜ |
| 3.4 | Create potion resources (4 potions) | P3-T3 | ⬜ |
| 3.5 | Implement event system (choices, outcomes) | P3-T4 | ⬜ |
| 3.6 | Create event resources (3 events) | P3-T4 | ⬜ |
| 3.7 | Integrate relics/potions into battle UI | Manual test | ⬜ |

---

## P4 — Boss & Balance

**Milestone**: Playable complete run with boss fight

### Tasks

| # | Task | Test Coverage | Done |
|---|------|--------------|------|
| 4.1 | Implement boss phase system (HP threshold transitions) | P4-T1 | ⬜ |
| 4.2 | Create Shadow Lord boss resource (3 phases) | P4-T2 | ⬜ |
| 4.3 | Create elite enemy resources (Dark Knight, Fire Elemental) | P0-T6 (regression) | ⬜ |
| 4.4 | Expand card pool to 30+ cards | Data validation | ⬜ |
| 4.5 | Balance tuning pass | P4-bal | ⬜ |

---

## P5 — Polish & Ship

**Milestone**: Shippable Windows build

### Tasks

| # | Task | Test Coverage | Done |
|---|------|--------------|------|
| 5.1 | Implement save/load system | P5-T1, P5-T2 | ⬜ |
| 5.2 | Implement main menu (new game, continue, settings) | Manual test | ⬜ |
| 5.3 | Data integrity validation for all .tres files | P5-T3 | ⬜ |
| 5.4 | UI polish (animations, transitions) | Manual test | ⬜ |
| 5.5 | Audio integration | Manual test | ⬜ |
| 5.6 | Windows export & packaging | Manual test | ⬜ |

---

## Progress Log

| Date | Phase | Notes |
|------|-------|-------|
| — | — | — |
