extends Node2D

const GRID_WIDTH = 10
const GRID_HEIGHT = 10
const NUM_FOODS = 1 # Cheto: Cantidad de manzanas simultáneas

@export var velocidad_humana: float = 0.15

var foods: Array[Vector2i] = [] # Ahora es un Array
var score: int = 0
var timer: float = 0.0
var game_over: bool = false

@onready var snake: Snake = $Snake
@onready var ai_controller = $Snake/AIController2D
@onready var points = $Points

var total_reward: float = 0.0
var step = 0

func is_training() -> bool:
	# 1. Buscamos el nodo usando su grupo oficial (mucho más seguro que rutas rígidas como get_parent o $Sync)
	var sync_nodes = get_tree().get_nodes_in_group("sync")
	
	if sync_nodes.size() > 0:
		var sync_node = sync_nodes[0]
		
		# 2. EL PARCHE ANTI-CRASHEOS: Preguntamos si la variable existe en ese nodo específico
		if "control_mode" in sync_node:
			return sync_node.control_mode != 0
			
	return false

func _ready() -> void:
	start_game()

func start_game() -> void:
	game_over = false
	score = 0
	points.text = str(score)
	timer = 0.0
	total_reward = 0.0
	foods.clear()
	snake.reset()
	
	# Generar el número inicial de manzanas
	for i in range(NUM_FOODS):
		spawn_food()

func _physics_process(delta: float) -> void:
	if is_training() and ai_controller.needs_reset:
		ai_controller.reset() 
		start_game()
		return

	if game_over:
		if not is_training() and Input.is_action_just_pressed("ui_accept"):
			start_game()
		return

	if is_training():
		process_turn()
	else:
		timer += delta
		if timer >= velocidad_humana:
			timer = 0.0
			process_turn()

func process_turn() -> void:
	var future_head = snake.advance_step()
	
	if future_head.x < 0 or future_head.x >= GRID_WIDTH or future_head.y < 0 or future_head.y >= GRID_HEIGHT:
		end_game()
		return
		
	if snake.check_self_collision(future_head):
		end_game()
		return
		
	# Si la cabeza choca con CUALQUIER manzana del array
	if future_head in foods:
		snake.extend_to(future_head)
		score += 1
		points.text = str(score)
		
		if is_training():
			ai_controller.reward += 10.0
			
		# Eliminar la manzana comida y poner una nueva
		foods.erase(future_head)
		spawn_food()
	else:
		snake.move_to(future_head)
		
		# --- REWARD SHAPING: POZO DE GRAVEDAD DINÁMICO ---
		if is_training():
			var size = snake.body.size()
			
			# Calculamos distancia a la comida más cercana
			var min_dist_food = 9999
			for f in foods:
				var dist = abs(future_head.x - f.x) + abs(future_head.y - f.y)
				if dist < min_dist_food:
					min_dist_food = dist
			
			if size <= 15:
				# FASE 1: CAZADOR
				# Se prioriza llegar rápido a la comida. 
				var proporcion_comida = float(min_dist_food) / 32.0 
				ai_controller.reward -= (proporcion_comida * 0.02)
				
			else:
				# FASE 2: ESTRATEGA (Supervivencia en late-game)
				# Prioriza mantenerse compacta y cerca de su cola.
				var tail_pos = snake.body[-1]
				var dist_cola = abs(future_head.x - tail_pos.x) + abs(future_head.y - tail_pos.y)
				
				var proporcion_cola = float(dist_cola) / 32.0 
				var proporcion_comida = float(min_dist_food) / 32.0 
				
				# Castigamos fuertemente si se separa de su cola
				var castigo_cola = proporcion_cola * 0.02
				# Mantenemos un leve castigo por hambre para obligarla a comer al final
				var castigo_comida = proporcion_comida * 0.005 
				
				ai_controller.reward -= (castigo_cola + castigo_comida)
				
	if is_training() and not game_over:
		total_reward += ai_controller.reward

func spawn_food() -> void:
	randomize()
	while true:
		var pos = Vector2i(randi() % GRID_WIDTH, randi() % GRID_HEIGHT)
		# Asegurar que no caiga en la serpiente ni encima de otra manzana
		if not pos in snake.body and not pos in foods:
			foods.append(pos)
			snake.update_foods(foods) 
			break

func end_game() -> void:
	if is_training():
		ai_controller.reward -= 1.5 
		ai_controller.done = true 
		ai_controller.needs_reset = true 
		game_over = true 
	else:
		game_over = true
