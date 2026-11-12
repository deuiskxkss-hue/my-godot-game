extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _physics_process(delta: float) -> void:
	# Добавляем гравитацию по умолчанию, чтобы Дед не летал по воздуху
	if not is_on_floor():
		velocity += get_gravity() * delta

	# По умолчанию Дед просто двигается вперёд по своей оси Z
	var direction = Vector3.FORWARD
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
