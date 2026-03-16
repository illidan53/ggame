extends GutTest

# T5. Turn Flow (6 cases)

func _make_card(card_name: String, cost: int = 1, card_type: String = "Attack") -> CardData:
	var card = CardData.new()
	card.card_name = card_name
	card.cost = cost
	card.card_type = card_type
	card.base_damage = 6
	card.keywords = [] as Array[String]
	return card

func _setup_combat() -> CombatState:
	var state = CombatState.new()
	state.player = Combatant.new()
	state.player.hp = 80
	state.player.max_hp = 80
	state.player.max_energy = 3
	state.player.is_player = true

	# Create a 10-card deck
	var deck: Array[CardInstance] = []
	for i in range(10):
		deck.append(CardInstance.new(_make_card("Card_%d" % i)))

	CardPileManager.init_piles(state, deck)
	return state

func test_T5_1_turn_start():
	# New turn: block resets to 0, energy = 3, draw 5 cards
	var state = _setup_combat()
	state.player.block = 7
	TurnFlow.start_player_turn(state)
	assert_eq(state.player.block, 0, "Block should reset at turn start")
	assert_eq(state.player.energy, 3, "Energy should be 3")
	assert_eq(state.hand.size(), 5, "Should draw 5 cards")

func test_T5_2_play_card_costs_energy():
	# Play a 2-cost card with 3 energy → Energy = 1, card effect applied
	var state = _setup_combat()
	TurnFlow.start_player_turn(state)
	var card_data = _make_card("Heavy Strike", 2)
	var card = CardInstance.new(card_data)
	state.hand.append(card)

	var result = TurnFlow.can_play_card(state, card)
	assert_true(result, "Should be able to play 2-cost card with 3 energy")
	TurnFlow.spend_energy(state, card.data.cost)
	assert_eq(state.player.energy, 1, "Energy should be 1 after playing 2-cost card")

func test_T5_3_insufficient_energy():
	# Try to play 2-cost card with 1 energy → rejected
	var state = _setup_combat()
	state.player.energy = 1
	var card_data = _make_card("Heavy Strike", 2)
	var card = CardInstance.new(card_data)
	state.hand.append(card)

	var result = TurnFlow.can_play_card(state, card)
	assert_false(result, "Should not be able to play 2-cost with 1 energy")

func test_T5_4_end_turn_discards_hand():
	# Player ends turn with 3 cards → all to discard
	var state = _setup_combat()
	TurnFlow.start_player_turn(state)
	# Keep only 3 cards in hand
	while state.hand.size() > 3:
		state.hand.pop_back()
	var hand_size = state.hand.size()
	assert_eq(hand_size, 3)
	TurnFlow.end_player_turn(state)
	assert_eq(state.hand.size(), 0, "Hand should be empty")
	assert_eq(state.discard_pile.size(), 3, "Discard should have 3 cards")

func test_T5_5_victory_condition():
	# All enemies HP <= 0 → combat ends with victory
	var state = _setup_combat()
	var enemy = Combatant.new()
	enemy.hp = 0
	enemy.max_hp = 20
	state.enemies.append(enemy)

	TurnFlow.check_combat_end(state)
	assert_true(state.is_combat_over, "Combat should be over")
	assert_eq(state.combat_result, "victory", "Result should be victory")

func test_T5_6_defeat_condition():
	# Player HP <= 0 → combat ends with defeat
	var state = _setup_combat()
	state.player.hp = 0
	var enemy = Combatant.new()
	enemy.hp = 20
	enemy.max_hp = 20
	state.enemies.append(enemy)

	TurnFlow.check_combat_end(state)
	assert_true(state.is_combat_over, "Combat should be over")
	assert_eq(state.combat_result, "defeat", "Result should be defeat")
