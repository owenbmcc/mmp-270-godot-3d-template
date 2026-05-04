extends CharacterBody3D
## creates an enemy that patrols an area, detects player, and "attacks"
## 
## • CharacterBody3D (Enemy) # enemy.gd
## |enemies| [enemies] {platforms}
## • CollisionShape3D
## • Mesh/Visual
## • $NavigationAgent3D
## • Area3D ($player_detector)
## [player detector] {player}
## -> body_entered -> _on_player_detector_body_entered (self)
## • Area3D ($player_attack)
## [player attack] {player}
## -> body_entered -> _on_player_attack_body_entered (self)
## • Area3D ($hit_box)
## [enemy hit box] {player, pickables} (or anything that can kill enemy)
## -> body_entered -> _on_hit_box_body_entered (self)
## ~ $AnimationPlayer ("idle", "walk", "follow", "attack")
## ~ AudioStreamPlayer3D ($detect_sound)
## ~ AudioStreamPlayer3D ($attack_sound)
## ~ PackedScene (Explosion)
## 
## requires patrol locations, separate node structure
## • Node3D (patrol locations)
## • Marker3D (patrol 1)
## • ...
## 
## add patrol locations to export var patrol_locations

@onready var nav_agent = $NavigationAgent3D
@export var speed : float = 3
@export var patrol_locations : Array[Marker3D]
@export var patrol_distance : float = 1.5
@export var attack_distance : float = 2.0
@export var character_node : Node3D
@export var explosion : PackedScene

signal enemy_attack

var patrol_index : int = 0
var wait_frame : bool = true
var is_following_player : bool = false
var is_patrolling : bool = true

var animation_player : AnimationPlayer

var has_attack_sound : bool = false
var has_detect_sound : bool = false

func _ready():
	if patrol_locations.size() == 0:
		is_patrolling = false
	set_patrol_location()
	if character_node:
		animation_player = character_node.find_child("AnimationPlayer")
		if animation_player:
			animation_player.play("walk")
	
	# assert to check audio setup
	if has_node("attack_sound"):
		has_attack_sound = true
		assert($attack_sound.stream, "attack_sound require stream (audio file), remove node or add stream")
	if has_node("detect_sound"):
		has_detect_sound = true
		assert($detect_sound.stream, "detect_sound require stream (audio file), remove node or add stream")
		

func set_patrol_location() -> void:
	if not is_patrolling:
		return
	if not patrol_locations[patrol_index].is_inside_tree():
		return # prevent error after killing player and resetting scene
	var location = patrol_locations[patrol_index].global_position
	nav_agent.set_target_position(location)

func _physics_process(_delta) -> void:
	# no navigation in the first physics frame
	if wait_frame:
		wait_frame = false
		return
	
	# if enemy gets close to patrol target, set the next target
	if nav_agent.distance_to_target() < patrol_distance and not is_following_player:
		patrol_index = patrol_index + 1
		if patrol_index >= patrol_locations.size():
			patrol_index = 0
		set_patrol_location()
		return
	
	# enemy follows player
	if nav_agent.distance_to_target() < attack_distance and is_following_player:
		if animation_player:
			animation_player.play("follow")
		return
	
	if nav_agent.is_navigation_finished():
		return
	
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * speed
	velocity = new_velocity
	if position.distance_to(current_location + new_velocity) > 0:
		look_at(current_location + new_velocity, Vector3.UP, true)
	move_and_slide()

# gets the player location from the nav region
func update_target_location(target_location):
	if not is_following_player:
		return
	nav_agent.set_target_position(target_location)

# player enters detection area
func _on_player_detector_body_entered(_body) -> void:
	is_following_player = true
	if animation_player:
		animation_player.play("follow")
	if has_detect_sound:
		$detect_sound.play()

# player leaves detection area
func _on_player_detector_body_exited(_body) -> void:
	is_following_player = false
	set_patrol_location()
	if animation_player:
		animation_player.play("walk")

# player/projectile hits hitbox
func _on_hit_box_body_entered(_body):
	if explosion:
		var e = explosion.instantiate()
		e.position = position # sets particle system to position of enemy
		get_tree().current_scene.add_child(e)
	queue_free()


func _on_player_attack_body_entered(player: CharacterBody3D) -> void:
	player.is_dead = true
	if has_attack_sound:
		$attack_sound.play()
		await $attack_sound.finished
	call_deferred("emit_signal", "enemy_attack")
