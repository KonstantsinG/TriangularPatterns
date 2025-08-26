extends Node2D

@export_group("Boundary")
@export var bounding_box : Rect2 = Rect2(0, 0, 0, 0)
@export var fullscreen : bool = true
@export var draw_bounding_box : bool = false
@export var bounding_box_color : Color = Color.WEB_GREEN

@export_group("Points")
@export_range(3, 1000, 1, "or_greater") var points_amount : int = 100
@export_range(5, 250, 1, "or_greater") var points_min_spacing : float = 50
@export_enum("Static", "Directional") var points_movement_mode = 1
@export_range(1, 30, 1) var points_speed : float = 10
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
var directions : Array[Vector2] = []
var triangles : Array[Triangle]
var triangulator = null

var triangulation_timer : Timer = null
var triangulate := true
var triangulation_thread : Thread = null
var mutex := Mutex.new()


func _ready() -> void:
	_check_bounding_box()
	_generate_points()
	_setup_triangulation()


## setup triangulation algorithm and thread
func _setup_triangulation() -> void:
	# select triangulation algorithm
	if triangulation_algorithm == 0:
		triangulator = BowyerWatsonTriangulator.new()
	triangles = triangulator.triangulate(points)
	
	if use_multiple_threads: # run triangulation in separated thred
		_setup_triangulation_thread()
	else: # or in main thread
		triangulation_timer = Timer.new()
		triangulation_timer.wait_time = 1
		triangulation_timer.timeout.connect(_triangulate)
		triangulation_timer.autostart = true
		get_tree().root.add_child.call_deferred(triangulation_timer)


## setup triangulation loop in separate thread
func _setup_triangulation_thread() -> void:
	triangulation_thread = Thread.new()
	triangulation_thread.start(_triangulation_loop)


## triangulation loop for separated thread
func _triangulation_loop() -> void:
	var new_triangles
	var access
	
	while true:
		mutex.lock()
		access = triangulate
		mutex.unlock()
		
		if access == false:
			break
		
		new_triangles = triangulator.triangulate(points)
		mutex.lock()
		triangles = new_triangles
		mutex.unlock()


func _triangulate() -> void:
	triangles = triangulator.triangulate(points)


## set bounding box to window size if fullscreen is true
func _check_bounding_box() -> void:
	if fullscreen:
		var window = get_window()
		bounding_box = Rect2(0, 0, window.size.x, window.size.y)


## generate points for animation
func _generate_points() -> void:
	var new_point = Vector2.ZERO
	var max_iterations = 50
	var current_iteration = 0
	
	# generate on_screen points
	for i in range(points_amount):
		current_iteration = 0
		new_point = _generate_bounding_box_point()
		# try generate valid point
		while (!_is_point_valid(new_point) and current_iteration < max_iterations):
			new_point = _generate_bounding_box_point()
			current_iteration += 1
		
		# add generated point if it is valid
		if (current_iteration < max_iterations):
			points.append(new_point)
			directions.append(Vector2(randf() * 2. - 1., randf() * 2. - 1.))
	
	_generate_off_screen_points()


## generate point inside bounding box
func _generate_bounding_box_point() -> Vector2:
	var new_point = Vector2.ZERO
	new_point.x = randf_range(bounding_box.position.x, bounding_box.position.x + bounding_box.size.x)
	new_point.y = randf_range(bounding_box.position.y, bounding_box.position.y + bounding_box.size.y)
	
	return new_point


## generate points outside bounding box (for continuous effect)
func _generate_off_screen_points() -> void:
	var off_screen_offset = 50
	var top_left = bounding_box.position - Vector2(off_screen_offset, off_screen_offset)
	points.append(top_left)
	directions.append(Vector2.ZERO)
	
	var top_right = Vector2(bounding_box.position.x + bounding_box.size.x + off_screen_offset, \
							bounding_box.position.y - off_screen_offset)
	points.append(top_right)
	directions.append(Vector2.ZERO)
	
	var bottom_right = bounding_box.position + bounding_box.size + Vector2(off_screen_offset, off_screen_offset)
	points.append(bottom_right)
	directions.append(Vector2.ZERO)
	
	var bottom_left = Vector2(bounding_box.position.x - off_screen_offset, \
							  bounding_box.position.y + bounding_box.size.y + off_screen_offset)
	points.append(bottom_left)
	directions.append(Vector2.ZERO)
	
	_generate_line_segment_points(top_left, top_right)
	_generate_line_segment_points(top_right, bottom_right)
	_generate_line_segment_points(bottom_right, bottom_left)
	_generate_line_segment_points(bottom_left, top_left)


## generate static points in line segment
func _generate_line_segment_points(a : Vector2, b : Vector2) -> void:
	for p in _subdivide_line_segment(a, b):
		points.append(p)
		directions.append(Vector2.ZERO)


## check if point is valid
func _is_point_valid(new_point) -> bool:
	for p in points:
		if p.distance_to(new_point) < points_min_spacing:
			return false
	
	return true


## subdivide line segment in multiple small segments
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


func _process(delta: float) -> void:
	if points_movement_mode == 1:
		_move_points_directional(delta)
	
	queue_redraw()


## move points towards specified direction
func _move_points_directional(delta : float) -> void:
	for i in range(points.size()):
		points[i] += directions[i] * points_speed * delta
		
		if (points[i].x <= bounding_box.position.x) or (points[i].x >= bounding_box.position.x + bounding_box.size.x):
			directions[i].x *= -1
		if (points[i].y <= bounding_box.position.y) or (points[i].y >= bounding_box.position.y + bounding_box.size.y):
			directions[i].y *= -1


func _draw() -> void:
	_draw_triangles()
	if draw_points: _draw_points()
	if draw_bounding_box: _draw_bounding_box()


func _draw_bounding_box() -> void:
	draw_rect(bounding_box, bounding_box_color, false, 3.0)


func _draw_points() -> void:
	for p in points:
		draw_circle(p, 2, points_color)


func _draw_triangles() -> void:
	mutex.lock()
	
	var distances_to_light = []
	var edges = []
	var max_distance = -INF
	var min_distance = INF
	
	# calculate distances from triangles to light
	for i in range(triangles.size()):
		var center = (points[triangles[i].p1] + points[triangles[i].p2] + points[triangles[i].p3]) / 3
		var distance = center.distance_to(light_position)
		distances_to_light.append(distance)
		
		if distance < min_distance: min_distance = distance
		elif distance > max_distance: max_distance = distance
		
		if draw_triangle_borders:
			for e in triangles[i].get_edges():
				if !edges.has(e): edges.append(e)
	
	# normalize distances and map them to color gradient
	for i in range(triangles.size()):
		var remapped_distance = remap(distances_to_light[i], min_distance, max_distance, 0, 1)
		var triangle_color = light_color_ramp.sample(remapped_distance)
		var triangles_points = PackedVector2Array([points[triangles[i].p1], points[triangles[i].p2], points[triangles[i].p3]])
		
		draw_colored_polygon(triangles_points, triangle_color)
	
	# draw triangle borders
	if draw_triangle_borders:
		for e in edges:
			draw_line(points[e.p1], points[e.p2], triangle_borders_color, 1)
	
	mutex.unlock()


func _exit_tree() -> void:
	if use_multiple_threads:
		mutex.lock()
		triangulate = false
		mutex.unlock()
		
		triangulation_thread.wait_to_finish()
