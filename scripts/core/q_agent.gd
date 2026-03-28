class_name QAgent
extends RefCounted

## Epsilon-greedy Q-learning agent with separate combat and deck-building Q-tables.

var combat_q: QTable
var deckbuild_q: QTable
var epsilon: float = 1.0
var epsilon_min: float = 0.05
var epsilon_decay: float = 0.9995
var rng: RandomNumberGenerator

func _init() -> void:
	combat_q = QTable.new()
	deckbuild_q = QTable.new()
	rng = RandomNumberGenerator.new()
	rng.seed = 12345

## Apply hyperparameters from BalanceConfig.
func apply_config(params: Dictionary) -> void:
	combat_q.alpha = params.get("alpha", 0.1)
	combat_q.gamma = params.get("gamma", 0.95)
	deckbuild_q.alpha = params.get("alpha", 0.1)
	deckbuild_q.gamma = params.get("gamma", 0.95)
	epsilon = params.get("epsilon_start", 1.0)
	epsilon_min = params.get("epsilon_min", 0.05)
	epsilon_decay = params.get("epsilon_decay", 0.9995)

## Choose which card to play in combat (or end turn / use potion).
func choose_combat_action(state: CombatState, potions: Array[String]) -> Dictionary:
	var state_key = QState.encode_combat(state)
	var available = QState.get_combat_actions(state, potions)

	var chosen: String
	if rng.randf() < epsilon:
		chosen = available[rng.randi_range(0, available.size() - 1)]
	else:
		chosen = combat_q.get_best_action(state_key, available, rng)

	if chosen == "end_turn":
		return {"type": "end_turn"}

	if chosen.begins_with("potion:"):
		var potion_name = chosen.substr(7)
		for i in potions.size():
			if potions[i] == potion_name:
				return {"type": "use_potion", "potion_index": i}
		return {"type": "end_turn"}

	# Find card in hand matching this name
	for i in state.hand.size():
		var card = state.hand[i]
		var cost = card.data.cost
		if cost == -1:
			cost = 0
		if card.data.card_name == chosen and state.player.energy >= cost:
			var target := -1
			if card.data.target_mode == "single" and card.data.base_damage > 0:
				target = _pick_lowest_hp_enemy(state)
			return {"type": "play_card", "card_name": chosen, "card_index": i, "target": target}

	return {"type": "end_turn"}

## Choose which card to pick from rewards. Returns index (0-2) or -1 for skip.
func choose_card_pick(offered: Array[CardData], run: RunData) -> int:
	var state_key = QState.encode_deckbuild(run)
	var available: Array[String] = []
	for card in offered:
		available.append(card.card_name)
	available.append("skip")

	var chosen: String
	if rng.randf() < epsilon:
		chosen = available[rng.randi_range(0, available.size() - 1)]
	else:
		chosen = deckbuild_q.get_best_action(state_key, available, rng)

	if chosen == "skip":
		return -1
	for i in offered.size():
		if offered[i].card_name == chosen:
			return i
	return -1

## Choose rest site action. Returns "rest" or "upgrade".
func choose_rest_action(run: RunData) -> String:
	var state_key = QState.encode_rest(run)
	var available: Array[String] = ["rest", "upgrade"]
	if rng.randf() < epsilon:
		return available[rng.randi_range(0, 1)]
	return deckbuild_q.get_best_action(state_key, available, rng)

## Choose which map node to visit. Returns the chosen connection index.
func choose_map_path(run: RunData, connections: Array[int], next_layer_nodes: Array) -> int:
	if connections.is_empty():
		return 0
	var state_key = QState.encode_map(run)
	var available: Array[String] = []
	var action_to_conn := {}
	for conn_idx in connections:
		var node_type := "combat"
		if conn_idx < next_layer_nodes.size():
			node_type = next_layer_nodes[conn_idx].node_type
		var action_key = node_type + ":" + str(conn_idx)
		available.append(action_key)
		action_to_conn[action_key] = conn_idx

	var chosen: String
	if rng.randf() < epsilon:
		chosen = available[rng.randi_range(0, available.size() - 1)]
	else:
		chosen = deckbuild_q.get_best_action(state_key, available, rng)

	if action_to_conn.has(chosen):
		return action_to_conn[chosen]
	return connections[0]

## Compute immediate reward for a combat card play.
static func compute_combat_reward(
	hp_before: int, hp_after: int,
	enemies_hp_before: Array[int], enemies_hp_after: Array[int],
	block_before: int, block_after: int
) -> float:
	var reward := 0.0
	var total_damage := 0
	var enemies_killed := 0
	for i in enemies_hp_before.size():
		var dmg = enemies_hp_before[i] - enemies_hp_after[i]
		if dmg > 0:
			total_damage += dmg
		if enemies_hp_before[i] > 0 and enemies_hp_after[i] <= 0:
			enemies_killed += 1
	reward += 0.1 * (float(total_damage) / 10.0)
	reward += 0.5 * enemies_killed
	var block_gained = block_after - block_before
	if block_gained > 0:
		reward += 0.05 * (float(block_gained) / 5.0)
	var hp_lost = hp_before - hp_after
	if hp_lost > 0:
		reward -= 0.2 * (float(hp_lost) / 10.0)
	return reward

## Compute terminal reward for combat end.
static func compute_combat_terminal(result: String, hp: int, max_hp: int) -> float:
	if result == "victory":
		return 1.0 + 0.5 * (float(hp) / float(maxi(max_hp, 1)))
	return -1.0

## Compute terminal reward for run end.
static func compute_run_terminal(result: String, layer_reached: int) -> float:
	if result == "victory":
		return 10.0
	return -1.0 + 0.5 * (float(layer_reached) / 10.0)

## Decay epsilon after each episode.
func decay_epsilon() -> void:
	epsilon = maxf(epsilon_min, epsilon * epsilon_decay)

func _pick_lowest_hp_enemy(state: CombatState) -> int:
	var best_idx := -1
	var lowest_hp := 999999
	for i in state.enemies.size():
		if state.enemies[i].is_alive() and state.enemies[i].hp < lowest_hp:
			lowest_hp = state.enemies[i].hp
			best_idx = i
	return best_idx
