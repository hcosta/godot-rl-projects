extends Marker2D

@export var target_scene: PackedScene
@export var height_range: float = 100.0 

func _on_timer_timeout() -> void:
	# print("Generating Target...")
	var new_target = target_scene.instantiate()
	
	# Generate a random height in the range and set it
	var random_y = randf_range(-height_range, height_range)
	new_target.position = Vector2(0, random_y)
	
	add_child(new_target) # Add the target to the scene
