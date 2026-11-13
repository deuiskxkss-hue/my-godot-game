extends CharacterBody3D

@export var speed: float = 3.2
@export var chase_distance: float = 30.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var player: Node3D = null
var chase_music: AudioStreamPlayer3D = null

func _ready() -> void:
	add_to_group("ded")
	player = get_tree().current_scene.find_child("Player", true, false)
	
	# Автоматически находим любую картинку в папках и надеваем на деда
	auto_find_and_apply_texture()
	
	# Подключаем музыку погони
	chase_music = find_child("ChaseMusic", true, false)
	if chase_music == null:
		chase_music = AudioStreamPlayer3D.new()
		chase_music.name = "ChaseMusic"
		add_child(chase_music)
		if ResourceLoader.exists("res://chase.mp3"):
			chase_music.stream = load("res://chase.mp3")

func auto_find_and_apply_texture() -> void:
	var folders = ["res://textures", "res://models", "res://"]
	var loaded_tex: Texture2D = null
	
	for folder in folders:
		var dir = DirAccess.open(folder)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				# Ищем любую картинку по началу или расширению (игнорируем icon.svg)
				var lower = file_name.to_lower()
				if not dir.current_is_dir() and not lower.ends_with(".import") and lower != "icon.svg":
					if lower.ends_with(".png") or lower.ends_with(".jpg") or lower.ends_with(".jpeg") or lower.ends_with(".webp"):
						var full_path = folder.path_join(file_name)
						if ResourceLoader.exists(full_path):
							loaded_tex = load(full_path)
							break
				file_name = dir.get_next()
		if loaded_tex != null:
			break
			
	if loaded_tex != null:
		var mat = StandardMaterial3D.new()
		mat.albedo_texture = loaded_tex
		var meshes = find_children("*", "MeshInstance3D", true, false)
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
