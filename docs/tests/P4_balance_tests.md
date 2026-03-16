# P4 Test Specification — Balance (Random AI Simulation)

> Scope: Full-run simulation covering ALL systems (combat, map, rewards, shop, rest, events, relics, potions, boss)
> Prerequisite: All P0 + P1 + P2 + P3 + P4 boss/elite tests pass
> This test is placed in P4 because it requires all gameplay systems to be implemented first.

---

## Random AI Behavior

The test AI makes **uniformly random** decisions at every decision point:

| Decision Point | Random AI Behavior |
|---------------|-------------------|
| Card play (combat) | Randomly play affordable cards until energy runs out; random target for single-target attacks |
| End turn | End turn when no affordable cards remain |
| Card reward | 50% chance pick random card, 50% chance skip |
| Map path | Random connected node |
| Shop | 50% chance buy random affordable item, 50% skip |
| Rest site | 50% rest, 50% upgrade random card |
| Event | Uniformly random choice among available options |
| Potion use | 30% chance to use a random potion each turn |

---

## T1. Overall Win Rate (1 case)

| ID | Scenario | Sample Size | Expected Result |
|----|----------|-------------|-----------------|
| T1.1 | Random AI full run | 1000 runs | Win rate between **5% and 15%** |

---

## T2. Survival Curve (4 cases)

| ID | Checkpoint | Expected Survival Rate |
|----|-----------|----------------------|
| T2.1 | Reach Layer 3 (first Elite) | 70%-85% |
| T2.2 | Reach Layer 6 (second Elite) | 40%-60% |
| T2.3 | Reach Layer 9 (pre-Boss) | 20%-35% |
| T2.4 | Reach Layer 10 (Boss) | 18%-30% |

---

## T3. Average Run Depth (1 case)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T3.1 | Mean layer reached at death (across failed runs) | Between **Layer 5 and Layer 7** |

---

## T4. Boss Kill Rate (1 case)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T4.1 | Win rate given reaching Boss (conditional) | Between **30% and 50%** |

---

## T5. Death Distribution (1 case)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T5.1 | Death count by layer across all failed runs | Elite layers (3,6,8) should have higher death counts than adjacent non-Elite layers |

---

## Notes

- All tolerance ranges are preliminary and should be tuned after initial implementation
- If any metric falls outside its range, it indicates a **balance problem** — not necessarily a code bug
- These tests should run headless and complete within ~60 seconds for 1000 runs
- A failing balance test should produce a **diagnostic report** (actual values vs expected ranges) rather than a simple pass/fail
- Balance tests are separated from functional tests because they may need range adjustments independent of code changes

---

## Summary

| Category | Case Count |
|----------|-----------|
| T1. Overall Win Rate | 1 |
| T2. Survival Curve | 4 |
| T3. Average Run Depth | 1 |
| T4. Boss Kill Rate | 1 |
| T5. Death Distribution | 1 |
| **Total** | **8** |
