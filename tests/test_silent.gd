extends GutTest

# --- T1: Poison Mechanics ---

func test_T1_1_poison_deals_damage_and_decays():
	var enemy = Combatant.new()
	enemy.hp = 30
	enemy.max_hp = 30
	StatusEffects.apply_effect(enemy, "Poison", 5)
	var dmg = StatusEffects.apply_poison(enemy)
	assert_eq(dmg, 5, "Poison should deal 5 damage")
	assert_eq(enemy.hp, 25, "Enemy HP should be 30-5=25")
	assert_eq(enemy.get_status_stacks("Poison"), 4, "Poison should decay to 4")

func test_T1_2_poison_bypasses_block():
	var enemy = Combatant.new()
	enemy.hp = 30
	enemy.max_hp = 30
	enemy.block = 10
	StatusEffects.apply_effect(enemy, "Poison", 5)
	StatusEffects.apply_poison(enemy)
	assert_eq(enemy.block, 10, "Block should be unchanged")
	assert_eq(enemy.hp, 25, "Poison bypasses block")

func test_T1_3_poison_stacks_additively():
	var enemy = Combatant.new()
	enemy.hp = 50
	enemy.max_hp = 50
	StatusEffects.apply_effect(enemy, "Poison", 3)
	StatusEffects.apply_effect(enemy, "Poison", 4)
	assert_eq(enemy.get_status_stacks("Poison"), 7, "Poison should stack to 7")

func test_T1_4_poison_expires_at_zero():
	var enemy = Combatant.new()
	enemy.hp = 30
	enemy.max_hp = 30
	StatusEffects.apply_effect(enemy, "Poison", 1)
	StatusEffects.apply_poison(enemy)
	assert_eq(enemy.hp, 29, "Should take 1 damage")
	assert_false(enemy.has_status("Poison"), "Poison should be removed at 0")

func test_T1_5_catalyst_doubles_poison():
	var enemy = Combatant.new()
	enemy.hp = 50
	enemy.max_hp = 50
	StatusEffects.apply_effect(enemy, "Poison", 5)
	StatusEffects.multiply_poison(enemy, 2)
	assert_eq(enemy.get_status_stacks("Poison"), 10, "Catalyst should double to 10")

# --- T2: Intangible ---

func test_T2_1_intangible_reduces_damage_to_1():
	var target = Combatant.new()
	target.hp = 50
	target.max_hp = 50
	StatusEffects.apply_effect(target, "Intangible", 1)
	CombatCalc.apply_damage_to_target(target, 20)
	assert_eq(target.hp, 49, "Intangible should reduce 20 damage to 1")

func test_T2_2_intangible_decays():
	var target = Combatant.new()
	target.hp = 50
	target.max_hp = 50
	StatusEffects.apply_effect(target, "Intangible", 2)
	StatusEffects.tick_effects(target)
	assert_eq(target.get_status_stacks("Intangible"), 1, "Intangible should decay by 1")

# --- T3: Silent Starting Deck ---

func test_T3_1_silent_starting_deck_12_cards():
	var run = RunData.create_new(42, "Silent")
	assert_eq(run.deck.size(), 12, "Silent starting deck should have 12 cards")

func test_T3_2_silent_starting_hp_70():
	var run = RunData.create_new(42, "Silent")
	assert_eq(run.player_hp, 70, "Silent should start with 70 HP")
	assert_eq(run.player_max_hp, 70, "Silent max HP should be 70")

func test_T3_3_silent_has_ring_of_snake():
	var run = RunData.create_new(42, "Silent")
	assert_true("Ring of the Snake" in run.relics, "Silent should start with Ring of the Snake")

func test_T3_4_silent_deck_contains_neutralize():
	var run = RunData.create_new(42, "Silent")
	var has_neutralize := false
	for card in run.deck:
		if card.data.card_name == "Neutralize":
			has_neutralize = true
			break
	assert_true(has_neutralize, "Silent deck should contain Neutralize")

func test_T3_5_silent_deck_contains_survivor():
	var run = RunData.create_new(42, "Silent")
	var has_survivor := false
	for card in run.deck:
		if card.data.card_name == "Survivor":
			has_survivor = true
			break
	assert_true(has_survivor, "Silent deck should contain Survivor")

func test_T3_6_warrior_unchanged():
	var run = RunData.create_new(42, "Warrior")
	assert_eq(run.deck.size(), 10, "Warrior deck should still be 10 cards")
	assert_eq(run.player_hp, 80, "Warrior HP should still be 80")

# --- T4: Silent Card Effects ---

func test_T4_1_poisoned_stab_applies_poison():
	var state = _make_silent_combat()
	var card = CardInstance.new(load("res://resources/cards/poisoned_stab.tres"))
	state.hand.append(card)
	state.player.energy = 3
	BattleManager.play_card(state, 0, 0)
	assert_true(state.enemies[0].get_status_stacks("Poison") >= 3, "Should apply 3+ Poison")

func test_T4_2_bane_double_hit_on_poisoned():
	var state = _make_silent_combat()
	StatusEffects.apply_effect(state.enemies[0], "Poison", 3)
	var hp_before = state.enemies[0].hp
	var card = CardInstance.new(load("res://resources/cards/bane.tres"))
	state.hand.append(card)
	state.player.energy = 3
	BattleManager.play_card(state, 0, 0)
	var dmg = hp_before - state.enemies[0].hp
	assert_true(dmg >= 14, "Bane should deal double (7+7=14) vs poisoned enemy, got %d" % dmg)

func test_T4_3_blade_dance_adds_shivs():
	var state = _make_silent_combat()
	var card = CardInstance.new(load("res://resources/cards/blade_dance.tres"))
	state.hand.append(card)
	state.player.energy = 3
	BattleManager.play_card(state, 0, -1)
	var shiv_count := 0
	for c in state.hand:
		if c.data.card_name == "Shiv":
			shiv_count += 1
	assert_eq(shiv_count, 3, "Blade Dance should add 3 Shivs")

func test_T4_4_shiv_exhausts_after_play():
	var state = _make_silent_combat()
	var shiv = CardInstance.new(load("res://resources/cards/shiv.tres"))
	state.hand.append(shiv)
	state.player.energy = 3
	BattleManager.play_card(state, 0, 0)
	assert_true(state.exhaust_pile.size() >= 1, "Shiv should go to exhaust pile")

func test_T4_5_deadly_poison_applies_5():
	var state = _make_silent_combat()
	var card = CardInstance.new(load("res://resources/cards/deadly_poison.tres"))
	state.hand.append(card)
	state.player.energy = 3
	BattleManager.play_card(state, 0, 0)
	assert_eq(state.enemies[0].get_status_stacks("Poison"), 5, "Should apply 5 Poison")

func test_T4_6_neutralize_applies_weak():
	var state = _make_silent_combat()
	var card = CardInstance.new(load("res://resources/cards/neutralize.tres"))
	state.hand.append(card)
	state.player.energy = 3
	BattleManager.play_card(state, 0, 0)
	assert_true(state.enemies[0].has_status("Weak"), "Neutralize should apply Weak")

# --- T5: Discard Mechanics ---

func test_T5_1_discard_random_removes_card():
	var state = _make_silent_combat()
	# Add some cards to hand
	for i in 5:
		state.hand.append(CardInstance.new(load("res://resources/cards/strike_s.tres")))
	var hand_before = state.hand.size()
	CardPileManager.discard_random(state, 1)
	assert_eq(state.hand.size(), hand_before - 1, "Should remove 1 card from hand")
	assert_eq(state.discard_pile.size(), 1, "Discarded card should go to discard pile")

func test_T5_2_retain_keeps_card_in_hand():
	var state = _make_silent_combat()
	var card = CardInstance.new(load("res://resources/cards/strike_s.tres"))
	card.data = card.data.duplicate()
	var kw: Array[String] = ["Retain"]
	card.data.keywords = kw
	state.hand.append(card)
	CardPileManager.discard_hand(state)
	assert_eq(state.hand.size(), 1, "Retained card should stay in hand")

# --- T6: Silent Simulation ---

func test_T6_1_silent_run_completes():
	var result = RunSimulator.simulate_run(42, "Silent")
	assert_true(result.has("outcome"), "Silent run should produce an outcome")
	assert_true(result["outcome"] in ["victory", "defeat"], "Outcome should be victory or defeat")

func test_T6_2_silent_batch_runs():
	var stats = RunSimulator.simulate_batch(50, 42, "Silent")
	assert_true(stats["win_rate"] >= 0.0 and stats["win_rate"] <= 1.0, "Win rate should be 0-1")
	gut.p("Silent random win rate (50 runs): %.1f%%" % (stats["win_rate"] * 100))

# --- Helpers ---

func _make_silent_combat() -> CombatState:
	var state = CombatState.new()
	state.player = Combatant.new()
	state.player.hp = 70
	state.player.max_hp = 70
	state.player.energy = 3
	state.player.is_player = true

	var enemy = Combatant.new()
	enemy.hp = 30
	enemy.max_hp = 30
	enemy.enemy_data = load("res://resources/enemies/goblin.tres") as EnemyData
	state.enemies.append(enemy)
	return state
