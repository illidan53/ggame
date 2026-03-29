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

	# Handle X-cost special effects (Malaise: -X Strength, X Weak to target)
	if data.special_effect == "malaise" and cost > 0 and target_index >= 0 and target_index < state.enemies.size():
		var target = state.enemies[target_index]
		StatusEffects.apply_effect(target, "Strength", -cost)
		StatusEffects.apply_effect(target, "Weak", cost)

	# Accuracy bonus for Shivs
	if data.card_name == "Shiv":
		strength += state.player.get_status_stacks("Accuracy")

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
		var hit_count = maxi(data.hits, 1)
		for _h in hit_count:
			CombatCalc.apply_damage_to_target(target, damage)
		# Bane: if enemy has Poison, deal damage again
		if data.special_effect == "bane" and target.has_status("Poison"):
			CombatCalc.apply_damage_to_target(target, damage)
	if data.base_block > 0:
		var dexterity = state.player.get_status_stacks("Dexterity")
		CombatCalc.apply_block(state.player, data.base_block, dexterity)
	# Apply Poison to single target
	if data.poison_amount > 0 and target_index >= 0 and target_index < state.enemies.size():
		StatusEffects.apply_effect(state.enemies[target_index], "Poison", data.poison_amount)
	# Apply Weak to single target
	if data.weak_amount > 0 and target_index >= 0 and target_index < state.enemies.size():
		StatusEffects.apply_effect(state.enemies[target_index], "Weak", data.weak_amount)
	_apply_common_effects(state, data)

static func _execute_aoe(state: CombatState, data: CardData, x_value: int, strength: int, is_weak: bool) -> void:
	var hit_count: int
	if data.cost == -1:  # X-cost: hit X times
		hit_count = x_value
	else:
		hit_count = maxi(data.hits, 1)
	for _hit in hit_count:
		for enemy in state.enemies:
			if not enemy.is_alive():
				continue
			var is_vulnerable = enemy.has_status("Vulnerable")
			var damage = CombatCalc.calculate_damage(data.base_damage, strength, is_weak, is_vulnerable)
			CombatCalc.apply_damage_to_target(enemy, damage)
	# Apply Poison/Weak to all enemies
	if data.poison_amount > 0:
		for enemy in state.enemies:
			if enemy.is_alive():
				StatusEffects.apply_effect(enemy, "Poison", data.poison_amount)
	if data.weak_amount > 0:
		for enemy in state.enemies:
			if enemy.is_alive():
				StatusEffects.apply_effect(enemy, "Weak", data.weak_amount)
	_apply_common_effects(state, data)

static func _execute_self(state: CombatState, data: CardData) -> void:
	if data.base_block > 0:
		var dexterity = state.player.get_status_stacks("Dexterity")
		CombatCalc.apply_block(state.player, data.base_block, dexterity)
	# Named special effects for self-target cards
	match data.special_effect:
		"catalyst":
			var best_enemy: Combatant = null
			var best_poison := 0
			for enemy in state.enemies:
				if enemy.is_alive():
					var p = enemy.get_status_stacks("Poison")
					if p > best_poison:
						best_poison = p
						best_enemy = enemy
			if best_enemy != null:
				StatusEffects.multiply_poison(best_enemy, 2)
		"footwork":
			StatusEffects.apply_effect(state.player, "Dexterity", 2)
		"accuracy":
			StatusEffects.apply_effect(state.player, "Accuracy", 4)
		"noxious_fumes":
			StatusEffects.apply_effect(state.player, "NoxiousFumes", 2)
		"wraith_form":
			StatusEffects.apply_effect(state.player, "Intangible", 2)
			StatusEffects.apply_effect(state.player, "WraithFormDex", 1)
		"piercing_wail":
			for enemy in state.enemies:
				if enemy.is_alive():
					StatusEffects.apply_effect(enemy, "Strength", -6)
		"adrenaline":
			state.player.energy += 1
		"burst":
			StatusEffects.apply_effect(state.player, "Burst", 1)

	# Apply Poison to all enemies (self-target poison skills)
	if data.poison_amount > 0:
		for enemy in state.enemies:
			if enemy.is_alive():
				StatusEffects.apply_effect(enemy, "Poison", data.poison_amount)
	# Apply Weak to all enemies (self-target weak skills like Crippling Cloud)
	if data.weak_amount > 0:
		for enemy in state.enemies:
			if enemy.is_alive():
				StatusEffects.apply_effect(enemy, "Weak", data.weak_amount)
	_apply_common_effects(state, data)

## Common effects shared across all target modes: draw, discard, shiv generation
static func _apply_common_effects(state: CombatState, data: CardData) -> void:
	# Generate Shivs
	if data.shiv_count > 0:
		var shiv_data = load("res://resources/cards/shiv.tres") as CardData
		if shiv_data:
			for _i in data.shiv_count:
				var shiv = CardInstance.new(shiv_data)
				CardPileManager.add_to_hand(state, shiv)
	# Draw cards
	if data.draw_amount > 0:
		CardPileManager.draw_cards(state, data.draw_amount)
	# Discard random cards (in headless/sim mode; UI would let player choose)
	if data.discard_amount > 0:
		CardPileManager.discard_random(state, data.discard_amount)
