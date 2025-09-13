class_name GreedyTriangulator
extends RefCounted


func triangulate(points : Array[Vector2]) -> Array[Triangle]:
	var triangles : Array[Triangle] = []
	
	var lala := UniformGrid.new([], 0.0, Vector2i.DOWN)
	lala.get_neighbors()

	return triangles
