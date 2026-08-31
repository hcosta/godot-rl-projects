extends AIController2D

var accumulated_reward: float = 0.0

# ==========================================
# 0. REFERENCIAS (Presentando los nodos)
# ==========================================
# Le decimos al script quién es el coche (su padre) y quién es el sensor (su hermano)
@onready var car: CharacterBody2D = get_parent()
@onready var raycast_sensor = get_parent().get_node("RaycastSensor2D")
@onready var raycast_sensor_back = get_parent().get_node("RaycastSensor2D2")


## ==========================================
## 1. LOS OJOS (Observaciones)
## ==========================================
func get_obs() -> Dictionary:
	# El nodo RaycastSensor2D nos da la información ya masticada
	var radar_data = raycast_sensor.get_observation()
	
	return {
		"obs": radar_data
	}
	
#func get_obs() -> Dictionary:
	## El nodo RaycastSensor2D nos da la información ya masticada
	#var radar_data = raycast_sensor.get_observation()
	#var radar_back_data = raycast_sensor_back.get_observation()
	#
	## Unimos ambos radares en una sola lista de números para el cerebro de la IA
	#var total_radar = radar_data.duplicate()
	#total_radar.append_array(radar_back_data)
	#
	#return {
		#"obs": total_radar
	#}

# ==========================================
# 2. EL CARNÉ DE CONDUCIR (Espacio de Acciones)
# ==========================================
func get_action_space() -> Dictionary:
	return {
		"continuous": {
			"size": 2, 
			"action_type": "continuous" 
		}
	}


## ==========================================
## 3. LOS MÚSCULOS (Ejecutar Acciones)
## ==========================================
#func set_action(action) -> void:
	## La IA nos envía dos números decimales entre -1.0 y 1.0
	#var steering_decision = action["continuous"][0] 
	#var acceleration_decision = action["continuous"][1] 
	#
	## Aquí es donde la IA sustituye a tus dedos en el teclado
	#car.input_steering = steering_decision
	#car.input_acceleration = acceleration_decision
	
func set_action(action: Dictionary) -> void:
	## La IA nos envía dos números decimales entre -1.0 y 1.0
	# Obtenemos las decisiones de la IA
	var ai_steering = action["continuous"][0] 
	var ai_acceleration = action["continuous"][1] 
	
	## Aquí es donde la IA sustituye a tus dedos en el teclado
	# En lugar de darle el control absoluto de golpe, hacemos un "lerp" (suavizado).
	# El coche se acercará a la decisión de la IA un 20% en cada fotograma.
	car.input_steering = lerp(car.input_steering, ai_steering, 0.2)
	car.input_acceleration = lerp(car.input_acceleration, ai_acceleration, 0.2)

## ==========================================
## 4. EL PREMIO Y CASTIGO (Recompensas)
## ==========================================	
#func get_reward() -> float:
	#var total_reward: float = 0.0
	#
	## EL PREMIO (+): ¿El coche está avanzando rápido? ¡Buen chico!
	#if car.velocity.length() > 50.0:
		#total_reward += 0.1
		#
	## Si el episodio ha terminado, comprobamos por qué
	#if car.is_done: 
		#if car.has_won:
			#total_reward += 20.0
			## print("¡Meta! Recompensa aplicada: +20.0") # Añade esta línea
		#else:
			#total_reward -= 10.0 
			## print("¡Choque! Castigo aplicado: -10.0") # Añade esta línea
		#
	## print("Recompensa del paso: ", total_reward) # Añade esta línea
	#
	## Al final de get_reward() sumamos la recompensa de cada paso:
	#accumulated_reward += total_reward
	#
	## print("Recompensa acumulada del episodio: ", accumulated_reward) # Añade esta línea
	#
	#return total_reward

func get_reward() -> float:
	var total_reward: float = 0.0
	
	# 1. MATEMÁTICA VECTORIAL: Medimos la velocidad "hacia adelante" real
	var forward_vector = car.transform.x
	var forward_speed = car.velocity.dot(forward_vector)
	
	# 2. PREMIO POR VELOCIDAD: Cuanto más rápido vaya hacia adelante, más puntos gana
	if forward_speed > 10.0:
		# Dividimos entre max_speed (aprox 600) para que dé un premio máximo cercano a 0.1
		total_reward += (forward_speed / 600.0) * 0.1
		
	# 3. CASTIGO POR MARCHA ATRÁS: ¡Se acabaron las trampas!
	elif forward_speed < -10.0:
		total_reward -= 0.1
		
	# 4. IMPUESTO AL VOLANTE: Evita que el coche haga peonzas o zig-zag
	if abs(car.input_steering) > 0.1:
		# Castigo minúsculo pero constante si abusa del giro
		total_reward -= 0.01 * abs(car.input_steering)
		
	# 5. PREMIOS Y CASTIGOS POR CHECKPOINTS (¡Faltaba esto!)
	# Revisamos si el coche acaba de guardar puntos en su mochila temporal
	if car.pending_checkpoint_reward != 0.0:
		total_reward += car.pending_checkpoint_reward
		
		# ¡Vaciamos la mochila inmediatamente! Así no cobra los puntos infinitamente.
		car.pending_checkpoint_reward = 0.0
		
	# 6. RESULTADOS DE FIN DE EPISODIO
	if car.is_done: 
		if car.has_won:
			total_reward += 20.0
		else:
			total_reward -= 10.0 
		
	# Sumamos al contable para tener el debug en pantalla
	accumulated_reward += total_reward
	
	return total_reward


# ==========================================
# 5. EL FIN DEL JUEGO (Terminar el episodio)
# ==========================================
func get_done() -> bool:
	# Guardamos si el coche ha chocado o ganado
	var episode_ended = car.is_done
	
	# ¡EL TRUCO MAESTRO! 
	# No esperamos la orden oficial de Python. Si el episodio terminó, 
	# teletransportamos el coche a la salida en este preciso milisegundo.
	if episode_ended:
		# Imprimimos el resultado final de nuestro contable visual y lo reiniciamos
		print("Puntuación Final del Episodio: ", accumulated_reward)
		accumulated_reward = 0.0
		
		# Teletransportamos el coche ANTES de que Python tome la primera foto
		car.reset_state()
		
	# Le decimos a Python: "Sí, el episodio terminó (y ya me he reiniciado por mi cuenta)"
	return episode_ended
