extends Node


const SHIP_A : PackedScene = preload("res://scenes/ships/ship_cargo_a.tscn")
const SHIP_B : PackedScene = preload("res://scenes/ships/ship_cargo_b.tscn")
const SHIP_C : PackedScene = preload("res://scenes/ships/ship_cargo_c.tscn")


var north_spawn_points : Array[Vector3] = []
var south_spawn_points : Array[Vector3] = []
var ships : Array[PackedScene] = [SHIP_A, SHIP_B, SHIP_C]
var last_spawn_was_north : bool = false
var light_pos : Vector3 = Vector3.ZERO


func _ready() -> void:

	GDConsole.create_command(_game_over)

	%RestartButton.pressed.connect(_on_restart_button_pressed)
	%SpawnTimer.timeout.connect(_on_spawn_timer_timeout)
	SignalBus.ship_collided.connect(_on_ship_collided)

	for child : Node3D in %NorthSpawnPoints.get_children():

		north_spawn_points.append(child.global_position)

	for child : Node3D in %SouthSpawnPoints.get_children():

		south_spawn_points.append(child.global_position)

	await get_tree().create_timer(%SpawnTimer.wait_time).timeout
	%StartLabel.hide()


func _unhandled_input(event: InputEvent) -> void:

	if not event is InputEventMouseMotion:

		return

	var viewport : Viewport = get_viewport()
	var camera : Camera3D = viewport.get_camera_3d()
	var mouse_pos : Vector2 = viewport.get_mouse_position()
	var from : Vector3 = camera.global_position
	var to : Vector3 = from + camera.project_ray_normal(mouse_pos) * 100
	var space : PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
	var query : PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.collide_with_areas = true
	query.collision_mask = 0b10
	var result : Dictionary = space.intersect_ray(query)

	if not result.is_empty():

		%SpotLight3D.look_at(result.position)
		light_pos = result.position


func _process(_delta: float) -> void:

	if ships.is_empty():

		return

	for ship : Ship in %Ships.get_children():

		if ship.global_position.distance_to(light_pos) < 3:

			ship.enable_light()
			var target_light_pos : Vector3 = Vector3(light_pos.x, ship.global_position.y, light_pos.z)
			var target_transform : Transform3D = ship.global_transform.looking_at(target_light_pos, \
			Vector3.UP, true)
			ship.global_transform = ship.global_transform.interpolate_with(target_transform, 0.01)
			continue

		ship.disable_light()


func _spawn_ship() -> void:

	var ship_instance : Ship = ships.pick_random().instantiate()
	var spawn_pos : Vector3 = Vector3.ZERO
	var rng : int = randi_range(0, 2)

	if last_spawn_was_north:

		spawn_pos = south_spawn_points[rng]

	else:

		spawn_pos = north_spawn_points[rng]

	match rng:

		0 when last_spawn_was_north:

			ship_instance.rotate_y(deg_to_rad(randf_range(150, 195)))

		1 when last_spawn_was_north:

			ship_instance.rotate_y(deg_to_rad(randf_range(150, 210)))

		2 when last_spawn_was_north:

			ship_instance.rotate_y(deg_to_rad(randf_range(175, 210)))

		0:

			ship_instance.rotate_y(deg_to_rad(randf_range(-15, 30)))

		1:

			ship_instance.rotate_y(deg_to_rad(randf_range(-30, 30)))

		2:

			ship_instance.rotate_y(deg_to_rad(randf_range(-30, 5)))

	last_spawn_was_north = not last_spawn_was_north
	%Ships.add_child(ship_instance)
	ship_instance.global_position = spawn_pos


func _game_over() -> void:

	get_tree().paused = true
	%GameOverLabel.show()
	%RestartButton.show()


func _restart() -> void:

	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_ship_collided() -> void:

	_game_over()


func _on_restart_button_pressed() -> void:

	_restart()


func _on_spawn_timer_timeout() -> void:

	_spawn_ship()
	%SpawnTimer.wait_time = randf_range(5, 10)
	%SpawnTimer.start()
