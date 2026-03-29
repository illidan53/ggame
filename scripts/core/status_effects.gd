class_name StatusEffects
extends RefCounted

## Effects that decay each turn (debuffs)
const DECAYING_EFFECTS = ["Vulnerable", "Weak"]

## Effects that are permanent stacking buffs
const PERMANENT_EFFECTS = ["Strength", "Dexterity", "Thorns", "AutoBlock"]

## Poison: ticks at enemy turn start (damage = stacks, bypasses block, decays by 1)
const POISON_EFFECT = "Poison"

## Intangible: reduces all damage to 1, decays each turn
const INTANGIBLE_EFFECT = "Intangible"

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
		if effect_name in DECAYING_EFFECTS or effect_name == INTANGIBLE_EFFECT:
			combatant.status_effects[effect_name] -= 1
			if combatant.status_effects[effect_name] <= 0:
				to_remove.append(effect_name)
	for effect_name in to_remove:
		combatant.status_effects.erase(effect_name)

## Get thorns damage value (0 if no thorns)
static func get_thorns_damage(combatant: Combatant) -> int:
	return combatant.get_status_stacks("Thorns")

## Apply turn-start effects (Auto-Block, Wraith Form dex loss)
static func apply_turn_start_effects(combatant: Combatant) -> void:
	var auto_block = combatant.get_status_stacks("AutoBlock")
	if auto_block > 0:
		combatant.block += auto_block
	# Wraith Form: lose 1 Dexterity each turn
	var wraith = combatant.get_status_stacks("WraithFormDex")
	if wraith > 0:
		apply_effect(combatant, "Dexterity", -1)

## Apply Noxious Fumes: at player turn start, apply Poison to all enemies.
## Called separately because it needs CombatState (not just Combatant).
static func apply_noxious_fumes(state: CombatState) -> int:
	var stacks = state.player.get_status_stacks("NoxiousFumes")
	if stacks <= 0:
		return 0
	for enemy in state.enemies:
		if enemy.is_alive():
			apply_effect(enemy, "Poison", stacks)
	return stacks

## Apply Poison damage at the start of a poisoned combatant's turn.
## Poison bypasses block, deals damage = stacks, then decays by 1.
## Returns the damage dealt (0 if no poison).
static func apply_poison(combatant: Combatant) -> int:
	var stacks = combatant.get_status_stacks(POISON_EFFECT)
	if stacks <= 0:
		return 0
	# Bypass block — damage applied directly to HP
	combatant.hp -= stacks
	combatant.status_effects[POISON_EFFECT] -= 1
	if combatant.status_effects[POISON_EFFECT] <= 0:
		combatant.status_effects.erase(POISON_EFFECT)
	return stacks

## Double (or multiply) an enemy's Poison stacks (for Catalyst).
static func multiply_poison(combatant: Combatant, multiplier: int = 2) -> void:
	var stacks = combatant.get_status_stacks(POISON_EFFECT)
	if stacks > 0:
		combatant.status_effects[POISON_EFFECT] = stacks * multiplier
