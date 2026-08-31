extends AIController2D

@onready var snake: Snake = get_parent()
@onready var main_game = snake.get_parent()

# --- 1. SENSOR: FLOOD FILL (Claustrofobia) ---
func get_espacio_disponible(start_pos: Vector2i, longitud_serpiente: int, body_dict: Dictionary) -> int:
	if start_pos.x < 0 or start_pos.x >= main_game.GRID_WIDTH or start_pos.y < 0 or start_pos.y >= main_game.GRID_HEIGHT:
		return 0
	if body_dict.has(start_pos):
		return 0

	var queue: Array[Vector2i] = [start_pos]
	var visited: Dictionary = {start_pos: true}
	var espacio_libre: int = 0
	var q_idx: int = 0 
	var dirs = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	
	while q_idx < queue.size() and espacio_libre <= longitud_serpiente:
		var actual = queue[q_idx]
		q_idx += 1
		espacio_libre += 1
		
		for d in dirs:
			var vecino = actual + d
			if visited.has(vecino): continue
			if vecino.x < 0 or vecino.x >= main_game.GRID_WIDTH or vecino.y < 0 or vecino.y >= main_game.GRID_HEIGHT: continue
			if body_dict.has(vecino): continue
			
			visited[vecino] = true
			queue.append(vecino)
			
	return espacio_libre

# --- 2. NUEVO SENSOR: PATHFINDING BFS HACIA LA COLA ---
func get_distancia_a_cola(start_pos: Vector2i, tail_pos: Vector2i, body_dict: Dictionary) -> float:
	# Verificaciones iniciales de seguridad
	if start_pos.x < 0 or start_pos.x >= main_game.GRID_WIDTH or start_pos.y < 0 or start_pos.y >= main_game.GRID_HEIGHT:
		return -1.0
	# Cuidado: Si evaluamos un cuerpo, debe ser un muro, EXCEPTO si es la propia cola (porque se va a mover)
	if body_dict.has(start_pos) and start_pos != tail_pos:
		return -1.0
		
	if start_pos == tail_pos:
		return 0.0

	var queue: Array[Vector2i] = [start_pos]
	# El diccionario visited guardará la distancia directamente
	var visited: Dictionary = {start_pos: 0}
	var q_idx: int = 0
	var dirs = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	
	while q_idx < queue.size():
		var actual = queue[q_idx]
		var dist_actual = visited[actual]
		q_idx += 1
		
		for d in dirs:
			var vecino = actual + d
			
			# Si encontramos la cola, devolvemos la distancia + 1
			if vecino == tail_pos:
				return float(dist_actual + 1)
				
			if visited.has(vecino): continue
			if vecino.x < 0 or vecino.x >= main_game.GRID_WIDTH or vecino.y < 0 or vecino.y >= main_game.GRID_HEIGHT: continue
			
			# La cola realímite del cuerpo
			if body_dict.has(vecino): continue
			
			visited[vecino] = dist_actual + 1
			queue.append(vecino)
			
	# Si agotamos la búsqueda y no llegamos, la ruta está bloqueada
	return -1.0

func get_action_space() -> Dictionary:
	return {
		"move_action": {
			"size": 4,
			"action_type": "discrete"
		}
	}

func set_action(action) -> void:
	var move_choice = action["move_action"]
	if typeof(move_choice) == TYPE_ARRAY: move_choice = move_choice[0]
	move_choice = int(move_choice)
	
	match move_choice:
		0: if snake.direction != snake.DOWN: snake.next_direction = snake.UP
		1: if snake.direction != snake.UP: snake.next_direction = snake.DOWN
		2: if snake.direction != snake.RIGHT: snake.next_direction = snake.LEFT
		3: if snake.direction != snake.LEFT: snake.next_direction = snake.RIGHT

func get_obs() -> Dictionary:
	var obs: Array[float] = []
	var head_pos = snake.body[0]
	var body_size = snake.body.size()
	
	# --- HASH MAP DEL CUERPO ---
	var body_dict: Dictionary = {}
	for b in snake.body:
		body_dict[b] = true
	
	# 1. BRÚJULA DE COMIDA (2 elementos)
	var closest_food = main_game.foods[0]
	var min_dist = 9999
	for f in main_game.foods:
		var dist = abs(head_pos.x - f.x) + abs(head_pos.y - f.y)
		if dist < min_dist:
			min_dist = dist
			closest_food = f
			
	var dir_comida = Vector2(closest_food - head_pos).normalized()
	obs.append(dir_comida.x)
	obs.append(dir_comida.y)

	var direcciones_vitales = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

	# 2. EL 6º SENTIDO: CLAUSTROFOBIA (4 elementos)
	for d in direcciones_vitales:
		var espacio = get_espacio_disponible(head_pos + d, body_size, body_dict)
		var seguridad = clamp(float(espacio) / float(body_size), 0.0, 1.0)
		obs.append(seguridad)

	# 3. NUEVO: CONEXIÓN CON LA COLA (4 elementos)
	var tail_pos = snake.body[-1]
	var max_dist_posible = float(main_game.GRID_WIDTH * main_game.GRID_HEIGHT)
	
	for d in direcciones_vitales:
		var dist_cola = get_distancia_a_cola(head_pos + d, tail_pos, body_dict)
		
		if dist_cola == -1.0:
			obs.append(-1.0) # -1.0 = Ruta cortada (Muerte inminente a largo plazo)
		else:
			# Normalizamos la distancia: 1.0 es que está al lado, 0.0 es que está muy lejos
			var seguridad_cola = 1.0 - (dist_cola / max_dist_posible)
			# Si no podemos ir a la cola ese camino es malo -1.0
			obs.append(seguridad_cola)
	
	return {"obs": obs}

func get_reward() -> float:
	var current_reward = reward
	reward = 0.0 
	return current_reward
