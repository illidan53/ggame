# P0 Test Specification — Core Battle System

> GDD References: Section 4 (Combat), Section 5 (Cards), Section 8.0 (Enemy AI)
> Test framework: GUT (Godot Unit Test)

---

## T1. Damage Calculation (6 cases)

| ID | Scenario | Setup | Expected Result |
|----|----------|-------|-----------------|
| T1.1 | Base damage | Card deals 6 damage, target has 0 block, 20 HP | Target HP = 14 |
| T1.2 | Strength buff | Card deals 6 damage, attacker has 3 Strength | Damage dealt = 9 |
| T1.3 | Vulnerable debuff | Card deals 6 damage, target has Vulnerable | Damage dealt = 9 (6 × 1.5, floor) |
| T1.4 | Weak debuff | Card deals 6 damage, attacker has Weak | Damage dealt = 4 (6 × 0.75, floor) |
| T1.5 | Strength + Vulnerable combo | Card deals 6, attacker has 2 Strength, target has Vulnerable | Damage = floor((6+2) × 1.5) = 12 |
| T1.6 | Block absorbs damage | Card deals 10 damage, target has 6 block, 20 HP | Block → 0, HP = 16 (10-6=4 overflow) |

### Edge cases
| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T1.7 | Block fully absorbs | Deal 5 damage to target with 8 block → Block = 3, HP unchanged |
| T1.8 | Zero damage | Deal 0 base damage with no Strength → 0 damage dealt |

---

## T2. Block Calculation (3 cases)

| ID | Scenario | Setup | Expected Result |
|----|----------|-------|-----------------|
| T2.1 | Base block | Card gives 5 block | Combatant block += 5 |
| T2.2 | Dexterity buff | Card gives 5 block, combatant has 2 Dexterity | Block gained = 7 |
| T2.3 | Block resets each turn | Combatant has 10 block, new turn starts | Block = 0 |

---

## T3. Status Effects (6 cases)

| ID | Scenario | Setup | Expected Result |
|----|----------|-------|-----------------|
| T3.1 | Buff stacking | Apply Strength(2), then apply Strength(3) | Total Strength = 5 |
| T3.2 | Debuff turn decay | Apply Vulnerable(2), advance 1 turn | Vulnerable = 1 |
| T3.3 | Debuff expires | Apply Vulnerable(1), advance 1 turn | Vulnerable removed entirely |
| T3.4 | Thorns reflect | Combatant has Thorns(3), gets attacked | Attacker takes 3 damage |
| T3.5 | Auto-Block trigger | Combatant has Auto-Block(4), turn starts | Gains 4 block at turn start |
| T3.6 | Multiple effects | Combatant has Strength(2) + Weak, deals base 6 | Damage = floor((6+2) × 0.75) = 6 |

---

## T4. Card Pile Management (7 cases)

| ID | Scenario | Setup | Expected Result |
|----|----------|-------|-----------------|
| T4.1 | Battle start shuffle | Deck of 10 cards, battle begins | Draw pile has 10 cards (shuffled), discard empty |
| T4.2 | Draw cards | Draw pile has 8 cards, draw 5 | Hand has 5 cards, draw pile has 3 |
| T4.3 | End turn discard | Hand has 3 cards, end turn | Hand empty, discard pile += 3 |
| T4.4 | Reshuffle on empty | Draw pile has 2 cards, discard has 5, draw 5 | Draw 2, shuffle discard into draw, draw 3 more |
| T4.5 | Exhaust card | Play a card with Exhaust keyword | Card goes to Exhaust pile, not discard |
| T4.6 | Innate in opening hand | Deck has 1 Innate card among 10 | Innate card is always in the 5-card opening hand |
| T4.7 | Ethereal auto-exhaust | Ethereal card in hand, end turn without playing it | Card moves to Exhaust pile (not discard) |

---

## T5. Turn Flow (6 cases)

| ID | Scenario | Setup | Expected Result |
|----|----------|-------|-----------------|
| T5.1 | Turn start | New turn begins | Block resets to 0, energy = 3, draw 5 cards |
| T5.2 | Play card costs energy | Play a 2-cost card with 3 energy | Energy = 1, card effect applied |
| T5.3 | Insufficient energy | Try to play a 2-cost card with 1 energy | Card not played, energy unchanged, hand unchanged |
| T5.4 | End turn discards hand | Player ends turn with 3 cards in hand | All 3 cards move to discard pile |
| T5.5 | Victory condition | All enemies have HP ≤ 0 | Combat ends with victory result |
| T5.6 | Defeat condition | Player HP ≤ 0 | Combat ends with defeat result |

---

## T6. Enemy AI (4 cases)

| ID | Scenario | Setup | Expected Result |
|----|----------|-------|-----------------|
| T6.1 | Pattern cycles | Enemy pattern: [Attack(6), Defend(4)], 3 turns | Turn 1: Attack(6), Turn 2: Defend(4), Turn 3: Attack(6) |
| T6.2 | Intent display | Enemy next action is Attack(8) | Intent returns {type: "attack", value: 8} |
| T6.3 | Multi-enemy independence | 2 enemies with different patterns | Each advances its own pattern index independently |
| T6.4 | Conditional branch | Enemy switches pattern when HP < 50% | Below threshold → uses alternate pattern |

---

## T7. Targeting Rules (3 cases)

| ID | Scenario | Setup | Expected Result |
|----|----------|-------|-----------------|
| T7.1 | Single-target attack | Play Strike, 2 enemies on field | Must specify a target; damage applies only to that target |
| T7.2 | AOE attack | Play Whirlwind (X=2), 3 enemies on field | All 3 enemies take 10 damage (2×5 each) |
| T7.3 | Skill no target | Play Defend | No target selection needed; block applies to player |

---

## Summary

| Category | Case Count |
|----------|-----------|
| T1. Damage Calculation | 8 |
| T2. Block Calculation | 3 |
| T3. Status Effects | 6 |
| T4. Card Pile Management | 7 |
| T5. Turn Flow | 6 |
| T6. Enemy AI | 4 |
| T7. Targeting Rules | 3 |
| **Total** | **37** |

All 37 tests must pass before P0 is considered complete.
