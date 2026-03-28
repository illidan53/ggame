class_name BattleManager
extends RefCounted

## Create and initialize a combat state
static func create_combat(player_hp: int, max_energy: int, deck: Array[CardInstance], enemy_datas: Array[EnemyData]) -> CombatState:
	var state = CombatState.new()

	state.player = Combatant.new()
	state.player.hp = player_hp
	state.player.max_hp = player_hp
	state.player.max_energy = max_energy
	state.player.is_player = true

	for edata in enemy_datas:
		var enemy = Combatant.new()
		enemy.hp = edata.hp
		enemy.max_hp = edata.hp
		enemy.enemy_data = edata
		state.enemies.append(enemy)

	CardPileManager.init_piles(state, deck)
	return state

## Start the player's turn: reset block, restore energy, draw cards
static func begin_player_turn(state: CombatState, draw_count: int = 5) -> Array[String]:
	var log: Array[String] = []
	TurnFlow.start_player_turn(state, draw_count)
	log.append("--- Turn %d ---" % state.turn_number)
	log.append("Drew %d cards." % state.hand.size())
	return log

## Play a card from hand. Returns {success: bool, log: Array[String]}
static func play_card(state: CombatState, card_index: int, target_index: int) -> Dictionary:
	var log: Array[String] = []

	# Validate card index
	if card_index < 0 or card_index >= state.hand.size():
		return {"success": false, "log": ["Invalid card number."]}

	var card = state.hand[card_index]

	# Validate energy
	if not TurnFlow.can_play_card(state, card):
		return {"success": false, "log": ["Not enough energy (%d needed, %d available)." % [card.data.cost, state.player.energy]]}

	# Validate target for single-target attacks
	if card.data.target_mode == "single" and card.data.base_damage > 0:
		if target_index < 0 or target_index >= state.enemies.size():
			return {"success": false, "log": ["Specify a valid target."]}
		if not state.enemies[target_index].is_alive():
			return {"success": false, "log": ["That enemy is dead."]}

	# Execute card
	Targeting.execute_card(state, card, target_index)

	# Handle Bash special: apply Vulnerable
	if card.data.card_name == "Bash" and target_index >= 0 and target_index < state.enemies.size():
		StatusEffects.apply_effect(state.enemies[target_index], "Vulnerable", 2)

	# Build log message
	var tname := ""
	if target_index >= 0 and target_index < state.enemies.size():
		tname = " -> " + state.enemies[target_index].enemy_data.enemy_name
	log.append("Played %s [%d energy]%s" % [card.data.card_name, card.data.cost, tname])

	# Check combat end after each card
	TurnFlow.check_combat_end(state)

	return {"success": true, "log": log}

## End player turn, execute enemy turns, check combat end
static func end_turn(state: CombatState) -> Array[String]:
	var log: Array[String] = []

	# End player turn (discard hand, tick player debuffs)
	TurnFlow.end_player_turn(state)
	TurnFlow.check_combat_end(state)
	if state.is_combat_over:
		log.append(_combat_end_message(state))
		return log

	# Enemy turns
	log.append("--- Enemy Turn ---")
	log.append_array(_execute_enemy_turns(state))

	TurnFlow.check_combat_end(state)
	if state.is_combat_over:
		log.append(_combat_end_message(state))

	return log

# --- Enemy Turn Logic ---

static func _execute_enemy_turns(state: CombatState) -> Array[String]:
	var log: Array[String] = []
	for enemy in state.enemies:
		if not enemy.is_alive():
			continue
		CombatCalc.reset_block(enemy)
		var intent = EnemyAI.get_intent(enemy)
		log.append_array(_execute_enemy_intent(state, enemy, intent))
		EnemyAI.advance_pattern(enemy)
		StatusEffects.tick_effects(enemy)
	return log

static func _execute_enemy_intent(state: CombatState, enemy: Combatant, intent: Dictionary) -> Array[String]:
	var log: Array[String] = []
	var ename = enemy.enemy_data.enemy_name
	var type = intent.get("type", "")
	var value = intent.get("value", 0)

	match type:
		"attack":
			var dmg = _calc_enemy_damage(state, enemy, value)
			CombatCalc.apply_damage_to_target(state.player, dmg)
			log.append_array(_apply_thorns(state, enemy))
			log.append("%s attacks for %d damage." % [ename, dmg])

		"multi_attack":
			var hits = intent.get("hits", 1)
			var dmg = _calc_enemy_damage(state, enemy, value)
			for h in hits:
				CombatCalc.apply_damage_to_target(state.player, dmg)
				log.append_array(_apply_thorns(state, enemy))
			log.append("%s attacks %d times for %d total damage." % [ename, hits, dmg * hits])

		"defend":
			var dex = enemy.get_status_stacks("Dexterity")
			CombatCalc.apply_block(enemy, value, dex)
			log.append("%s gains %d block." % [ename, value + dex])

		"attack_debuff":
			var dmg = _calc_enemy_damage(state, enemy, value)
			CombatCalc.apply_damage_to_target(state.player, dmg)
			log.append_array(_apply_thorns(state, enemy))
			var debuff = intent.get("debuff", "")
			var stacks = intent.get("debuff_stacks", 1)
			if debuff != "":
				StatusEffects.apply_effect(state.player, debuff, stacks)
			log.append("%s attacks for %d and applies %d %s." % [ename, dmg, stacks, debuff])

		"buff":
			var buff = intent.get("buff", "")
			var stacks = intent.get("buff_stacks", 1)
			if buff != "":
				StatusEffects.apply_effect(enemy, buff, stacks)
			log.append("%s gains %d %s." % [ename, stacks, buff])

	return log

static func _calc_enemy_damage(state: CombatState, enemy: Combatant, base_value: int) -> int:
	var strength = enemy.get_status_stacks("Strength")
	var is_weak = enemy.has_status("Weak")
	var is_vuln = state.player.has_status("Vulnerable")
	return CombatCalc.calculate_damage(base_value, strength, is_weak, is_vuln)

static func _apply_thorns(state: CombatState, enemy: Combatant) -> Array[String]:
	var log: Array[String] = []
	var thorns = StatusEffects.get_thorns_damage(state.player)
	if thorns > 0:
		CombatCalc.apply_damage_to_target(enemy, thorns)
		log.append("  Thorns deals %d to %s." % [thorns, enemy.enemy_data.enemy_name])
	return log

static func _combat_end_message(state: CombatState) -> String:
	if state.combat_result == "victory":
		return "*** VICTORY ***"
	else:
		return "*** DEFEAT ***"
