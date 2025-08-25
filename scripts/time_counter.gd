extends Node2D

var points : Array[Vector2] = []
var amounts = [ 100, 250, 500, 1000, 2500, 5000 ]
var bowyer_watson = BowyerWatsonTriangulator.new() # 98, 437, 1489, 5306, 31_331, 124_519


func _ready() -> void:
	test()


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
