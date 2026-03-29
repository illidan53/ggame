extends GutTest

# --- T1: State Encoding ---

func test_T1_1_combat_state_encoding_format():
	var state = _make_combat_state(60, 80, 3, 0)
	var key = QState.encode_combat(state)
	var parts = key.split("|")
	assert_eq(parts.size(), 9, "Combat state key should have 9 pipe-separated fields")

func test_T1_2_combat_state_hp_bucketing():
	var s1 = _make_combat_state(80, 80, 3, 0)
	assert_eq(QState.encode_combat(s1).split("|")[0], "3", "80/80 HP -> bucket 3")

	var s2 = _make_combat_state(20, 80, 3, 0)
	assert_eq(QState.encode_combat(s2).split("|")[0], "1", "20/80 HP -> bucket 1")

	var s3 = _make_combat_state(10, 80, 3, 0)
	assert_eq(QState.encode_combat(s3).split("|")[0], "0", "10/80 HP -> bucket 0")

func test_T1_3_deckbuild_state_encoding():
	var run = RunData.new()
	run.player_hp = 60
	run.player_max_hp = 80
	run.current_layer = 5
	var strike = load("res://resources/cards/strike.tres") as CardData
	var defend = load("res://resources/cards/defend.tres") as CardData
	run.deck = [] as Array[CardInstance]
	for i in 8:
		run.deck.append(CardInstance.new(strike))
	for i in 7:
		run.deck.append(CardInstance.new(defend))

	var parts = QState.encode_deckbuild(run).split("|")
	assert_eq(parts.size(), 5, "Deckbuild key should have 5 fields")
	assert_eq(parts[0], "1", "15 cards -> deck_size_bucket 1")
	assert_eq(parts[4], "1", "Layer 5 -> floor_bucket 1")

func test_T1_4_encoding_determinism():
	var state = _make_combat_state(40, 80, 2, 5)
	assert_eq(QState.encode_combat(state), QState.encode_combat(state), "Same input -> same key")

# --- T2: Q-Table ---

func test_T2_1_default_q_value():
	var qt = QTable.new()
	assert_eq(qt.get_q("x", "y"), 0.0, "Unseen state-action returns 0.0")

func test_T2_2_single_update():
	var qt = QTable.new()
	qt.alpha = 0.1
	qt.update_terminal("s", "a", 1.0)
	assert_almost_eq(qt.get_q("s", "a"), 0.1, 0.001, "Terminal update: 0 + 0.1*(1-0) = 0.1")

func test_T2_3_best_action():
	var qt = QTable.new()
	qt.update_terminal("s", "Strike", 5.0)
	qt.update_terminal("s", "Defend", 8.0)
	var available: Array[String] = ["Strike", "Defend"]
	assert_eq(qt.get_best_action("s", available), "Defend", "Higher Q should be chosen")

func test_T2_4_save_load_roundtrip():
	var qt = QTable.new()
	qt.update_terminal("s1", "a1", 5.0)
	qt.update_terminal("s2", "a2", -3.0)
	var qt2 = QTable.from_dict(qt.to_dict())
	assert_almost_eq(qt2.get_q("s1", "a1"), qt.get_q("s1", "a1"), 0.001)
	assert_almost_eq(qt2.get_q("s2", "a2"), qt.get_q("s2", "a2"), 0.001)

func test_T2_5_visit_counting():
	var qt = QTable.new()
	qt.update_terminal("s", "a", 1.0)
	qt.update_terminal("s", "a", 1.0)
	qt.update_terminal("s", "a", 1.0)
	assert_eq(qt.get_visits("s", "a"), 3, "3 updates -> 3 visits")

# --- T3: Agent ---

func test_T3_1_epsilon_zero_exploits():
	var agent = QAgent.new()
	agent.epsilon = 0.0
	var state = _make_combat_state(60, 80, 3, 0)
	var key = QState.encode_combat(state)
	agent.combat_q.update_terminal(key, "Bash", 10.0)
	agent.combat_q.update_terminal(key, "Strike", 1.0)
	agent.combat_q.update_terminal(key, "end_turn", -1.0)

	var potions: Array[String] = []
	var d = agent.choose_combat_action(state, potions)
	if d["type"] == "play_card":
		assert_eq(d["card_name"], "Bash", "Epsilon=0 should exploit highest Q")

func test_T3_2_epsilon_one_explores():
	var counts := {}
	var available: Array[String] = ["A", "B", "C", "D"]
	var rng = RandomNumberGenerator.new()
	for i in 200:
		rng.seed = i
		var chosen = available[rng.randi_range(0, available.size() - 1)]
		counts[chosen] = counts.get(chosen, 0) + 1
	for a in available:
		assert_true(counts.get(a, 0) > 0, "All actions should appear with epsilon=1")

func test_T3_3_epsilon_decay():
	var agent = QAgent.new()
	agent.epsilon = 1.0
	agent.epsilon_decay = 0.9995
	agent.decay_epsilon()
	assert_almost_eq(agent.epsilon, 0.9995, 0.0001)

func test_T3_4_card_pick_valid_index():
	var agent = QAgent.new()
	agent.epsilon = 1.0
	var run = RunData.create_new(42)
	var offered: Array[CardData] = [
		load("res://resources/cards/strike.tres"),
		load("res://resources/cards/defend.tres"),
		load("res://resources/cards/bash.tres"),
	]
	var idx = agent.choose_card_pick(offered, run)
	assert_true(idx >= -1 and idx <= 2, "Pick index should be -1..2, got %d" % idx)

# --- T4: Rewards ---

func test_T4_1_victory_reward_positive():
	assert_true(QAgent.compute_combat_terminal("victory", 50, 80) > 0)

func test_T4_2_defeat_reward_negative():
	assert_true(QAgent.compute_combat_terminal("defeat", 0, 80) < 0)

func test_T4_3_run_victory_beats_defeat():
	assert_true(QAgent.compute_run_terminal("victory", 10) > QAgent.compute_run_terminal("defeat", 5))

# --- T5: Integration ---

func test_T5_1_single_run_completes():
	var agent = QAgent.new()
	var result = QRunSimulator.train(1, agent, 42)
	assert_eq(result["total_runs"], 1)

func test_T5_2_q_table_populated():
	var agent = QAgent.new()
	QRunSimulator.train(10, agent, 42)
	assert_true(agent.combat_q.state_count() > 0, "Combat Q-table should have entries")

func test_T5_3_trained_agent_not_worse_than_random():
	var agent = QAgent.new()
	QRunSimulator.train(500, agent, 42)
	var trained = QRunSimulator.evaluate(200, agent, 99999)
	var random = RunSimulator.simulate_batch(200, 99999)
	gut.p("Trained: %.1f%%, Random: %.1f%%" % [trained["win_rate"] * 100, random["win_rate"] * 100])
	assert_true(trained["win_rate"] >= random["win_rate"] - 0.05,
		"Trained (%.1f%%) should not be much worse than random (%.1f%%)" % [
			trained["win_rate"] * 100, random["win_rate"] * 100])

# --- T6: Balance Runner ---

func test_T6_1_random_report_has_metrics():
	var report = BalanceRunner.run_random(100, 42)
	assert_eq(report["strategy"], "random")
	assert_true(report["metrics"].has("win_rate"))
	assert_true(report["metrics"].has("survive_act1"))

func test_T6_2_balance_config_check():
	var metrics = {"win_rate": 0.03, "survive_act1": 0.05, "survive_act2": 0.01,
		"reach_boss": 0.005, "boss_kill_rate": 0.50, "avg_death_layer": 6.0}
	var check = BalanceConfig.check_expectations("random", metrics)
	assert_true(check["passed"], "All-in-range metrics should pass")

# --- Helpers ---

func _make_combat_state(hp: int, max_hp: int, energy: int, block: int) -> CombatState:
	var state = CombatState.new()
	state.player = Combatant.new()
	state.player.hp = hp
	state.player.max_hp = max_hp
	state.player.energy = energy
	state.player.block = block
	state.player.is_player = true

	var enemy = Combatant.new()
	enemy.hp = 18
	enemy.max_hp = 18
	enemy.enemy_data = load("res://resources/enemies/goblin.tres") as EnemyData
	state.enemies.append(enemy)

	state.hand.append(CardInstance.new(load("res://resources/cards/strike.tres")))
	state.hand.append(CardInstance.new(load("res://resources/cards/defend.tres")))
	state.hand.append(CardInstance.new(load("res://resources/cards/bash.tres")))
	return state
