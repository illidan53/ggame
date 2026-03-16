class_name Targeting
extends RefCounted

## Execute a card's effect based on its target mode
## target_index: index into state.enemies for single-target, -1 for self/aoe
static func execute_card(state: CombatState, card: CardInstance, target_index: int) -> void:
	var data = card.data
	var strength = state.player.get_status_stacks("Strength")
	var is_weak = state.player.has_status("Weak")

	# Determine cost and spend energy
	var cost = data.cost
	if cost == -1:  # X-cost card
		cost = state.player.energy
	state.player.energy -= cost

	# Execute based on target mode
	match data.target_mode:
		"single":
			_execute_single(state, data, target_index, strength, is_weak)
		"aoe":
			_execute_aoe(state, data, cost, strength, is_weak)
		"self":
			_execute_self(state, data)

	# Move card from hand to appropriate pile
	CardPileManager.play_card(state, card)

static func _execute_single(state: CombatState, data: CardData, target_index: int, strength: int, is_weak: bool) -> void:
	if data.base_damage > 0 and target_index >= 0 and target_index < state.enemies.size():
		var target = state.enemies[target_index]
		var is_vulnerable = target.has_status("Vulnerable")
		var damage = CombatCalc.calculate_damage(data.base_damage, strength, is_weak, is_vulnerable)
		CombatCalc.apply_damage_to_target(target, damage)
	if data.base_block > 0:
		var dexterity = state.player.get_status_stacks("Dexterity")
		CombatCalc.apply_block(state.player, data.base_block, dexterity)

static func _execute_aoe(state: CombatState, data: CardData, x_value: int, strength: int, is_weak: bool) -> void:
	# For X-cost cards, deal X * base_damage to all enemies
	if data.cost == -1:  # X-cost
		for _hit in range(x_value):
			for enemy in state.enemies:
				var is_vulnerable = enemy.has_status("Vulnerable")
				var damage = CombatCalc.calculate_damage(data.base_damage, strength, is_weak, is_vulnerable)
				CombatCalc.apply_damage_to_target(enemy, damage)
	else:
		for enemy in state.enemies:
			var is_vulnerable = enemy.has_status("Vulnerable")
			var damage = CombatCalc.calculate_damage(data.base_damage, strength, is_weak, is_vulnerable)
			CombatCalc.apply_damage_to_target(enemy, damage)

static func _execute_self(state: CombatState, data: CardData) -> void:
	if data.base_block > 0:
		var dexterity = state.player.get_status_stacks("Dexterity")
		CombatCalc.apply_block(state.player, data.base_block, dexterity)
