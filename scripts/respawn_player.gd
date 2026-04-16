extends Area3D
## respawns player to position
## use for resetting player position when player falls off a platform
## could also respawn/teleport/portal player in level
## 
## node setup
## • Area3D (player catcher) # respawn_player.gd
## 	-> body_entered -> _on_body_entered (self)
## 	• CollisionShape3D [platforms] {player}

# position to respawn player to
@export var respawn_point : Node3D

# if player enters, reset position to respawn point
func _on_body_entered(body):
	body.position = respawn_point.position
	body.rotation = respawn_point.rotation
