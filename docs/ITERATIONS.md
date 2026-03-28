# Iteration Log

> Newest entries first. Each entry is created by `/checkpoint` after all tests pass.
> Format: [I-{number}] Phase-Task: Description — Date

---

## [I-017] P3-T7: Integrate relics/potions/events into UI — 2026-03-27
- **Phase**: P3 (Task 3.7)
- **Changes**: Wired relics into combat (combat-start effects, draw/energy modifiers), added potion command in battle, integrated events into map with branching choices, elite relic drops go to RunState
- **Files**: scenes/battle/battle_scene.gd, scenes/map/map_scene.gd, scripts/core/run_state.gd, scripts/core/turn_flow.gd, scripts/core/battle_manager.gd
- **Tests**: 0 new (manual UI), 109/109 total passing
- **Commit**: `eff03dd`

---

## [I-016] P3-T1~T6: Relics, potions, and events — 2026-03-27
- **Phase**: P3 (Tasks 3.1-3.6)
- **Changes**: Implemented RelicSystem (6 relics with combat-start/turn-start/attack triggers), PotionSystem (4 potions, carry limit 3, no energy cost), EventSystem (3 events with branching choices)
- **Files**: scripts/core/{relic_system,potion_system,event_system}.gd, tests/{test_relics,test_potions,test_events}.gd
- **Tests**: 24 new tests added, 109/109 total passing
- **Commit**: `75427a2`

---

## [I-015] P2-T7~T8: Run loop UI screens — 2026-03-27
- **Phase**: P2 (Tasks 2.7, 2.8)
- **Changes**: Integrated reward selection, shop (buy/remove cards), rest site (heal/upgrade), victory/defeat summary, deck viewer, and gold tracking into map scene; battle scene now uses RunState deck
- **Files**: scenes/map/map_scene.gd, scenes/battle/battle_scene.gd, scripts/core/run_state.gd
- **Tests**: 0 new (manual UI), 85/85 total passing
- **Commit**: `b3992d5`

---

## [I-014] P2-T1~T6: Run loop systems + card pool — 2026-03-27
- **Phase**: P2 (Tasks 2.1-2.6)
- **Changes**: Implemented RunData, RewardGenerator, ShopGenerator, RestSite, CardUpgrade; created 12 new card resources (15 total); full reward/shop/rest/upgrade/serialization logic
- **Files**: scripts/core/{run_data,reward_generator,shop_generator,rest_site,card_upgrade}.gd, resources/cards/{12 new .tres}, tests/{test_rewards,test_shop,test_rest_site}.gd
- **Tests**: 17 new tests added, 85/85 total passing
- **Commit**: `58c129c`

---

## [I-013] P1-T6: Map ↔ battle scene transition — 2026-03-27
- **Phase**: P1 (Task 1.6)
- **Changes**: Created RunState autoload for cross-scene state; wired map → battle transition on combat/elite/boss nodes; battle returns to map with HP persisted; set map as main scene
- **Files**: scripts/core/run_state.gd, scenes/map/map_scene.gd, scenes/battle/battle_scene.gd, project.godot
- **Tests**: 0 new (manual UI task), 68/68 total passing
- **Commit**: `29d2b7e`

---

## [I-012] P1-T5: Map scene — 2026-03-27
- **Phase**: P1 (Task 1.5)
- **Changes**: Built terminal-style map scene with node selection, full map view, and position tracking
- **Files**: scenes/map/map_scene.gd, scenes/map/map_scene.tscn
- **Tests**: 0 new (manual UI task), 68/68 total passing
- **Commit**: `6a68d37`

---

## [I-011] P1-T4: Node selection logic — 2026-03-27
- **Phase**: P1 (Task 1.4)
- **Changes**: Implemented MapNavigator with legal move validation and backtrack prevention
- **Files**: scripts/core/map_navigator.gd, tests/test_map.gd
- **Tests**: 2 new tests added, 68/68 total passing
- **Commit**: `982346d`

---

## [I-010] P1-T3: Path connectivity validation — 2026-03-27
- **Phase**: P1 (Task 1.3)
- **Changes**: Added path connectivity tests (min connections, full reachability, no orphans); connectivity was already implemented in MapGenerator
- **Files**: tests/test_map.gd
- **Tests**: 3 new tests added, 66/66 total passing
- **Commit**: `1783f9d`

---

## [I-009] P1-T1~T2: Map data models and generator — 2026-03-27
- **Phase**: P1 (Tasks 1.1, 1.2)
- **Changes**: Created MapData, MapNode, MapGenerator with layer rules, fixed node types, connections, and seed determinism
- **Files**: scripts/core/map_data.gd, scripts/core/map_node.gd, scripts/core/map_generator.gd, tests/test_map.gd
- **Tests**: 7 new tests added, 63/63 total passing
- **Commit**: `5543e2d`

---

## [I-008] P0-T11: Battle scene + BattleManager — 2026-03-27
- **Phase**: P0 (Task 0.11)
- **Changes**: Extracted battle flow logic into pure BattleManager class, built terminal-style battle scene (RichTextLabel + LineEdit), wrote 14 integration tests covering full combat loop
- **Files**: scripts/core/battle_manager.gd, scenes/battle/battle_scene.gd, scenes/battle/battle_scene.tscn, tests/test_battle_manager.gd, project.godot
- **Tests**: 14 new tests added, 54/54 total passing
- **Commit**: `2adfdba`

---

## [I-007] P0-T9~T10: Card and enemy resources — 2026-03-15
- **Phase**: P0 (Tasks 0.9, 0.10)
- **Changes**: Created .tres resources for Strike, Defend, Bash cards and Slime, Goblin, Skeleton, Bat Swarm enemies
- **Files**: resources/cards/{strike,defend,bash}.tres, resources/enemies/{slime,goblin,skeleton,bat_swarm}.tres
- **Tests**: 0 new tests, 40/40 total passing (regression OK)
- **Commit**: `48cacbf`

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
