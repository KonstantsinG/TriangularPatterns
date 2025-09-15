class_name GreedyTriangulator
extends RefCounted


#TOFIX -> bounding box offsets apply incorrectly


var _bounding_box: Vector2
var _points: PackedVector2Array


func _init(bounding_box: Vector2) -> void:
	_bounding_box = bounding_box


func triangulate(points: PackedVector2Array) -> Array[Triangle]:
	_points = points
	
	# 1. Initialize UniformGrid for high neighbors search speed
	var n = points.size()
	var bb_scale_factor = sqrt(_bounding_box.x * _bounding_box.y)
	var cell_size = bb_scale_factor / sqrt(n)
	var grid_size = Vector2i(ceil(_bounding_box.x / cell_size), ceil(_bounding_box.y / cell_size))
	var grid = UniformGrid.new(points, cell_size, grid_size)
	
	# 2. Generate all possible pairs between points-neighbors
	var pairs: Array[Triangle.Edge] = []
	var excluded_points: PackedInt32Array = []
	
	for i in range(n):
		var neighbors = grid.get_neighbors(points[i], i, true)
		for neighbor in neighbors:
			if excluded_points.has(neighbor):
				continue
			pairs.push_back(Triangle.Edge.new(i, neighbor))
		
		excluded_points.push_back(i)
	
	# 3. Sort all the pairs by its length
	var sorted_pairs: Array[int] = []
	
	for i in range(pairs.size()):
		sorted_pairs.push_back(i)
	
	sorted_pairs.sort_custom(func(a, b): 
		return _get_edge_length(pairs[a]) < _get_edge_length(pairs[b]))
	
	# 4. Add edges in triangulation one by one, checking for intersections
	var triangulation_edges: Array[Triangle.Edge] = []
	var adjacency: Dictionary[int, PackedInt32Array] = {} # Dictionary[point_id, Array[connected_edges_ids]]
	var new_edge_id := 0
	
	for i in sorted_pairs:
		var new_edge = pairs[i]
		var correct := true
		
		for j in range(triangulation_edges.size()):
			var existing_edge = triangulation_edges[j]
			
			if _is_edges_intersect(new_edge, existing_edge):
				correct = false
				break
		
		if correct:
			triangulation_edges.push_back(new_edge)
			
			if adjacency.has(new_edge.p1):
				adjacency[new_edge.p1].push_back(new_edge_id)
			else:
				adjacency.set(new_edge.p1, PackedInt32Array([ new_edge_id ]))
			if adjacency.has(new_edge.p2):
				adjacency[new_edge.p2].push_back(new_edge_id)
			else:
				adjacency.set(new_edge.p2, PackedInt32Array([ new_edge_id ]))
			
			new_edge_id += 1
	
	# 5. Construct triangles from triangulation edges using adjacency set
	var triangles: Array[Triangle] = []
	var excluded_edges : PackedInt32Array = []
	
	for i in range(triangulation_edges.size()):
		var current_edge = triangulation_edges[i]
		var neighbors_one = adjacency[current_edge.p1]
		var neighbors_two = adjacency[current_edge.p2]
		var triangles_found := 0
		
		for n_one in neighbors_one:
			if excluded_edges.has(n_one) or n_one == i:
				continue
			var edge_one = triangulation_edges[n_one]
			var point_one = edge_one.p1 if edge_one.p2 == current_edge.p1 else edge_one.p2
			
			for n_two in neighbors_two:
				if excluded_edges.has(n_two) or n_two == i:
					continue
				var edge_two = triangulation_edges[n_two]
				var point_two = edge_two.p1 if edge_one.p2 == current_edge.p2 else edge_one.p2
				
				if point_one == point_two:
					triangles_found += 1
					triangles.push_back(Triangle.new(current_edge.p1, current_edge.p2, point_one))
				
				if triangles_found >= 2:
					break
			
			if triangles_found >= 2:
					break
		
		excluded_edges.push_back(i)
	
	return triangles


func _get_edge_length(edge: Triangle.Edge) -> float:
	return _points[edge.p1].distance_to(_points[edge.p2])


func _is_edges_intersect(a: Triangle.Edge, b: Triangle.Edge) -> bool:
	# 1. Check bounding boxes
	if max(_points[a.p1].x, _points[a.p2].x) < min(_points[b.p1].x, _points[b.p2].x) \
		or max(_points[a.p1].y, _points[a.p2].y) < min(_points[b.p1].y, _points[b.p2].y):
		return false
	if max(_points[b.p1].x, _points[b.p2].x) < min(_points[a.p1].x, _points[a.p2].x) \
		or max(_points[b.p1].y, _points[b.p2].y) < min(_points[a.p1].y, _points[a.p2].y):
		return false
	
	# 2. Check for common endpoints and overlapping
	var common_points = 0
	var a_on_b = false
	var b_on_a = false
	
	# Проверяем общие точки и наложение
	if a.p1 == b.p1 or a.p1 == b.p2:
		common_points += 1
		# Проверяем, лежит ли вторая точка одного отрезка на другом
		if a.p1 == b.p1:
			b_on_a = _is_point_on_segment(_points[a.p2], _points[b.p1], _points[b.p2])
			a_on_b = _is_point_on_segment(_points[b.p2], _points[a.p1], _points[a.p2])
		else: # a.p1 == b.p2
			b_on_a = _is_point_on_segment(_points[a.p2], _points[b.p1], _points[b.p2])
			a_on_b = _is_point_on_segment(_points[b.p1], _points[a.p1], _points[a.p2])
	
	if a.p2 == b.p1 or a.p2 == b.p2:
		common_points += 1
		# Проверяем, лежит ли вторая точка одного отрезка на другом
		if a.p2 == b.p1:
			b_on_a = _is_point_on_segment(_points[a.p1], _points[b.p1], _points[b.p2])
			a_on_b = _is_point_on_segment(_points[b.p2], _points[a.p1], _points[a.p2])
		else: # a.p2 == b.p2
			b_on_a = _is_point_on_segment(_points[a.p1], _points[b.p1], _points[b.p2])
			a_on_b = _is_point_on_segment(_points[b.p1], _points[a.p1], _points[a.p2])
	
	# Обрабатываем случаи с общими точками согласно вашим правилам
	if common_points == 1:
		# Одна общая точка + наложение = пересечение
		# Одна общая точка без наложения = не пересечение
		return b_on_a or a_on_b
	elif common_points == 2:
		# Две общие точки = пересечение (отрезки идентичны или один внутри другого)
		return true
	
	# 3. Check for general intersection (no common points)
	var o1 = _orientation(_points[a.p1], _points[a.p2], _points[b.p1])
	var o2 = _orientation(_points[a.p1], _points[a.p2], _points[b.p2])
	var o3 = _orientation(_points[b.p1], _points[b.p2], _points[a.p1])
	var o4 = _orientation(_points[b.p1], _points[b.p2], _points[a.p2])
	
	# General case: different orientations
	if o1 != o2 and o3 != o4:
		return true
	
	# Collinear segments with overlap
	if o1 == 0 and _is_point_on_segment(_points[a.p1], _points[b.p1], _points[a.p2]):
		return true
	if o2 == 0 and _is_point_on_segment(_points[a.p1], _points[b.p2], _points[a.p2]):
		return true
	if o3 == 0 and _is_point_on_segment(_points[b.p1], _points[a.p1], _points[b.p2]):
		return true
	if o4 == 0 and _is_point_on_segment(_points[b.p1], _points[a.p2], _points[b.p2]):
		return true
	
	return false

# Вспомогательная функция: проверяет, лежит ли точка q на отрезке pr
func _is_point_on_segment(q: Vector2, p: Vector2, r: Vector2) -> bool:
	# Сначала проверяем коллинеарность
	if _orientation(p, q, r) != 0:
		return false
	
	# Затем проверяем, что q находится между p и r по обеим координатам
	if (q.x <= max(p.x, r.x) and q.x >= min(p.x, r.x) and
		q.y <= max(p.y, r.y) and q.y >= min(p.y, r.y)):
		return true
	return false

# Вспомогательная функция для определения ориентации трех точек
func _orientation(p: Vector2, q: Vector2, r: Vector2) -> int:
	var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
	if abs(val) < 1e-10:  # Небольшой допуск для floating point
		return 0  # коллинеарны
	return 1 if val > 0 else 2  # по часовой или против
