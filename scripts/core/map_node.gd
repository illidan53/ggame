class_name MapNode
extends RefCounted

var layer: int = 0          # 0-indexed layer
var index: int = 0          # Index within the layer
var node_type: String = ""  # "combat", "elite", "shop", "rest", "event", "boss"
var connections: Array[int] = []  # Indices of connected nodes on the NEXT layer
