extends GutTest

# --- Helpers ---

var _strike: CardData
var _defend: CardData
var _bash: CardData
var _slime: EnemyData
var _goblin: EnemyData

func before_each() -> void:
	_strike = load("res://resources/cards/strike.tres") as CardData
	_defend = load("res://resources/cards/defend.tres") as CardData
	_bash = load("res://resources/cards/bash.tres") as CardData
	_slime = load("res://resources/enemies/slime.tres") as EnemyData
	_goblin = load("res://resources/enemies/goblin.tres") as EnemyData

func _make_deck() -> Array[CardInstance]:
	var deck: Array[CardInstance] = []
	var id := 0
	for i in 5:
		var c = CardInstance.new(_strike)
		c.instance_id = id; id += 1
		deck.append(c)
	for i in 4:
		var c = CardInstance.new(_defend)
		c.instance_id = id; id += 1
		deck.append(c)
	var bash_card = CardInstance.new(_bash)
	bash_card.instance_id = id
	deck.append(bash_card)
	return deck

func _create_combat(enemies: Array[EnemyData] = []) -> CombatState:
	if enemies.is_empty():
		enemies = [_slime]
	return BattleManager.create_combat(80, 3, _make_deck(), enemies)

# --- Test: Initialization ---

func test_T11_1_init_combat_state():
	var state = _create_combat()
	assert_eq(state.player.hp, 80, "Player HP should be 80")
	assert_eq(state.player.max_hp, 80, "Player max HP should be 80")
	assert_eq(state.player.max_energy, 3, "Player max energy should be 3")
	assert_eq(state.enemies.size(), 1, "Should have 1 enemy")
	assert_eq(state.enemies[0].hp, _slime.hp, "Enemy HP should match data")
	assert_eq(state.draw_pile.size(), 10, "Draw pile should have 10 cards")
	assert_eq(state.hand.size(), 0, "Hand should be empty before first turn")
	assert_false(state.is_combat_over, "Combat should not be over")

func test_T11_2_init_multi_enemy():
	var state = _create_combat([_slime, _goblin])
	assert_eq(state.enemies.size(), 2, "Should have 2 enemies")
	assert_eq(state.enemies[0].enemy_data.enemy_name, "Slime")
	assert_eq(state.enemies[1].enemy_data.enemy_name, "Goblin")

# --- Test: Starting Deck Composition ---

func test_T11_15_starting_deck_composition():
	var deck = _make_deck()
	assert_eq(deck.size(), 10, "Starting deck should have 10 cards")
	var strike_count := 0
	var defend_count := 0
	var bash_count := 0
	for card in deck:
		match card.data.card_name:
			"Strike": strike_count += 1
			"Defend": defend_count += 1
			"Bash": bash_count += 1
	assert_eq(strike_count, 5, "Should have 5 Strikes")
	assert_eq(defend_count, 4, "Should have 4 Defends")
	assert_eq(bash_count, 1, "Should have 1 Bash")

# --- Test: Card Resource Values ---

func test_T11_16_card_resource_values_match_gdd():
	# GDD Sec 5.2: Strike cost=1, dmg=6; Defend cost=1, block=5; Bash cost=2, dmg=14
	assert_eq(_strike.cost, 1, "Strike cost should be 1")
	assert_eq(_strike.base_damage, 6, "Strike damage should be 6")
	assert_eq(_strike.card_type, "Attack", "Strike should be Attack type")
	assert_eq(_defend.cost, 1, "Defend cost should be 1")
	assert_eq(_defend.base_block, 5, "Defend block should be 5")
	assert_eq(_defend.card_type, "Skill", "Defend should be Skill type")
	assert_eq(_bash.cost, 2, "Bash cost should be 2")
	assert_eq(_bash.base_damage, 14, "Bash damage should be 14")

# --- Test: Begin Turn ---

func test_T11_3_begin_turn_draws_and_restores():
	var state = _create_combat()
	BattleManager.begin_player_turn(state)
	assert_eq(state.player.energy, 3, "Energy should be restored to max")
	assert_eq(state.hand.size(), 5, "Should draw 5 cards")
	assert_eq(state.player.block, 0, "Block should be reset")
	assert_eq(state.turn_number, 1, "Turn number should be 1")

# --- Test: Play Attack ---

func test_T11_4_play_attack_deals_damage():
	var state = _create_combat()
	BattleManager.begin_player_turn(state)
	# Find a Strike in hand
	var strike_idx := -1
	for i in state.hand.size():
		if state.hand[i].data.card_name == "Strike":
			strike_idx = i
			break
	assert_ne(strike_idx, -1, "Should have a Strike in hand")
	var enemy_hp_before = state.enemies[0].hp
	var result = BattleManager.play_card(state, strike_idx, 0)
	assert_true(result.success, "Play should succeed")
	assert_eq(state.enemies[0].hp, enemy_hp_before - 6, "Slime should take 6 damage")
	assert_eq(state.player.energy, 2, "Energy should decrease by 1")
	assert_eq(state.hand.size(), 4, "Hand should have 4 cards")

# --- Test: Play Defend ---

func test_T11_5_play_defend_gains_block():
	var state = _create_combat()
	BattleManager.begin_player_turn(state)
	var defend_idx := -1
	for i in state.hand.size():
		if state.hand[i].data.card_name == "Defend":
			defend_idx = i
			break
	assert_ne(defend_idx, -1, "Should have a Defend in hand")
	var result = BattleManager.play_card(state, defend_idx, -1)
	assert_true(result.success, "Play should succeed")
	assert_eq(state.player.block, 5, "Player should have 5 block")

# --- Test: Insufficient Energy ---

func test_T11_6_insufficient_energy_rejected():
	var state = _create_combat()
	BattleManager.begin_player_turn(state)
	state.player.energy = 0
	var hand_size_before = state.hand.size()
	var result = BattleManager.play_card(state, 0, 0)
	assert_false(result.success, "Should fail with no energy")
	assert_eq(state.hand.size(), hand_size_before, "Hand should be unchanged")

# --- Test: Invalid Card Index ---

func test_T11_7_invalid_card_index_rejected():
	var state = _create_combat()
	BattleManager.begin_player_turn(state)
	var result = BattleManager.play_card(state, 99, 0)
	assert_false(result.success, "Should fail with invalid index")

# --- Test: Single Target Needs Target ---

func test_T11_8_attack_needs_valid_target():
	var state = _create_combat()
	BattleManager.begin_player_turn(state)
	var strike_idx := -1
	for i in state.hand.size():
		if state.hand[i].data.card_name == "Strike":
			strike_idx = i
			break
	var result = BattleManager.play_card(state, strike_idx, -1)
	assert_false(result.success, "Attack without target should fail")

# --- Test: End Turn — Enemies Act ---

func test_T11_9_end_turn_enemies_attack():
	var state = _create_combat()  # vs Slime, first intent is attack 6
	BattleManager.begin_player_turn(state)
	var hp_before = state.player.hp
	BattleManager.end_turn(state)
	assert_lt(state.player.hp, hp_before, "Player should have taken damage from enemy")

# --- Test: Victory ---

func test_T11_10_victory_when_all_enemies_dead():
	var state = _create_combat()
	BattleManager.begin_player_turn(state)
	# Kill the enemy directly
	state.enemies[0].hp = 1
	# Find a Strike
	var strike_idx := -1
	for i in state.hand.size():
		if state.hand[i].data.card_name == "Strike":
			strike_idx = i
			break
	BattleManager.play_card(state, strike_idx, 0)
	assert_true(state.is_combat_over, "Combat should be over")
	assert_eq(state.combat_result, "victory", "Result should be victory")

# --- Test: Defeat ---

func test_T11_11_defeat_when_player_dies():
	var state = _create_combat()
	BattleManager.begin_player_turn(state)
	state.player.hp = 1
	state.player.block = 0
	BattleManager.end_turn(state)  # Slime attacks for 6
	assert_true(state.is_combat_over, "Combat should be over")
	assert_eq(state.combat_result, "defeat", "Result should be defeat")

# --- Test: Bash Applies Vulnerable ---

func test_T11_12_bash_applies_vulnerable():
	var state = _create_combat()
	BattleManager.begin_player_turn(state)
	# Find Bash in hand
	var bash_idx := -1
	for i in state.hand.size():
		if state.hand[i].data.card_name == "Bash":
			bash_idx = i
			break
	if bash_idx == -1:
		# Bash might not be drawn — set it up manually
		var bash_card = CardInstance.new(_bash)
		bash_card.instance_id = 99
		state.hand.append(bash_card)
		bash_idx = state.hand.size() - 1
	BattleManager.play_card(state, bash_idx, 0)
	assert_true(state.enemies[0].has_status("Vulnerable"), "Enemy should be Vulnerable after Bash")
	assert_eq(state.enemies[0].get_status_stacks("Vulnerable"), 2, "Should have 2 Vulnerable stacks")

# --- Test: Vulnerable Increases Subsequent Damage ---

func test_T11_13_vulnerable_increases_damage():
	var state = _create_combat()
	BattleManager.begin_player_turn(state)
	# Apply Vulnerable to enemy
	StatusEffects.apply_effect(state.enemies[0], "Vulnerable", 2)
	var hp_before = state.enemies[0].hp
	# Find a Strike
	var strike_idx := -1
	for i in state.hand.size():
		if state.hand[i].data.card_name == "Strike":
			strike_idx = i
			break
	assert_ne(strike_idx, -1, "Should have Strike")
	BattleManager.play_card(state, strike_idx, 0)
	# Strike base 6, vulnerable = floor(6 * 1.5) = 9
	assert_eq(state.enemies[0].hp, hp_before - 9, "Vulnerable should increase damage to 9")

# --- Test: Full Combat Loop ---

func test_T11_14_full_combat_to_completion():
	var state = _create_combat()  # vs Slime (12 HP)
	var max_turns := 20
	for turn in max_turns:
		if state.is_combat_over:
			break
		BattleManager.begin_player_turn(state)
		# Play all affordable attacks
		while not state.hand.is_empty() and not state.is_combat_over:
			var played := false
			for i in state.hand.size():
				var card = state.hand[i]
				if state.player.energy >= card.data.cost:
					var target := 0 if card.data.target_mode == "single" and card.data.base_damage > 0 else -1
					var result = BattleManager.play_card(state, i, target)
					if result.success:
						played = true
						break
			if not played:
				break
		if not state.is_combat_over:
			BattleManager.end_turn(state)
	assert_true(state.is_combat_over, "Combat should end within %d turns" % max_turns)
	assert_true(state.combat_result in ["victory", "defeat"], "Result should be victory or defeat")
