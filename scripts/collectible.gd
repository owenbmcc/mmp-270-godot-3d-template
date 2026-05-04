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

var has_audio : bool = false
var has_anim : bool = false

func _ready() -> void:
	# register item, needed for ui etc., only happens once, ignored by other instances
	global.register_item(item_name, item_type)
	
	# assert errors for missing setup / components
	if has_node("AudioStreamPlayer3D"):
		has_audio = true
		assert($AudioStreamPlayer3D.stream, "AudioStreamPlayer3D is missing stream (audio file), remove or add stream")
	if has_node("AnimationPlayer"):
		has_anim = true
		assert($AnimationPlayer.has_animation("idle"), "AnimationPlayer requires idle animation, remove or add idle")
		assert($AnimationPlayer.has_animation("activated"), "AnimationPlayer requires activated animation, remove or add activated")

func _on_body_entered(_body) -> void:
	if is_collected:
		return
	is_collected = true
	
	global.update_item(item_name)
	emit_signal("item_collected", item_name)
	
	if has_audio:
		$AudioStreamPlayer3D.play()
		if not has_anim:
			await $AudioStreamPlayer3D.finished
	
	if has_anim:
		$AnimationPlayer.play("activated")
		await $AnimationPlayer.animation_finished
		$AnimationPlayer.play("idle")
	
	queue_free() # remove object from scene
