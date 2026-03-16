class_name TurnFlow
extends RefCounted

## Start the player's turn: reset block, restore energy, draw cards
static func start_player_turn(state: CombatState) -> void:
	state.turn_number += 1
	CombatCalc.reset_block(state.player)
	state.player.energy = state.player.max_energy
	StatusEffects.apply_turn_start_effects(state.player)
	CardPileManager.draw_cards(state, 5)

## Check if a card can be played (enough energy)
static func can_play_card(state: CombatState, card: CardInstance) -> bool:
	return state.player.energy >= card.data.cost

## Spend energy to play a card
static func spend_energy(state: CombatState, cost: int) -> void:
	state.player.energy -= cost

## End the player's turn: discard hand, tick status effects
static func end_player_turn(state: CombatState) -> void:
	CardPileManager.discard_hand(state)
	StatusEffects.tick_effects(state.player)

## Check if combat has ended (victory or defeat)
static func check_combat_end(state: CombatState) -> void:
	# Check defeat
	if not state.player.is_alive():
		state.is_combat_over = true
		state.combat_result = "defeat"
		return

	# Check victory — all enemies dead
	var all_dead = true
	for enemy in state.enemies:
		if enemy.is_alive():
			all_dead = false
			break
	if all_dead and state.enemies.size() > 0:
		state.is_combat_over = true
		state.combat_result = "victory"
