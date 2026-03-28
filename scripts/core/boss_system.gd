class_name BossSystem
extends RefCounted

## Get the current phase number for a boss (1, 2, or 3)
## Shadow Lord: Phase 1 (HP>60), Phase 2 (HP 30-60), Phase 3 (HP<30)
static func get_phase(boss: Combatant) -> int:
	if boss.enemy_data == null or not boss.enemy_data.is_boss:
		return 1
	var phases = boss.enemy_data.phases
	# Check phases from highest number (last) to lowest
	for i in range(phases.size() - 1, -1, -1):
		if boss.hp <= phases[i].get("hp_threshold", 0):
			return i + 2  # phase 2 for index 0, phase 3 for index 1
	return 1  # Default: phase 1

## Get the boss action based on current phase
static func get_boss_action(boss: Combatant) -> Dictionary:
	var phase = get_phase(boss)
	var pattern = _get_phase_pattern(boss, phase)
	if pattern.is_empty():
		return {"type": "attack", "value": 10}
	var idx = boss.pattern_index % pattern.size()
	return pattern[idx]

## Advance boss pattern index
static func advance_boss(boss: Combatant) -> void:
	var phase = get_phase(boss)
	var pattern = _get_phase_pattern(boss, phase)
	if not pattern.is_empty():
		boss.pattern_index = (boss.pattern_index + 1) % pattern.size()

## Apply Phase 3 enrage: +2 Strength per turn
static func apply_enrage(boss: Combatant) -> void:
	StatusEffects.apply_effect(boss, "Strength", 2)

## Get Dark Knight damage multiplier based on turn count
static func get_dark_knight_multiplier(dk: Combatant) -> int:
	if dk.turn_count > 3:
		return 2
	return 1

## Get pattern for a specific phase
static func _get_phase_pattern(boss: Combatant, phase: int) -> Array:
	if not boss.enemy_data.is_boss:
		return boss.enemy_data.pattern
	match phase:
		1:
			return boss.enemy_data.pattern  # Phase 1 uses main pattern
		_:
			var phase_idx = phase - 2  # phase 2 → idx 0, phase 3 → idx 1
			if phase_idx >= 0 and phase_idx < boss.enemy_data.phases.size():
				return boss.enemy_data.phases[phase_idx].get("pattern", [])
	return boss.enemy_data.pattern
