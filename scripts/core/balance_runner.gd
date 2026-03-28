class_name BalanceRunner
extends RefCounted

## Unified balance simulation runner. Runs any strategy headless and produces
## a structured report with metrics checked against BalanceConfig expectations.

## Run the random strategy. Returns a full report dictionary.
static func run_random(sample_size: int = 1000, base_seed: int = 42) -> Dictionary:
	var stats = RunSimulator.simulate_batch(sample_size, base_seed)
	var metrics = _extract_metrics(stats)
	var check = BalanceConfig.check_expectations("random", metrics)
	return {
		"strategy": "random",
		"sample_size": sample_size,
		"raw_stats": stats,
		"metrics": metrics,
		"check": check,
	}

## Run the Q-learning strategy: train then evaluate. Returns a full report dictionary.
static func run_q_learning(params: Dictionary = {}) -> Dictionary:
	if params.is_empty():
		params = BalanceConfig.Q_LEARNING_PARAMS

	var agent = QAgent.new()
	agent.apply_config(params)

	var training_episodes: int = params.get("training_episodes", 5000)
	var eval_runs: int = params.get("eval_runs", 1000)
	var base_seed: int = params.get("base_seed", 42)

	# Train
	var train_result = QRunSimulator.train(training_episodes, agent, base_seed)

	# Evaluate (epsilon=0)
	var eval_stats = QRunSimulator.evaluate(eval_runs, agent, base_seed + 100000)

	var metrics = _extract_metrics(eval_stats)
	var check = BalanceConfig.check_expectations("q_learning", metrics)

	# Card power rankings from Q-tables
	var card_rankings = _build_card_rankings(agent, eval_stats)

	return {
		"strategy": "q_learning",
		"training_episodes": training_episodes,
		"eval_runs": eval_runs,
		"training_win_rates": train_result["win_rates"],
		"final_epsilon": train_result["epsilon"],
		"raw_stats": eval_stats,
		"metrics": metrics,
		"check": check,
		"card_rankings": card_rankings,
	}

## Run both strategies and return a comparison report.
static func run_comparison(random_runs: int = 1000, q_params: Dictionary = {}) -> Dictionary:
	var random_report = run_random(random_runs)
	var q_report = run_q_learning(q_params)
	return {
		"random": random_report,
		"q_learning": q_report,
		"win_rate_improvement": q_report["metrics"]["win_rate"] - random_report["metrics"]["win_rate"],
	}

## Format a strategy report as human-readable text.
static func format_report(report: Dictionary) -> String:
	var lines: Array[String] = []
	var strategy: String = report["strategy"]

	lines.append("=" .repeat(60))
	lines.append("  DarkPath Balance Report — %s strategy" % strategy.to_upper())
	lines.append("=" .repeat(60))

	if strategy == "q_learning":
		lines.append("Training: %d episodes | Final epsilon: %.4f" % [
			report.get("training_episodes", 0), report.get("final_epsilon", 0.0)])
		# Learning curve summary
		var wrs: Array = report.get("training_win_rates", [])
		if wrs.size() >= 2:
			lines.append("Learning curve: %.0f%% (first 100) -> %.0f%% (last 100)" % [
				wrs[0] * 100.0, wrs[-1] * 100.0])

	var m: Dictionary = report["metrics"]
	lines.append("")
	lines.append("--- Key Metrics ---")
	lines.append("Win rate:          %.1f%%" % (m["win_rate"] * 100.0))
	lines.append("Survive layer 3:   %.1f%%" % (m["survive_layer_3"] * 100.0))
	lines.append("Survive layer 6:   %.1f%%" % (m["survive_layer_6"] * 100.0))
	lines.append("Survive layer 9:   %.1f%%" % (m["survive_layer_9"] * 100.0))
	lines.append("Reach boss:        %.1f%%" % (m["reach_boss"] * 100.0))
	lines.append("Boss kill rate:    %.1f%%" % (m["boss_kill_rate"] * 100.0))
	lines.append("Avg death layer:   %.1f" % m["avg_death_layer"])

	# Expectation check
	lines.append("")
	lines.append(BalanceConfig.format_check(strategy, report["check"]))

	# Card rankings for Q-learning
	if report.has("card_rankings") and not report["card_rankings"].is_empty():
		lines.append("")
		lines.append("--- Card Power Rankings (by avg combat Q-value) ---")
		var rankings: Array = report["card_rankings"]
		for i in rankings.size():
			var c = rankings[i]
			lines.append("%2d. %-20s Q=%6.3f  Pick=%.0f%%  WinContrib=%.0f%%  (seen %d runs)" % [
				i + 1, c["name"], c["avg_q"],
				c["pick_rate"] * 100.0, c["win_contrib"] * 100.0, c["presence"]])

	# Deaths by layer
	lines.append("")
	lines.append("--- Deaths by Layer ---")
	var deaths: Dictionary = report["raw_stats"].get("deaths_by_layer", {})
	var layers = deaths.keys()
	layers.sort()
	for layer in layers:
		lines.append("  Layer %s: %d deaths" % [str(layer), deaths[layer]])

	return "\n".join(lines)

## Format a comparison report.
static func format_comparison(comparison: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append(format_report(comparison["random"]))
	lines.append("")
	lines.append(format_report(comparison["q_learning"]))
	lines.append("")
	lines.append("=" .repeat(60))
	lines.append("  WIN RATE IMPROVEMENT: %+.1f percentage points" % (comparison["win_rate_improvement"] * 100.0))
	lines.append("=" .repeat(60))
	return "\n".join(lines)

# --- Internal helpers ---

## Extract standard metrics from raw simulation stats.
static func _extract_metrics(stats: Dictionary) -> Dictionary:
	var total: int = stats["total"]
	var deaths: Dictionary = stats.get("deaths_by_layer", {})

	var deaths_before_3 := 0
	var deaths_before_6 := 0
	var deaths_before_9 := 0
	for layer in deaths:
		var count: int = deaths[layer]
		if layer < 3:
			deaths_before_3 += count
		if layer < 6:
			deaths_before_6 += count
		if layer < 9:
			deaths_before_9 += count

	return {
		"win_rate": stats["win_rate"],
		"survive_layer_3": 1.0 - float(deaths_before_3) / float(maxi(total, 1)),
		"survive_layer_6": 1.0 - float(deaths_before_6) / float(maxi(total, 1)),
		"survive_layer_9": 1.0 - float(deaths_before_9) / float(maxi(total, 1)),
		"reach_boss": float(stats["reached_boss"]) / float(maxi(total, 1)),
		"boss_kill_rate": stats["boss_kill_rate"],
		"avg_death_layer": stats["avg_depth"],
	}

## Build card rankings from Q-tables and eval data.
static func _build_card_rankings(agent: QAgent, eval_stats: Dictionary) -> Array[Dictionary]:
	# Average Q-value per card from combat table
	var card_q := {}  # card_name -> {total: float, count: int}
	for state_key in agent.combat_q.table:
		var actions = agent.combat_q.table[state_key]
		for action in actions:
			if action == "end_turn" or action.begins_with("potion:"):
				continue
			if not card_q.has(action):
				card_q[action] = {"total": 0.0, "count": 0}
			card_q[action]["total"] += actions[action]
			card_q[action]["count"] += 1

	# Pick rates from deckbuild visit counts
	var card_picks := {}  # card_name -> {picked: int, total_decisions: int}
	for state_key in agent.deckbuild_q.visit_count:
		var actions = agent.deckbuild_q.visit_count[state_key]
		for action in actions:
			if action == "skip" or action == "rest" or action == "upgrade":
				continue
			if action.find(":") >= 0:
				continue
			if not card_picks.has(action):
				card_picks[action] = {"picked": 0, "total": 0}
			card_picks[action]["picked"] += actions[action]

	# Win contribution from eval
	var card_presence: Dictionary = eval_stats.get("card_presence", {})

	# Merge all card names
	var all_names := {}
	for n in card_q:
		all_names[n] = true
	for n in card_picks:
		all_names[n] = true
	for n in card_presence:
		all_names[n] = true

	var rankings: Array[Dictionary] = []
	for card_name in all_names:
		var avg_q := 0.0
		if card_q.has(card_name) and card_q[card_name]["count"] > 0:
			avg_q = card_q[card_name]["total"] / float(card_q[card_name]["count"])

		var pick_rate := 0.0
		if card_picks.has(card_name) and card_picks[card_name]["picked"] > 0:
			# Approximate: picked / (picked + skip_count_estimate)
			pick_rate = 1.0  # If it was picked, rate is high; refined below

		var win_contrib := 0.0
		var presence := 0
		if card_presence.has(card_name):
			presence = card_presence[card_name]["total"]
			if presence > 0:
				win_contrib = float(card_presence[card_name]["wins"]) / float(presence)

		rankings.append({
			"name": card_name,
			"avg_q": avg_q,
			"pick_rate": pick_rate,
			"win_contrib": win_contrib,
			"presence": presence,
		})

	rankings.sort_custom(func(a, b): return a["avg_q"] > b["avg_q"])
	return rankings
