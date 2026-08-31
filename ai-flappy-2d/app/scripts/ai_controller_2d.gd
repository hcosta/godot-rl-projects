extends AIController2D

func get_ray_data(ray: RayCast2D) -> float:
	if ray.is_colliding():
		var distance = global_position.distance_to(ray.get_collision_point())
		return distance / ray.target_position.length()
	return 1.0

# Que veo?
func get_obs() -> Dictionary:
	var obs = [
		_player.velocity.y / 512.0,
		_player.next_target_vector.x / 288.0,
		_player.next_target_vector.y / 512.0
	]
	
	# Process and normalize all rays
	for ray in _player.raycast_sensor_2d.get_children():
		if ray is RayCast2D:
			obs.append(get_ray_data(ray))
	
	return {"obs": obs}

# que puedo hacer
func get_action_space() -> Dictionary:
	return {
		"jump_action" : { 
			"size": 2, 
			"action_type": "discrete" 
		}
	}

# que voy a hacer?
func set_action(action) -> void:
	if action["jump_action"] == 1:
		_player.jump()

# lo he hecho bien? recompensa de ciclo
func get_reward() -> float: 
	# Add a little reward for staying alive
	return reward + 0.05
