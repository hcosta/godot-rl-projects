extends CharacterBody2D


# Parámetros del coche (ajustables desde el Inspector)
@export var max_speed: float = 600.0
@export var acceleration: float = 1200.0
@export var braking: float = 1800.0
@export var friction: float = 400.0
@export var steering_speed: float = 3.5
@export var is_ai: bool = false
@export var sprite: Texture2D = null

@export var max_reverse_speed: float = 200.0
var pending_checkpoint_reward: float = 0.0

# Variables de input (preparadas para la IA)
var input_acceleration: float = 0.0
var input_steering: float = 0.0

# Variables de reseteo
var is_done: bool = false
var has_won: bool = false
var start_position: Vector2
var start_rotation: float

# Variables para respawn en Checkpoint
var current_checkpoint_position: Vector2
var current_checkpoint_rotation: float

func _ready() -> void:
	# El coche memoriza exactamente dónde lo pusiste en el editor
	start_position = global_position
	start_rotation = rotation
	
	# Inicializamos el checkpoint en el punto de salida
	current_checkpoint_position = start_position
	current_checkpoint_rotation = start_rotation

	# 1. Esperamos un fotograma para que todos los nodos terminen de cargarse
	await get_tree().process_frame

	# 2. Buscamos el nodo Sync en la escena principal
	var sync_node = get_tree().root.find_child("Sync", true, false)

	if sync_node:
		print("Modo del Sync detectado: ", sync_node.control_mode)
		# En el nodo Sync: 0 = Human, 1 = Training, 2 = ONNX Inference
		# Si es mayor que 0 (Training o ONNX), la IA toma el volante
		is_ai = sync_node.control_mode > 0
	else:
		# Si no hay nodo Sync en la escena (por ejemplo, haciendo pruebas aisladas)
		is_ai = false
		
	if sprite:
		$Sprite2D.texture = sprite

	print("¿El coche es IA?: ", is_ai)

func _physics_process(delta: float) -> void:
	# SOLO leemos el teclado si NO somos una IA
	if not is_ai:
		_get_manual_inputs()
	# Las físicas se aplican siempre, usando los inputs que correspondan
	_apply_car_physics(delta)

func _get_manual_inputs() -> void:
	# Lee nuestro Input Map actualizado al inglés. Devuelve un valor entre -1.0 y 1.0
	input_steering = Input.get_axis("turn_left", "turn_right")
	input_acceleration = Input.get_axis("brake", "accelerate")

func _apply_car_physics(delta: float) -> void:
	# "Hacia adelante" es el eje X local
	var forward_vector: Vector2 = transform.x 
	
	# 1. DIRECCIÓN (Solo giramos si el coche tiene velocidad)
	if velocity.length() > 20.0:
		# Invertimos el giro si vamos marcha atrás
		var moving_forward: bool = velocity.dot(forward_vector) > 0
		var turn_direction: float = 1.0 if moving_forward else -1.0
		rotation += input_steering * steering_speed * turn_direction * delta

	# 2. ACELERACIÓN Y FRENADO
	if input_acceleration > 0:
		velocity += forward_vector * input_acceleration * acceleration * delta
	elif input_acceleration < 0:
		velocity += forward_vector * input_acceleration * braking * delta
		
	# 3. FRICCIÓN (Frena el coche si soltamos el acelerador)
	if input_acceleration == 0:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
	# Limitar a la velocidad máxima (distinguiendo adelante de atrás)
	if velocity.dot(forward_vector) > 0:
		velocity = velocity.limit_length(max_speed)
	else:
		velocity = velocity.limit_length(max_reverse_speed)
	
	# 4. FÍSICAS DE DERRAPE (El toque "Arcade")
	# Calcula el impulso lateral y lo reduce drásticamente
	var lateral_velocity: Vector2 = forward_vector.orthogonal() * velocity.dot(forward_vector.orthogonal())
	velocity -= lateral_velocity * 0.85

	move_and_slide()
	
	## 5. PROCESAR EL FIN DE JUEGO
	## Godot nos dice cuántos golpes ha tenido el coche al hacer el move_and_slide()
	#if get_slide_collision_count() > 0:
		#is_done = true # ¡Nos hemos estrellado! El episodio debe terminar.
	
	# Detección de choques
	# Godot nos dice cuántos golpes ha tenido el coche al hacer el move_and_slide()
	
	if get_slide_collision_count() > 0:
		var hit_obstacle = false
		
		# Revisamos uno por uno contra qué hemos chocado en este fotograma
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			# Si el objeto golpeado existe y NO empieza por la palabra "Car"...
			if collider and not collider.name.begins_with("Car"):
				hit_obstacle = true # ¡Es un muro, una roca o el escenario!
				
		# Si confirmamos que hemos chocado contra el escenario, terminamos el episodio
		if hit_obstacle:
			is_done = true
			has_won = false
	
func reset_state() -> void:
	# 1. Volver al último checkpoint registrado
	global_position = current_checkpoint_position
	rotation = current_checkpoint_rotation
	
	# 2. Matar toda la inercia
	velocity = Vector2.ZERO
	
	# 3. Limpiar los controles
	input_acceleration = 0.0
	input_steering = 0.0
	
	# 4. Restablecer estados
	is_done = false
	has_won = false
	pending_checkpoint_reward = 0.0 # ¡Añade esta línea!
	
func reset_to_start() -> void:
	current_checkpoint_position = start_position
	current_checkpoint_rotation = start_rotation
	reset_state()

#func reach_goal() -> void:
	#is_done = true
	#has_won = true

func hit_checkpoint(checkpoint_forward: Vector2, ckpt_pos: Vector2, ckpt_rot: float) -> void:
	var alignment = transform.x.dot(checkpoint_forward)
	
	if alignment > 0:
		pending_checkpoint_reward += 25.0
		# Guardamos la posición central del checkpoint y su ángulo
		current_checkpoint_position = ckpt_pos
		current_checkpoint_rotation = ckpt_rot
	else:
		pending_checkpoint_reward -= 30.0
