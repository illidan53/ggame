class_name EnemyAI
extends RefCounted

## Get the current intent for an enemy combatant
## enemy_combatant must have: pattern_index, enemy_data, hp, max_hp
static func get_intent(enemy: Combatant) -> Dictionary:
	var pattern = _get_active_pattern(enemy)
	if pattern.is_empty():
		return {}
	var index = enemy.pattern_index % pattern.size()
	return pattern[index]

## Advance the enemy's pattern to the next step
static func advance_pattern(enemy: Combatant) -> void:
	var pattern = _get_active_pattern(enemy)
	if not pattern.is_empty():
		enemy.pattern_index = (enemy.pattern_index + 1) % pattern.size()

## Get the active pattern (normal or alt based on HP threshold)
static func _get_active_pattern(enemy: Combatant) -> Array[Dictionary]:
	if enemy.enemy_data == null:
		return [] as Array[Dictionary]
	var data: EnemyData = enemy.enemy_data
	if data.hp_threshold_percent > 0.0 and enemy.max_hp > 0:
		var hp_pct = float(enemy.hp) / float(enemy.max_hp)
		if hp_pct < data.hp_threshold_percent and not data.alt_pattern.is_empty():
			return data.alt_pattern
	return data.pattern
