class_name PotionSystem
extends RefCounted

const MAX_POTIONS := 3

## Use a potion's effect on the combat state (no energy cost)
static func use_potion(potion_name: String, state: CombatState) -> void:
	match potion_name:
		"Health Potion":
			state.player.hp = mini(state.player.hp + 20, state.player.max_hp)
		"Strength Potion":
			StatusEffects.apply_effect(state.player, "Strength", 2)
		"Block Potion":
			state.player.block += 12
		"Fire Potion":
			for enemy in state.enemies:
				CombatCalc.apply_damage_to_target(enemy, 10)

## Try to add a potion to inventory. Returns true if added, false if full.
static func try_add_potion(potions: Array[String], potion_name: String) -> bool:
	if potions.size() >= MAX_POTIONS:
		return false
	potions.append(potion_name)
	return true

## Use potion at index and remove it from inventory
static func use_and_remove(potions: Array[String], index: int, state: CombatState) -> void:
	if index < 0 or index >= potions.size():
		return
	var potion_name = potions[index]
	use_potion(potion_name, state)
	potions.remove_at(index)
