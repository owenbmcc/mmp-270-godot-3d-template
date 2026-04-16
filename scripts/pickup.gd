extends Node3D
## pick up objects and parent then to $Hand positions
## parent to camera in player scene
## add camera to camera export
## needs player editable children to connect signal to hud
## 
## • Node3D (player_pickup) # pickup.gd
## 	• Marker3D (hand)
## 	• Area3D (pickup_area)
## 		[pickup detector] {pickables}
## 	• CollisionShape3D
## 	• AudioStreamPlayer3D ($pickup_sound)
## 	• AudioStreamPlayer3D ($throw_sound)
## 
## fps_controller uses inputs: throw, pickup
## Defined in Project > Project Settings > Input Map
## 
## pick up objects don't need script but do need node setup:
## • RigidBody3D
## 	[pickable] {platforms, pickup detector, enemy hit box}
## 	• CollisionShape3D
## 	• Mesh/Visual

@export var camera : Camera3D
@onready var hand = $hand
@onready var pickup_area : Area3D = $pickup_area

var pull_speed = 2
var throw_speed = 8

var pickup_object = null
var is_picked = false

signal update_console(message: String)

func _ready():
	assert(camera != null, "add camera to export vars")
	assert(get_parent().get_class() == "Camera3D", "PlayerPickup must be child of player camera")

	# connect signals from pickup area to script
	pickup_area.body_entered.connect(_on_body_entered)
	pickup_area.body_exited.connect(_on_body_exited)

func _physics_process(_delta):
	# check that we have an object picked up
	if pickup_object and is_picked:
		
		# get the distance between object and hand
		var obj_pos = pickup_object.global_transform.origin
		var hand_pos = hand.global_transform.origin
		
		if pickup_object.freeze:
			pickup_object.global_transform.origin = hand_pos
			return
		
		# get the direction of that distance
		var dir = (hand_pos - obj_pos).normalized() * pull_speed
		# move the object in that direction
		pickup_object.set_linear_velocity(dir)
		var distance = hand_pos - obj_pos
		if (distance.length_squared() < 0.1):
			pickup_object.freeze = true

# detect user input
func _unhandled_input(_event):
	# if user hits "f" or pickup button
	if Input.is_action_just_pressed("pickup"):
		update_console.emit("")
		# if object detected
		if pickup_object:
			# if object already picked up
			if is_picked:
				# drop object
				if pickup_object.freeze:
					pickup_object.freeze = false
				pickup_object = null
				is_picked = false
				
			else:
				# pick up object
				is_picked = true
				if $pickup_sound:
					$pickup_sound.play()
	
	# detect user clicked throw
	if Input.is_action_just_pressed("throw") and pickup_object and is_picked:
		if pickup_object.freeze:
			pickup_object.freeze = false
		# get direction of camera
		var dir = -camera.global_transform.basis.z.normalized()
		# add an upward direction
		dir = dir + Vector3(0, 1, 0)
		# apply force in direction with throw_speed
		
		pickup_object.apply_impulse(dir * throw_speed)
		# remove object
		pickup_object = null
		is_picked = false
		if $throw_sound:
			$throw_sound.play()

func _on_body_entered(body):
	# first check if an object is picked up
	if pickup_object and is_picked:
		return # if so, end function here
	pickup_object = body
	update_console.emit("Press F to pick up box.")

func _on_body_exited(_body):
	update_console.emit("")
