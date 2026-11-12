extends Node3D

var is_open := false
var closed_pos: Vector3
var door_btn: TouchScreenButton

func _ready() -> void:
	# Запоминаем закрытое положение двери
	closed_pos = position
	
	# Автоматически находим сенсорную кнопку-картинку во всей сцене
	door_btn = get_tree().root.find_child("DoorTouchBtn", true, false)
	
	if door_btn:
		# Прячем кнопку при старте игры
		door_btn.visible = false
		# Подключаем нажатие пальцем к открытию/закрытию двери
		door_btn.pressed.connect(toggle_door)

func toggle_door() -> void:
	is_open = !is_open
	# Если открываем — плавно сдвигаем дверь на 2 метра в сторону по оси X
	var target_pos := closed_pos + Vector3(2.0, 0.0, 0.0) if is_open else closed_pos
	
	var tween := create_tween()
	tween.tween_property(self, "position", target_pos, 0.4).set_trans(Tween.TRANS_SINE)

# Срабатывает, когда игрок входит в зону двери
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player" and door_btn:
		door_btn.visible = true

# Срабатывает, когда игрок уходит от двери
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.name == "Player" and door_btn:
		door_btn.visible = false
