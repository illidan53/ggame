class_name QRunSimulator
extends RefCounted

## Full run simulation with Q-learning agent decisions and learning updates.
## Mirrors RunSimulator but replaces random decisions with Q-agent policy.

## Train the agent over multiple episodes. Returns training metrics.
static func train(episodes: int, agent: QAgent, base_seed: int = 0) -> Dictionary:
	var win_rates: Array[float] = []
	var total_wins := 0
	var recent_wins := 0
	var card_pool = RunSimulator._load_card_pool()

	for ep in episodes:
		var seed_val = base_seed + ep * 7919
		agent.rng.seed = seed_val + 1
		var result = _simulate_run(agent, seed_val, card_pool)

		if result["outcome"] == "victory":
			total_wins += 1
			recent_wins += 1

		# Terminal run reward — backprop to deck-building transitions
		var run_reward = QAgent.compute_run_terminal(result["outcome"], result["layer_reached"])
		var transitions: Array = result["deckbuild_transitions"]
		if not transitions.is_empty():
			var last = transitions[-1]
			agent.deckbuild_q.update_terminal(last["state"], last["action"], run_reward)
			for i in range(transitions.size() - 2, -1, -1):
				var t = transitions[i]
				var next_t = transitions[i + 1]
				agent.deckbuild_q.update(t["state"], t["action"], 0.0, next_t["state"], [next_t["action"]])

		agent.decay_epsilon()

		if (ep + 1) % 100 == 0:
			win_rates.append(float(recent_wins) / 100.0)
			recent_wins = 0

	return {
		"total_runs": episodes,
		"total_wins": total_wins,
		"win_rate": float(total_wins) / maxi(episodes, 1),
		"win_rates": win_rates,
		"epsilon": agent.epsilon,
	}

## Evaluate the trained agent (no learning, epsilon=0).
## Returns stats compatible with RunSimulator.simulate_batch format + card_presence.
static func evaluate(count: int, agent: QAgent, base_seed: int = 0) -> Dictionary:
	var saved_epsilon = agent.epsilon
	agent.epsilon = 0.0
	var card_pool = RunSimulator._load_card_pool()

	var wins := 0
	var deaths_by_layer := {}
	var total_depth := 0
	var failed_runs := 0
	var reached_boss := 0
	var boss_wins := 0
	var card_presence: Dictionary = {}  # card_name -> {wins: int, total: int}

	for i in count:
		var seed_val = base_seed + i * 7919
		agent.rng.seed = seed_val + 1
		var result = _simulate_run(agent, seed_val, card_pool)
		var outcome = result["outcome"]
		var layer = result["layer_reached"]

		for card_name in result["deck_cards"]:
			if not card_presence.has(card_name):
				card_presence[card_name] = {"wins": 0, "total": 0}
			card_presence[card_name]["total"] += 1
			if outcome == "victory":
				card_presence[card_name]["wins"] += 1

		if outcome == "victory":
			wins += 1
			boss_wins += 1
			reached_boss += 1
		else:
			deaths_by_layer[layer] = deaths_by_layer.get(layer, 0) + 1
			total_depth += layer
			failed_runs += 1
			if layer == 10:
				reached_boss += 1

	agent.epsilon = saved_epsilon

	return {
		"total": count,
		"wins": wins,
		"win_rate": float(wins) / maxi(count, 1),
		"deaths_by_layer": deaths_by_layer,
		"avg_depth": float(total_depth) / maxi(failed_runs, 1),
		"reached_boss": reached_boss,
		"boss_wins": boss_wins,
		"boss_kill_rate": float(boss_wins) / maxi(reached_boss, 1),
		"card_presence": card_presence,
	}

## Simulate a single run with Q-agent decisions.
static func _simulate_run(agent: QAgent, seed_value: int, card_pool: Array[CardData]) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value

	var run = RunData.create_new(seed_value)
	var deckbuild_transitions: Array = []

	var current_node_idx := rng.randi_range(0, run.map.layers[0].size() - 1)
	run.current_layer = 0
	run.current_node = current_node_idx

	for layer_idx in 10:
		run.current_layer = layer_idx
		var node = run.map.layers[layer_idx][run.current_node]

		match node.node_type:
			"combat", "elite", "boss":
				var enemies = RunSimulator._get_enemies_for_node_at_layer(node.node_type, layer_idx, rng)
				var survived = _simulate_combat_with_learning(run, enemies, agent)
				if not survived:
					return _make_result("defeat", layer_idx + 1, deckbuild_transitions, run)

				run.gold += RewardGenerator.roll_gold(node.node_type, rng.randi())

				if not card_pool.is_empty():
					var rewards = RewardGenerator.roll_card_rewards(card_pool, node.node_type, rng.randi())
					if not rewards.is_empty():
						var state_key = QState.encode_deckbuild(run)
						var pick_idx = agent.choose_card_pick(rewards, run)
						var action_name: String
						if pick_idx >= 0 and pick_idx < rewards.size():
							action_name = rewards[pick_idx].card_name
							var card = CardInstance.new(rewards[pick_idx])
							card.instance_id = rng.randi()
							run.deck.append(card)
						else:
							action_name = "skip"
						deckbuild_transitions.append({"state": state_key, "action": action_name})

				if node.node_type == "elite":
					var available = RelicSystem.get_available_relics(EventSystem.ALL_RELICS, run.relics)
					if not available.is_empty():
						run.relics.append(available[rng.randi_range(0, available.size() - 1)])

			"shop":
				if run.gold >= 30 and not card_pool.is_empty():
					var prices = ShopGenerator.generate_prices(rng.randi())
					var affordable_rarity = ""
					if run.gold >= prices["Common"]:
						affordable_rarity = "Common"
					if run.gold >= prices["Uncommon"] and rng.randf() < 0.3:
						affordable_rarity = "Uncommon"
					if affordable_rarity != "":
						var filtered = card_pool.filter(func(c): return c.rarity == affordable_rarity)
						if not filtered.is_empty():
							var shop_offers: Array[CardData] = []
							for j in mini(3, filtered.size()):
								shop_offers.append(filtered[rng.randi_range(0, filtered.size() - 1)])
							var state_key = QState.encode_deckbuild(run)
							var pick_idx = agent.choose_card_pick(shop_offers, run)
							var action_name: String
							if pick_idx >= 0 and pick_idx < shop_offers.size():
								action_name = shop_offers[pick_idx].card_name
								run.gold -= prices[affordable_rarity]
								var card = CardInstance.new(shop_offers[pick_idx])
								card.instance_id = rng.randi()
								run.deck.append(card)
							else:
								action_name = "skip"
							deckbuild_transitions.append({"state": state_key, "action": action_name})

			"rest":
				var state_key = QState.encode_rest(run)
				var choice = agent.choose_rest_action(run)
				deckbuild_transitions.append({"state": state_key, "action": choice})
				if choice == "rest":
					run.player_hp = RestSite.rest(run.player_hp, run.player_max_hp)
				else:
					var upgradeable: Array = []
					for i in run.deck.size():
						if not run.deck[i].data.is_upgraded:
							upgradeable.append(i)
					if not upgradeable.is_empty():
						var idx = upgradeable[rng.randi_range(0, upgradeable.size() - 1)]
						run.deck[idx].data = CardUpgrade.upgrade(run.deck[idx].data)

			"event":
				var events = EventSystem.get_event_list()
				var event_id = events[rng.randi_range(0, events.size() - 1)]
				var choices = EventSystem.get_choices(event_id)
				var choice = choices[rng.randi_range(0, choices.size() - 1)]
				var data := {
					"hp": run.player_hp, "max_hp": run.player_max_hp,
					"gold": run.gold, "relics": run.relics, "deck": run.deck,
				}
				EventSystem.execute_choice(event_id, choice["id"], data, rng.randi())
				run.player_hp = data["hp"]
				run.gold = maxi(data["gold"], 0)
				if run.player_hp <= 0:
					return _make_result("defeat", layer_idx + 1, deckbuild_transitions, run)

		# Navigate to next layer
		if layer_idx < 9:
			var source = run.map.layers[layer_idx][run.current_node]
			if source.connections.is_empty():
				break
			var next_layer_nodes = run.map.layers[layer_idx + 1]
			var conn_idx = agent.choose_map_path(run, source.connections, next_layer_nodes)
			var state_key = QState.encode_map(run)
			var node_type := "combat"
			if conn_idx < next_layer_nodes.size():
				node_type = next_layer_nodes[conn_idx].node_type
			deckbuild_transitions.append({"state": state_key, "action": node_type + ":" + str(conn_idx)})
			run.current_node = conn_idx

	return _make_result("victory", 10, deckbuild_transitions, run)

## Simulate a single combat with Q-learning updates.
static func _simulate_combat_with_learning(run: RunData, enemy_datas: Array[EnemyData], agent: QAgent) -> bool:
	var deck_copy: Array[CardInstance] = []
	for card in run.deck:
		var c = CardInstance.new(card.data)
		c.instance_id = card.instance_id
		deck_copy.append(c)

	var max_energy = RelicSystem.get_max_energy(3, run.relics)
	var state = BattleManager.create_combat(run.player_hp, max_energy, deck_copy, enemy_datas)
	RelicSystem.apply_combat_start(state, run.relics)

	var draw_count = RelicSystem.get_draw_count(5, run.relics)
	var max_turns := 50
	var last_state_key := ""
	var last_action := ""

	for _turn in max_turns:
		if state.is_combat_over:
			break
		BattleManager.begin_player_turn(state, draw_count)

		var max_plays := 20
		for _play in max_plays:
			if state.hand.is_empty() or state.is_combat_over:
				break

			# Snapshot before
			var hp_before = state.player.hp
			var block_before = state.player.block
			var enemies_hp_before: Array[int] = []
			for e in state.enemies:
				enemies_hp_before.append(e.hp)

			var state_key = QState.encode_combat(state)
			var decision = agent.choose_combat_action(state, run.potions)

			if decision["type"] == "end_turn":
				if last_state_key != "":
					var next_actions = QState.get_combat_actions(state, run.potions)
					agent.combat_q.update(last_state_key, last_action, 0.0, state_key, next_actions)
				last_state_key = state_key
				last_action = "end_turn"
				break

			if decision["type"] == "use_potion":
				var pidx: int = decision["potion_index"]
				if pidx >= 0 and pidx < run.potions.size():
					PotionSystem.use_and_remove(run.potions, pidx, state)
				continue

			# Play card
			var card_idx: int = decision["card_index"]
			var target: int = decision["target"]
			var card_name: String = decision["card_name"]

			var play_result = BattleManager.play_card(state, card_idx, target)
			if not play_result["success"]:
				continue

			# Snapshot after
			var enemies_hp_after: Array[int] = []
			for e in state.enemies:
				enemies_hp_after.append(e.hp)

			var reward = QAgent.compute_combat_reward(
				hp_before, state.player.hp, enemies_hp_before, enemies_hp_after,
				block_before, state.player.block
			)

			if last_state_key != "":
				agent.combat_q.update(last_state_key, last_action, 0.0, state_key, [card_name])

			last_state_key = state_key
			last_action = card_name

			if state.is_combat_over:
				var terminal = QAgent.compute_combat_terminal(
					state.combat_result, state.player.hp, state.player.max_hp
				)
				agent.combat_q.update_terminal(last_state_key, last_action, reward + terminal)
				last_state_key = ""
				break

		if not state.is_combat_over:
			BattleManager.end_turn(state)
			if state.is_combat_over and last_state_key != "":
				var terminal = QAgent.compute_combat_terminal(
					state.combat_result, state.player.hp, state.player.max_hp
				)
				agent.combat_q.update_terminal(last_state_key, last_action, terminal)
				last_state_key = ""

	run.player_hp = state.player.hp
	return state.combat_result == "victory"

static func _make_result(outcome: String, layer: int, transitions: Array, run: RunData) -> Dictionary:
	var names: Array[String] = []
	for card in run.deck:
		if not names.has(card.data.card_name):
			names.append(card.data.card_name)
	return {
		"outcome": outcome,
		"layer_reached": layer,
		"deckbuild_transitions": transitions,
		"deck_cards": names,
	}
