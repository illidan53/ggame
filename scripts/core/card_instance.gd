class_name CardInstance
extends RefCounted

## Reference to the card's base data
var data: CardData
## Unique ID for this instance in combat
var instance_id: int

static var _next_id: int = 0

func _init(card_data: CardData = null) -> void:
	data = card_data
	instance_id = _next_id
	_next_id += 1

func has_keyword(keyword: String) -> bool:
	if data == null:
		return false
	return data.keywords.has(keyword)
