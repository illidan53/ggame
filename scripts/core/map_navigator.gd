class_name MapNavigator
extends RefCounted

## Check if a player can select a target node
## current_layer/current_node: player's current position (0-indexed)
## target_layer/target_node: where the player wants to go
static func can_select_node(map: MapData, current_layer: int, current_node: int, target_layer: int, target_node: int) -> bool:
	# No backtracking: target must be exactly the next layer
	if target_layer != current_layer + 1:
		return false

	# Target must be within bounds
	if target_layer < 0 or target_layer >= map.layers.size():
		return false
	if target_node < 0 or target_node >= map.layers[target_layer].size():
		return false

	# Must be connected from current node
	var source = map.layers[current_layer][current_node]
	return target_node in source.connections
