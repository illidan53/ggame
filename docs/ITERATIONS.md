# Iteration Log

> Newest entries first. Each entry is created by `/checkpoint` after all tests pass.
> Format: [I-{number}] Phase-Task: Description — Date

---

## [I-006] P0-T8: Targeting logic — 2026-03-15
- **Phase**: P0 (Task 0.8)
- **Changes**: Implemented Targeting with single-target, AOE, self-target, and X-cost card handling
- **Files**: scripts/core/targeting.gd, tests/test_targeting.gd
- **Tests**: 5 new tests added, 40/40 total passing
- **Commit**: `4ca8021`

---

## [I-005] P0-T7: Enemy AI system — 2026-03-15
- **Phase**: P0 (Task 0.7)
- **Changes**: Implemented EnemyAI with pattern cycling, intent display, multi-enemy independence, conditional HP-based branching
- **Files**: scripts/core/enemy_ai.gd, resources/enemies/enemy_data.gd, scripts/core/combatant.gd, tests/test_enemy_ai.gd
- **Tests**: 4 new tests added, 35/35 total passing
- **Commit**: `af4a03b`

---

## [I-004] P0-T6: Turn flow state machine — 2026-03-15
- **Phase**: P0 (Task 0.6)
- **Changes**: Implemented TurnFlow with turn start/end, energy check, combat end conditions
- **Files**: scripts/core/turn_flow.gd, tests/test_turn_flow.gd
- **Tests**: 6 new tests added, 31/31 total passing
- **Commit**: `fb07d2b`

---

## [I-003] P0-T5: Card pile manager — 2026-03-15
- **Phase**: P0 (Task 0.5)
- **Changes**: Implemented CardPileManager with draw, discard, reshuffle, exhaust, innate, and ethereal keyword handling
- **Files**: scripts/core/card_pile_manager.gd, tests/test_card_pile.gd
- **Tests**: 7 new tests added, 25/25 total passing
- **Commit**: `5941899`

---

## [I-002] P0-T4: Status effect system — 2026-03-15
- **Phase**: P0 (Task 0.4)
- **Changes**: Implemented StatusEffects with apply, tick/decay, thorns reflect, auto-block trigger
- **Files**: scripts/core/status_effects.gd, tests/test_status_effects.gd
- **Tests**: 6 new tests added, 18/18 total passing
- **Commit**: `eb909f1`

---

## [I-001] P0-T1~T3: Setup project, data models, damage/block calc — 2026-03-15
- **Phase**: P0 (Tasks 0.1, 0.2, 0.3)
- **Changes**: Created Godot project, installed GUT addon, implemented Combatant/CardInstance/CombatState data models, CombatCalc with damage formula and block logic
- **Files**: project.godot, .gutconfig.json, addons/gut/, scripts/core/combatant.gd, scripts/core/combat_calc.gd, scripts/core/card_instance.gd, scripts/core/combat_state.gd, resources/cards/card_data.gd, tests/test_damage_calc.gd
- **Tests**: 12 new tests added, 12/12 total passing
- **Commit**: `4ec9896`

---
