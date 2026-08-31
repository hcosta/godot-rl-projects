extends CharacterBody2D

const JUMP_VELOCITY = -250.0

# Texturas de las alas
@export var texture_up: Texture2D = preload("res://sprites/yellowbird-upflap.png")
@export var texture_mid: Texture2D = preload("res://sprites/yellowbird-midflap.png")
@export var texture_down: Texture2D = preload("res://sprites/yellowbird-downflap.png")

# Referencias a los nodos necesarios
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var ai_controller = $AIController2D # Aseguraos la ruta
@onready var raycast_sensor_2d: RaycastSensor2D = $RaycastSensor2D
@onready var initial_pos = position

var jumps_counter = 0
var ceil_distance_norm = 1.0  # ← Rename
var floor_distance_norm = 1.0  # ← Rename
var next_target_vector = Vector2(288.0, 0)

func _ready():
	# Iniciamos la IA pasándole referencia a este cuerpo
	ai_controller.init(self)
	
	# Enable all the rays in the raycast sensor
	for ray in raycast_sensor_2d.get_children():
		if ray is RayCast2D:
			ray.enabled = true
	
func _physics_process(delta: float) -> void:	     
	# CADA 10000 FOTOGRAMAS (STEPS POR DEFECTO AICONTROLLER2D) LA IA ACABA EL CAPITULO 
	# PARA INICIAR UNO NUEVO DEBEMOS REINICIAR EL JUEGO [PERO SIN PENALIZARLA]
	# POR ESO TENEMOS QUE DIFERENCIAR ENTRE PARTIDA PERDIDA Y REINICIAR PARTIDA
	if ai_controller.needs_reset:
		ai_controller.reset() # Envía los datos finales a Python
		game_reset()          # Reiniciar la partida
		return                # Importante: No seguimos calculando físicas este frame

	# 2. GRAVEDAD
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Human actions
	if Input.is_action_just_pressed("ui_accept"):
		jump()
		
	move_and_slide()
	
	# ANIMACIÓN Y ROTACIÓN ESTILO FLAPPY BIRD
	_update_bird_animation(delta)
	
	# detecta colision estática en el techo o en el suelo
	if get_slide_collision_count() > 0:
		game_over()
	
	# Calculate next target vector
	update_next_target_vector()

	# Redibujar debug (rayos)
	queue_redraw() 

func jump():
	velocity.y = JUMP_VELOCITY
	jumps_counter += 1

func _update_bird_animation(delta: float) -> void:
	# A) Cambiar textura según la velocidad Y
	if velocity.y < -50:
		sprite_2d.texture = texture_up     # Subiendo fuerte: alas arriba
	elif velocity.y > 50:
		sprite_2d.texture = texture_down   # Cayendo: alas abajo
	else:
		sprite_2d.texture = texture_mid    # Transición/Punto alto: alas en medio

	# B) Rotación suave según la velocidad vertical
	# Si cae (velocity.y > 0), rotará hacia abajo (hasta unos 70º / 1.2 rad)
	# Si sube (velocity.y < 0), rotará hacia arriba (hasta unos -25º / -0.4 rad)
	var target_rotation = clamp(velocity.y * 0.003, -0.4, 1.2)
	sprite_2d.rotation = lerp_angle(sprite_2d.rotation, target_rotation, 12.0 * delta)

# Esta función se llama desde la señal de la SafeZone cuando salimos del área
func game_over():
	# Solo es necesario configurar recompensas y reinicios durante el entrenamiento
	if ai_controller:
		## CASTIGO: Le damos un golpe negativo por fallar.
		## Esto le enseña que salir de la zona es MUY malo.
		ai_controller.reward -= 1.0 
		# Avisamos a Python que se acabó el episodio para que inicie uno nuevo
		ai_controller.done = true   
		ai_controller.needs_reset = true  
	game_reset()
	
func game_reset():   
	position = initial_pos
	velocity = Vector2.ZERO
	jumps_counter = 0
	get_tree().call_group("Targets", "queue_free")
	
func _draw():
	return
	
	if raycast_sensor_2d:
		for ray in raycast_sensor_2d.get_children():
			if ray is RayCast2D:
				draw_ray(ray)
	
	if next_target_vector != Vector2.ZERO:
		# Rectify normalized positions multiplying by the scene size
		draw_line(Vector2.ZERO, next_target_vector, Color.BLUE, 3.0)
		draw_circle(next_target_vector, 5.0, Color.BLUE)

func draw_ray(ray: RayCast2D):
	# Usamos el método corregido que respeta rotación
	var start_pos = ray.position
	var end_pos = ray.target_position
	var color = Color.GREEN 

	if ray.is_colliding():
		# La posición de colisión se recibe en coordenadas globales,
		# la transformamos a coordenadas locales del propio jugador
		end_pos = to_local(ray.get_collision_point())
		color = Color.RED 
	
	draw_line(start_pos, end_pos, color, 1.5)

func target_achieved():
	if ai_controller:
		ai_controller.reward += 1.0 # Huge reward
		
func update_next_target_vector():
	var closest_target: Node2D = null
	var closest_dx = INF
	
	for target: Node2D in get_tree().get_nodes_in_group("Targets"):
		var offset = target.global_position - global_position
		
		# Solo targets a la derecha
		if offset.x > 0.0 and offset.x < closest_dx:
			closest_dx = offset.x
			closest_target = target
	
	if closest_target == null:
		# By default the next reward is far in X coord
		next_target_vector = Vector2(288.0, 0.0)
	else:
		next_target_vector = Vector2(
			closest_target.global_position.x - global_position.x, 
			closest_target.global_position.y - global_position.y
		)

	# print(next_target_vector)
	
