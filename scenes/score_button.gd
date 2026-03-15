extends Control
## 分数按钮场景 - 点击生成可拖动数字

@export var number_scene: PackedScene

@onready var add_button: Button = $AddButton


func _ready() -> void:
	if number_scene == null:
		number_scene = preload("res://scenes/number_object.tscn")
	add_button.pressed.connect(_on_add_button_pressed)


func _on_add_button_pressed() -> void:
	_spawn_number()


func _spawn_number() -> void:
	## 生成一个数字对象在按钮正上方
	var number = number_scene.instantiate()

	# 添加到场景树
	get_tree().current_scene.add_child(number)

	# 设置位置：在按钮正上方（不重叠）
	var button_center = add_button.global_position + add_button.size / 2
	var spawn_y_offset = -add_button.size.y - number.size.y / 2 - 10  # 按钮高度 + 数字高度 + 间距

	# 轻微随机X偏移，避免数字完全重叠
	var random_x_offset = randf_range(-30, 30)

	number.global_position = Vector2(
		button_center.x - number.size.x / 2 + random_x_offset,
		button_center.y + spawn_y_offset
	)

	# 应用弹出动画
	_apply_pop_animation(number)


func _apply_pop_animation(number: Control) -> void:
	## 弹出动画效果
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)

	# 缩放动画
	number.scale = Vector2(0.1, 0.1)
	tween.tween_property(number, "scale", Vector2(1, 1), 0.3)
