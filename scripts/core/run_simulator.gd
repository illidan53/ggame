class_name RunSimulator
extends RefCounted

## Simulate a single full run with random AI. Returns result dictionary.
static func simulate_run(seed_value: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value

	# Setup run
	var run = RunData.create_new(seed_value)
	var card_pool = _load_card_pool()

	# Traverse map layers 0-9
	var current_node_idx := rng.randi_range(0, run.map.layers[0].size() - 1)
	run.current_layer = 0
	run.current_node = current_node_idx

	for layer_idx in 10:
		run.current_layer = layer_idx
		var node = run.map.layers[layer_idx][run.current_node]

		match node.node_type:
			"combat", "elite", "boss":
				var enemies = _get_enemies_for_node_at_layer(node.node_type, layer_idx, rng)
				var survived = _simulate_combat(run, enemies, rng)
				if not survived:
					return {"outcome": "defeat", "death_layer": layer_idx + 1}
				# Rewards
				run.gold += RewardGenerator.roll_gold(node.node_type, rng.randi())
				if rng.randf() < 0.5 and not card_pool.is_empty():
					var rewards = RewardGenerator.roll_card_rewards(card_pool, node.node_type, rng.randi())
					if not rewards.is_empty():
						var pick = rewards[rng.randi_range(0, rewards.size() - 1)]
						var card = CardInstance.new(pick)
						card.instance_id = rng.randi()
						run.deck.append(card)
				if node.node_type == "elite":
					var available = RelicSystem.get_available_relics(EventSystem.ALL_RELICS, run.relics)
					if not available.is_empty():
						run.relics.append(available[rng.randi_range(0, available.size() - 1)])

			"shop":
				if rng.randf() < 0.5 and run.gold >= 30:
					# Buy random affordable card
					var prices = ShopGenerator.generate_prices(rng.randi())
					var affordable_rarity = ""
					if run.gold >= prices["Common"]:
						affordable_rarity = "Common"
					if run.gold >= prices["Uncommon"] and rng.randf() < 0.3:
						affordable_rarity = "Uncommon"
					if affordable_rarity != "" and not card_pool.is_empty():
						var filtered = card_pool.filter(func(c): return c.rarity == affordable_rarity)
						if not filtered.is_empty():
							var pick = filtered[rng.randi_range(0, filtered.size() - 1)]
							run.gold -= prices[affordable_rarity]
							var card = CardInstance.new(pick)
							card.instance_id = rng.randi()
							run.deck.append(card)

			"rest":
				if rng.randf() < 0.5:
					run.player_hp = RestSite.rest(run.player_hp, run.player_max_hp)
				else:
					# Upgrade random card
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
					return {"outcome": "defeat", "death_layer": layer_idx + 1}

		# Navigate to next layer
		if layer_idx < 9:
			var source = run.map.layers[layer_idx][run.current_node]
			if source.connections.is_empty():
				break
			run.current_node = source.connections[rng.randi_range(0, source.connections.size() - 1)]

	return {"outcome": "victory", "death_layer": -1}

## Simulate a batch of runs and return aggregate stats
static func simulate_batch(count: int, base_seed: int = 0) -> Dictionary:
	var wins := 0
	var deaths_by_layer := {}
	var total_depth := 0
	var failed_runs := 0
	var reached_boss := 0
	var boss_wins := 0

	for i in count:
		var seed_val = base_seed + i * 7919  # Prime spacing for variety
		var result = simulate_run(seed_val)

		if result["outcome"] == "victory":
			wins += 1
			boss_wins += 1
			reached_boss += 1
		else:
			var dl = result["death_layer"]
			deaths_by_layer[dl] = deaths_by_layer.get(dl, 0) + 1
			total_depth += dl
			failed_runs += 1
			if dl == 10:
				reached_boss += 1  # Died at boss

	return {
		"total": count,
		"wins": wins,
		"win_rate": float(wins) / count,
		"deaths_by_layer": deaths_by_layer,
		"avg_depth": float(total_depth) / maxi(failed_runs, 1),
		"reached_boss": reached_boss,
		"boss_wins": boss_wins,
		"boss_kill_rate": float(boss_wins) / maxi(reached_boss, 1),
	}

## Simulate a single combat encounter. Returns true if player survived.
static func _simulate_combat(run: RunData, enemy_datas: Array[EnemyData], rng: RandomNumberGenerator) -> bool:
	var deck_copy: Array[CardInstance] = []
	for card in run.deck:
		var c = CardInstance.new(card.data)
		c.instance_id = card.instance_id
		deck_copy.append(c)

	var max_energy = RelicSystem.get_max_energy(3, run.relics)
	var state = BattleManager.create_combat(run.player_hp, max_energy, deck_copy, enemy_datas)
	RelicSystem.apply_combat_start(state, run.relics)

	var draw_count = RelicSystem.get_draw_count(5, run.relics)
	var max_turns := 50  # Safety limit

	for turn in max_turns:
		if state.is_combat_over:
			break
		BattleManager.begin_player_turn(state, draw_count)

		# Random potion use (30% chance)
		if not run.potions.is_empty() and rng.randf() < 0.3:
			var potion_idx = rng.randi_range(0, run.potions.size() - 1)
			PotionSystem.use_and_remove(run.potions, potion_idx, state)

		# Play affordable cards randomly
		var max_plays := 20  # Safety limit per turn
		for _play in max_plays:
			if state.hand.is_empty() or state.is_combat_over:
				break
			# Find affordable cards
			var affordable: Array[int] = []
			for i in state.hand.size():
				var card = state.hand[i]
				var cost = card.data.cost
				if cost == -1:
					cost = 0  # X-cost always playable
				if state.player.energy >= cost:
					affordable.append(i)
			if affordable.is_empty():
				break
			var card_idx = affordable[rng.randi_range(0, affordable.size() - 1)]
			var card = state.hand[card_idx]
			var target := -1
			if card.data.target_mode == "single" and card.data.base_damage > 0:
				# Pick random alive enemy
				var alive: Array[int] = []
				for e in state.enemies.size():
					if state.enemies[e].is_alive():
						alive.append(e)
				if alive.is_empty():
					break
				target = alive[rng.randi_range(0, alive.size() - 1)]
			BattleManager.play_card(state, card_idx, target)
			if state.is_combat_over:
				break

		if not state.is_combat_over:
			BattleManager.end_turn(state)

	run.player_hp = state.player.hp
	return state.combat_result == "victory"

static func _get_enemies_for_node_at_layer(node_type: String, layer: int, rng: RandomNumberGenerator) -> Array[EnemyData]:
	var enemies: Array[EnemyData] = []
	match node_type:
		"combat":
			var pool: Array[EnemyData] = [
				load("res://resources/enemies/goblin.tres"),
				load("res://resources/enemies/bat_swarm.tres"),
			]
			if layer >= 3:
				pool.append(load("res://resources/enemies/skeleton.tres"))
			# 2 enemies layer 0, 2-3 for layers 1+ (40% chance of 3rd)
			var count := 2
			if layer >= 1:
				count = 2 + (1 if rng.randf() < 0.4 else 0)
			for i in count:
				enemies.append(pool[rng.randi_range(0, pool.size() - 1)])
		"elite":
			enemies.append(load("res://resources/enemies/dark_knight.tres") if rng.randf() < 0.5 else load("res://resources/enemies/fire_elemental.tres"))
			enemies.append(load("res://resources/enemies/skeleton.tres"))
		"boss":
			enemies.append(load("res://resources/enemies/shadow_lord.tres"))
	return enemies

static func _load_card_pool() -> Array[CardData]:
	var pool: Array[CardData] = []
	var dir = DirAccess.open("res://resources/cards/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var card = load("res://resources/cards/" + file_name) as CardData
				if card and card.card_name not in ["Strike", "Defend", "Bash"]:
					pool.append(card)
			file_name = dir.get_next()
	return pool
