extends Area2D

@export var speed: float = 150.0
@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleNotifier
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


func _process(delta: float) -> void:
	# Move to left in each frame
	position.x -= speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("target_achieved"):
		body.target_achieved()
	# Destroy only the sprite and the collider
	sprite_2d.queue_free()
	collision_shape_2d.queue_free()


func _on_visible_notifier_screen_exited() -> void:
	# print("Autodestroying Target...")
	await get_tree().create_timer(1.0).timeout
	queue_free()
