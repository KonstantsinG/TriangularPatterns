class_name UniformGrid
extends RefCounted
## A data structure for efficient search of fixed-radius neighbors on a 2D plane.
## 
## It represents a [b]square grid[/b], where each cell contains corresponding points.
## When searching for neighbors, it passes only through neighboring cells, 
## and not across the entire plane, which ensures [b]high search speed[/b].


## The size of the grid cell
var _cell_size: float
## A grid size vector representing the number of cells along the X and Y axes
var _grid_size: Vector2i
## The list of cells with its identifiers, each containing the list of points
var _cells: Dictionary[int, PackedInt32Array] # Dictionary[cell_id, Array[points_ids]]


## Creates a grid with [param grid_size].X by [param grid_size].Y cells,
## each with size of [param cell_size] and distribute [param points] over it.
## [br]
## [b]Note:[/b] Use [code]cell_size=1/√(points_count)[/code] for optimal grid cells sizing.
func _init(points: PackedVector2Array, cell_size: float, grid_size: Vector2i) -> void:
	_cell_size = cell_size
	_grid_size = grid_size
	_cells = {}
	
	# Insert each point into the grid
	for i in range(points.size()):
		var px := int(points[i].x / cell_size) # numer of cell on the X axis
		var py := int(points[i].y / cell_size) # number of cell on the Y axis
		var id = _pack_id(px, py) # compute cell id by its coordinates
		
		if _cells.has(id): # if this cell is already exists
			_cells.get(id).push_back(i) # just add a point id
		else:
			_cells.set(id, PackedInt32Array([i])) # otherwise, create a cell and add a point


## Packs two [code]Int16[/code] cell coordinates into a single [code]Int32[/code] id.
func _pack_id(x: int, y: int) -> int:
	# (shift x into last 16 bits) combine (mask first 16 bits from y)
	return (x << 16) | (y & 0xFFFF)


## Unpacks [code]Int32[/code] id into two [code]Int16[/code] cell coordinates
func _unpack_id(id : int) -> Vector2i:
	var x: int = (id >> 16) & 0xFFFF # take x from last part
	var y: int = id & 0xFFFF # take y from first part
	
	return Vector2i(x, y)


## Get the points contained in a cell with coordinates ([param x], [param y])
func get_points_in_cell(x: int, y: int) -> PackedInt32Array:
	var id = _pack_id(x, y)
	var points = _cells.get(id)
	
	return points if points != null else PackedInt32Array()


## Get all the neighbors for [param point] contained in adjacent [b]8[/b] cells.
## [param point_index] is specified to avoid adding [param point] as its own neighbor.[br]
## If [code]deep_search=true[/code], the method will search for [b]all[/b] possible neighbors.
## This means that if one of the 8 adjacent cells is empty, 
## the search will continue in the cells adjacent to this cell.
func get_neighbors(point: Vector2, point_index : int, deep_search: bool = false) -> PackedInt32Array:
	var neighbors: PackedInt32Array = []
	var empty_cells: Array[Vector2i] = []
	var px := int(point.x / _cell_size) # the X coordinate of the cell containing this point
	var py := int(point.y / _cell_size) # the Y coordinate of the cell containing this point
	
	# coordinates of 8 adjacent cells
	var directions = [
		Vector2i(px - 1, py + 1), Vector2i(px, py + 1), Vector2i(px + 1, py + 1),
		Vector2i(px - 1, py    ),                       Vector2i(px + 1, py    ),
		Vector2i(px - 1, py - 1), Vector2i(px, py - 1), Vector2i(px + 1, py - 1)
	]
	
	# check own cell for neighbors
	var own_cell = get_points_in_cell(px, py)
	for p in own_cell:
		if p != point_index:
			neighbors.push_back(p)
	
	# iterate over all adjacent cells
	for d in directions:
		if _is_coordinate_valid(d): # if this cell is exist
			var cell = get_points_in_cell(d.x, d.y) # get all the points from it
			
			if cell.is_empty(): # if there is no points
				empty_cells.push_back(d) # store this cell as an empty one
			else:
				neighbors.append_array(cell) # otherwise, save the found neighbors
	
	# if deep_search value is true, we will continue searching through all empty cells
	if deep_search:
		neighbors.append_array(_get_next_pass_neighbors(Vector2i(px, py), empty_cells))
	
	return neighbors


## Checks if a cell exists with the specified [param coordinate].
func _is_coordinate_valid(coordinate: Vector2i) -> bool:
	var x_valid = coordinate.x >= 0 and coordinate.x < _grid_size.x
	var y_valid = coordinate.y >= 0 and coordinate.y < _grid_size.y
	
	return x_valid and y_valid


## Searches for neighbors of [param target] in cells adjacent to [param empty_cells].[br]
## [b]Note:[/b] This method is used by the [method get_neighbors] for [b]deep search[/b]
func _get_next_pass_neighbors(origin: Vector2i, empty_cells: Array[Vector2i]) -> PackedInt32Array:
	var neighbors: PackedInt32Array = []
	var new_empty_cells: Array[Vector2i] = []
	
	for c in empty_cells: # search for neighbors of each empty cell
		# the direction from the original search target to an empty cell,
		# in this direction the neighboring cells of the next pass will be located.
		var directions = _get_next_pass_directions(c, origin)
		
		# calculate the coordinates of the neighbors using the directions and find the points inside
		for d in directions:
			if (_is_coordinate_valid(d)): # if this cell is exists
				var cell = get_points_in_cell(d.x, d.y) # sesarch for points inside
				
				if cell.is_empty(): # if no points were found
					if not new_empty_cells.has(d):
						new_empty_cells.push_back(d) # add this cell to the empties list
				else:
					neighbors.append_array(cell) # otherwise, save neighbors
	
	# if empty cells were found during the search, call this function recursively for them.
	# we need to find all possible neighbors, so the search will continue
	# until there are no empty cells or until all possible cells are checked.
	if not new_empty_cells.is_empty():
		neighbors.append_array(_get_next_pass_neighbors(origin, new_empty_cells))
		neighbors = _remove_duplicate_neighbors(neighbors)
	
	return neighbors


## Calculates directions to [b]three[/b] adjacent [param target] cells
## in the direction from [param origin] to [param target].[br]
## The three neighbors will be calculated as follows:[br]
## [i]1. The next cell from [param target] in the direction from [param origin] to [param target][br]
## 2. The first neighbor rotated by 45 degrees clockwise around [param target][br]
## 3. The first neighbor rotated by 45 degrees counter clockwise around [param target][/i][br]
## [br]
## [b]Note:[/b] this method is used to propagate neighbor search in
## [method _get_next_pass_neighbors] for deep search
func _get_next_pass_directions(target: Vector2i, origin: Vector2i) -> Array[Vector2i]:
	var forward_direction = (target - origin).clampi(-1, 1) # forward direction from origin to target
	var cw_direction: Vector2i # ClockWise direction from origin to target
	var ccw_direction: Vector2i # Counter ClockWise direction from origin to target
	
	# The diagrams below explain the directions in specific cases
	# [ ] - cell
	# [o] - origin
	# [t] - target
	# [fw ] - forward direction
	# [cw ] - clockwise direction
	# [ccw] - counter clockwise direction
	
	# Orthogonal directions 
	# [cw ] [ ] [ ] [ ]
	# [fw ] [t] [o] [ ]
	# [ccw] [ ] [ ] [ ]
	if forward_direction.x == 0 or forward_direction.y == 0:
		cw_direction = Vector2i(forward_direction.x - forward_direction.y, 
								forward_direction.y + forward_direction.x)
		ccw_direction = Vector2i(forward_direction.x + forward_direction.y, 
								 forward_direction.y - forward_direction.x)
	# Diagonal directions
	# [fw ] [cw ]
	# [ccw] [t] [ ] [ ]
	#       [ ] [o] [ ]
	#       [ ] [ ] [ ]
	else:
		if abs(forward_direction.x) == 1:
			cw_direction = Vector2i(forward_direction.x, 0)
			ccw_direction = Vector2i(0, forward_direction.y)
		else:
			cw_direction = Vector2i(0, forward_direction.y)
			ccw_direction = Vector2i(forward_direction.x, 0)
	
	return [target + ccw_direction, target + forward_direction, target + cw_direction]


## Removes all duplicates from the [param neighbors] array
func _remove_duplicate_neighbors(neighbors : PackedInt32Array) -> PackedInt32Array:
	var unique_neighbors: PackedInt32Array = []
	
	for n in neighbors:
		if not unique_neighbors.has(n):
			unique_neighbors.push_back(n)
	
	return unique_neighbors
