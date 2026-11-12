extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 10.0 # Мега-прыжок на крышу
const MOUSE_SENSITIVITY = 0.003 # Чувствительность мышки

# Ссылка на узел камеры игрока
@onready var camera_pivot: Node3D = $CameraPivot
@onready var walk_sound: AudioStreamPlayer = $WalkSound


var is_dead := false
var is_falling := false

func _ready() -> void:
	# Прячем и фиксируем курсор по центру экрана
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	# Поворачиваем камеру при движении мышки, если игрок жив
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not is_dead:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	# Возвращаем курсор по нажатию клавиши Escape
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Если игрок повален Дедом, отключаем управление
	if is_dead:
		return

	# 1. Гравитация
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Мега-прыжок на Пробел
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Ходьба (WASD / Стрелочки)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	# Проверяем: если игрок на земле И реально двигается (скорость больше 0.1)
	if is_on_floor() and Vector2(velocity.x, velocity.z).length() > 0.1:
		# Если звук ещё не играет — запускаем его
		if not walk_sound.playing:
			walk_sound.play()
		# Ускоряем шаги, если зажат Shift для бега
		walk_sound.pitch_scale = 1.4 if Input.is_key_pressed(KEY_SHIFT) else 1.0
	else:
		# Если игрок остановился или подпрыгнул в воздух — выключаем звук
		if walk_sound.playing:
			walk_sound.stop()

	# 4. Авто-возрождение при падении за край карты
	if global_position.y < -10.0 and not is_falling:
		is_falling = true
		await get_tree().create_timer(1.5).timeout
		get_tree().reload_current_scene()

func fall_down() -> void:
	if is_dead:
		return
	is_dead = true
	
	# Плавная анимация падения игрока на землю за 0.5 секунды
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "rotation:z", deg_to_rad(85.0), 0.5).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(self, "rotation:x", deg_to_rad(25.0), 0.5)
	tween.tween_property(camera_pivot, "position:y", 0.2, 0.5)
	
	# Ждём 2 секунды и перезапускаем уровень
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

# Функция приёма сигнала от зоны Area3D Деда
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		fall_down()
