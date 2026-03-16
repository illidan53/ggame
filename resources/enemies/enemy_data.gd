class_name EnemyData
extends Resource

@export var enemy_name: String
@export var hp: int
@export var pattern: Array[Dictionary]  # [{type: "attack", value: 6}, {type: "defend", value: 4}]
@export var alt_pattern: Array[Dictionary]  # Used when HP < threshold
@export var hp_threshold_percent: float = 0.0  # 0 = no conditional branch
