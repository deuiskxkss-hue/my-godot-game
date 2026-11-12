extends CharacterBody3D

const CHASE_SPEED = 3.8 # Сбалансированная скорость (можно убежать от Деда)
var time := 0.0
var voice_timer := 1.5 # Через сколько секунд после старта Дед крикнет первый раз

# Ссылки на игрока и 3D-динамик голоса Деда
@onready var player: CharacterBody3D = $"../Player"
@onready var voice_sound: AudioStreamPlayer3D = get_node_or_null("VoiceSound")

func _physics_process(delta: float) -> void:
	# 1. Гравитация, чтобы Дед твёрдо стоял на земле
	if not is_on_floor():
		velocity += get_gravity() * delta

	if player:
		# 2. Считаем направление от Деда к игроку
		var direction := (player.global_position - global_position).normalized()
		
		# 3. Двигаем Деда в погоню
		velocity.x = direction.x * CHASE_SPEED
		velocity.z = direction.z * CHASE_SPEED
		
		# 4. Бешеная анимация бега в стиле «5 ночей с Тимохой»
		time += delta * 18.0
		$Sketchfab_Scene.position.y = abs(sin(time)) * 0.25
		$Sketchfab_Scene.rotation.z = sin(time) * 0.22
		$Sketchfab_Scene.rotation.x = deg_to_rad(20.0) + cos(time * 1.5) * 0.08
		$Sketchfab_Scene.rotation.y = deg_to_rad(180.0) + sin(time) * 0.15
		
		# 5. Разворачиваем Деда лицом к игроку
		if global_position.distance_to(player.global_position) > 0.5:
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		
		# 6. Голос Деда: выкрикивает фразу каждые 4–7 секунд погони
		voice_timer -= delta
		if voice_timer <= 0.0:
			if voice_sound and not voice_sound.playing:
				voice_sound.play()
			voice_timer = randf_range(4.0, 7.0)
			
		# 7. Ускорение фоновой музыки, если Дед подбегает близко
		var dist := global_position.distance_to(player.global_position)
		if has_node("../ChaseMusic"):
			$"../ChaseMusic".pitch_scale = clamp(1.4 - (dist / 30.0), 1.0, 1.35)
	
	# Применяем физику движения
	move_and_slide()
