extends AIController2D

@onready var snake: Snake = get_parent()
@onready var main_game = snake.get_parent()

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

# --- FLOOD FILL OPTIMIZADO PARA VELOCIDAD ---
func get_espacio_disponible(start_pos: Vector2i, longitud_serpiente: int, body_dict: Dictionary) -> int:
	if start_pos.x < 0 or start_pos.x >= main_game.GRID_WIDTH or start_pos.y < 0 or start_pos.y >= main_game.GRID_HEIGHT:
		return 0
	if body_dict.has(start_pos):
		return 0

	var queue: Array[Vector2i] = [start_pos]
	var visited: Dictionary = {start_pos: true}
	var espacio_libre: int = 0
	var q_idx: int = 0 # Usamos un índice para no hacer pop_front()
	var dirs = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	
	# Paramos si llenamos el espacio o agotamos la cola
	while q_idx < queue.size() and espacio_libre <= longitud_serpiente:
		var actual = queue[q_idx]
		q_idx += 1
		espacio_libre += 1
		
		for d in dirs:
			var vecino = actual + d
			if visited.has(vecino): continue
			if vecino.x < 0 or vecino.x >= main_game.GRID_WIDTH or vecino.y < 0 or vecino.y >= main_game.GRID_HEIGHT: continue
			
			# Usamos body_dict.has() que es instantáneo
			if body_dict.has(vecino): continue
			
			visited[vecino] = true
			queue.append(vecino)
			
	return espacio_libre

func get_obs() -> Dictionary:
	var obs: Array[float] = []
	var head_pos = snake.body[0]
	var body_size = snake.body.size()
	
	# --- EL SECRETO DE RENDIMIENTO: DICCIONARIO HASH ---
	# Creamos un diccionario con el cuerpo una sola vez por frame
	var body_dict: Dictionary = {}
	for b in snake.body:
		body_dict[b] = true
	
	# 1. RADAR EGOCÉNTRICO 7x7 (49 elementos)
	for y_offset in range(-3, 4):
		for x_offset in range(-3, 4):
			var celda_evaluar = head_pos + Vector2i(x_offset, y_offset)
			
			if celda_evaluar.x < 0 or celda_evaluar.x >= main_game.GRID_WIDTH or celda_evaluar.y < 0 or celda_evaluar.y >= main_game.GRID_HEIGHT:
				obs.append(-1.0)
			elif celda_evaluar in main_game.foods:
				obs.append(0.5)
			# Búsqueda ultra rápida en lugar de 'in array'
			elif body_dict.has(celda_evaluar):
				obs.append(-1.0)
			else:
				obs.append(0.0)
				
	# 2. BRÚJULA ADICIONAL (2 elementos)
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

	# 3. EL 6º SENTIDO: CLAUSTROFOBIA (4 elementos)
	var direcciones_vitales = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	
	for d in direcciones_vitales:
		# Le pasamos el diccionario precalculado al Flood Fill
		var espacio = get_espacio_disponible(head_pos + d, body_size, body_dict)
		var seguridad = clamp(float(espacio) / float(body_size), 0.0, 1.0)
		obs.append(seguridad)

	# --- NUEVO: 4. BRÚJULA DE LA COLA (2 elementos) ---
	var tail_pos = snake.body[-1]
	var dir_cola = Vector2(tail_pos - head_pos).normalized()
	obs.append(dir_cola.x)
	obs.append(dir_cola.y)

	# Total del vector: 49 (radar) + 2 (comida) + 4 (claustrofobia) + 2 (cola) = 57 elementos
	return {"obs": obs}

func get_reward() -> float:
	var current_reward = reward
	reward = 0.0 
	return current_reward
