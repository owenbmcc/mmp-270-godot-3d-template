extends Node
## sets any StaticBody3D to platforms layer (2)


func _ready() -> void:
	var children = find_children("StaticBody3D")
	for child in children:
		child.collision_layer = 2
