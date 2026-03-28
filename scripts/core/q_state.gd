class_name QState
extends RefCounted

## Pure functions to discretize game state into compact string keys for Q-table lookup.

## Encode combat state into a string key for the combat Q-table.
## Format: "hp|enemy_hp|energy|block|has_atk|has_blk|has_pwr|vuln|intent"
static func encode_combat(state: CombatState) -> String:
	var hp_bucket = _hp_bucket(state.player.hp, state.player.max_hp)

	var strongest: Combatant = null
	for e in state.enemies:
		if e.is_alive():
			if strongest == null or e.hp > strongest.hp:
				strongest = e

	var enemy_hp_bucket := 0
	if strongest != null:
		enemy_hp_bucket = _hp_bucket(strongest.hp, strongest.max_hp)

	var energy = clampi(state.player.energy, 0, 4)
	var block_bucket = _block_bucket(state.player.block)

	var has_attack := 0
	var has_block := 0
	var has_power := 0
	for card in state.hand:
		var cost = card.data.cost
		if cost == -1:
			cost = 0
		if state.player.energy >= cost:
			if card.data.card_type == "Attack":
				has_attack = 1
			elif card.data.base_block > 0:
				has_block = 1
			if card.data.card_type == "Power":
				has_power = 1

	var enemy_vuln := 0
	if strongest != null and strongest.has_status("Vulnerable"):
		enemy_vuln = 1

	var intent_str := "unk"
	if strongest != null:
		var intent = EnemyAI.get_intent(strongest)
		var itype = intent.get("type", "")
		match itype:
			"attack", "multi_attack", "attack_debuff":
				intent_str = "atk"
			"defend":
				intent_str = "def"
			"buff":
				intent_str = "buf"

	return "%d|%d|%d|%d|%d|%d|%d|%d|%s" % [
		hp_bucket, enemy_hp_bucket, energy, block_bucket,
		has_attack, has_block, has_power, enemy_vuln, intent_str
	]

## Encode deck-building state. Format: "deck_size|atk_ratio|avg_cost|hp|floor"
static func encode_deckbuild(run: RunData) -> String:
	var n = run.deck.size()
	var deck_size_bucket := 0
	if n >= 18:
		deck_size_bucket = 2
	elif n >= 12:
		deck_size_bucket = 1

	var attack_count := 0
	var total_cost := 0
	for card in run.deck:
		if card.data.card_type == "Attack":
			attack_count += 1
		var c = card.data.cost
		if c < 0:
			c = 0
		total_cost += c

	var attack_ratio := 0.5
	if n > 0:
		attack_ratio = float(attack_count) / float(n)
	var attack_ratio_bucket := 1
	if attack_ratio < 0.4:
		attack_ratio_bucket = 0
	elif attack_ratio > 0.6:
		attack_ratio_bucket = 2

	var avg_cost := 1.0
	if n > 0:
		avg_cost = float(total_cost) / float(n)
	var avg_cost_bucket := 1
	if avg_cost < 1.2:
		avg_cost_bucket = 0
	elif avg_cost > 1.8:
		avg_cost_bucket = 2

	var hp_bucket = _hp_bucket(run.player_hp, run.player_max_hp)

	var floor_bucket := 0
	if run.current_layer >= 7:
		floor_bucket = 2
	elif run.current_layer >= 4:
		floor_bucket = 1

	return "%d|%d|%d|%d|%d" % [deck_size_bucket, attack_ratio_bucket, avg_cost_bucket, hp_bucket, floor_bucket]

## Encode rest site state. Format: "hp|floor"
static func encode_rest(run: RunData) -> String:
	var hp_bucket = _hp_bucket(run.player_hp, run.player_max_hp)
	var floor_bucket := 0
	if run.current_layer >= 7:
		floor_bucket = 2
	elif run.current_layer >= 4:
		floor_bucket = 1
	return "%d|%d" % [hp_bucket, floor_bucket]

## Encode map navigation state. Format: "hp|floor|deck_size"
static func encode_map(run: RunData) -> String:
	var hp_bucket = _hp_bucket(run.player_hp, run.player_max_hp)
	var floor_bucket := 0
	if run.current_layer >= 7:
		floor_bucket = 2
	elif run.current_layer >= 4:
		floor_bucket = 1
	var deck_size_bucket := 0
	var n = run.deck.size()
	if n >= 18:
		deck_size_bucket = 2
	elif n >= 12:
		deck_size_bucket = 1
	return "%d|%d|%d" % [hp_bucket, floor_bucket, deck_size_bucket]

## Get available combat actions as card name strings + "end_turn"
static func get_combat_actions(state: CombatState, potions: Array[String]) -> Array[String]:
	var actions: Array[String] = []
	var seen := {}
	for card in state.hand:
		var cost = card.data.cost
		if cost == -1:
			cost = 0
		if state.player.energy >= cost and not seen.has(card.data.card_name):
			actions.append(card.data.card_name)
			seen[card.data.card_name] = true
	for potion in potions:
		actions.append("potion:" + potion)
	actions.append("end_turn")
	return actions

# --- Helpers ---

static func _hp_bucket(hp: int, max_hp: int) -> int:
	if max_hp <= 0:
		return 0
	var ratio = float(hp) / float(max_hp)
	return clampi(int(ratio * 4.0), 0, 3)

static func _block_bucket(block: int) -> int:
	if block <= 0:
		return 0
	if block <= 5:
		return 1
	if block <= 12:
		return 2
	return 3
