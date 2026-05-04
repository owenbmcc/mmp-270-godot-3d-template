class_name Player extends CharacterBody3D
## simple 3d fps controller
## based on
## https://github.com/rbarongr/GodotFirstPersonController/blob/main/Player/player.gd
## 
## • CharacterBody3D #PlayerController.gd (Player)
## 	• CollisionShape3D
## 	• Camera3D
## 		% player_pickup
## 	~ AudioStreamPlayer3D ($jump_sound)
## 	~ AudioStreamPlayer3D ($footstep_sound)
## 	~ Timer ($footstep_timer)
## 
## fps_controller inputs:
## move_forward, move_backward, move_right, move_left, jump
## mouse to toggle mouse capture
## Defined in Project > Project Settings > Input Map

@export_category("player")

# player physics settings
@export_range(1, 35, 1) var speed: float = 10 # m/s
@export_range(10, 400, 1) var acceleration: float = 100 # m/s^2
@export_range(0.1, 3.0, 0.1) var jump_height: float = 1 # m
@export_range(0.1, 3.0, 0.1, "or_greater") var camera_sens: float = 1

# member vars
var jumping: bool = false
var mouse_captured: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

var is_talking : bool = false
var is_dead : bool = false

@onready var camera: Camera3D = $Camera3D
@onready var footstep_timer = $footstep_timer

func _ready() -> void:
	capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look_dir = event.relative * 0.001
		if mouse_captured: _rotate_camera()
	if Input.is_action_just_pressed("jump"): jumping = true
	if Input.is_action_just_pressed("mouse"):
		if mouse_captured:
			release_mouse()
		else:
			capture_mouse()

func _physics_process(delta: float) -> void:
	if is_talking or is_dead:
		return
	if mouse_captured: _handle_joypad_camera_rotation(delta)
	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	move_and_slide()

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _rotate_camera(sens_mod: float = 1.0) -> void:
	camera.rotation.y -= look_dir.x * camera_sens * sens_mod
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod, -1.5, 1.5)

func _handle_joypad_camera_rotation(delta: float, sens_mod: float = 1.0) -> void:
	var joypad_dir: Vector2 = Input.get_vector("look_left","look_right","look_up","look_down")
	if joypad_dir.length() > 0:
		look_dir += joypad_dir * delta
		_rotate_camera(sens_mod)
		look_dir = Vector2.ZERO

func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var _forward: Vector3 = camera.global_transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	play_footstep_sound()
	return walk_vel

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel

func _jump(delta: float) -> Vector3:
	if jumping:
		if is_on_floor(): jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		if $jump_sound:
			$jump_sound.play() # maybe debug later ... 
		return jump_vel
	jump_vel = Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel

func play_footstep_sound():
	if !$footstep_sound:
		return
	# if walk vector is greater than zero, we are moving
	if walk_vel.length_squared() > 0 and is_on_floor():
		if footstep_timer.is_stopped():
			$footstep_sound.pitch_scale = randf_range(0.5, 1.5)
			$footstep_sound.play()
			footstep_timer.wait_time = randf_range(0.25, 0.35)
			footstep_timer.start()
