# P1 Test Specification — Map System

> GDD References: Section 3 (Map System)
> Prerequisite: All P0 tests pass

---

## T1. Map Generation (6 cases)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T1.1 | Layer count | Generated map has exactly 10 layers |
| T1.2 | Nodes per layer | Each layer has 2-4 nodes |
| T1.3 | Layer 1 type | All nodes on layer 1 are Normal Combat |
| T1.4 | Layer 10 type | Layer 10 has exactly 1 Boss node |
| T1.5 | Fixed layer types | Layer 3,6,8 contain Elite; Layer 4,7 contain Shop; Layer 5,9 contain Rest |
| T1.6 | No duplicate types per layer | When a layer has ≤ number of available types, no two nodes share the same type |

---

## T2. Path Connectivity (3 cases)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T2.1 | Minimum connections | Every node on layers 1-9 connects to at least 2 nodes on the next layer |
| T2.2 | Full reachability | From any layer-1 node, there exists a path to the layer-10 boss node |
| T2.3 | No orphan nodes | Every node on layers 2-10 has at least 1 incoming connection |

---

## T3. Node Selection (2 cases)

| ID | Scenario | Setup | Expected Result |
|----|----------|-------|-----------------|
| T3.1 | Legal move only | Player is on layer 3 node A, connected to layer 4 nodes [B, C] | Can only select B or C; selecting unconnected node D is rejected |
| T3.2 | No backtracking | Player has advanced to layer 5 | Cannot select any node on layers 1-4 |

---

## T4. Map Seed Determinism (1 case)

| ID | Scenario | Expected Result |
|----|----------|-----------------|
| T4.1 | Same seed same map | Generate map with seed X twice → identical layer structure, node types, and connections |

---

## Summary

| Category | Case Count |
|----------|-----------|
| T1. Map Generation | 6 |
| T2. Path Connectivity | 3 |
| T3. Node Selection | 2 |
| T4. Seed Determinism | 1 |
| **Total** | **12** |

All 12 tests + all P0 tests (40) must pass before P1 is complete.
