extends RefCounted
class_name ColorRamp


#region GRADIENTS
static func get_black_and_white_gradient() -> Gradient:
	var gradiennt = Gradient.new()
	gradiennt.offsets = PackedFloat32Array([0.0, 1.0])
	gradiennt.colors = PackedColorArray([
		Color.from_rgba8(255, 255, 255), Color.from_rgba8(0, 0, 0)
		])
	return gradiennt


static func get_mint_gradient() -> Gradient:
	var gradiennt = Gradient.new()
	gradiennt.offsets = PackedFloat32Array([0.0, 0.333, 0.666, 1.0])
	gradiennt.colors = PackedColorArray([
		Color.from_rgba8(221, 244, 231), Color.from_rgba8(103, 192, 144),
		Color.from_rgba8(38, 102, 128), Color.from_rgba8(18, 65, 112)
		])
	return gradiennt


static func get_marshmallow_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.255, 0.5, 0.888])
	gradient.colors = PackedColorArray([
		Color.from_rgba8(255, 242, 239), Color.from_rgba8(255, 207, 158),
		Color.from_rgba8(247, 153, 153), Color.from_rgba8(81, 91, 122)
	])
	return gradient


static func get_desert_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.093, 0.267, 0.795, 1.0])
	gradient.colors = PackedColorArray([
		Color.from_rgba8(246, 241, 233), Color.from_rgba8(255, 217, 61),
		Color.from_rgba8(255, 154, 0), Color.from_rgba8(79, 32, 13),
		Color.from_rgba8(51, 19, 19)
	])
	return gradient


static func get_midnight_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.08, 0.225, 0.385, 0.672, 1.0])
	gradient.colors = PackedColorArray([
		Color.from_rgba8(255, 214, 10), Color.from_rgba8(143, 86, 30),
		Color.from_rgba8(36, 65, 92), Color.from_rgba8(0, 53, 102),
		Color.from_rgba8(0, 29, 61), Color.from_rgba8(0, 8, 20)
	])
	return gradient


static func get_forest_sunset_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.05, 0.18, 0.373, 0.752, 0.925])
	gradient.colors = PackedColorArray([
		Color.from_rgba8(231, 111, 81), Color.from_rgba8(244, 162, 97),
		Color.from_rgba8(233, 196, 106), Color.from_rgba8(42, 157, 143),
		Color.from_rgba8(38, 70, 83)
	])
	return gradient


static func get_cherry_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.043, 0.174, 0.36, 0.491, 0.919])
	gradient.colors = PackedColorArray([
		Color.from_rgba8(217, 141, 98), Color.from_rgba8(217, 85, 85),
		Color.from_rgba8(217, 4, 82), Color.from_rgba8(191, 4, 91),
		Color.from_rgba8(43, 40, 61)
	])
	return gradient


static func get_biscuit_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.067, 0.207, 0.527, 0.787, 0.925])
	gradient.colors = PackedColorArray([
		Color.from_rgba8(138, 191, 166), Color.from_rgba8(191, 217, 195),
		Color.from_rgba8(38, 37, 35), Color.from_rgba8(217, 141, 98),
		Color.from_rgba8(166, 79, 60)
	])
	return gradient


static func get_rainbow_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.155, 0.304, 0.447, 0.602, 0.758, 0.925])
	gradient.colors = PackedColorArray([
		Color.from_rgba8(232, 81, 81), Color.from_rgba8(245, 159, 88),
		Color.from_rgba8(233, 196, 106), Color.from_rgba8(73, 184, 97),
		Color.from_rgba8(117, 186, 184), Color.from_rgba8(66, 134, 173),
		Color.from_rgba8(87, 50, 128)
	])
	return gradient
#endregion


## linearly interpolates two gradients a and b by given ratio
static func mix_gradients(a : Gradient, b : Gradient, ratio : float) -> Gradient:
	var new_gradient = Gradient.new()
	
	# collect and sort all points from two gradients
	var points := []
	for p in a.offsets:
		if !points.has(p): points.append(p)
	for p in b.offsets:
		if !points.has(p): points.append(p)
	points.sort()
	
	# interpolate color for each point
	var offsets := []
	var colors := []
	for p in points:
		var color_a = a.sample(p)
		var color_b = b.sample(p)
		offsets.append(p)
		colors.append(_lerp_color(color_a, color_b, ratio))
	
	new_gradient.offsets = PackedFloat32Array(offsets)
	new_gradient.colors = PackedColorArray(colors)
	
	return new_gradient


## linearly interpolates two colors a and b by given ratio
static func _lerp_color(a : Color, b : Color, ratio : float) -> Color:
	return Color(
		lerpf(a.r, b.r, ratio),
		lerpf(a.g, b.g, ratio),
		lerpf(a.b, b.b, ratio),
		lerpf(a.a, b.a, ratio)
	)
