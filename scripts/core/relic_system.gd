class_name RelicSystem
extends RefCounted

## Apply combat-start relic effects to the combat state
static func apply_combat_start(state: CombatState, relics: Array[String]) -> void:
	for relic in relics:
		match relic:
			"Iron Bracers":
				state.player.block += 4
			"Blood Pendant":
				state.player.hp = mini(state.player.hp + 2, state.player.max_hp)
			"Thorn Armor":
				StatusEffects.apply_effect(state.player, "Thorns", 3)

## Get modified draw count based on relics
static func get_draw_count(base_draw: int, relics: Array[String]) -> int:
	var draw = base_draw
	if "War Drum" in relics:
		draw += 1
	if "Cracked Crown" in relics:
		draw -= 1
	return draw

## Get bonus draw for the first turn only (Ring of the Snake: +2 on turn 1)
static func get_first_turn_bonus_draw(relics: Array[String]) -> int:
	var bonus := 0
	if "Ring of the Snake" in relics:
		bonus += 2
	return bonus

## Get modified max energy based on relics
static func get_max_energy(base_energy: int, relics: Array[String]) -> int:
	var energy = base_energy
	if "Cracked Crown" in relics:
		energy += 1
	return energy

## Get bonus damage for attack cards from relics
static func get_attack_bonus(relics: Array[String]) -> int:
	var bonus := 0
	if "Rage Mask" in relics:
		bonus += 3
	return bonus

## Filter out owned relics from the full pool
static func get_available_relics(all_relics: Array[String], owned: Array[String]) -> Array[String]:
	var available: Array[String] = []
	for relic in all_relics:
		if relic not in owned:
			available.append(relic)
	return available
