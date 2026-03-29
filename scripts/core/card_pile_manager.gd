class_name CardPileManager
extends RefCounted

## Initialize piles from a deck (shuffle into draw pile)
static func init_piles(state: CombatState, deck: Array[CardInstance]) -> void:
	state.draw_pile = deck.duplicate()
	state.draw_pile.shuffle()
	state.hand = []
	state.discard_pile = []
	state.exhaust_pile = []

## Draw N cards from draw pile into hand. Reshuffles discard if needed.
static func draw_cards(state: CombatState, count: int) -> void:
	for i in range(count):
		if state.draw_pile.is_empty():
			_reshuffle_discard(state)
		if state.draw_pile.is_empty():
			break  # No cards left anywhere
		state.hand.append(state.draw_pile.pop_back())

## Draw opening hand with Innate guarantee
static func draw_opening_hand(state: CombatState, count: int) -> void:
	# Find and pull Innate cards from draw pile first
	var innate_cards: Array[CardInstance] = []
	var remaining: Array[CardInstance] = []
	for card in state.draw_pile:
		if card.has_keyword("Innate"):
			innate_cards.append(card)
		else:
			remaining.append(card)
	state.draw_pile = remaining

	# Add innate cards to hand first
	for card in innate_cards:
		state.hand.append(card)

	# Draw remaining slots normally
	var slots_left = count - state.hand.size()
	if slots_left > 0:
		draw_cards(state, slots_left)

## Discard entire hand (Ethereal→exhaust, Retain→stay, others→discard)
static func discard_hand(state: CombatState) -> void:
	var retained: Array[CardInstance] = []
	for card in state.hand:
		if card.has_keyword("Ethereal"):
			state.exhaust_pile.append(card)
		elif card.has_keyword("Retain"):
			retained.append(card)
		else:
			state.discard_pile.append(card)
	state.hand = retained

## Discard a specific card from hand by index. Returns the discarded card or null.
static func discard_from_hand(state: CombatState, index: int) -> CardInstance:
	if index < 0 or index >= state.hand.size():
		return null
	var card = state.hand[index]
	state.hand.remove_at(index)
	state.discard_pile.append(card)
	return card

## Discard N random cards from hand. Returns discarded cards.
static func discard_random(state: CombatState, count: int, rng: RandomNumberGenerator = null) -> Array[CardInstance]:
	var discarded: Array[CardInstance] = []
	for _i in count:
		if state.hand.is_empty():
			break
		var idx: int
		if rng != null:
			idx = rng.randi_range(0, state.hand.size() - 1)
		else:
			idx = randi_range(0, state.hand.size() - 1)
		discarded.append(state.hand[idx])
		state.discard_pile.append(state.hand[idx])
		state.hand.remove_at(idx)
	return discarded

## Add a token card (e.g. Shiv) directly into the hand.
static func add_to_hand(state: CombatState, card: CardInstance) -> void:
	state.hand.append(card)

## Play a card from hand (Exhaust cards go to exhaust pile)
static func play_card(state: CombatState, card: CardInstance) -> void:
	state.hand.erase(card)
	if card.has_keyword("Exhaust"):
		state.exhaust_pile.append(card)
	else:
		state.discard_pile.append(card)

## Shuffle discard pile into draw pile
static func _reshuffle_discard(state: CombatState) -> void:
	state.draw_pile = state.discard_pile.duplicate()
	state.draw_pile.shuffle()
	state.discard_pile = []
