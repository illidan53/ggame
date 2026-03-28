extends GutTest

# --- Helpers ---

func _make_state(hp: int = 80, energy: int = 3) -> CombatState:
	var state = CombatState.new()
	state.player = Combatant.new()
	state.player.hp = hp
	state.player.max_hp = 80
	state.player.energy = energy
	state.player.max_energy = 3
	state.player.is_player = true
	# Add 3 enemies for Fire Potion test
	for i in 3:
		var slime = load("res://resources/enemies/slime.tres") as EnemyData
		var enemy = Combatant.new()
		enemy.hp = slime.hp
		enemy.max_hp = slime.hp
		enemy.enemy_data = slime
		state.enemies.append(enemy)
	return state

# --- T3: Potion System ---

func test_T3_1_health_potion():
	var state = _make_state(50)
	PotionSystem.use_potion("Health Potion", state)
	assert_eq(state.player.hp, 70, "Health Potion should restore 20 HP")

func test_T3_1b_health_potion_cap():
	var state = _make_state(75)
	PotionSystem.use_potion("Health Potion", state)
	assert_eq(state.player.hp, 80, "Health Potion should not exceed max HP")

func test_T3_2_strength_potion():
	var state = _make_state()
	PotionSystem.use_potion("Strength Potion", state)
	assert_eq(state.player.get_status_stacks("Strength"), 2, "Strength Potion should give 2 Strength")

func test_T3_3_block_potion():
	var state = _make_state()
	PotionSystem.use_potion("Block Potion", state)
	assert_eq(state.player.block, 12, "Block Potion should give 12 block")

func test_T3_4_fire_potion():
	var state = _make_state()
	assert_eq(state.enemies.size(), 3, "Should have 3 enemies")
	PotionSystem.use_potion("Fire Potion", state)
	for enemy in state.enemies:
		assert_eq(enemy.hp, enemy.max_hp - 10, "Fire Potion should deal 10 to each enemy")

func test_T3_5_carry_limit():
	var potions: Array[String] = ["Health Potion", "Strength Potion", "Block Potion"]
	var result = PotionSystem.try_add_potion(potions, "Fire Potion")
	assert_false(result, "Should reject adding 4th potion")
	assert_eq(potions.size(), 3, "Potion count should stay at 3")

func test_T3_6_no_energy_cost():
	var state = _make_state(50, 0)
	PotionSystem.use_potion("Health Potion", state)
	assert_eq(state.player.hp, 70, "Potion should work with 0 energy")
	assert_eq(state.player.energy, 0, "Energy should remain 0")

func test_T3_7_single_use():
	var potions: Array[String] = ["Health Potion", "Strength Potion"]
	var state = _make_state(50)
	PotionSystem.use_and_remove(potions, 0, state)
	assert_eq(potions.size(), 1, "Potion should be removed after use")
	assert_eq(potions[0], "Strength Potion", "Remaining potion should be Strength")
	assert_eq(state.player.hp, 70, "Health Potion effect should apply")
