class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var card_type: String  # "Attack", "Skill", "Power"
@export var rarity: String     # "Common", "Uncommon", "Rare"
@export var base_damage: int
@export var base_block: int
@export var effect_text: String
@export var keywords: Array[String]  # ["Exhaust", "Innate", etc.]
@export var is_upgraded: bool = false
@export var target_mode: String = "single"  # "single", "aoe", "self"
