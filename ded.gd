extends CharacterBody3D

@export var speed: float = 3.2
@export var chase_distance: float = 30.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var player: Node3D = null
var chase_music: AudioStreamPlayer3D = null

func _ready() -> void:
	add_to_group("ded")
	player = get_tree().current_scene.find_child("Player", true, false)
	
	apply_ded_material()
	
	chase_music = find_child("ChaseMusic", true, false)
	if chase_music == null:
		chase_music = AudioStreamPlayer3D.new()
		chase_music.name = "ChaseMusic"
		add_child(chase_music)
		if ResourceLoader.exists("res://chase.mp3"):
			chase_music.stream = load("res://chase.mp3")

func apply_ded_material() -> void:
	var mat = StandardMaterial3D.new()
	# Отключаем тени/блики, чтобы текстура была максимально яркой и чёткой на телефоне
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Пробуем загрузить картинку всеми доступными способами
	var tex: Texture2D = null
	if ResourceLoader.exists("res://Material_0_baseColor.jpeg"):
		tex = load("res://Material_0_baseColor.jpeg")
	elif ResourceLoader.exists("res://textures/Material_0_baseColor.jpeg"):
		tex = load("res://textures/Material_0_baseColor.jpeg")
		
	if tex != null:
		mat.albedo_texture = tex
	else:
		# Если картинка не упаковалась в APK — красим деда в мрачный тёмно-красный цвет
		mat.albedo_color = Color(0.6, 0.15, 0.15)
		
	# Ищем все 3D-части внутри деда (включая внутренние сцены Sketchfab)
	var meshes = find_children("*", "MeshInstance3D", true, true)
	for mesh in meshes:
		mesh.material_override = mat

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if player != null:
		var distance = global_position.distance_to(player.global_position)
		if distance < chase_distance:
			if chase_music and chase_music.stream and not chase_music.playing:
				chase_music.play()
				
			var direction = (player.global_position - global_position)
			direction.y = 0
			direction = direction.normalized()
			
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			var look_target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
			if global_position.distance_to(look_target) > 0.1:
				look_at(look_target, Vector3.UP)
		else:
			if chase_music and chase_music.playing:
				chase_music.stop()
				
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
