extends Node2D


#region EXPORT_PROPERTIES
## Animation boundary settings
@export_group("Boundary")
## Animation area dimensions
@export var bounding_box: Rect2 = Rect2(50, 50, 1050, 550)
## Use fullscreen mode for the animation area dimensions[br]
## if [code]true[/code] - will use a window dimensions for bounding_box value[br]
## if [code]false[/code] - will use a user-defined bounding_box value
@export var fullscreen: bool = true
## Draw the animation area dimensions
@export var draw_bounding_box: bool = false
## Animation area dimensions color
@export var bounding_box_color: Color = Color.WEB_GREEN

## Animation points settings
@export_group("Points")
## Amount of a generated points for the animation[br]
## [i][b]100-300[/b] points give best the appearance and performance[/i]
@export_range(50, 300, 1, "or_greater") var points_amount : int = 100
## Minimum distance between a two close points[br]
## Lower values will give a more chaotic distribution of a points[br]
## Higher values will give a more uniform distribution[br]
@export_range(5, 250, 1, "or_greater") var points_min_spacing : float = 50
## Instructions on how a points will move during the simulation[br]
## Static - no movement at all[br]
## Directional - the points will start moving in a random direction, bouncing off the boundary
@export_enum("Static", "Directional") var points_movement_mode = 1
## Points normal speed
@export_range(1, 30, 1) var points_speed: float = 10
## Draw dots to indicate the points position
@export var draw_points: bool = true
## Points color
@export var points_color: Color = Color.BLACK

## Animation light and shading settings
@export_group("Light")
## Light source initial position
@export var light_position: Vector2 = Vector2(100, 100)
## Instructions on how a light source will move during the simulation[br]
## Static - no movement at all[br]
## Circular - the light source will circle around the bounding box center[br]
## Directional - the light source will start moving in a random direction, bouncing off the outer boundary
@export_enum("Static", "Circular") var light_movement_mode = 0
## Light angular speed for circular movement mode
@export_range(0.05, 1.0, 0.05) var light_angular_speed: float = 0.1
## Color gradient for shading triangles
## Left color is for the most highlighted triangles
## Right color is for the most shaded ones
@export var light_color_ramp: Gradient
## Predefined color gradients[br]
## Custom - use the color gradient specified in light_color_ramp[br]
## Animated - creates a smooth transition between all predefined gradients at runtime[br]
## B&W-rainbow - predefined gradient palettes
@export_enum("Custom", "Animated", "B&W", "Mint", "Marshmallow", "Desert", "Midnight", "ForestSunset", "Cherry", \
			 "Biscuit", "Rainbow") var color_ramp_mode = 3

## Triangulation algorithm and triangular grid settings
@export_group("Triangulation")
## Run resource-intensive operations in a separate threads[br]
## if [code]true[/code] - the triangulation loop will be performed in a separate thread (highly recommended)[br]
## if [code]false[/code] - all operations will be performed in the main thread (may cause freezes)
@export var use_multiple_threads: bool = true
## Draw triangular grid
@export var draw_triangle_borders: bool = false
## Triangular grid color
@export var triangle_borders_color: Color = Color(1.0, 1.0, 1.0, 0.1)

## Interations with animation settings
@export_group("Interaction")
## Use mouse cursor for interations
@export var cursor_interaction: bool = true
## Target object to which interactions will be applied[br]
## Points - interactions will affect the points[br]
## Light - interactions will affect the light source
@export_enum("Points", "Light") var interaction_target = 0
## Instructions on how the mouse cursor will interact with the simulation[br]
## Attract - mouse cursor (with R/LMB pressed) will attract the points[br]
## Repel - mouse cursor (with R/LMB pressed) will repel the points[br]
## Attract_and_Repel - mouse cursor with LMB pressed will attract the points, with RMB pressed will repel the points
@export_enum("Attract", "Repel", "Attract and Repel") var cursor_interaction_mode = 2
## Value that indicates how much interations will affect the targets
@export_range(1, 100, 1) var interaction_magnitude: float = 20
## Value that indicates in which radius the targets will be affected by interactions
@export_range(1, 150, 1) var interaction_radius: float = 150
#endregion


#region BASIC_ANIMATION_DATA
# containers for data
var points: Array[Vector2] = []
var directions: Array[Vector2] = []
var triangles: Array[Triangle]

var triangulator: DelaunayTriangulator = null
var animated_gradient: ColorRamp.AnimatedGradient = null
var light_angle: float = 3.9

# triangulation loop paramethers
var triangulation_timer: Timer = null
var triangulate := true
var triangulation_thread: Thread = null
var mutex := Mutex.new()
#endregion


func _ready() -> void:
	# prepare simulation
	_set_bounding_box()
	_set_light_color_ramp()
	
	_generate_points()
	_setup_triangulation()


#region INITIAL_PARAMETERS_SETUP
## set the bounding box according to a given conditions
func _set_bounding_box() -> void:
	if fullscreen: # if fullscreen is true - set bounding box as window dimensions
		bounding_box = Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	# otherwise - use user-defined dimensions


## set the light color ramp according to a given conditions
func _set_light_color_ramp() -> void:
	# if the color ramp mode is in the predefined gradients range - use it
	if color_ramp_mode >= ColorRamp.FIRST_GRADIENT:
		light_color_ramp = ColorRamp.get_gradient_by_id(color_ramp_mode)
	# if the animated color ramp mode is selected - create AnimatedGradient
	elif color_ramp_mode == ColorRamp.ANIMATED_GRADIENT:
		animated_gradient = ColorRamp.AnimatedGradient.new(ColorRamp.FIRST_GRADIENT, ColorRamp.FIRST_GRADIENT + 1)
	# if the custom color ramp is selected and it is not specified - use default value
	elif color_ramp_mode == ColorRamp.CUSTOM_GRADIENT and light_color_ramp == null:
		light_color_ramp = ColorRamp.get_gradient_by_id(ColorRamp.FIRST_GRADIENT)
#endregion


#region POINTS_GENERATION
## generate a points for the animation
func _generate_points() -> void:
	var new_point = Vector2.ZERO
	var max_iterations = 50
	var current_iteration = 0
	
	# generate the points inside the bounding box
	for i in range(points_amount):
		current_iteration = 0
		new_point = _generate_bounding_box_point()
		# try generate a valid point
		while (!_is_point_valid(new_point) and current_iteration < max_iterations):
			new_point = _generate_bounding_box_point()
			current_iteration += 1
		
		# add the generated point if it is valid
		# and generate the random movement direction for it
		if (current_iteration < max_iterations):
			points.push_back(new_point)
			directions.push_back(Vector2(randf() * 2. - 1., randf() * 2. - 1.))
	
	# generate the points outside the bounding box
	_generate_off_screen_points()


## generate a new point inside the bounding box
func _generate_bounding_box_point() -> Vector2:
	var new_point = Vector2.ZERO
	new_point.x = randf_range(bounding_box.position.x, bounding_box.position.x + bounding_box.size.x)
	new_point.y = randf_range(bounding_box.position.y, bounding_box.position.y + bounding_box.size.y)
	
	return new_point


## check if generated new_point is valid
func _is_point_valid(new_point: Vector2) -> bool:
	for p in points:
		# distance between two near points must be greather than specified minimum spacing
		if p.distance_to(new_point) < points_min_spacing:
			return false
	
	return true


## generate points outside the bounding box (for the animation continuous effect)
func _generate_off_screen_points() -> void:
	var off_screen_offset = 50 # how far from the boundary points should be
	
	# top left off-screen point
	var top_left = bounding_box.position - Vector2(off_screen_offset, off_screen_offset)
	points.push_back(top_left)
	# zero direction for the point means it must be static (not affected by the simulation)
	directions.push_back(Vector2.ZERO)
	
	# top right off-screen point
	var top_right = Vector2(bounding_box.position.x + bounding_box.size.x + off_screen_offset, \
							bounding_box.position.y - off_screen_offset)
	points.append(top_right)
	directions.append(Vector2.ZERO)
	
	# bottom right off-screen point
	var bottom_right = bounding_box.position + bounding_box.size + Vector2(off_screen_offset, off_screen_offset)
	points.append(bottom_right)
	directions.append(Vector2.ZERO)
	
	# bottom left off-screen point
	var bottom_left = Vector2(bounding_box.position.x - off_screen_offset, \
							  bounding_box.position.y + bounding_box.size.y + off_screen_offset)
	points.append(bottom_left)
	directions.append(Vector2.ZERO)
	
	# the four off-screen corner points define an off-screen frame
	# divide each segment in that frame into subsegments
	# and place a new point on the boundary of the generated segments
	_generate_line_segment_points(top_left, top_right) 			# up line segment
	_generate_line_segment_points(top_right, bottom_right) 		# right line segment
	_generate_line_segment_points(bottom_right, bottom_left) 	# bottom line segment
	_generate_line_segment_points(bottom_left, top_left)		# left line segmemt


## generate static points in the line segment [a; b]
func _generate_line_segment_points(a: Vector2, b: Vector2) -> void:
	for p in _subdivide_line_segment(a, b):
		# save each subdivided point as the static off-screen point
		points.push_back(p)
		directions.push_back(Vector2.ZERO)


## subdivide a line segment [a; b] into several smaller segments
func _subdivide_line_segment(a: Vector2, b: Vector2) -> Array[Vector2]:
	var new_points : Array[Vector2] = []
	var segments = [ {"from" : a, "to" : b} ] # store 'from' and 'to' points for each segment
	var c = (a + b) / 2 # center point
	
	# subdivide segments until the length of a subsegment is less than two minimum spacings
	while (a.distance_to(c) > max(50, points_min_spacing * 2)): # using max() to prevent generating too many off-screen points
		for i in range(segments.size()):
			a = segments[i]["from"]
			b = segments[i]["to"]
			c = (a + b) / 2 # subdivide the segment by the middle point
			new_points.push_back(c)
			
			# one large segment became two small segments
			segments.append({"from" : a, "to" : c})
			segments[i] = {"from" : c, "to" : b}
	
	return new_points
#endregion


#region TRIANGULATION_LOOP
## setup the triangulation algorithm and the thread
func _setup_triangulation() -> void:
	triangulator = DelaunayTriangulator.new()
	triangles = triangulator.triangulate(points)
	
	if use_multiple_threads: # run triangulation loop in the separated thred
		triangulation_thread = Thread.new()
		triangulation_thread.start(_triangulation_loop)
	else: # or in the main thread by the timer
		triangulation_timer = Timer.new()
		triangulation_timer.wait_time = 0.5 # retriangulate the grid each 0.5 seconds
		triangulation_timer.timeout.connect(func(): triangles = triangulator.triangulate(points))
		triangulation_timer.autostart = true
		# add to the tree and start the timer when the scene is ready
		get_tree().root.add_child.call_deferred(triangulation_timer)


## triangulation loop for the separate thread
func _triangulation_loop() -> void:
	var new_triangles
	var access
	
	# triangulation loop
	while true:
		mutex.lock() # safe general data access
		access = triangulate
		mutex.unlock()
		
		# command for shutdown the triangulation thread
		if access == false: break
		
		new_triangles = triangulator.triangulate(PackedVector2Array(points))
		mutex.lock()
		triangles = new_triangles
		mutex.unlock()
#endregion


func _process(delta: float) -> void:
	# move the points if necessary
	if points_movement_mode == 1:
		_move_points_directional(delta)
	
	# move the light source if necessary
	if light_movement_mode == 1:
		_move_light(delta)
	
	# animate the light color ramp if necessary
	if color_ramp_mode == ColorRamp.ANIMATED_GRADIENT:
		_animate_gradient(delta)
	
	# draw the next animation frame
	queue_redraw()


#region POINTS_MOVEMENT
## move the points towards the specified directions
func _move_points_directional(delta: float) -> void:
	# get mouse buttons input
	var left_input = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var right_input = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	
	for i in range(points.size()):
		var velocity = directions[i] * points_speed
		
		# if points interaction is enabled and some input is received
		if cursor_interaction and interaction_target == 0 and (left_input or right_input):
			var mouse_position = get_global_mouse_position()
			var cursor_direction = points[i].direction_to(mouse_position)
			if (cursor_interaction_mode == 1) or (cursor_interaction_mode == 2 and right_input):
				cursor_direction *= -1
			
			var distance_to_cursor = points[i].distance_to(mouse_position)
			var distance_multiplier = distance_to_cursor * 0.01
			var cursor_velocity = cursor_direction * interaction_magnitude / distance_multiplier
			if directions[i] != Vector2.ZERO and (distance_to_cursor > 15 and distance_to_cursor < interaction_radius):
				velocity += cursor_velocity
		
		_check_boundary_intersections(i)
		points[i] += velocity * delta


## check if a point intersect the simulation boundary
func _check_boundary_intersections(point_idx : int) -> void:
	# points with direction = 0 are static, we ignore them
	if directions[point_idx] == Vector2.ZERO: return
	
	# if the point is crosses the boundary, we need to inverse its direction (for auto movement)
	# and fix its position on the boundary (for cursor interactions)
	
	# negative x boundary
	if (points[point_idx].x <= bounding_box.position.x):
		directions[point_idx].x *= -1
		points[point_idx].x = bounding_box.position.x + 1
	# positive x boundary
	if points[point_idx].x >= (bounding_box.position.x + bounding_box.size.x):
		directions[point_idx].x *= -1
		points[point_idx].x = bounding_box.position.x + bounding_box.size.x - 1
	
	# positive y boundary (y-axe is reversed)
	if points[point_idx].y <= bounding_box.position.y:
		directions[point_idx].y *= -1
		points[point_idx].y = bounding_box.position.y + 1
	# negative y boundary
	if points[point_idx].y >= bounding_box.position.y + bounding_box.size.y:
		directions[point_idx].y *= -1
		points[point_idx].y = bounding_box.position.y + bounding_box.size.y - 1
#endregion


#region LIGHT_MOVEMENT
func _move_light(delta: float) -> void:
	# bounding box center
	var center = (bounding_box.size - bounding_box.position) / 2.0
	
	# if interactions with light is enables
	if cursor_interaction and interaction_target == 1:
		var left_input = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		var right_input = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		
		# if some mouse input received
		if left_input or right_input:
			# light source must follow cursor
			light_position = get_global_mouse_position()
			light_angle = (light_position - center).angle()
			return
	
	# move light source by parametric equation of a circle
	var radius = light_position.distance_to(center)
	light_angle += light_angular_speed * delta
	
	# x = r * cos(t); y = r * sin(t)
	var new_x = center.x + radius * cos(light_angle)
	var new_y = center.y + radius * sin(light_angle)
	
	light_position = Vector2(new_x, new_y)
#endregion


#region ANIMATED_GRADIENT
## animate the light color ramp based on the simulation time
func _animate_gradient(delta : float) -> void:
	# if interpolation is reached the right border:
	if animated_gradient.interpolation_ratio >= 1.0:
		animated_gradient.next_gradients_pair() 		# take the next gradients pair
		animated_gradient.interpolation_ratio = 0.0 	# and reset the interpolation ratio
	
	# increase the interpolation ratio by the frame-dependant step
	animated_gradient.interpolation_ratio += 0.05 * delta
	# update the gradient colors by interpolation
	animated_gradient.interpolate()
#endregion


func _draw() -> void:
	# draw triangular patterns
	_draw_triangles()
	
	# draw extra details
	if draw_points: _draw_points()
	if draw_bounding_box: _draw_bounding_box()


#region DRAWING
## draw the simulation borders
func _draw_bounding_box() -> void:
	draw_rect(bounding_box, bounding_box_color, false, 3.0)


## draw the points
func _draw_points() -> void:
	for p in points:
		draw_circle(p, 2, points_color)


## draw the triangles and the triangular grid
func _draw_triangles() -> void:
	mutex.lock() # lock triangulation data while drawing
	
	var distances_to_light := []
	var edges := []
	var max_distance = -INF
	var min_distance = INF
	
	# prepare data for drawing
	for i in range(triangles.size()):
		# ignore invalid triangles
		if !triangles[i].is_valid(points):
			distances_to_light.push_back(NAN) # NAN value is used here as the invalid flag
			continue
		
		# calculate distance from the triangle center to the light source position
		var center = (points[triangles[i].p1] + points[triangles[i].p2] + points[triangles[i].p3]) / 3
		var distance = center.distance_to(light_position)
		distances_to_light.push_back(distance)
		
		# save min and max distances
		if distance < min_distance: min_distance = distance
		elif distance > max_distance: max_distance = distance
		
		# if drawing triangular grid is enabled - save triangle edges data
		if draw_triangle_borders:
			for e in triangles[i].get_edges():
				if !edges.has(e): edges.push_back(e)
	
	# normalize distances and map them to the color gradient
	for i in range(triangles.size()):
		# ignore invalid triangles
		if is_nan(distances_to_light[i]): continue
		
		# remap distance between the min and max found distances
		var remapped_distance = remap(distances_to_light[i], min_distance, max_distance, 0, 1)
		
		# sample the triangle color based on the remapped distance
		# (use the animated or predefined gradient)
		var triangle_color = animated_gradient.sample(remapped_distance) if color_ramp_mode == ColorRamp.ANIMATED_GRADIENT \
							 else light_color_ramp.sample(remapped_distance)
		var triangles_points = PackedVector2Array([points[triangles[i].p1], points[triangles[i].p2], points[triangles[i].p3]])
		
		# draw the colored triangle
		draw_colored_polygon(triangles_points, triangle_color)
	
	# draw the triangle borders
	if draw_triangle_borders:
		for e in edges:
			draw_line(points[e.p1], points[e.p2], triangle_borders_color, 1)
	
	mutex.unlock()
#endregion


func _exit_tree() -> void:
	# shutdown the triangulation thread before exiting the tree
	if use_multiple_threads:
		mutex.lock()
		triangulate = false # send the shutdown command
		mutex.unlock()
		
		# wait until shutdown
		triangulation_thread.wait_to_finish()
