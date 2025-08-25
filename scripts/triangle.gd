class_name Triangle
extends RefCounted

# indexes for points array
var p1 : int
var p2 : int
var p3 : int

class Edge:
	func _init(_p1 : int, _p2 : int) -> void:
		p1 = _p1
		p2 = _p2
	
	var p1 : int
	var p2 : int


func _init(_p1 : int, _p2 : int, _p3 : int) -> void:
	p1 = _p1
	p2 = _p2
	p3 = _p3

func get_edges() -> Array[Edge]:
	var e1 = Edge.new(p1, p2)
	var e2 = Edge.new(p2, p3)
	var e3 = Edge.new(p3, p1)
	return [e1, e2, e3]


func is_contain_edge(edge : Edge) -> bool:
	for e in get_edges():
		if (e.p1 == edge.p1 and e.p2 == edge.p2) or \
		   (e.p1 == edge.p2 and e.p2 == edge.p1):
			return true
	
	return false
