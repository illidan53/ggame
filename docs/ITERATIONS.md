# Iteration Log

> Newest entries first. Each entry is created by `/checkpoint` after all tests pass.
> Format: [I-{number}] Phase-Task: Description — Date

---

## [I-001] P0-T1~T3: Setup project, data models, damage/block calc — 2026-03-15
- **Phase**: P0 (Tasks 0.1, 0.2, 0.3)
- **Changes**: Created Godot project, installed GUT addon, implemented Combatant/CardInstance/CombatState data models, CombatCalc with damage formula and block logic
- **Files**: project.godot, .gutconfig.json, addons/gut/, scripts/core/combatant.gd, scripts/core/combat_calc.gd, scripts/core/card_instance.gd, scripts/core/combat_state.gd, resources/cards/card_data.gd, tests/test_damage_calc.gd
- **Tests**: 12 new tests added, 12/12 total passing
- **Commit**: `4ec9896`

---
