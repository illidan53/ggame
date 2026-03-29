class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var card_type: String  # "Attack", "Skill", "Power"
@export var rarity: String     # "Common", "Uncommon", "Rare"
@export var base_damage: int
@export var base_block: int
@export var effect_text: String
@export var keywords: Array[String]  # ["Exhaust", "Innate", "Ethereal", "Retain"]
@export var is_upgraded: bool = false
@export var target_mode: String = "single"  # "single", "aoe", "self"
@export var character_class: String = "Warrior"  # "Warrior", "Silent", "Neutral"

## Silent-specific fields
@export var poison_amount: int = 0       # Poison stacks to apply
@export var draw_amount: int = 0         # Cards to draw on play
@export var discard_amount: int = 0      # Cards to discard on play
@export var shiv_count: int = 0          # Shivs to add to hand
@export var weak_amount: int = 0         # Weak stacks to apply
@export var hits: int = 1                # Number of times to deal damage
@export var special_effect: String = ""  # Named special effects: "bane", "catalyst", etc.
