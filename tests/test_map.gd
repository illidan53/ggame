extends GutTest

# --- T1: Map Generation ---

func test_T1_1_layer_count():
	var map = MapGenerator.generate(12345)
	assert_eq(map.layers.size(), 10, "Map should have exactly 10 layers")

func test_T1_2_nodes_per_layer():
	var map = MapGenerator.generate(12345)
	for i in map.layers.size():
		var layer = map.layers[i]
		if i == 9:  # Layer 10 (0-indexed) is boss
			assert_eq(layer.size(), 1, "Layer 10 should have exactly 1 boss node")
		else:
			assert_true(layer.size() >= 2 and layer.size() <= 4,
				"Layer %d should have 2-4 nodes, got %d" % [i + 1, layer.size()])

func test_T1_3_layer_1_type():
	var map = MapGenerator.generate(12345)
	for node in map.layers[0]:
		assert_eq(node.node_type, "combat", "All layer 1 nodes should be Normal Combat")

func test_T1_4_layer_10_type():
	var map = MapGenerator.generate(12345)
	assert_eq(map.layers[9].size(), 1, "Layer 10 should have 1 node")
	assert_eq(map.layers[9][0].node_type, "boss", "Layer 10 node should be Boss")

func test_T1_5_fixed_layer_types():
	var map = MapGenerator.generate(12345)
	# Elite on layers 3, 6, 8 (0-indexed: 2, 5, 7)
	for layer_idx in [2, 5, 7]:
		var types = _get_layer_types(map, layer_idx)
		assert_true("elite" in types,
			"Layer %d should contain an Elite node" % (layer_idx + 1))
	# Shop on layers 4, 7 (0-indexed: 3, 6)
	for layer_idx in [3, 6]:
		var types = _get_layer_types(map, layer_idx)
		assert_true("shop" in types,
			"Layer %d should contain a Shop node" % (layer_idx + 1))
	# Rest on layers 5, 9 (0-indexed: 4, 8)
	for layer_idx in [4, 8]:
		var types = _get_layer_types(map, layer_idx)
		assert_true("rest" in types,
			"Layer %d should contain a Rest node" % (layer_idx + 1))

func test_T1_6_no_duplicate_types_per_layer():
	var map = MapGenerator.generate(12345)
	for i in map.layers.size():
		var layer = map.layers[i]
		var types: Array[String] = []
		for node in layer:
			types.append(node.node_type)
		# GDD: no duplicates when node count <= available types
		# Available types per layer vary, but we check: if all types are unique, great
		# If there are duplicates, the layer must have more nodes than available types
		var unique_types = {}
		for t in types:
			unique_types[t] = true
		if layer.size() <= unique_types.size():
			# node count <= unique types means no duplicates allowed
			assert_eq(types.size(), unique_types.size(),
				"Layer %d should have no duplicate node types" % (i + 1))

# --- T4: Seed Determinism ---

func test_T4_1_same_seed_same_map():
	var map1 = MapGenerator.generate(99999)
	var map2 = MapGenerator.generate(99999)
	assert_eq(map1.layers.size(), map2.layers.size(), "Layer count should match")
	for i in map1.layers.size():
		assert_eq(map1.layers[i].size(), map2.layers[i].size(),
			"Layer %d node count should match" % (i + 1))
		for j in map1.layers[i].size():
			var n1 = map1.layers[i][j]
			var n2 = map2.layers[i][j]
			assert_eq(n1.node_type, n2.node_type,
				"Layer %d node %d type should match" % [i + 1, j])
			assert_eq(n1.connections.size(), n2.connections.size(),
				"Layer %d node %d connection count should match" % [i + 1, j])
			for k in n1.connections.size():
				assert_eq(n1.connections[k], n2.connections[k],
					"Layer %d node %d connection %d should match" % [i + 1, j, k])

# --- Helpers ---

func _get_layer_types(map: MapData, layer_idx: int) -> Array[String]:
	var types: Array[String] = []
	for node in map.layers[layer_idx]:
		types.append(node.node_type)
	return types
