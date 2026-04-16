extends Node

@export_file var game_over_scene
@export_file var won_game_scene

func restart_level() -> void:
	get_tree().reload_current_scene()

func game_over() -> void:
	get_tree().change_scene_to_file(game_over_scene)

func won_game() -> void:
	get_tree().change_scene_to_file(won_game_scene)
