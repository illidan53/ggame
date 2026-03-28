extends GutTest

# --- Helpers ---

func _make_shadow_lord(hp: int = 100) -> Combatant:
	var data = load("res://resources/enemies/shadow_lord.tres") as EnemyData
	var boss = Combatant.new()
	boss.hp = hp
	boss.max_hp = 70
	boss.enemy_data = data
	return boss

func _make_state_with_boss(boss_hp: int = 100) -> CombatState:
	var state = CombatState.new()
	state.player = Combatant.new()
	state.player.hp = 80
	state.player.max_hp = 80
	state.player.max_energy = 3
	state.player.is_player = true
	state.enemies.append(_make_shadow_lord(boss_hp))
	return state

# --- T1: Boss Phase Transitions ---

func test_T1_1_phase_1_active():
	# HP > 60 → Phase 1 pattern
	var boss = _make_shadow_lord(70)
	var phase = BossSystem.get_phase(boss)
	assert_eq(phase, 1, "HP > 60 should be Phase 1")

func test_T1_2_phase_2_trigger():
	# HP drops to 55 → Phase 2
	var boss = _make_shadow_lord(55)
	var phase = BossSystem.get_phase(boss)
	assert_eq(phase, 2, "HP 30-60 should be Phase 2")

func test_T1_3_phase_3_trigger():
	# HP drops to 25 → Phase 3
	var boss = _make_shadow_lord(25)
	var phase = BossSystem.get_phase(boss)
	assert_eq(phase, 3, "HP < 30 should be Phase 3")

# --- T2: Boss Abilities ---

func test_T2_1_phase_1_attack():
	var state = _make_state_with_boss(70)
	var action = BossSystem.get_boss_action(state.enemies[0])
	assert_true(action["type"] in ["attack", "defend"], "Phase 1 should attack or defend")

func test_T2_2_phase_1_defend():
	# Advance pattern to find a defend action
	var boss = _make_shadow_lord(70)
	var found_defend := false
	for i in 5:
		var action = BossSystem.get_boss_action(boss)
		if action["type"] == "defend":
			found_defend = true
			break
		BossSystem.advance_boss(boss)
	assert_true(found_defend, "Phase 1 should include defend in pattern")

func test_T2_3_phase_2_summon():
	var state = _make_state_with_boss(55)
	var action = BossSystem.get_boss_action(state.enemies[0])
	# Phase 2 pattern should include summon
	var found_summon := false
	for i in 5:
		action = BossSystem.get_boss_action(state.enemies[0])
		if action["type"] == "summon":
			found_summon = true
			break
		BossSystem.advance_boss(state.enemies[0])
	assert_true(found_summon, "Phase 2 should include summon action")

func test_T2_4_phase_2_self_buff():
	var boss = _make_shadow_lord(55)
	var found_buff := false
	for i in 5:
		var action = BossSystem.get_boss_action(boss)
		if action["type"] == "buff":
			found_buff = true
			break
		BossSystem.advance_boss(boss)
	assert_true(found_buff, "Phase 2 should include self-buff action")

func test_T2_5_phase_3_enrage():
	var boss = _make_shadow_lord(25)
	var action = BossSystem.get_boss_action(boss)
	# Phase 3: should gain Strength
	BossSystem.apply_enrage(boss)
	assert_eq(boss.get_status_stacks("Strength"), 2, "Phase 3 enrage should add +2 Strength")

# --- T3: Elite Enemies ---

func test_T3_1_dark_knight_normal():
	var data = load("res://resources/enemies/dark_knight.tres") as EnemyData
	var dk = Combatant.new()
	dk.hp = data.hp
	dk.max_hp = data.hp
	dk.enemy_data = data
	# Turn 1-3: normal pattern
	var intent1 = EnemyAI.get_intent(dk)
	assert_eq(intent1["type"], "attack", "Turn 1 should be attack")
	assert_eq(intent1["value"], 10, "Turn 1 attack should be 10")

func test_T3_2_dark_knight_after_turn_3():
	var data = load("res://resources/enemies/dark_knight.tres") as EnemyData
	var dk = Combatant.new()
	dk.hp = data.hp
	dk.max_hp = data.hp
	dk.enemy_data = data
	dk.turn_count = 4  # After turn 3
	# With turn_count > 3, attack values should double
	var bonus = BossSystem.get_dark_knight_multiplier(dk)
	assert_eq(bonus, 2, "After turn 3, damage multiplier should be 2")

func test_T3_3_fire_elemental_turn_1():
	var data = load("res://resources/enemies/fire_elemental.tres") as EnemyData
	var fe = Combatant.new()
	fe.hp = data.hp
	fe.max_hp = data.hp
	fe.enemy_data = data
	var intent = EnemyAI.get_intent(fe)
	assert_eq(intent["type"], "attack_debuff", "Turn 1 should be attack_debuff")
	assert_eq(intent["value"], 8, "Attack value should be 8")
	assert_eq(intent["debuff"], "Vulnerable", "Should apply Vulnerable")

func test_T3_4_fire_elemental_turn_2():
	var data = load("res://resources/enemies/fire_elemental.tres") as EnemyData
	var fe = Combatant.new()
	fe.hp = data.hp
	fe.max_hp = data.hp
	fe.enemy_data = data
	EnemyAI.advance_pattern(fe)
	var intent = EnemyAI.get_intent(fe)
	assert_eq(intent["type"], "attack", "Turn 2 should be attack")
	assert_eq(intent["value"], 12, "Attack value should be 12")
