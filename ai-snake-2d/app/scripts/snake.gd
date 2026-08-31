extends TileMapLayer
class_name Snake

const UP = Vector2i(0, -1)
const DOWN = Vector2i(0, 1)
const LEFT = Vector2i(-1, 0)
const RIGHT = Vector2i(1, 0)

var body: Array[Vector2i] = []
var direction: Vector2i = RIGHT
var next_direction: Vector2i = RIGHT
var sprite_ids: Dictionary = {}

# NUEVO: Lista de posiciones de las manzanas
var food_positions: Array[Vector2i] = []

var debug_rays: Array = []
const TAMANIO_CELDA = 40.0 

func _ready() -> void:
	_load_sprite_ids()
	reset()

func _load_sprite_ids() -> void:
	if tile_set:
		for i in range(tile_set.get_source_count()):
			var source_id = tile_set.get_source_id(i)
			var source = tile_set.get_source(source_id)
			if source is TileSetAtlasSource and source.texture != null:
				var sprite_name = source.texture.resource_path.get_file().get_basename()
				sprite_ids[sprite_name] = source_id

func reset() -> void:
	direction = RIGHT
	next_direction = RIGHT
	body = [
		Vector2i(6, 5),
		Vector2i(5, 5),
		Vector2i(4, 5)
	]
	update_rendering()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	if Input.is_action_just_pressed("move_up") and direction != DOWN:
		next_direction = UP
	elif Input.is_action_just_pressed("move_down") and direction != UP:
		next_direction = DOWN
	elif Input.is_action_just_pressed("move_left") and direction != RIGHT:
		next_direction = LEFT
	elif Input.is_action_just_pressed("move_right") and direction != LEFT:
		next_direction = RIGHT

func advance_step() -> Vector2i:
	direction = next_direction
	return body[0] + direction

func extend_to(new_position: Vector2i) -> void:
	body.insert(0, new_position)
	update_rendering()

func move_to(new_position: Vector2i) -> void:
	body.insert(0, new_position)
	body.pop_back()
	update_rendering()

func check_self_collision(new_position: Vector2i) -> bool:
	return new_position in body

# NUEVO: Recibe el Array de manzanas desde main.gd
func update_foods(positions: Array[Vector2i]) -> void:
	food_positions = positions
	update_rendering()

func update_rendering() -> void:
	clear()

	# NUEVO: Dibujar TODAS las manzanas
	for pos in food_positions:
		set_cell(pos, sprite_ids.get("apple", 0), Vector2i(0, 0))

	# Dibujar Serpiente
	for i in range(body.size()):
		var pos = body[i]
		if i == 0:
			set_cell(pos, get_head_source_id(direction), Vector2i(0, 0))
		elif i == body.size() - 1:
			var tail_dir = body[i-1] - pos
			set_cell(pos, get_tail_source_id(tail_dir), Vector2i(0, 0))
		else:
			var dir_to_prev = body[i-1] - pos
			var dir_to_next = body[i+1] - pos
			set_cell(pos, get_body_source_id(dir_to_prev, dir_to_next), Vector2i(0, 0))

func get_head_source_id(dir: Vector2i) -> int:
	match dir:
		UP: return sprite_ids.get("head_up", 0)
		DOWN: return sprite_ids.get("head_down", 0)
		LEFT: return sprite_ids.get("head_left", 0)
		RIGHT: return sprite_ids.get("head_right", 0)
	return sprite_ids.get("head_right", 0)

func get_tail_source_id(tail_dir: Vector2i) -> int:
	match tail_dir:
		UP: return sprite_ids.get("tail_down", 0)
		DOWN: return sprite_ids.get("tail_up", 0)
		LEFT: return sprite_ids.get("tail_right", 0)
		RIGHT: return sprite_ids.get("tail_left", 0)
	return sprite_ids.get("tail_left", 0)

func get_body_source_id(prev: Vector2i, next: Vector2i) -> int:
	if (prev == LEFT and next == RIGHT) or (prev == RIGHT and next == LEFT):
		return sprite_ids.get("body_horizontal", 0)
	if (prev == UP and next == DOWN) or (prev == DOWN and next == UP):
		return sprite_ids.get("body_vertical", 0)
		
	if (prev == UP and next == LEFT) or (prev == LEFT and next == UP):
		return sprite_ids.get("body_topleft", 0)
	if (prev == UP and next == RIGHT) or (prev == RIGHT and next == UP):
		return sprite_ids.get("body_topright", 0)
	if (prev == DOWN and next == LEFT) or (prev == LEFT and next == DOWN):
		return sprite_ids.get("body_bottomleft", 0)
	if (prev == DOWN and next == RIGHT) or (prev == RIGHT and next == DOWN):
		return sprite_ids.get("body_bottomright", 0)
		
	return sprite_ids.get("body_horizontal", 0)
