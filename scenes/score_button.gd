extends Control
## 分数按钮场景 - 点击生成可拖动数字
## 拖动模式下可拖动按钮本身

## 网格大小
const GRID_SIZE: int = 25

## 层级节点数组（由外部设置）
@export var level_node_arr: Array[Node2D] = []

@export var number_scene: PackedScene

## 拖动状态
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_preview: Control = null
var _original_position: Vector2 = Vector2.ZERO

@onready var add_button: Button = $AddButton


func _ready() -> void:
	add_to_group("placeable_items")
	if number_scene == null:
		number_scene = preload("res://scenes/number_object.tscn")
	add_button.pressed.connect(_on_add_button_pressed)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	# 拖动时更新预览位置
	if _is_dragging and _drag_preview:
		var target_pos = get_global_mouse_position() - _drag_offset
		var snapped_pos = _calculate_snapped_position(target_pos)
		_drag_preview.global_position = snapped_pos


func _calculate_snapped_position(pos: Vector2) -> Vector2:
	## 计算网格对齐后的位置
	return Vector2(
		roundi(pos.x / GRID_SIZE) * GRID_SIZE,
		roundi(pos.y / GRID_SIZE) * GRID_SIZE
	)


func _gui_input(event: InputEvent) -> void:
	## 点击模式下不拦截按钮点击事件
	pass


func _input(event: InputEvent) -> void:
	## 拖动模式下拖动按钮
	if Global.is_drag_mode():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 检查鼠标是否在本节点内
				var rect = Rect2(global_position, size)
				if rect.has_point(get_global_mouse_position()):
					_start_drag()
			else:
				if _is_dragging:
					_end_drag()


func _start_drag() -> void:
	## 开始拖动
	_is_dragging = true
	_drag_offset = get_local_mouse_position()
	_original_position = global_position
	_create_drag_preview()


func _end_drag() -> void:
	## 结束拖动
	if _drag_preview:
		# 检测目标位置是否被占用
		var target_pos = _drag_preview.global_position
		if Global.check_position_occupied(target_pos, size, self):
			# 位置被占用，回到原位置
			global_position = _original_position
		else:
			# 移动到预览位置
			global_position = target_pos
		_remove_drag_preview()
	_is_dragging = false


func _create_drag_preview() -> void:
	## 创建拖动预览
	_drag_preview = Control.new()
	_drag_preview.size = size

	# 创建背景
	var bg = Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	_drag_preview.add_child(bg)

	# 设置半透明
	_drag_preview.modulate.a = 0.5
	_drag_preview.modulate = Color(0.5, 1.0, 0.5, 0.5)  # 绿色半透明

	# 设置初始位置
	var target_pos = get_global_mouse_position() - _drag_offset
	_drag_preview.global_position = _calculate_snapped_position(target_pos)

	# 添加到场景
	get_tree().current_scene.add_child(_drag_preview)


func _remove_drag_preview() -> void:
	## 移除拖动预览
	if _drag_preview:
		_drag_preview.queue_free()
		_drag_preview = null


func _on_add_button_pressed() -> void:
	## 只在点击模式下生成数字
	if Global.is_click_mode():
		_spawn_number()


func _spawn_number() -> void:
	## 生成一个数字对象在按钮正上方
	var number = number_scene.instantiate()

	# 获取Level3父节点（层级3）
	var parent = _get_level_parent(3)
	if parent:
		parent.add_child(number)
	else:
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


func _get_level_parent(level: int) -> Node:
	## 获取对应层级的父节点
	# level_node_arr[0] = Level1, level_node_arr[1] = Level2, level_node_arr[2] = Level3
	var index = level - 1
	if level_node_arr.size() > index and level_node_arr[index]:
		return level_node_arr[index]
	return null


func _apply_pop_animation(number: Control) -> void:
	## 弹出动画效果
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)

	# 缩放动画
	number.scale = Vector2(0.1, 0.1)
	tween.tween_property(number, "scale", Vector2(1, 1), 0.3)
