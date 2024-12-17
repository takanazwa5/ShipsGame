class_name Ship extends CharacterBody3D


const _SPEED : float = 1.5


func _ready() -> void:

	%Area3D.area_entered.connect(_on_collision)
	%VOSN.screen_exited.connect(_on_vosn_screen_exited)


func _physics_process(_delta: float) -> void:

	var direction : Vector3 = basis.z.normalized()
	velocity.x = direction.x * _SPEED
	velocity.z = direction.z * _SPEED

	move_and_slide()


func enable_light() -> void:

	%Lamp.show()


func disable_light() -> void:

	%Lamp.hide()


func _on_collision(_area: Area3D) -> void:

	SignalBus.ship_collided.emit()
	print("ship collided")


func _on_vosn_screen_exited() -> void:

	queue_free()
