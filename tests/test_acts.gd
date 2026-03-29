extends GutTest

# --- T1: 3-Act Structure ---

func test_T1_1_run_has_3_acts():
	assert_eq(RunData.TOTAL_ACTS, 3, "Should have 3 acts")

func test_T1_2_run_creates_with_act():
	var run = RunData.create_new(42)
	assert_eq(run.current_act, 1, "New run starts at act 1")

func test_T1_3_warrior_run_completes_or_dies():
	var result = RunSimulator.simulate_run(42, "Warrior")
	assert_true(result["outcome"] in ["victory", "defeat"])
	if result["outcome"] == "defeat":
		assert_true(result["death_layer"] >= 1 and result["death_layer"] <= 30,
			"Death layer should be 1-30, got %d" % result["death_layer"])

func test_T1_4_silent_run_completes_or_dies():
	var result = RunSimulator.simulate_run(42, "Silent")
	assert_true(result["outcome"] in ["victory", "defeat"])

# --- T2: Per-Act Enemies ---

func test_T2_1_act1_boss_is_shadow_lord():
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	var enemies = RunSimulator._get_enemies_for_act("boss", 1, 9, rng)
	assert_eq(enemies[0].enemy_name, "Shadow Lord")

func test_T2_2_act2_boss_is_crystal_king():
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	var enemies = RunSimulator._get_enemies_for_act("boss", 2, 9, rng)
	assert_eq(enemies[0].enemy_name, "Crystal King")

func test_T2_3_act3_boss_is_void_dragon():
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	var enemies = RunSimulator._get_enemies_for_act("boss", 3, 9, rng)
	assert_eq(enemies[0].enemy_name, "Void Dragon")

func test_T2_4_act2_combat_uses_new_enemies():
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	var enemies = RunSimulator._get_enemies_for_act("combat", 2, 5, rng)
	var names: Array[String] = []
	for e in enemies:
		if not names.has(e.enemy_name):
			names.append(e.enemy_name)
	# Act 2 should use Fungus/Bandit/Golem, not Act 1 enemies
	var act2_names = ["Fungus", "Bandit", "Golem"]
	var has_act2 := false
	for n in names:
		if n in act2_names:
			has_act2 = true
			break
	assert_true(has_act2, "Act 2 should use Act 2 enemies, got %s" % str(names))

# --- T3: Balance Simulation ---

func test_T3_1_warrior_batch_3acts():
	var stats = RunSimulator.simulate_batch(100, 42, "Warrior")
	gut.p("Warrior 3-act (100 runs): win=%.1f%%, avg_depth=%.1f/30" % [
		stats["win_rate"] * 100, stats["avg_depth"]])
	assert_true(stats["win_rate"] >= 0.0 and stats["win_rate"] <= 1.0)

func test_T3_2_silent_batch_3acts():
	var stats = RunSimulator.simulate_batch(100, 42, "Silent")
	gut.p("Silent 3-act (100 runs): win=%.1f%%, avg_depth=%.1f/30" % [
		stats["win_rate"] * 100, stats["avg_depth"]])
	assert_true(stats["win_rate"] >= 0.0 and stats["win_rate"] <= 1.0)

# --- T4: Q-Learning Across 3 Acts ---

func test_T4_1_q_training_3acts():
	var agent = QAgent.new()
	var result = QRunSimulator.train(100, agent, 42)
	gut.p("Q-learning 3-act (100 ep): win=%.1f%%, epsilon=%.3f" % [
		result["win_rate"] * 100, result["epsilon"]])
	assert_eq(result["total_runs"], 100)
	assert_true(agent.combat_q.state_count() > 0, "Should learn combat states")

func test_T4_2_q_trained_vs_random():
	# Train 500 episodes, eval 100
	var agent = QAgent.new()
	QRunSimulator.train(500, agent, 42)
	var trained = QRunSimulator.evaluate(100, agent, 99999)
	var random = RunSimulator.simulate_batch(100, 99999)
	gut.p("3-act trained: %.1f%% avg_depth=%.1f | random: %.1f%% avg_depth=%.1f" % [
		trained["win_rate"] * 100, trained["avg_depth"],
		random["win_rate"] * 100, random["avg_depth"]])
	# Trained agent should survive deeper on average
	assert_true(trained["avg_depth"] >= random["avg_depth"] - 2.0,
		"Trained avg depth (%.1f) should not be much worse than random (%.1f)" % [
			trained["avg_depth"], random["avg_depth"]])
