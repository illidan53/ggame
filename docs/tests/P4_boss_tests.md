# P4 Test Specification — Boss & Elite Enemies

> GDD References: Section 8.2 (Elite), Section 8.3 (Boss)
> Prerequisite: All P0 + P1 + P2 + P3 tests pass

---

## T1. Boss Phase Transitions (3 cases)

| ID | Scenario | Setup | Expected Result |
|----|----------|-------|-----------------|
| T1.1 | Phase 1 active | Shadow Lord HP > 60 | Uses Phase 1 pattern (standard attack/defend) |
| T1.2 | Phase 2 trigger | Shadow Lord HP drops from 65 to 55 | Switches to Phase 2 pattern (summon minions + self-buff) |
| T1.3 | Phase 3 trigger | Shadow Lord HP drops from 35 to 25 | Switches to Phase 3 pattern (enrage, +2 Strength/turn) |

---

## T2. Boss Abilities (5 cases)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T2.1 | Phase 1 attack | Shadow Lord deals standard attack damage |
| T2.2 | Phase 1 defend | Shadow Lord gains block |
| T2.3 | Phase 2 summon | Shadow Lord spawns a minion enemy (added to enemy list) |
| T2.4 | Phase 2 self-buff | Shadow Lord gains Strength |
| T2.5 | Phase 3 enrage | Shadow Lord gains +2 Strength at start of each of its turns |

---

## T3. Elite Enemies (4 cases)

| ID | Enemy | Scenario | Expected Result |
|----|-------|----------|-----------------|
| T3.1 | Dark Knight | Turn 1-3 normal attack | Pattern: Attack(10) → Attack(10) → Defend(8), cycling |
| T3.2 | Dark Knight | After turn 3 | Attack values double to 20 |
| T3.3 | Fire Elemental | Turn 1 action | Attack(8) + apply 1 Vulnerable to player |
| T3.4 | Fire Elemental | Turn 2 action | Attack(12), no Vulnerable applied |

---

## Summary

| Category | Case Count |
|----------|-----------|
| T1. Boss Phase Transitions | 3 |
| T2. Boss Abilities | 5 |
| T3. Elite Enemies | 4 |
| **Total** | **12** |

All 12 tests + all P0+P1+P2+P3 tests (92) must pass before P4 is complete.

> Balance testing is in a separate file: [P4_balance_tests.md](P4_balance_tests.md)
