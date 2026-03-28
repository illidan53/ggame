extends GutTest

# --- Helpers ---

func _make_player(hp: int = 80) -> Combatant:
	var p = Combatant.new()
	p.hp = hp
	p.max_hp = 80
	p.max_energy = 3
	p.is_player = true
	return p

func _make_state(relics: Array[String] = [], hp: int = 80) -> CombatState:
	var state = CombatState.new()
	state.player = _make_player(hp)
	var slime = load("res://resources/enemies/slime.tres") as EnemyData
	var enemy = Combatant.new()
	enemy.hp = slime.hp
	enemy.max_hp = slime.hp
	enemy.enemy_data = slime
	state.enemies.append(enemy)
	return state

# --- T1: Relic Effects ---

func test_T1_1_iron_bracers():
	var state = _make_state()
	var relics: Array[String] = ["Iron Bracers"]
	RelicSystem.apply_combat_start(state, relics)
	assert_eq(state.player.block, 4, "Iron Bracers should give 4 block at combat start")

func test_T1_2_war_drum():
	var state = _make_state()
	var relics: Array[String] = ["War Drum"]
	var draw_count = RelicSystem.get_draw_count(5, relics)
	assert_eq(draw_count, 6, "War Drum should increase draw by 1")

func test_T1_3_cracked_crown():
	var state = _make_state()
	var relics: Array[String] = ["Cracked Crown"]
	var energy = RelicSystem.get_max_energy(3, relics)
	var draw_count = RelicSystem.get_draw_count(5, relics)
	assert_eq(energy, 4, "Cracked Crown should give +1 energy")
	assert_eq(draw_count, 4, "Cracked Crown should draw 1 fewer card")

func test_T1_4_blood_pendant():
	var state = _make_state([], 70)
	var relics: Array[String] = ["Blood Pendant"]
	RelicSystem.apply_combat_start(state, relics)
	assert_eq(state.player.hp, 72, "Blood Pendant should heal 2 HP at combat start")

func test_T1_5_rage_mask():
	var relics: Array[String] = ["Rage Mask"]
	var bonus = RelicSystem.get_attack_bonus(relics)
	assert_eq(bonus, 3, "Rage Mask should add +3 damage to attacks")

func test_T1_6_thorn_armor():
	var state = _make_state()
	var relics: Array[String] = ["Thorn Armor"]
	RelicSystem.apply_combat_start(state, relics)
	assert_eq(state.player.get_status_stacks("Thorns"), 3, "Thorn Armor should give 3 Thorns")

# --- T2: Relic Stacking ---

func test_T2_1_multiple_relics():
	var state = _make_state()
	var relics: Array[String] = ["Iron Bracers", "War Drum"]
	RelicSystem.apply_combat_start(state, relics)
	assert_eq(state.player.block, 4, "Iron Bracers should give 4 block")
	var draw_count = RelicSystem.get_draw_count(5, relics)
	assert_eq(draw_count, 6, "War Drum should increase draw to 6")

func test_T2_2_duplicate_prevention():
	var owned: Array[String] = ["Iron Bracers", "War Drum"]
	var all_relics: Array[String] = ["Iron Bracers", "War Drum", "Cracked Crown", "Blood Pendant", "Rage Mask", "Thorn Armor"]
	var available = RelicSystem.get_available_relics(all_relics, owned)
	assert_false("Iron Bracers" in available, "Owned relic should not be in pool")
	assert_false("War Drum" in available, "Owned relic should not be in pool")
	assert_eq(available.size(), 4, "Should have 4 available relics")
