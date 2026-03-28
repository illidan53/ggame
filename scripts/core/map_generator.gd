class_name MapGenerator
extends RefCounted

## Node types required on specific layers (0-indexed)
## GDD 3.2: Elite on 3,6,8 → idx 2,5,7; Shop on 4,7 → idx 3,6; Rest on 5,9 → idx 4,8
const FIXED_TYPES := {
	2: "elite",   # Layer 3
	3: "shop",    # Layer 4
	4: "rest",    # Layer 5
	5: "elite",   # Layer 6
	6: "shop",    # Layer 7
	7: "elite",   # Layer 8
	8: "rest",    # Layer 9
}

## Fill types for non-fixed slots (layers 2-8)
const FILL_TYPES: Array[String] = ["combat", "event"]

## Generate a complete map from a seed
static func generate(seed_value: int) -> MapData:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value

	var map = MapData.new()
	map.seed_value = seed_value

	# Generate nodes for each layer
	for layer_idx in 10:
		var layer: Array = []

		if layer_idx == 0:
			# Layer 1: all Normal Combat, 2-4 nodes
			var count = rng.randi_range(2, 4)
			for i in count:
				var node = MapNode.new()
				node.layer = layer_idx
				node.index = i
				node.node_type = "combat"
				layer.append(node)

		elif layer_idx == 9:
			# Layer 10: single Boss node
			var node = MapNode.new()
			node.layer = layer_idx
			node.index = 0
			node.node_type = "boss"
			layer.append(node)

		else:
			# Layers 2-9: 2-4 nodes with type rules
			var count = rng.randi_range(2, 4)
			var types = _assign_types(layer_idx, count, rng)
			for i in count:
				var node = MapNode.new()
				node.layer = layer_idx
				node.index = i
				node.node_type = types[i]
				layer.append(node)

		map.layers.append(layer)

	# Generate connections between layers
	for layer_idx in 9:  # layers 0-8 connect to next
		_connect_layers(map.layers[layer_idx], map.layers[layer_idx + 1], rng)

	return map

## Assign node types for a layer, respecting fixed-type and no-duplicate rules
static func _assign_types(layer_idx: int, count: int, rng: RandomNumberGenerator) -> Array[String]:
	var types: Array[String] = []

	# Start with the required fixed type if any
	var required_type = FIXED_TYPES.get(layer_idx, "")

	if required_type != "":
		types.append(required_type)

	# Fill remaining slots with non-duplicate types
	var available: Array[String] = []
	for t in FILL_TYPES:
		if t != required_type:
			available.append(t)
	# Also allow the other fixed types that aren't already used
	# to provide variety (but only types valid for any layer)

	while types.size() < count:
		if available.is_empty():
			# Ran out of unique types, allow duplicates
			types.append(FILL_TYPES[rng.randi_range(0, FILL_TYPES.size() - 1)])
		else:
			var pick_idx = rng.randi_range(0, available.size() - 1)
			types.append(available[pick_idx])
			available.remove_at(pick_idx)

	# Shuffle to randomize position of fixed type
	_shuffle_array(types, rng)
	return types

## Connect two adjacent layers ensuring each source node connects to ≥2 targets
## and each target node has ≥1 incoming connection
static func _connect_layers(source_layer: Array, target_layer: Array, rng: RandomNumberGenerator) -> void:
	var target_count = target_layer.size()

	# Phase 1: Give each source node 2 random connections
	for node in source_layer:
		var targets_set := {}
		while targets_set.size() < mini(2, target_count):
			var t = rng.randi_range(0, target_count - 1)
			targets_set[t] = true
		var sorted_targets: Array[int] = []
		for t in targets_set:
			sorted_targets.append(t)
		sorted_targets.sort()
		node.connections = sorted_targets

	# Phase 2: Ensure every target has at least 1 incoming connection
	var connected_targets := {}
	for node in source_layer:
		for t in node.connections:
			connected_targets[t] = true

	for t in target_count:
		if not connected_targets.has(t):
			# Pick a random source to connect to this orphan target
			var src_idx = rng.randi_range(0, source_layer.size() - 1)
			var src_node = source_layer[src_idx]
			if t not in src_node.connections:
				src_node.connections.append(t)
				src_node.connections.sort()

static func _shuffle_array(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp
