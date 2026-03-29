class_name BalanceConfig
extends RefCounted

## Central source of truth for balance expectations per strategy.
## Each strategy defines expected ranges for key metrics.
## Tests compare simulation results against these ranges.

## Expected ranges: {metric_name: [min, max]}
const STRATEGIES := {
	"random": {
		"win_rate":        [0.00, 0.10],    # 0-10% across 3 acts with random AI
		"survive_act1":    [0.02, 0.20],    # 2-20% survive Act 1
		"survive_act2":    [0.00, 0.10],    # 0-10% survive Acts 1+2
		"reach_boss":      [0.00, 0.10],    # 0-10% reach final boss
		"boss_kill_rate":  [0.00, 0.80],    # Wide range (few samples)
		"avg_death_layer": [3.0, 12.0],     # Mean death layer (out of 30)
	},
	"random_silent": {
		"win_rate":        [0.02, 0.20],    # Silent may differ from Warrior
		"survive_layer_3": [0.60, 0.95],    # Lower HP but better card draw
		"survive_layer_6": [0.30, 0.65],    # Poison helps mid-game
		"survive_layer_9": [0.10, 0.40],    # Fragile late-game
		"reach_boss":      [0.08, 0.35],    # Varies with poison scaling
		"boss_kill_rate":  [0.15, 0.60],    # Poison can scale well vs boss
		"avg_death_layer": [4.0, 8.0],      # Wide range initially
	},
	"q_learning": {
		"win_rate":        [0.05, 0.65],    # 5-65% (depends on training episodes)
		"survive_layer_3": [0.80, 1.00],    # Trained agent should survive early game
		"survive_layer_6": [0.50, 0.95],    # Better mid-game survival
		"survive_layer_9": [0.25, 0.75],    # Better late-game survival
		"reach_boss":      [0.20, 0.75],    # More boss encounters
		"boss_kill_rate":  [0.10, 0.80],    # Depends on training depth
		"avg_death_layer": [6.0, 9.5],      # Dies later on average
	},
}

## Training hyperparameters for Q-learning strategy
const Q_LEARNING_PARAMS := {
	"training_episodes": 5000,
	"eval_runs":         1000,
	"alpha":             0.1,     # Learning rate
	"gamma":             0.95,    # Discount factor
	"epsilon_start":     1.0,
	"epsilon_min":       0.05,
	"epsilon_decay":     0.9995,
	"base_seed":         42,
}

## Check if a result is within expected range for a strategy.
## Returns {passed: bool, details: Array[Dictionary]}
static func check_expectations(strategy: String, results: Dictionary) -> Dictionary:
	if not STRATEGIES.has(strategy):
		return {"passed": false, "details": [{"metric": "strategy", "error": "Unknown strategy: " + strategy}]}

	var expectations = STRATEGIES[strategy]
	var details: Array[Dictionary] = []
	var all_passed := true

	for metric in expectations:
		if not results.has(metric):
			continue
		var value = results[metric]
		var bounds = expectations[metric]
		var passed = value >= bounds[0] and value <= bounds[1]
		if not passed:
			all_passed = false
		details.append({
			"metric": metric,
			"value": value,
			"min": bounds[0],
			"max": bounds[1],
			"passed": passed,
		})

	return {"passed": all_passed, "details": details}

## Format a check result as a human-readable string.
static func format_check(strategy: String, check_result: Dictionary) -> String:
	var lines: Array[String] = []
	var status = "PASS" if check_result["passed"] else "FAIL"
	lines.append("=== Balance Check: %s strategy [%s] ===" % [strategy, status])
	for d in check_result["details"]:
		var mark = "OK" if d["passed"] else "XX"
		lines.append("  [%s] %s: %.2f  (expected %.2f - %.2f)" % [
			mark, d["metric"], d["value"], d["min"], d["max"]
		])
	return "\n".join(lines)
