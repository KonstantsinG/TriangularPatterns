class_name BowyerWatsonTriangulator
extends RefCounted

var points : Array[Vector2]


func triangulate(_points : Array[Vector2]) -> Array[Triangle]:
	var triangles : Array[Triangle] = []
	points = _points.duplicate()
	var size = _points.size()
	
	# add gigant triangle (all points must be inside)
	points.append(Vector2(10_000, -10_000))
	points.append(Vector2(-10_000, -10_000))
	points.append(Vector2(0, 10_000))
	triangles.append(Triangle.new(size + 2, size + 1, size))
	
	var corrupted_triangles : Array[Triangle] = []
	var corrupted_edges : Array[Triangle.Edge] = []
	var new_triangle : Triangle
	
	for p in range(size):
		corrupted_triangles = _get_corrupted_triangles(p, triangles)
		corrupted_edges = _get_boundary(corrupted_triangles)
		
		for t in corrupted_triangles:
			triangles.erase(t)
		
		for e in corrupted_edges:
			new_triangle = Triangle.new(e.p1, e.p2, p)
			triangles.append(new_triangle)
	
	var big_triangles = []
	for t in triangles:
		if (t.p1 >= size or t.p2 >= size or t.p3 >= size):
			big_triangles.append(t)
	
	for t in big_triangles:
		triangles.erase(t)
	
	points.pop_back()
	points.pop_back()
	points.pop_back()
	
	return triangles


func _get_corrupted_triangles(p0 : int, _triangles : Array[Triangle]) -> Array[Triangle]:
	var corrupted_triangles : Array[Triangle] = []
	
	for t in _triangles:
		if _is_in_circumcircle(p0, t):
			corrupted_triangles.append(t)
	
	return corrupted_triangles


func _is_in_circumcircle(p0 : int, triangle : Triangle) -> bool:
	var pa = points[triangle.p1] - points[p0];
	var pb = points[triangle.p2] - points[p0];
	var pc = points[triangle.p3] - points[p0];
	
	var matrix = [
		[ pa.x, pa.y, pa.x ** 2 + pa.y ** 2 ],
		[ pb.x, pb.y, pb.x ** 2 + pb.y ** 2 ],
		[ pc.x, pc.y, pc.x ** 2 + pc.y ** 2 ]
	]
	
	return _determinant(matrix) > 0


func _determinant(matrix : Array) -> float:
	var a = matrix[0][0] * (matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1])
	var b = matrix[0][1] * (matrix[1][0] * matrix[2][2] - matrix[1][2] * matrix[2][0])
	var c = matrix[0][2] * (matrix[1][0] * matrix[2][1] - matrix[1][1] * matrix[2][0])
	
	return a - b + c;


func _get_boundary(_triangles : Array[Triangle]) -> Array[Triangle.Edge]:
	var boundary : Array[Triangle.Edge] = []
	var is_on_boundary = true
	
	for t in _triangles:
		for e in t.get_edges():
			is_on_boundary = true
			
			for corrupted_t in _triangles:
				if (t != corrupted_t and corrupted_t.is_contain_edge(e)):
					is_on_boundary = false
					break
			
			if is_on_boundary:
				boundary.append(e)
	
	return boundary
