class_name EnemyData
extends Resource

@export var enemy_name: String
@export var hp: int
@export var pattern: Array[Dictionary]  # [{type: "attack", value: 6}, {type: "defend", value: 4}]
@export var alt_pattern: Array[Dictionary]  # Used when HP < threshold
@export var hp_threshold_percent: float = 0.0  # 0 = no conditional branch

## Boss-specific: multiple phases with HP thresholds
## Each entry: {hp_threshold: int, pattern: Array[Dictionary]}
## Phases checked from last to first (lowest HP first)
@export var is_boss: bool = false
@export var phases: Array[Dictionary] = []
