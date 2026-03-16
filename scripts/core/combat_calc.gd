class_name CombatCalc
extends RefCounted

## Damage formula (GDD Section 4.2):
## floor(floor((base + Strength) × WeakMultiplier) × VulnerableMultiplier)
## Step 1: Add Strength to base damage
## Step 2: If attacker has Weak, multiply by 0.75 and floor
## Step 3: If target has Vulnerable, multiply by 1.5 and floor
static func calculate_damage(base: int, strength: int, is_weak: bool, is_vulnerable: bool) -> int:
	var dmg = base + strength
	if is_weak:
		dmg = int(floor(dmg * 0.75))
	if is_vulnerable:
		dmg = int(floor(dmg * 1.5))
	return dmg

## Apply calculated damage to a target, accounting for block
static func apply_damage_to_target(target: Combatant, damage: int) -> void:
	if damage <= 0:
		return
	if target.block >= damage:
		target.block -= damage
	else:
		var overflow = damage - target.block
		target.block = 0
		target.hp -= overflow

## Calculate and apply block to a combatant
static func apply_block(combatant: Combatant, base_block: int, dexterity: int) -> void:
	combatant.block += base_block + dexterity

## Reset block to 0 (called at turn start)
static func reset_block(combatant: Combatant) -> void:
	combatant.block = 0
