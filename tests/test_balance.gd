extends GutTest

# Balance tests run 1000 simulated runs with random AI across 3 acts (30 global layers).
# Range assertions are intentionally wide — failures indicate balance problems, not bugs.
# Global layer numbering: Act 1 = 1-10, Act 2 = 11-20, Act 3 = 21-30.

var _stats: Dictionary = {}

func before_all() -> void:
	_stats = RunSimulator.simulate_batch(1000, 42)

# --- T1: Overall Win Rate (all 3 acts) ---

func test_T1_1_win_rate():
	var rate = _stats["win_rate"] * 100
	gut.p("Win rate: %.1f%% (%d/%d)" % [rate, _stats["wins"], _stats["total"]])
	assert_true(rate >= 0 and rate <= 10,
		"Win rate should be 0-10%% across 3 acts, got %.1f%%" % rate)

# --- T2: Survival Curve (across acts) ---

func test_T2_1_survive_act1_layer3():
	var deaths_before := 0
	for layer in _stats["deaths_by_layer"]:
		if layer < 3:
			deaths_before += _stats["deaths_by_layer"][layer]
	var survived = (1.0 - float(deaths_before) / _stats["total"]) * 100
	gut.p("Survived to Act 1 Layer 3: %.1f%%" % survived)
	assert_true(survived >= 60 and survived <= 100,
		"60-100%% should reach Act 1 Layer 3, got %.1f%%" % survived)

func test_T2_2_survive_act1():
	# Survive all of Act 1 (layers 1-10)
	var deaths_in_act1 := 0
	for layer in _stats["deaths_by_layer"]:
		if layer <= 10:
			deaths_in_act1 += _stats["deaths_by_layer"][layer]
	var survived = (1.0 - float(deaths_in_act1) / _stats["total"]) * 100
	gut.p("Survived Act 1: %.1f%%" % survived)
	assert_true(survived >= 3 and survived <= 50,
		"3-50%% should survive Act 1, got %.1f%%" % survived)

func test_T2_3_survive_act2():
	# Survive Acts 1+2 (layers 1-20)
	var deaths_before_21 := 0
	for layer in _stats["deaths_by_layer"]:
		if layer <= 20:
			deaths_before_21 += _stats["deaths_by_layer"][layer]
	var survived = (1.0 - float(deaths_before_21) / _stats["total"]) * 100
	gut.p("Survived Acts 1+2: %.1f%%" % survived)
	assert_true(survived >= 0 and survived <= 30,
		"0-30%% should survive Acts 1+2, got %.1f%%" % survived)

func test_T2_4_reach_final_boss():
	var total_reached = _stats["reached_boss"]
	var rate = float(total_reached) / _stats["total"] * 100
	gut.p("Reached final boss: %.1f%% (%d)" % [rate, total_reached])
	assert_true(rate >= 0 and rate <= 20,
		"0-20%% should reach final boss, got %.1f%%" % rate)

# --- T3: Average Run Depth ---

func test_T3_1_avg_depth():
	var avg = _stats["avg_depth"]
	gut.p("Average death layer: %.1f (out of 30)" % avg)
	assert_true(avg >= 3 and avg <= 20,
		"Mean death layer should be 3-20, got %.1f" % avg)

# --- T4: Boss Kill Rate ---

func test_T4_1_boss_kill_rate():
	var rate = _stats["boss_kill_rate"] * 100
	gut.p("Final boss kill rate (given reaching): %.1f%%" % rate)
	# Very few reach the final boss with random AI, so wide range
	assert_true(rate >= 0 and rate <= 80,
		"Final boss kill rate should be 0-80%%, got %.1f%%" % rate)

# --- T5: Death Distribution ---

func test_T5_1_act1_elite_deaths():
	# Act 1 elite layers (3,6,8) should have more deaths than adjacent layers
	var deaths = _stats["deaths_by_layer"]
	var elite_deaths := 0
	for layer in [3, 6, 8]:
		elite_deaths += deaths.get(layer, 0)
	var non_elite_adjacent := 0
	for layer in [2, 4, 5, 7]:
		non_elite_adjacent += deaths.get(layer, 0)
	gut.p("Act 1 elite deaths: %d, adjacent: %d" % [elite_deaths, non_elite_adjacent])
	assert_true(elite_deaths >= non_elite_adjacent,
		"Elite layers should have >= deaths than adjacent layers")
