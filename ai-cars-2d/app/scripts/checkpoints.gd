extends Area2D

func _on_body_entered(body: Node2D) -> void:
	# Si lo que nos cruza es un coche...
	if body.has_method("hit_checkpoint"):
		# Obtenemos hacia dónde mira el checkpoint (la flecha roja / eje X).
		# Como usamos 'global_transform', esto funciona en horizontal, vertical o diagonal.
		var track_direction = global_transform.x
		
		# Le enviamos al coche: el vector de dirección, la posición del checkpoint y su rotación
		body.hit_checkpoint(track_direction, global_position, global_rotation)
		
