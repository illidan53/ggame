extends GutTest

# T7. Targeting Rules (5 cases)

func _make_card(card_name: String, cost: int, card_type: String, damage: int, target_mode: String = "single", keywords: Array[String] = [] as Array[String]) -> CardData:
	var card = CardData.new()
	card.card_name = card_name
	card.cost = cost
	card.card_type = card_type
	card.base_damage = damage
	card.base_block = 0
	card.target_mode = target_mode
	card.keywords = keywords
	return card

func _make_enemy(hp: int) -> Combatant:
	var enemy = Combatant.new()
	enemy.hp = hp
	enemy.max_hp = hp
	return enemy

func test_T7_1_single_target_attack():
	# Play Strike at enemy 0, 2 enemies → only enemy 0 takes damage
	var state = CombatState.new()
	state.player = Combatant.new()
	state.player.hp = 80
	state.player.max_hp = 80
	state.player.energy = 3
	state.enemies.append(_make_enemy(20))
	state.enemies.append(_make_enemy(20))

	var strike_data = _make_card("Strike", 1, "Attack", 6, "single")
	var strike = CardInstance.new(strike_data)
	state.hand.append(strike)

	Targeting.execute_card(state, strike, 0)
	assert_eq(state.enemies[0].hp, 14, "Target enemy should take 6 damage")
	assert_eq(state.enemies[1].hp, 20, "Other enemy should be unaffected")

func test_T7_2_aoe_attack():
	# Play Whirlwind (X=2), 3 enemies → all take 10 damage (2×5 each)
	var state = CombatState.new()
	state.player = Combatant.new()
	state.player.hp = 80
	state.player.max_hp = 80
	state.player.energy = 2
	state.enemies.append(_make_enemy(30))
	state.enemies.append(_make_enemy(30))
	state.enemies.append(_make_enemy(30))

	# Whirlwind: X-cost, deals X*5 damage to all
	var whirl_data = _make_card("Whirlwind", -1, "Attack", 5, "aoe")  # -1 = X cost
	var whirl = CardInstance.new(whirl_data)
	state.hand.append(whirl)

	Targeting.execute_card(state, whirl, -1)  # -1 target = no specific target (AOE)
	assert_eq(state.enemies[0].hp, 20, "Enemy 0 should take 10 damage (2×5)")
	assert_eq(state.enemies[1].hp, 20, "Enemy 1 should take 10 damage (2×5)")
	assert_eq(state.enemies[2].hp, 20, "Enemy 2 should take 10 damage (2×5)")

func test_T7_3_skill_no_target():
	# Play Defend → no target needed, block applies to player
	var state = CombatState.new()
	state.player = Combatant.new()
	state.player.hp = 80
	state.player.max_hp = 80
	state.player.energy = 3
	state.player.block = 0

	var defend_data = _make_card("Defend", 1, "Skill", 0, "self")
	defend_data.base_block = 5
	var defend = CardInstance.new(defend_data)
	state.hand.append(defend)

	Targeting.execute_card(state, defend, -1)
	assert_eq(state.player.block, 5, "Player should gain 5 block")

func test_T7_4_x_cost_uses_all_energy():
	# Play Whirlwind with 3 energy, 2 enemies → X=3, each takes 15 damage, energy = 0
	var state = CombatState.new()
	state.player = Combatant.new()
	state.player.hp = 80
	state.player.max_hp = 80
	state.player.energy = 3
	state.enemies.append(_make_enemy(30))
	state.enemies.append(_make_enemy(30))

	var whirl_data = _make_card("Whirlwind", -1, "Attack", 5, "aoe")
	var whirl = CardInstance.new(whirl_data)
	state.hand.append(whirl)

	Targeting.execute_card(state, whirl, -1)
	assert_eq(state.enemies[0].hp, 15, "Enemy should take 15 damage (3×5)")
	assert_eq(state.enemies[1].hp, 15, "Enemy should take 15 damage (3×5)")
	assert_eq(state.player.energy, 0, "Energy should be 0")

func test_T7_5_x_cost_with_0_energy():
	# Play Whirlwind with 0 energy → X=0, no damage, card still played
	var state = CombatState.new()
	state.player = Combatant.new()
	state.player.hp = 80
	state.player.max_hp = 80
	state.player.energy = 0
	state.enemies.append(_make_enemy(20))

	var whirl_data = _make_card("Whirlwind", -1, "Attack", 5, "aoe")
	var whirl = CardInstance.new(whirl_data)
	state.hand.append(whirl)

	Targeting.execute_card(state, whirl, -1)
	assert_eq(state.enemies[0].hp, 20, "No damage with 0 energy")
	assert_eq(state.player.energy, 0, "Energy stays at 0")
	assert_eq(state.hand.size(), 0, "Card should be removed from hand")
