# Scratchpad

> This file serves two purposes:
> 1. **Implementation plans** for complex tasks (>3 files)
> 2. **Error logs** during autonomous execution (`/run-phase`)
>
> Content here is temporary. Sections are cleared automatically when their Task passes all tests.

---

## Implementation Plan: P0-T11 — BattleManager Refactor

- **Task**: Extract battle flow logic from battle_scene.gd into pure BattleManager, write integration tests
- **Files to create/modify**:
  1. `scripts/core/battle_manager.gd` — NEW: pure logic, no Node/UI
  2. `tests/test_battle_manager.gd` — NEW: integration tests
  3. `scenes/battle/battle_scene.gd` — MODIFY: delegate to BattleManager
- **Approach**:
  - BattleManager is a static-function class (like all core scripts)
  - Returns Array[String] combat log from each action for UI to display
  - BattleScene becomes thin: input parsing → BattleManager call → render state
- **API Design**:
  ```
  BattleManager.create_combat(player_hp, max_energy, deck, enemy_datas) -> CombatState
  BattleManager.begin_player_turn(state) -> Array[String]
  BattleManager.play_card(state, card_index, target_index) -> Array[String]
  BattleManager.end_turn(state) -> Array[String]  # player end + enemy turns + check end
  ```
- **Test Cases**:
  1. init — correct HP, deck size, enemy count
  2. begin turn — energy restored, hand drawn, block reset
  3. play attack — damage dealt, energy spent, card discarded
  4. play defend — block gained
  5. insufficient energy — rejected, state unchanged
  6. invalid card/target — rejected
  7. end turn — enemies act, debuffs tick
  8. victory — all enemies dead
  9. defeat — player HP <= 0
  10. bash applies vulnerable — next attack deals more
  11. full combat loop — play until victory or defeat

---

<!--
TEMPLATE: Implementation Plan (used by /run-phase Step 2a)

## Implementation Plan: P{N}-T{M}
- **Task**: {task description}
- **Files to create/modify**:
  - {file1}
  - {file2}
- **Approach**: {brief description}
- **Dependencies**: {what must exist first}
-->

<!--
TEMPLATE: Error Log (used by /run-phase Step 2d)

## Active Error Log: P{N}-T{M} ({task description})

### Attempt 1 — {YYYY-MM-DD}
- **Failing test**: {test_function_name}
- **Error**: {Expected X, got Y / error message}
- **Fix tried**: {1-sentence description of what was changed}

### Attempt 2 — {YYYY-MM-DD}
- **Failing test**: {test_function_name}
- **Error**: {Expected X, got Y / error message}
- **Fix tried**: {1-sentence description of what was changed}

### STOPPED — {YYYY-MM-DD}
Same test `{test_name}` failed with same error 3 consecutive times.
Approaches tried: {summary}. Awaiting human input.
-->
