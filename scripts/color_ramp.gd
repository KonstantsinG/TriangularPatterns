extends RefCounted
class_name ColorRamp


#region GRADIENT_CONSTANTS
# gradient modes
const CUSTOM_GRADIENT 				:= 0
const ANIMATED_GRADIENT 			:= 1
# normal gradients
const BW_GRADIENT 					:= 2
const MINT_GRADIENT 				:= 3
const MARSHMALLOW_GRADIENT 			:= 4
const DESERT_GRADIENT 				:= 5
const MIDNIGHT_GRADIENT 			:= 6
const FOREST_SUNSET_GRADIENT 		:= 7
const CHERRY_GRADIENT 				:= 8
const BISCUIT_GRADIENT 				:= 9
const RAINBOW_GRADIENT 				:= 10

# normal gradients range
const FIRST_GRADIENT 				:= 2
const LAST_GRADIENT 				:= 10
#endregion


#region ANIMATED_GRADIENT
class AnimatedGradient:
	# gradient used for interpolation
	var _gradient_a : Gradient
	var _gradient_b : Gradient
	var _gradient_a_id := 0
	var _gradient_b_id := 0
	
	# gradient for interpolation result
	var _new_gradient : Gradient
	
	var _interpolation_ratio := 0.0
	var interpolation_ratio : float:
		get: return _interpolation_ratio
		set(value): _interpolation_ratio = value
	
	
	## perform linear interpolation between two gradients
	## by default interpolation ratio is taken from property with the same name
	## to get the interpolation result call sample function
	func interpolate(ratio : float = _interpolation_ratio) -> void:
		var colors := []
		
		# calculate color for each new_gradient point
		for ofs in _new_gradient.offsets:
			# sample colors from two gradients and mix them
			var color_a = _gradient_a.sample(ofs)
			var color_b = _gradient_b.sample(ofs)
			colors.push_back(_lerp_color(color_a, color_b, ratio))
		
		# store result
		_new_gradient.colors = PackedColorArray(colors)
	
	
	## sample color from interpolated gradient
	func sample(offset : float) -> Color:
		return _new_gradient.sample(offset)
	
	
	## redefine two interpolation gradients
	## new values will be taken from predefined gradients chain
	func next_gradients_pair() -> void:
		_gradient_a_id = ColorRamp.get_next_gradient_id(_gradient_a_id)
		_gradient_b_id = ColorRamp.get_next_gradient_id(_gradient_b_id)
		_gradient_a = ColorRamp.get_gradient_by_id(_gradient_a_id)
		_gradient_b = ColorRamp.get_gradient_by_id(_gradient_b_id)
		
		_new_gradient = Gradient.new()
		_calculate_new_gradient_points()
	
	
	## initializes animated gradient
	func _init(gradient_a_id : int, gradient_b_id : int) -> void:
		_gradient_a = ColorRamp.get_gradient_by_id(gradient_a_id)
		_gradient_b = ColorRamp.get_gradient_by_id(gradient_b_id)
		_gradient_a_id = gradient_a_id
		_gradient_b_id = gradient_b_id
		
		_new_gradient = Gradient.new()
		_calculate_new_gradient_points()
	
	
	## calculate points for new_gradient
	## they will be used later for gradient interpolation
	func _calculate_new_gradient_points() -> void:
		# collect and sort all points from two gradients
		var points := []
		for p in _gradient_a.offsets:
			if !points.has(p): points.push_back(p)
		for p in _gradient_b.offsets:
			if !points.has(p): points.push_back(p)
		points.sort()
		
		# set points from two gradients to new_gradient
		_new_gradient.offsets = PackedFloat32Array(points)
	
	
	## linear interpolation between two colors
	func _lerp_color(a : Color, b : Color, ratio : float) -> Color:
		return Color(
			lerpf(a.r, b.r, ratio),
			lerpf(a.g, b.g, ratio),
			lerpf(a.b, b.b, ratio),
			lerpf(a.a, b.a, ratio)
		)
#endregion


#region PREDEFINED_GRADIENTS
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


#region AUXILIARY_GRADIENT_FUNCTIONS
static func get_gradient_by_id(id : int) -> Gradient:
	match id:
		BW_GRADIENT: 				return ColorRamp.get_black_and_white_gradient()
		MINT_GRADIENT: 				return ColorRamp.get_mint_gradient()
		MARSHMALLOW_GRADIENT: 		return ColorRamp.get_marshmallow_gradient()
		DESERT_GRADIENT: 			return ColorRamp.get_desert_gradient()
		MIDNIGHT_GRADIENT: 			return ColorRamp.get_midnight_gradient()
		FOREST_SUNSET_GRADIENT: 	return ColorRamp.get_forest_sunset_gradient()
		CHERRY_GRADIENT: 			return ColorRamp.get_cherry_gradient()
		BISCUIT_GRADIENT: 			return ColorRamp.get_biscuit_gradient()
		RAINBOW_GRADIENT: 			return ColorRamp.get_rainbow_gradient()
		
		_: 							return Gradient.new()


static func get_next_gradient_id(id : int) -> int:
	if id >= LAST_GRADIENT: 		return FIRST_GRADIENT
	elif id < FIRST_GRADIENT:		return FIRST_GRADIENT
	else:							return id + 1
#endregion
