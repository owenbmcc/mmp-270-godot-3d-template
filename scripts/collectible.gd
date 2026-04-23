extends Area3D
## detects player collision to collect item
## 
## node setup:
## • Area3D (collectible name) # collectible.gd
## 	-> body_entered -> _on_body_entered (self)
## 	• CollisionShape3D
## 	~ Mesh/Visual
## 	~ AudioStreamPlayer3D
## 	~ AnimationPlayer

## name for the item to track globally
@export var item_name : String = "coin"

## type of item
@export var item_type := global.ItemTypes.COUNTABLE

## emit signal to update game manager, hud, ui, etc.
signal item_collected(item_name: String)

# prevent collecting after first collision
var is_collected = false

func _ready() -> void:
	global.register_item(item_name, item_type)

func _on_body_entered(_body) -> void:
	if is_collected:
		return
	is_collected = true
	
	global.update_item(item_name)
	emit_signal("item_collected", item_name)
	
	if has_node("AudioStreamPlayer3D"):
		$AudioStreamPlayer3D.play()
		if not has_node("AnimationPlayer"):
			await $AudioStreamPlayer3D.finished
	
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("activated")
		await $AnimationPlayer.animation_finished
		$AnimationPlayer.play("idle")
	
	queue_free() # remove object from scene
