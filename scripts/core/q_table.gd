class_name QTable
extends RefCounted

## Tabular Q-value storage with Bellman update, visit tracking, and JSON persistence.

var table: Dictionary = {}        # {state_key: {action_key: float}}
var visit_count: Dictionary = {}  # {state_key: {action_key: int}}
var alpha: float = 0.1            # Learning rate
var gamma: float = 0.95           # Discount factor

## Get Q-value for a state-action pair. Returns 0.0 if unseen.
func get_q(state: String, action: String) -> float:
	if table.has(state) and table[state].has(action):
		return table[state][action]
	return 0.0

## Get the best action from available actions. Breaks ties randomly.
func get_best_action(state: String, available_actions: Array[String], rng: RandomNumberGenerator = null) -> String:
	if available_actions.is_empty():
		return ""
	var best_val := -INF
	var best_actions: Array[String] = []
	for action in available_actions:
		var q = get_q(state, action)
		if q > best_val:
			best_val = q
			best_actions = [action]
		elif q == best_val:
			best_actions.append(action)
	if best_actions.size() == 1:
		return best_actions[0]
	if rng != null:
		return best_actions[rng.randi_range(0, best_actions.size() - 1)]
	return best_actions[randi_range(0, best_actions.size() - 1)]

## Standard Q-learning Bellman update.
func update(state: String, action: String, reward: float, next_state: String, next_actions: Array[String]) -> void:
	var current_q = get_q(state, action)
	var max_next_q := 0.0
	for a in next_actions:
		max_next_q = maxf(max_next_q, get_q(next_state, a))
	var new_q = current_q + alpha * (reward + gamma * max_next_q - current_q)
	_set_q(state, action, new_q)
	_increment_visit(state, action)

## Terminal update (no next state).
func update_terminal(state: String, action: String, reward: float) -> void:
	var current_q = get_q(state, action)
	var new_q = current_q + alpha * (reward - current_q)
	_set_q(state, action, new_q)
	_increment_visit(state, action)

## Get action rankings for a state, sorted by Q-value descending.
func get_action_rankings(state: String) -> Array[Dictionary]:
	var rankings: Array[Dictionary] = []
	if not table.has(state):
		return rankings
	for action in table[state]:
		var visits = 0
		if visit_count.has(state) and visit_count[state].has(action):
			visits = visit_count[state][action]
		rankings.append({"action": action, "q_value": table[state][action], "visits": visits})
	rankings.sort_custom(func(a, b): return a["q_value"] > b["q_value"])
	return rankings

## Get visit count for a state-action pair.
func get_visits(state: String, action: String) -> int:
	if visit_count.has(state) and visit_count[state].has(action):
		return visit_count[state][action]
	return 0

## Number of unique states in the table.
func state_count() -> int:
	return table.size()

## Serialize to Dictionary for JSON storage.
func to_dict() -> Dictionary:
	return {"table": table, "visit_count": visit_count, "alpha": alpha, "gamma": gamma}

## Deserialize from Dictionary.
static func from_dict(data: Dictionary) -> QTable:
	var qt = QTable.new()
	qt.table = data.get("table", {})
	qt.visit_count = data.get("visit_count", {})
	qt.alpha = data.get("alpha", 0.1)
	qt.gamma = data.get("gamma", 0.95)
	return qt

## Save Q-table to a JSON file.
func save_to_file(path: String) -> void:
	var json_string = JSON.stringify(to_dict())
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()

## Load Q-table from a JSON file. Returns null if file missing or invalid.
static func load_from_file(path: String) -> QTable:
	if not FileAccess.file_exists(path):
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		return null
	var data = json.data
	if not data is Dictionary:
		return null
	return from_dict(data)

# --- Internal ---

func _set_q(state: String, action: String, value: float) -> void:
	if not table.has(state):
		table[state] = {}
	table[state][action] = value

func _increment_visit(state: String, action: String) -> void:
	if not visit_count.has(state):
		visit_count[state] = {}
	if not visit_count[state].has(action):
		visit_count[state][action] = 0
	visit_count[state][action] += 1
