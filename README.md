# DarkPath

A Slay the Spire-inspired roguelike deckbuilder built with Godot 4.x and GDScript. Navigate a 10-layer dungeon, build your deck through combat rewards and shops, manage relics and potions, and defeat the Shadow Lord boss. Terminal-style UI — all interaction through text commands.

## Quick Start

```bash
/opt/homebrew/bin/godot --path .
```

## How to Play

Launch the game, then type commands in the input bar:

| Screen | Commands |
|--------|----------|
| **Main Menu** | `1` Continue, `2` New Game, `3` Quit |
| **Map** | `go <node#>`, `map`, `deck`, `help`, `menu` |
| **Battle** | `play <card#> [enemy#]`, `potion <#>`, `end`, `hand`, `help` |
| **Reward** | `1`-`3` pick card, `skip` |
| **Shop** | `1`-`3` buy card, `remove`, `leave` |
| **Rest** | `rest` (heal 30%), `upgrade` then pick card number |
| **Event** | `1`-`3` pick choice |

## Project Structure

```
scripts/core/       Pure game logic (no Node/UI dependencies)
scenes/             Godot scenes (menu, map, battle)
resources/cards/    31 card definitions (.tres)
resources/enemies/  7 enemy definitions (.tres)
tests/              GUT test suite (139 tests)
docs/               GDD, dev plan, test specs, iteration log
.claude/            Claude Code harness (commands, hooks, settings)
```

## Core Files

| File | Purpose |
|------|---------|
| `scripts/core/battle_manager.gd` | Combat flow orchestration |
| `scripts/core/combat_calc.gd` | Damage/block formulas |
| `scripts/core/card_pile_manager.gd` | Draw/discard/exhaust piles |
| `scripts/core/turn_flow.gd` | Turn start/end, energy, victory/defeat |
| `scripts/core/enemy_ai.gd` | Pattern cycling, intent, HP-threshold branching |
| `scripts/core/boss_system.gd` | 3-phase boss transitions, elite mechanics |
| `scripts/core/map_generator.gd` | Procedural 10-layer map with node types |
| `scripts/core/map_navigator.gd` | Legal move validation |
| `scripts/core/reward_generator.gd` | Gold, card rewards, rarity distribution |
| `scripts/core/shop_generator.gd` | Shop pricing, purchases |
| `scripts/core/rest_site.gd` | Heal and card upgrade |
| `scripts/core/relic_system.gd` | 6 passive relics with triggers |
| `scripts/core/potion_system.gd` | 4 potions, carry limit, single-use |
| `scripts/core/event_system.gd` | 3 random events with branching choices |
| `scripts/core/save_system.gd` | JSON save/load, permadeath |
| `scripts/core/run_simulator.gd` | 1000-run balance simulation |
| `scripts/core/run_state.gd` | Singleton autoload for cross-scene state |

## Running Tests

```bash
/opt/homebrew/bin/godot --headless --script addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
```

## Tech Stack

- **Engine**: Godot 4.6.1
- **Language**: GDScript
- **Tests**: GUT (Godot Unit Test)
- **Architecture**: All game logic as pure functions in `scripts/core/` — no Node dependencies, fully testable headless
