extends Node2D

var points : Array[Vector2] = []
var amounts = [ 100, 250, 500, 1000, 2500, 5000 ]
var bowyer_watson = BowyerWatsonTriangulator.new() # 98, 437, 1489, 5306, 31_331, 124_519


func _ready() -> void:
	#test()
	_test_intersections()


func test() -> void:
	for am in amounts:
		generate_points(am)
		calculate_time(bowyer_watson, "Bowyer-Watson with " + str(am) + " points: ")


func generate_points(amount : int) -> void:
	for i in range(amount - points.size()):
		points.append(Vector2(randf_range(-1000, 1000), randf_range(-1000, 1000)))


func calculate_time(triangulator, title) -> void:
	var start = Time.get_ticks_msec()
	triangulator.triangulate(points)
	var end = Time.get_ticks_msec()
	
	print(title, end - start, " ms")


func _test_intersections() -> void:
	var t := GreedyTriangulator.new(Vector2(5, 5))
	
	var points: PackedVector2Array = [Vector2(1,1), Vector2(4,3), Vector2(2,3), Vector2(3,0)]
	t._points = points
	var test = t._is_edges_intersect(Triangle.Edge.new(0, 1), Triangle.Edge.new(2, 3))
	assert(test == true, "1")
	
	points = [Vector2(1,1), Vector2(4,2), Vector2(1,3), Vector2(2,4)]
	t._points = points
	test = t._is_edges_intersect(Triangle.Edge.new(0, 1), Triangle.Edge.new(2, 3))
	assert(test == false, "2")
	
	points = [Vector2(1,0), Vector2(5,5), Vector2(2,4), Vector2(3,4)]
	t._points = points
	test = t._is_edges_intersect(Triangle.Edge.new(0, 1), Triangle.Edge.new(2, 3))
	assert(test == false, "3")
	
	points = [Vector2(3,1), Vector2(4,3), Vector2(2,2), Vector2(3,4)]
	t._points = points
	test = t._is_edges_intersect(Triangle.Edge.new(0, 1), Triangle.Edge.new(2, 3))
	assert(test == false, "4")
	
	points = [Vector2(1,1), Vector2(5,1), Vector2(4,1)]
	t._points = points
	test = t._is_edges_intersect(Triangle.Edge.new(0, 1), Triangle.Edge.new(2, 1))
	assert(test == true, "5")
	
	points = [Vector2(1,1), Vector2(4,2), Vector2(2,3)]
	t._points = points
	test = t._is_edges_intersect(Triangle.Edge.new(0, 1), Triangle.Edge.new(2, 0))
	assert(test == false, "6")
	
	points = [Vector2(1,2), Vector2(4,2), Vector2(3,1), Vector2(3,4)]
	t._points = points
	test = t._is_edges_intersect(Triangle.Edge.new(0, 1), Triangle.Edge.new(2, 3))
	assert(test == true, "7")
	
	points = [Vector2(1,2), Vector2(4,2), Vector2(1,1), Vector2(1,4)]
	t._points = points
	test = t._is_edges_intersect(Triangle.Edge.new(0, 1), Triangle.Edge.new(2, 3))
	assert(test == true, "8")
