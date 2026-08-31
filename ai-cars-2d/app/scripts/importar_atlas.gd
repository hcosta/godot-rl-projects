@tool
extends EditorScript

# Configura las rutas de tus archivos aquí
const XML_PATH = "res://assets/Tilesets/spritesheet_objects.xml"
const PNG_PATH = "res://assets/Tilesets/spritesheet_objects.png"
const SAVE_DIR = "res://assets/Importados/" # La carpeta donde se guardarán

func _run() -> void:
	# Crear el directorio si no existe
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
		
	var texture = load(PNG_PATH)
	if not texture:
		print("Error: No se encontró la imagen en ", PNG_PATH)
		return
		
	var parser = XMLParser.new()
	if parser.open(XML_PATH) != OK:
		print("Error: No se pudo abrir el XML en ", XML_PATH)
		return
		
	var cont = 0
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT and parser.get_node_name() == "SubTexture":
			var nombre = parser.get_named_attribute_value("name").replacen(".png", "")
			var x = parser.get_named_attribute_value("x").to_float()
			var y = parser.get_named_attribute_value("y").to_float()
			var w = parser.get_named_attribute_value("width").to_float()
			var h = parser.get_named_attribute_value("height").to_float()
			
			# Creamos el recurso AtlasTexture nativo de Godot
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = texture
			atlas_texture.region = Rect2(x, y, w, h)
			
			# Lo guardamos en el disco como un recurso .tres nativo
			var ruta_guardado = SAVE_DIR + nombre + ".tres"
			ResourceSaver.save(atlas_texture, ruta_guardado)
			cont += 1
			
	print("¡Proceso terminado! Se han creado ", cont, " texturas nativas en: ", SAVE_DIR)
	# Forzar a Godot a actualizar la interfaz para ver los nuevos archivos
	get_editor_interface().get_resource_filesystem().scan()
