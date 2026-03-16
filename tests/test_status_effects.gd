extends GutTest

# T3. Status Effects (6 cases)

func test_T3_1_buff_stacking():
	# Apply Strength(2), then apply Strength(3) → Total Strength = 5
	var combatant = Combatant.new()
	StatusEffects.apply_effect(combatant, "Strength", 2)
	StatusEffects.apply_effect(combatant, "Strength", 3)
	assert_eq(combatant.get_status_stacks("Strength"), 5, "Strength should stack additively")

func test_T3_2_debuff_turn_decay():
	# Apply Vulnerable(2), advance 1 turn → Vulnerable = 1
	var combatant = Combatant.new()
	StatusEffects.apply_effect(combatant, "Vulnerable", 2)
	StatusEffects.tick_effects(combatant)
	assert_eq(combatant.get_status_stacks("Vulnerable"), 1, "Vulnerable should decay by 1 per turn")

func test_T3_3_debuff_expires():
	# Apply Vulnerable(1), advance 1 turn → Vulnerable removed entirely
	var combatant = Combatant.new()
	StatusEffects.apply_effect(combatant, "Vulnerable", 1)
	StatusEffects.tick_effects(combatant)
	assert_false(combatant.has_status("Vulnerable"), "Vulnerable should be removed when stacks reach 0")

func test_T3_4_thorns_reflect():
	# Combatant has Thorns(3), gets attacked → Attacker takes 3 damage
	var defender = Combatant.new()
	defender.hp = 20
	defender.max_hp = 20
	StatusEffects.apply_effect(defender, "Thorns", 3)

	var attacker = Combatant.new()
	attacker.hp = 20
	attacker.max_hp = 20

	var thorns_dmg = StatusEffects.get_thorns_damage(defender)
	CombatCalc.apply_damage_to_target(attacker, thorns_dmg)
	assert_eq(attacker.hp, 17, "Attacker should take 3 thorns damage")

func test_T3_5_auto_block_trigger():
	# Combatant has Auto-Block(4), turn starts → Gains 4 block
	var combatant = Combatant.new()
	combatant.block = 0
	StatusEffects.apply_effect(combatant, "AutoBlock", 4)
	StatusEffects.apply_turn_start_effects(combatant)
	assert_eq(combatant.block, 4, "Auto-Block should grant block at turn start")

func test_T3_6_multiple_effects():
	# Combatant has Strength(2) + Weak, deals base 6 → floor((6+2) × 0.75) = 6
	var combatant = Combatant.new()
	StatusEffects.apply_effect(combatant, "Strength", 2)
	StatusEffects.apply_effect(combatant, "Weak", 1)

	var strength = combatant.get_status_stacks("Strength")
	var is_weak = combatant.has_status("Weak")
	var result = CombatCalc.calculate_damage(6, strength, is_weak, false)
	assert_eq(result, 6, "Strength(2) + Weak on base 6 = floor((6+2)*0.75) = 6")
