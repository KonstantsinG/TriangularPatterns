class_name GreedyTriangulator
extends RefCounted


class UniformGrid:
	var cell_size : int
	var cells_count : Vector2i
	var cells : Dictionary[int, Array]
	
	
	func _init(points : Array[Vector2], _cell_size : int, _cells_count : Vector2i) -> void:
		cell_size = _cell_size
		cells_count = _cells_count
		
		for p in points:
			var px = int(p.x / cell_size)
			var py = int(p.y / cell_size)
			var id = pack_id(px, py)
			
			if cells.has(id):
				cells.get(id).push_back(p)
			else:
				cells.set(id, [ p ])
	
	
	func pack_id(x : int, y : int) -> int:
		return (x << 16) | (y & 0xFFFF)
	
	
	func unpack_id(id : int) -> Vector2i:
		var a = (id >> 16) & 0xFFFF
		var b = id & 0xFFFF
		
		return Vector2i(a, b)
	
	
	func get_points_in_cell(x : int, y : int) -> Array[Vector2]:
		var id = pack_id(x, y)
		return cells.get(id)
	
	
	func get_neighbors(point : Vector2, deep_search : bool = false) -> Array[Vector2]:
		var neighbors : Array[Vector2] = []
		var empty_cells : Array[Vector2i] = []
		var px = int(point.x / cell_size)
		var py = int(point.y / cell_size)
		
		var directions = [
			Vector2i(px - 1, py + 1), Vector2i(px    , py + 1), Vector2i(px + 1, py + 1),
			Vector2i(px - 1, py    ),                           Vector2i(px + 1, py    ),
			Vector2i(px - 1, py - 1), Vector2i(px    , py - 1), Vector2i(px + 1, py - 1)
		]
		
		for d in directions:
			if _is_direction_valid(d):
				var cell = get_points_in_cell(d.x, d.y)
				
				if cell.is_empty(): empty_cells.push_back(d)
				else: neighbors.append_array(cell)
		
		if deep_search:
			neighbors.append_array(_get_next_pass_neighbors(Vector2i(px, py), empty_cells))
		
		return neighbors
	
	
	func _is_direction_valid(direction : Vector2i) -> bool:
		var x_valid = direction.x >= 0 and direction.x < cells_count.x
		var y_valid = direction.y >= 0 and direction.y < cells_count.y
		
		return x_valid and y_valid
	
	
	func _get_next_pass_neighbors(origin : Vector2i, empty_cells : Array[Vector2i]) -> Array[Vector2]:
		var neighbors : Array[Vector2] = []
		var new_empty_cells : Array[Vector2i] = []
		
		for c in empty_cells:
			var direction = (c - origin).clampi(-1, 1)
			var clockwise = Vector2i(-direction.y, direction.x)
			var counter_clockwise = Vector2(direction.y, -direction.x)
			
			for d in [c + counter_clockwise, c + direction, c + clockwise]:
				if (_is_direction_valid(d)):
					var cell = get_points_in_cell(d.x, d.y)
					
					if cell.is_empty():
						if !new_empty_cells.has(d): new_empty_cells.push_back(d)
					else:
						neighbors.push_back(cell)
		
		if !new_empty_cells.is_empty():
			neighbors.append_array(_get_next_pass_neighbors(origin, new_empty_cells))
		
		return neighbors


func triangulate(points : Array[Vector2]) -> Array[Triangle]:
	var triangles : Array[Triangle] = []
	
	
	
	return triangles
