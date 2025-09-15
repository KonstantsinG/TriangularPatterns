class_name Triangle
extends RefCounted

# indexes for the points array
var p1 : int
var p2 : int
var p3 : int


## triangle edge
class Edge:
	var p1 : int
	var p2 : int
	
	
	func _init(_p1 : int, _p2 : int) -> void:
		p1 = _p1
		p2 = _p2


func _init(_p1 : int, _p2 : int, _p3 : int) -> void:
	p1 = _p1
	p2 = _p2
	p3 = _p3


## get the list of edges for this triangle
func get_edges() -> Array[Edge]:
	var e1 = Edge.new(p1, p2)
	var e2 = Edge.new(p2, p3)
	var e3 = Edge.new(p3, p1)
	return [e1, e2, e3]


## checkk if this triangle contains a given edge
func is_contain_edge(edge : Edge) -> bool:
	for e in get_edges():
		if (e.p1 == edge.p1 and e.p2 == edge.p2) or \
		   (e.p1 == edge.p2 and e.p2 == edge.p1):
			return true
	
	return false


## check if this triangle is valid
## points - list of all simulation points
func is_valid(points : Array[Vector2]) -> bool:
	var eps_len := 0.5
	var eps_area := 0.25
	
	var a = points[p1]
	var b = points[p2]
	var c = points[p3]
	
	# check if one of the edges is too small
	if a.distance_squared_to(b) <= eps_len ** 2 or \
	   b.distance_squared_to(c) <= eps_len ** 2 or \
	   c.distance_squared_to(a) <= eps_len ** 2:
		return false
	
	# check if triangle area is too small
	if absf((b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)) <= eps_area:
		return false
	
	return true
