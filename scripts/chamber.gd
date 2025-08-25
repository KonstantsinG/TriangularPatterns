extends Node2D

@export_group("Boundary")
@export var bounding_box : Rect2 = Rect2(0, 0, 0, 0)
@export var fullscreen : bool = true
@export var draw_bounding_box : bool = false
@export var bounding_box_color : Color = Color.WEB_GREEN

@export_group("Points")
@export_range(3, 1000, 1, "or_greater") var points_amount : int = 150
@export_range(0, 250, 1, "or_greater") var points_min_spacing : float = 20
@export var draw_points : bool = true
@export var points_color : Color = Color.BLACK

@export_group("Light")
@export var light_position : Vector2 = Vector2(100, 100)
@export_enum("Static", "Circular") var light_movement_mode = 0
@export var light_color_ramp : Gradient
@export_enum("Custom", "Mint", "Rainbow") var color_ramp_mode = 0

@export_group("Triangulation")
@export_enum("Delaunay", "Greedy") var triangulation_algorithm = 0
@export var use_multiple_threads : bool = true
@export var draw_triangle_borders : bool = false
@export var triangle_borders_color : Color = Color.WHITE


var points : Array[Vector2] = []
var targets : Array[Vector2] = []
var triangles : Array[Triangle]
var bowyer_watson = null

var triangulate := true
var triangulation_thread : Thread = null
var mutex : Mutex = null


func _ready() -> void:
	_check_bounding_box()
	_generate_points()
	
	bowyer_watson = BowyerWatsonTriangulator.new()
	triangles = bowyer_watson.triangulate(points)
	
	_setup_triangulation_thread()


func _setup_triangulation_thread() -> void:
	triangulation_thread = Thread.new()
	mutex = Mutex.new()
	triangulation_thread.start(_triangulation_loop)


func _triangulation_loop() -> void:
	var new_triangles
	var access
	
	while true:
		mutex.lock()
		access = triangulate
		mutex.unlock()
		
		if access == false:
			break
		
		new_triangles = bowyer_watson.triangulate(points)
		mutex.lock()
		triangles = new_triangles
		mutex.unlock()


func _check_bounding_box() -> void:
	if fullscreen:
		var window = get_window()
		bounding_box = Rect2(0, 0, window.size.x, window.size.y)


func _generate_points() -> void:
	var new_point = Vector2.ZERO
	var max_iterations = 50
	var current_iteration = 0
	
	# generate on_screen points
	for i in range(points_amount):
		current_iteration = 0
		new_point = _generate_point()
		# try generate valid point
		while (!_is_point_valid(new_point) and current_iteration < max_iterations):
			new_point = _generate_point()
			current_iteration += 1
		
		# add generated point if it is valid
		if (current_iteration < max_iterations):
			points.append(new_point)
			targets.append(new_point + Vector2(randf_range(-100, 100), randf_range(-100, 100)))
	
	# generate off_screen points
	var off_screen_offset = 50
	var top_left = bounding_box.position - Vector2(off_screen_offset, off_screen_offset)
	points.append(top_left)
	targets.append(top_left)
	
	var top_right = Vector2(bounding_box.position.x + bounding_box.size.x + off_screen_offset, \
							bounding_box.position.y - off_screen_offset)
	points.append(top_right)
	targets.append(top_right)
	
	var bottom_right = bounding_box.position + bounding_box.size + Vector2(off_screen_offset, off_screen_offset)
	points.append(bottom_right)
	targets.append(bottom_right)
	
	var bottom_left = Vector2(bounding_box.position.x - off_screen_offset, \
							  bounding_box.position.y + bounding_box.size.y + off_screen_offset)
	points.append(bottom_left)
	targets.append(bottom_left)
	
	for p in _subdivide_line_segment(top_left, top_right):
		points.append(p)
		targets.append(p)
	
	for p in _subdivide_line_segment(top_right, bottom_right):
		points.append(p)
		targets.append(p)
	
	for p in _subdivide_line_segment(bottom_right, bottom_left):
		points.append(p)
		targets.append(p)
	
	for p in _subdivide_line_segment(bottom_left, top_left):
		points.append(p)
		targets.append(p)


func _generate_point() -> Vector2:
	var new_point = Vector2.ZERO
	new_point.x = randf_range(bounding_box.position.x, bounding_box.position.x + bounding_box.size.x)
	new_point.y = randf_range(bounding_box.position.y, bounding_box.position.y + bounding_box.size.y)
	
	return new_point


func _is_point_valid(new_point) -> bool:
	for p in points:
		if p.distance_to(new_point) < points_min_spacing:
			return false
	
	return true


func _subdivide_line_segment(a : Vector2, b : Vector2) -> Array[Vector2]:
	var new_points : Array[Vector2] = []
	var segments = [ {"from" : a, "to" : b} ]
	var c = (a + b) / 2
	
	while (a.distance_to(c) > points_min_spacing * 2):
		for i in range(segments.size()):
			a = segments[i]["from"]
			b = segments[i]["to"]
			c = (a + b) / 2
			new_points.append(c)
			
			segments.append({"from" : a, "to" : c})
			segments[i] = {"from" : c, "to" : b}
	
	return new_points


func _process(_delta: float) -> void:
	_move_points()
	queue_redraw()


func _move_points() -> void:
	for i in range(points.size()):
		targets[i] += Vector2(randf_range(-1, 1), randf_range(-1, 1))
		var newpos_x = move_toward(points[i].x, targets[i].x, 0.1)
		var newpos_y = move_toward(points[i].y, targets[i].y, 0.1)
		
		targets[i].x += newpos_x - points[i].x
		targets[i].y += newpos_y - points[i].y
		points[i].x = newpos_x
		points[i].y = newpos_y


func _draw() -> void:
	_draw_triangles()
	_draw_points()
	_draw_bounding_box()


func _draw_bounding_box() -> void:
	draw_rect(bounding_box, Color.WEB_GREEN, false, 3.0)


func _draw_points() -> void:
	for p in points:
		draw_circle(p, 2, Color.RED)


func _draw_triangles() -> void:
	mutex.lock()
	
	var distances_to_light = []
	var max_distance = -INF
	var min_distance = INF
	
	for i in range(triangles.size()):
		var center = (points[triangles[i].p1] + points[triangles[i].p2] + points[triangles[i].p3]) / 3
		var distance = center.distance_to(light_position)
		distances_to_light.append(distance)
		
		if distance < min_distance: min_distance = distance
		elif distance > max_distance: max_distance = distance
	
	for i in range(triangles.size()):
		var remapped_distance = remap(distances_to_light[i], min_distance, max_distance, 0, 1)
		var triangle_color = light_color_ramp.sample(remapped_distance)
		var triangles_points = PackedVector2Array([points[triangles[i].p1], points[triangles[i].p2], points[triangles[i].p3]])
		
		draw_colored_polygon(triangles_points, triangle_color)
	
	mutex.unlock()


func _exit_tree() -> void:
	mutex.lock()
	triangulate = false
	mutex.unlock()
	
	triangulation_thread.wait_to_finish()
