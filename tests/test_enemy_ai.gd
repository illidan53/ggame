extends GutTest

# T6. Enemy AI (4 cases)

func _make_enemy(pattern: Array[Dictionary], hp: int = 20, alt_pattern: Array[Dictionary] = [] as Array[Dictionary], threshold: float = 0.0) -> Combatant:
	var data = EnemyData.new()
	data.enemy_name = "TestEnemy"
	data.hp = hp
	data.pattern = pattern
	data.alt_pattern = alt_pattern
	data.hp_threshold_percent = threshold

	var enemy = Combatant.new()
	enemy.hp = hp
	enemy.max_hp = hp
	enemy.enemy_data = data
	enemy.pattern_index = 0
	return enemy

func test_T6_1_pattern_cycles():
	# Pattern: [Attack(6), Defend(4)], 3 turns → Attack, Defend, Attack
	var pattern: Array[Dictionary] = [
		{"type": "attack", "value": 6},
		{"type": "defend", "value": 4}
	]
	var enemy = _make_enemy(pattern)

	# Turn 1
	var intent1 = EnemyAI.get_intent(enemy)
	assert_eq(intent1["type"], "attack")
	assert_eq(intent1["value"], 6)
	EnemyAI.advance_pattern(enemy)

	# Turn 2
	var intent2 = EnemyAI.get_intent(enemy)
	assert_eq(intent2["type"], "defend")
	assert_eq(intent2["value"], 4)
	EnemyAI.advance_pattern(enemy)

	# Turn 3 (cycles back)
	var intent3 = EnemyAI.get_intent(enemy)
	assert_eq(intent3["type"], "attack")
	assert_eq(intent3["value"], 6)

func test_T6_2_intent_display():
	# Enemy next action is Attack(8) → Intent returns {type: "attack", value: 8}
	var pattern: Array[Dictionary] = [{"type": "attack", "value": 8}]
	var enemy = _make_enemy(pattern)
	var intent = EnemyAI.get_intent(enemy)
	assert_eq(intent["type"], "attack")
	assert_eq(intent["value"], 8)

func test_T6_3_multi_enemy_independence():
	# 2 enemies with different patterns, each advances independently
	var pattern_a: Array[Dictionary] = [
		{"type": "attack", "value": 6},
		{"type": "defend", "value": 4}
	]
	var pattern_b: Array[Dictionary] = [
		{"type": "defend", "value": 5},
		{"type": "attack", "value": 10}
	]
	var enemy_a = _make_enemy(pattern_a)
	var enemy_b = _make_enemy(pattern_b)

	# Both start at index 0
	assert_eq(EnemyAI.get_intent(enemy_a)["type"], "attack")
	assert_eq(EnemyAI.get_intent(enemy_b)["type"], "defend")

	# Advance only enemy_a
	EnemyAI.advance_pattern(enemy_a)
	assert_eq(EnemyAI.get_intent(enemy_a)["type"], "defend")
	assert_eq(EnemyAI.get_intent(enemy_b)["type"], "defend")  # unchanged

	# Advance enemy_b
	EnemyAI.advance_pattern(enemy_b)
	assert_eq(EnemyAI.get_intent(enemy_b)["type"], "attack")

func test_T6_4_conditional_branch():
	# Enemy switches pattern when HP < 50%
	var normal_pattern: Array[Dictionary] = [{"type": "attack", "value": 6}]
	var enraged_pattern: Array[Dictionary] = [{"type": "attack", "value": 12}]
	var enemy = _make_enemy(normal_pattern, 20, enraged_pattern, 0.5)

	# Above threshold
	var intent1 = EnemyAI.get_intent(enemy)
	assert_eq(intent1["value"], 6, "Should use normal pattern above threshold")

	# Drop below 50%
	enemy.hp = 9
	var intent2 = EnemyAI.get_intent(enemy)
	assert_eq(intent2["value"], 12, "Should use alt pattern below threshold")
