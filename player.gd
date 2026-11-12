extends CharacterBody3D

# Настройки скорости и чувствительности
@export var speed: float = 5.0
@export var jump_velocity: float = 4.5
@export var touch_sensitivity: float = 0.005
@export var mouse_sensitivity: float = 0.003

# Ссылка на узел поворота камеры (из вашего дерева сцены)
@onready var camera: Node3D = $CameraPivot

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_dead: bool = false

func _ready() -> void:
	# Захватываем курсор мыши ТОЛЬКО на компьютере
	if not OS.has_feature("mobile"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	# Если игрок уже упал — блокируем вращение камеры
	if is_dead:
		return

	# 1. Поворот камеры пальцем на Android
	if event is InputEventScreenDrag:
		rotate_y(-event.relative.x * touch_sensitivity)
		camera.rotate_x(-event.relative.y * touch_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		
	# 2. Поворот камеры мышкой на ПК
	elif event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	# Если игрок уже упал — останавливаем движение
	if is_dead:
		return

	# Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Прыжок
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Движение от джойстика или клавиш
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# Проверяем все столкновения игрока в этом кадре
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		# Если коснулись объекта, в названии которого есть "Ded" (или который в группе "ded")
		if collider and ("ded" in collider.name.to_lower() or collider.is_in_group("ded")):
			fall_down()

# Функция падения игрока при поимке
func fall_down() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector3.ZERO
	
	# Плавно заваливаем камеру на бок на 90 градусов (эффект падения на пол)
	var tween = create_tween()
	tween.tween_property(camera, "rotation:z", deg_to_rad(85), 0.35).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(camera, "position:y", camera.position.y - 0.8, 0.35)
	
	# Ждём 2 секунды и перезапускаем уровень (или замените на переход в меню проигрыша)
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
