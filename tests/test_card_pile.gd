extends GutTest

# T4. Card Pile Management (7 cases)

func _make_card(card_name: String, keywords: Array[String] = []) -> CardData:
	var card = CardData.new()
	card.card_name = card_name
	card.cost = 1
	card.card_type = "Attack"
	card.keywords = keywords
	return card

func _make_deck(count: int) -> Array[CardInstance]:
	var deck: Array[CardInstance] = []
	for i in range(count):
		var card = _make_card("Card_%d" % i)
		deck.append(CardInstance.new(card))
	return deck

func test_T4_1_battle_start_shuffle():
	# Deck of 10 cards, battle begins → Draw pile has 10, discard empty
	var state = CombatState.new()
	var deck = _make_deck(10)
	CardPileManager.init_piles(state, deck)
	assert_eq(state.draw_pile.size(), 10, "Draw pile should have 10 cards")
	assert_eq(state.discard_pile.size(), 0, "Discard pile should be empty")
	assert_eq(state.hand.size(), 0, "Hand should be empty")

func test_T4_2_draw_cards():
	# Draw pile has 8 cards, draw 5 → Hand has 5, draw pile has 3
	var state = CombatState.new()
	var deck = _make_deck(8)
	CardPileManager.init_piles(state, deck)
	CardPileManager.draw_cards(state, 5)
	assert_eq(state.hand.size(), 5, "Hand should have 5 cards")
	assert_eq(state.draw_pile.size(), 3, "Draw pile should have 3 remaining")

func test_T4_3_end_turn_discard():
	# Hand has 3 cards, end turn → Hand empty, discard += 3
	var state = CombatState.new()
	var deck = _make_deck(10)
	CardPileManager.init_piles(state, deck)
	CardPileManager.draw_cards(state, 3)
	assert_eq(state.hand.size(), 3)
	CardPileManager.discard_hand(state)
	assert_eq(state.hand.size(), 0, "Hand should be empty after discard")
	assert_eq(state.discard_pile.size(), 3, "Discard pile should have 3 cards")

func test_T4_4_reshuffle_on_empty():
	# Draw pile has 2, discard has 5, draw 5 → draw 2, shuffle discard, draw 3 more
	var state = CombatState.new()
	var deck = _make_deck(7)
	CardPileManager.init_piles(state, deck)
	# Draw 5, then discard them to fill discard pile
	CardPileManager.draw_cards(state, 5)
	CardPileManager.discard_hand(state)
	# Now: draw=2, discard=5, hand=0
	assert_eq(state.draw_pile.size(), 2, "Pre-check: draw pile should have 2")
	assert_eq(state.discard_pile.size(), 5, "Pre-check: discard pile should have 5")
	# Draw 5 → should trigger reshuffle
	CardPileManager.draw_cards(state, 5)
	assert_eq(state.hand.size(), 5, "Hand should have 5 after reshuffle draw")
	assert_eq(state.discard_pile.size(), 0, "Discard should be empty after reshuffle")

func test_T4_5_exhaust_card():
	# Play a card with Exhaust → goes to exhaust pile, not discard
	var state = CombatState.new()
	var exhaust_card_data = _make_card("War Stomp", ["Exhaust"] as Array[String])
	var exhaust_card = CardInstance.new(exhaust_card_data)
	state.hand.append(exhaust_card)
	CardPileManager.play_card(state, exhaust_card)
	assert_eq(state.exhaust_pile.size(), 1, "Exhaust pile should have 1 card")
	assert_eq(state.discard_pile.size(), 0, "Discard pile should be empty")
	assert_eq(state.hand.size(), 0, "Hand should be empty")

func test_T4_6_innate_in_opening_hand():
	# Deck has 1 Innate card among 10 → Innate card always in 5-card opening hand
	var state = CombatState.new()
	var deck: Array[CardInstance] = []
	for i in range(9):
		deck.append(CardInstance.new(_make_card("Normal_%d" % i)))
	var innate_data = _make_card("Innate Card", ["Innate"] as Array[String])
	var innate_card = CardInstance.new(innate_data)
	deck.append(innate_card)
	CardPileManager.init_piles(state, deck)
	CardPileManager.draw_opening_hand(state, 5)
	var found_innate = false
	for card in state.hand:
		if card.has_keyword("Innate"):
			found_innate = true
			break
	assert_true(found_innate, "Innate card should always be in opening hand")

func test_T4_7_ethereal_auto_exhaust():
	# Ethereal card in hand, end turn without playing → exhausted
	var state = CombatState.new()
	var ethereal_data = _make_card("Ethereal Card", ["Ethereal"] as Array[String])
	var ethereal_card = CardInstance.new(ethereal_data)
	var normal_card = CardInstance.new(_make_card("Normal"))
	state.hand.append(ethereal_card)
	state.hand.append(normal_card)
	CardPileManager.discard_hand(state)
	assert_eq(state.exhaust_pile.size(), 1, "Ethereal card should be exhausted")
	assert_eq(state.discard_pile.size(), 1, "Normal card should be discarded")
	assert_eq(state.hand.size(), 0, "Hand should be empty")
