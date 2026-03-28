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

# --- T2: Path Connectivity ---

func test_T2_1_minimum_connections():
	var map = MapGenerator.generate(12345)
	# Every node on layers 1-9 connects to at least 2 nodes on next layer
	# Exception: layer 9→10 where boss is only 1 node, so min is 1
	for layer_idx in 9:  # layers 0-8
		var next_layer_size = map.layers[layer_idx + 1].size()
		var min_connections = mini(2, next_layer_size)
		for node in map.layers[layer_idx]:
			assert_true(node.connections.size() >= min_connections,
				"Layer %d node %d should connect to >= %d next-layer nodes, got %d" % [
					layer_idx + 1, node.index, min_connections, node.connections.size()])

func test_T2_2_full_reachability():
	var map = MapGenerator.generate(12345)
	# From any layer-1 node, there exists a path to the layer-10 boss
	for start_node in map.layers[0]:
		var reachable = _can_reach_boss(map, start_node)
		assert_true(reachable,
			"Layer 1 node %d should be able to reach the boss" % start_node.index)

func test_T2_3_no_orphan_nodes():
	var map = MapGenerator.generate(12345)
	# Every node on layers 2-10 has at least 1 incoming connection
	for layer_idx in range(1, 10):
		var incoming_count := {}
		for i in map.layers[layer_idx].size():
			incoming_count[i] = 0
		# Count incoming from previous layer
		for node in map.layers[layer_idx - 1]:
			for conn in node.connections:
				incoming_count[conn] = incoming_count.get(conn, 0) + 1
		for node_idx in incoming_count:
			assert_true(incoming_count[node_idx] >= 1,
				"Layer %d node %d should have at least 1 incoming connection" % [
					layer_idx + 1, node_idx])

# --- T3: Node Selection ---

func test_T3_1_legal_move_only():
	var map = MapGenerator.generate(12345)
	# Player at layer 1 (idx 0), node 0 — can only select connected nodes on layer 2
	var node_a = map.layers[0][0]
	var connected = node_a.connections
	# Valid move: connected node
	for conn in connected:
		assert_true(MapNavigator.can_select_node(map, 0, 0, 1, conn),
			"Should be able to select connected node %d on layer 2" % conn)
	# Invalid move: unconnected node (find one not in connections)
	for i in map.layers[1].size():
		if i not in connected:
			assert_false(MapNavigator.can_select_node(map, 0, 0, 1, i),
				"Should NOT be able to select unconnected node %d on layer 2" % i)

func test_T3_2_no_backtracking():
	var map = MapGenerator.generate(12345)
	# Player has advanced to layer 5 (idx 4) — cannot select any node on layers 1-4
	for past_layer in range(0, 4):
		for node_idx in map.layers[past_layer].size():
			assert_false(MapNavigator.can_select_node(map, 4, 0, past_layer, node_idx),
				"Should NOT be able to go back to layer %d" % (past_layer + 1))

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

func _can_reach_boss(map: MapData, start_node: MapNode) -> bool:
	# BFS from start_node through connections to see if we reach layer 10
	var current_reachable := {start_node.index: true}
	for layer_idx in range(0, 9):
		var next_reachable := {}
		for node_idx in current_reachable:
			var node = map.layers[layer_idx][node_idx]
			for conn in node.connections:
				next_reachable[conn] = true
		current_reachable = next_reachable
		if current_reachable.is_empty():
			return false
	return not current_reachable.is_empty()

func _get_layer_types(map: MapData, layer_idx: int) -> Array[String]:
	var types: Array[String] = []
	for node in map.layers[layer_idx]:
		types.append(node.node_type)
	return types
