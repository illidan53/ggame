class_name Combatant
extends RefCounted

## Core stats
var hp: int = 0
var max_hp: int = 0
var block: int = 0
var energy: int = 0
var max_energy: int = 3

## Status effects: Dictionary of {effect_name: stacks}
## Buffs (permanent stacks): Strength, Dexterity, Thorns, AutoBlock
## Debuffs (turn-based decay): Vulnerable, Weak
var status_effects: Dictionary = {}

## Whether this combatant is the player or an enemy
var is_player: bool = false

## Enemy-specific fields
var enemy_data: EnemyData = null
var pattern_index: int = 0

func is_alive() -> bool:
	return hp > 0

func has_status(effect_name: String) -> bool:
	return status_effects.has(effect_name) and status_effects[effect_name] > 0

func get_status_stacks(effect_name: String) -> int:
	if status_effects.has(effect_name):
		return status_effects[effect_name]
	return 0
