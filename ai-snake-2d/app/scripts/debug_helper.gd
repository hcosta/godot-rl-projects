extends Node


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		get_tree().debug_collisions_hint = not get_tree().debug_collisions_hint
		var is_visible: bool = get_tree().debug_collisions_hint
		
		_toggle_collisions_recursive(get_tree().root, is_visible)
		print("Visibilidad de Colisiones: ", is_visible)

func _toggle_collisions_recursive(node: Node, is_visible: bool) -> void:
	# 1. Shapes normales
	if node is CollisionShape2D or node is CollisionPolygon2D:
		node.queue_redraw()
	
	# 2. RAYCASTS: Si los ocultamos con visible = false, Godot destruye su línea dibujada al instante
	elif node is RayCast2D:
		node.visible = is_visible
		node.queue_redraw()
		
	for child in node.get_children():
		_toggle_collisions_recursive(child, is_visible)
