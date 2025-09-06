class_name BowyerWatsonTriangulator
extends RefCounted

var _points : Array[Vector2]


## generate a triangular grid from a given points array
func triangulate(points : Array[Vector2]) -> Array[Triangle]:
	var triangles : Array[Triangle] = []
	_points = points.duplicate() # duplicate the points array to leave the original data unchanged
	var size = points.size()
	
	# STEP 1:
	# add a giant triangle to the triangulation (all points should fit inside)
	_points.push_back(Vector2(10_000, 10_000)) # bottom right
	_points.push_back(Vector2(-10_000, 10_000)) # bottom left
	_points.push_back(Vector2(0, -10_000)) # up center
	# all triangles must be defined in a clockwise order
	triangles.push_back(Triangle.new(size + 2, size, size + 1))
	
	var corrupted_triangles : Array[Triangle]
	var corrupted_edges : Array[Triangle.Edge]
	var new_triangle : Triangle
	
	# STEP 2:
	# add each point to the triangulation one by one
	for p in range(size):
		# 2.1: find triangles that became corrupted after adding the new point
		corrupted_triangles = _get_corrupted_triangles(p, triangles)
		# 2.2: find list of edges that surround all corrupted triangles
		corrupted_edges = _get_boundary(corrupted_triangles)
		
		# 2.3: remove all corrupted triangles from the triangulation
		for t in corrupted_triangles:
			triangles.erase(t)
		
		# 2.4: retriangulate area of a removed triangles using the new point
		for e in corrupted_edges:
			new_triangle = Triangle.new(e.p1, e.p2, p)
			triangles.append(new_triangle)
	
	# STEP 3:
	# remove all giant triangle remnants from the triangulation
	var big_triangles = []
	for t in triangles:
		if (t.p1 >= size or t.p2 >= size or t.p3 >= size):
			big_triangles.push_back(t)
	
	for t in big_triangles:
		triangles.erase(t)
	
	return triangles


## find all triangles that became corrupted after adding a new point
## the corrupted triangles are determined by the Delaunay condition
func _get_corrupted_triangles(new_point : int, _triangles : Array[Triangle]) -> Array[Triangle]:
	var corrupted_triangles : Array[Triangle] = []
	
	for t in _triangles:
		# if the new point is lies inside the circumcircle of the triangle
		# the Delaunay condition is false and the triangle is determined to be corrupted
		if _is_in_circumcircle(new_point, t):
			corrupted_triangles.append(t)
	
	return corrupted_triangles


## checks whether a given point lies inside a given triangle
func _is_in_circumcircle(point : int, triangle : Triangle) -> bool:
	# calculate vectors from the given point to all vertices of the given triangle
	# it transfers the system to a state in which the given point is at the coordinate center (0; 0)
	var pa = _points[triangle.p1] - _points[point];
	var pb = _points[triangle.p2] - _points[point];
	var pc = _points[triangle.p3] - _points[point];
	
	# matrix for checking the circumcircle condition
	var matrix = [
		[ pa.x, pa.y, pa.x ** 2 + pa.y ** 2 ],
		[ pb.x, pb.y, pb.x ** 2 + pb.y ** 2 ],
		[ pc.x, pc.y, pc.x ** 2 + pc.y ** 2 ]
	]
	
	# if the matrix determinant is greater than zero (and the triangle is set in clockwise order)
	# the given point is located inside the circumcircle
	return _determinant(matrix) > 0


## calculate determinant of a given matrix
func _determinant(matrix : Array) -> float:
	var a = matrix[0][0] * (matrix[1][1] * matrix[2][2] - matrix[1][2] * matrix[2][1])
	var b = matrix[0][1] * (matrix[1][0] * matrix[2][2] - matrix[1][2] * matrix[2][0])
	var c = matrix[0][2] * (matrix[1][0] * matrix[2][1] - matrix[1][1] * matrix[2][0])
	
	return a - b + c;


## find the outer boundary of a given triaangles set
func _get_boundary(_triangles : Array[Triangle]) -> Array[Triangle.Edge]:
	var boundary : Array[Triangle.Edge] = []
	var is_on_boundary = true
	
	for t in _triangles:
		for e in t.get_edges():
			is_on_boundary = true
			
			# find all unique edges the triangles set
			for t2 in _triangles:
				if (t != t2 and t2.is_contain_edge(e)):
					is_on_boundary = false
					break
			
			if is_on_boundary:
				boundary.append(e)
	
	return boundary
