class_name StatusEffects
extends RefCounted

## Effects that decay each turn (debuffs)
const DECAYING_EFFECTS = ["Vulnerable", "Weak"]

## Effects that are permanent stacking buffs
const PERMANENT_EFFECTS = ["Strength", "Dexterity", "Thorns", "AutoBlock"]

## Apply stacks of an effect to a combatant
static func apply_effect(combatant: Combatant, effect_name: String, stacks: int) -> void:
	if combatant.status_effects.has(effect_name):
		combatant.status_effects[effect_name] += stacks
	else:
		combatant.status_effects[effect_name] = stacks

## Tick decaying effects at end of turn (reduce by 1, remove if 0)
static func tick_effects(combatant: Combatant) -> void:
	var to_remove: Array[String] = []
	for effect_name in combatant.status_effects.keys():
		if effect_name in DECAYING_EFFECTS:
			combatant.status_effects[effect_name] -= 1
			if combatant.status_effects[effect_name] <= 0:
				to_remove.append(effect_name)
	for effect_name in to_remove:
		combatant.status_effects.erase(effect_name)

## Get thorns damage value (0 if no thorns)
static func get_thorns_damage(combatant: Combatant) -> int:
	return combatant.get_status_stacks("Thorns")

## Apply turn-start effects (Auto-Block)
static func apply_turn_start_effects(combatant: Combatant) -> void:
	var auto_block = combatant.get_status_stacks("AutoBlock")
	if auto_block > 0:
		combatant.block += auto_block
