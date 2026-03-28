extends GutTest

# Balance tests run 1000 simulated runs with random AI.
# Range assertions are intentionally wide — failures indicate balance problems, not bugs.

var _stats: Dictionary = {}

func before_all() -> void:
	# Run simulation once, share results across all tests
	_stats = RunSimulator.simulate_batch(1000, 42)

# --- T1: Overall Win Rate ---

func test_T1_1_win_rate():
	var rate = _stats["win_rate"] * 100
	gut.p("Win rate: %.1f%% (%d/%d)" % [rate, _stats["wins"], _stats["total"]])
	assert_true(rate >= 3 and rate <= 15,
		"Win rate should be 3-15%%, got %.1f%%" % rate)

# --- T2: Survival Curve ---

func test_T2_1_reach_layer_3():
	var deaths_before_3 := 0
	for layer in _stats["deaths_by_layer"]:
		if layer < 3:
			deaths_before_3 += _stats["deaths_by_layer"][layer]
	var survived = (1.0 - float(deaths_before_3) / _stats["total"]) * 100
	gut.p("Survived to layer 3: %.1f%%" % survived)
	assert_true(survived >= 70 and survived <= 100,
		"70-100%% should reach layer 3, got %.1f%%" % survived)

func test_T2_2_reach_layer_6():
	var deaths_before_6 := 0
	for layer in _stats["deaths_by_layer"]:
		if layer < 6:
			deaths_before_6 += _stats["deaths_by_layer"][layer]
	var survived = (1.0 - float(deaths_before_6) / _stats["total"]) * 100
	gut.p("Survived to layer 6: %.1f%%" % survived)
	assert_true(survived >= 40 and survived <= 65,
		"40-65%% should reach layer 6, got %.1f%%" % survived)

func test_T2_3_reach_layer_9():
	var deaths_before_9 := 0
	for layer in _stats["deaths_by_layer"]:
		if layer < 9:
			deaths_before_9 += _stats["deaths_by_layer"][layer]
	var survived = (1.0 - float(deaths_before_9) / _stats["total"]) * 100
	gut.p("Survived to layer 9: %.1f%%" % survived)
	assert_true(survived >= 12 and survived <= 35,
		"12-35%% should reach layer 9, got %.1f%%" % survived)

func test_T2_4_reach_layer_10():
	var total_reached = _stats["reached_boss"]
	var rate = float(total_reached) / _stats["total"] * 100
	gut.p("Reached boss: %.1f%% (%d)" % [rate, total_reached])
	assert_true(rate >= 8 and rate <= 30,
		"8-30%% should reach boss, got %.1f%%" % rate)

# --- T3: Average Run Depth ---

func test_T3_1_avg_depth():
	var avg = _stats["avg_depth"]
	gut.p("Average death layer: %.1f" % avg)
	assert_true(avg >= 5 and avg <= 7,
		"Mean death layer should be 5-7, got %.1f" % avg)

# --- T4: Boss Kill Rate ---

func test_T4_1_boss_kill_rate():
	var rate = _stats["boss_kill_rate"] * 100
	gut.p("Boss kill rate (given reaching boss): %.1f%%" % rate)
	assert_true(rate >= 30 and rate <= 50,
		"Boss kill rate should be 30-50%%, got %.1f%%" % rate)

# --- T5: Death Distribution ---

func test_T5_1_elite_layer_deaths():
	# Elite layers (3,6,8) should have higher death counts than adjacent layers
	var deaths = _stats["deaths_by_layer"]
	var elite_deaths := 0
	for layer in [3, 6, 8]:
		elite_deaths += deaths.get(layer, 0)
	var non_elite_adjacent := 0
	for layer in [2, 4, 5, 7]:
		non_elite_adjacent += deaths.get(layer, 0)
	gut.p("Elite layer deaths: %d, Adjacent non-elite: %d" % [elite_deaths, non_elite_adjacent])
	assert_true(elite_deaths > non_elite_adjacent,
		"Elite layers should have more deaths than adjacent non-elite layers")
