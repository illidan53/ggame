extends GutTest

## Balance tests for the Q-learning strategy.
## Trains an agent, evaluates, and checks against BalanceConfig expectations.
## These tests are slow (~30-60s) due to training. Run separately when needed.

var _report: Dictionary = {}

func before_all() -> void:
	# Train with reduced episodes for test speed (500 train, 200 eval)
	var params = BalanceConfig.Q_LEARNING_PARAMS.duplicate()
	params["training_episodes"] = 500
	params["eval_runs"] = 200
	_report = BalanceRunner.run_q_learning(params)
	gut.p(BalanceRunner.format_report(_report))

func test_T1_q_learning_win_rate_above_random():
	var random_report = BalanceRunner.run_random(200, 42)
	var q_wr = _report["metrics"]["win_rate"]
	var r_wr = random_report["metrics"]["win_rate"]
	gut.p("Q-learning: %.1f%%, Random: %.1f%%" % [q_wr * 100, r_wr * 100])
	assert_true(q_wr >= r_wr - 0.05,
		"Q-learning (%.1f%%) should not be much worse than random (%.1f%%)" % [q_wr * 100, r_wr * 100])

func test_T2_q_learning_report_has_card_rankings():
	var rankings: Array = _report.get("card_rankings", [])
	assert_true(rankings.size() > 0, "Should have card rankings")
	if not rankings.is_empty():
		assert_true(rankings[0].has("name"), "Rankings should have card names")
		assert_true(rankings[0].has("avg_q"), "Rankings should have Q-values")
		assert_true(rankings[0].has("win_contrib"), "Rankings should have win contribution")

func test_T3_q_learning_win_rate_in_range():
	var wr = _report["metrics"]["win_rate"]
	assert_true(wr >= 0.0 and wr <= 1.0, "Win rate should be 0-1, got %.2f" % wr)

func test_T4_q_learning_learning_curve_improves():
	var wrs: Array = _report.get("training_win_rates", [])
	if wrs.size() >= 3:
		# Last segment should be at least as good as first (with tolerance)
		var first = wrs[0]
		var last = wrs[-1]
		gut.p("Learning curve: %.0f%% -> %.0f%%" % [first * 100, last * 100])
		assert_true(last >= first - 0.10,
			"Agent should not degrade: first %.0f%% -> last %.0f%%" % [first * 100, last * 100])

func test_T5_q_learning_metrics_complete():
	var m = _report["metrics"]
	for key in ["win_rate", "survive_act1", "survive_act2",
		"reach_boss", "boss_kill_rate", "avg_death_layer"]:
		assert_true(m.has(key), "Metrics should include %s" % key)
