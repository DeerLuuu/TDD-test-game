class_name DeleteCursor extends Control
## DeleteCursor - 删除模式的光标指示器
## 跟随鼠标，显示红色半透明区域
## 悬停在物品上时自动调整为物品大小
## Ctrl+左键拖动可删除路径上的所有面板

## 当前悬停的物品
var _hovered_item: Control = null

## 背景面板
var _background: Panel = null

## 是否正在Ctrl拖动删除
var _is_ctrl_dragging: bool = false

## Ctrl拖动过程中删除的物品（用于避免重复删除）
var _deleted_items_during_drag: Array[Control] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_background()
	visible = false

	# 连接模式变化信号
	if not Global.mode_changed.is_connected(_on_mode_changed):
		Global.mode_changed.connect(_on_mode_changed)


func _process(_delta: float) -> void:
	if not Global.is_delete_mode():
		visible = false
		return

	visible = true
	_update_position()
	_update_size()
	_update_hovered_item()


func _create_background() -> void:
	_background = Panel.new()
	_background.anchor_right = 1.0
	_background.anchor_bottom = 1.0
	add_child(_background)

	# 设置红色半透明样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.2, 0.2, 0.5)  # 红色半透明
	style.border_color = Color(1.0, 0.0, 0.0, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	_background.add_theme_stylebox_override("panel", style)


func _update_position() -> void:
	## 更新位置跟随鼠标（使用世界坐标）
	var viewport = get_viewport()
	if not viewport:
		return

	var canvas_transform = viewport.get_canvas_transform()

	if _hovered_item:
		# 物品的世界坐标 -> 屏幕坐标
		global_position = canvas_transform * _hovered_item.global_position
	else:
		# 使用世界坐标对齐
		@warning_ignore("static_called_on_instance")
		var world_mouse = Global.get_scaled_global_mouse_position(viewport)
		var cursor_size = Vector2(Global.GRID_SIZE, Global.GRID_SIZE)
		@warning_ignore("static_called_on_instance")
		var snapped_pos = Global.snap_position_to_grid(world_mouse - cursor_size / 2)
		global_position = canvas_transform * snapped_pos


func _update_size() -> void:
	## 更新大小
	if _hovered_item:
		# 考虑相机缩放调整大小
		var viewport = get_viewport()
		var camera = viewport.get_camera_2d()
		var zoom = Vector2(1, 1)
		if camera:
			zoom = camera.zoom

		custom_minimum_size = _hovered_item.size * zoom
		size = _hovered_item.size * zoom
	else:
		custom_minimum_size = Vector2(Global.GRID_SIZE, Global.GRID_SIZE)
		size = Vector2(Global.GRID_SIZE, Global.GRID_SIZE)


func _update_hovered_item() -> void:
	## 更新悬停物品检测
	# 使用世界坐标检测物品
	@warning_ignore("static_called_on_instance")
	var global_mouse = Global.get_scaled_global_mouse_position(get_viewport())
	var items = get_tree().get_nodes_in_group("placeable_items")

	_hovered_item = null

	for item in items:
		if not is_instance_valid(item):
			continue
		if not item is Control:
			continue
		# 排除加分面板（不与删除模式交互）
		if item.is_in_group("score_drop_zone"):
			continue

		var rect = Rect2(item.global_position, item.size)
		if rect.has_point(global_mouse):
			_hovered_item = item
			break


func _input(event: InputEvent) -> void:
	## 处理点击删除和Ctrl拖动删除
	if not Global.is_delete_mode():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Ctrl+左键：开始拖动删除
			if Input.is_key_pressed(KEY_CTRL):
				_start_ctrl_drag()
			elif _hovered_item:
				# 普通点击：删除单个物品
				_delete_item(_hovered_item)
		else:
			# 左键释放：结束拖动删除
			if _is_ctrl_dragging:
				_end_ctrl_drag()

	elif event is InputEventMouseMotion and _is_ctrl_dragging:
		# Ctrl拖动过程中：删除路径上的物品
		_delete_items_in_path()


func _start_ctrl_drag() -> void:
	## 开始Ctrl拖动删除
	_is_ctrl_dragging = true
	_deleted_items_during_drag.clear()


func _end_ctrl_drag() -> void:
	## 结束Ctrl拖动删除
	_is_ctrl_dragging = false
	_deleted_items_during_drag.clear()


func _delete_items_in_path() -> void:
	## 删除光标路径上的所有物品
	@warning_ignore("static_called_on_instance")
	var global_mouse = Global.get_scaled_global_mouse_position(get_viewport())
	var items = get_tree().get_nodes_in_group("placeable_items")

	for item in items:
		if not is_instance_valid(item):
			continue
		if not item is Control:
			continue
		# 排除加分面板
		if item.is_in_group("score_drop_zone"):
			continue
		# 跳过已删除的物品
		if item in _deleted_items_during_drag:
			continue

		var rect = Rect2(item.global_position, item.size)
		if rect.has_point(global_mouse):
			# 删除物品并生成掉落数字
			var drop_values = Global.calculate_drop_values(_get_item_value(item))
			_spawn_drop_numbers(drop_values, item.global_position + item.size / 2)
			item.queue_free()
			_deleted_items_during_drag.append(item)


func _delete_item(item: Control) -> void:
	## 删除物品并生成掉落数字
	# 再次确认不是加分面板
	if item.is_in_group("score_drop_zone"):
		return

	# 计算掉落价值
	var drop_values = Global.calculate_drop_values(_get_item_value(item))

	# 生成掉落数字
	_spawn_drop_numbers(drop_values, item.global_position + item.size / 2)

	# 删除物品
	item.queue_free()
	_hovered_item = null


func _get_item_value(item: Control) -> int:
	## 获取物品价值
	if item.get_script() and item.get_script().resource_path.find("score_button") != -1:
		return 100
	if item is ConveyorBelt:
		return 100
	return 50


func _spawn_drop_numbers(values: Array, center_pos: Vector2) -> void:
	## 生成掉落数字，使用Tween实现爆开效果
	var NumberScene = preload("res://scenes/number_object.tscn")

	for i in values.size():
		var number = NumberScene.instantiate()
		number.value = values[i]

		var parent = Global.get_level_parent(3)
		if parent:
			parent.add_child(number)
		else:
			get_tree().current_scene.add_child(number)

		number.global_position = center_pos

		# 计算爆开方向
		var angle = (TAU / values.size()) * i + randf_range(-0.3, 0.3)
		var distance = randf_range(50, 100)
		var target_pos = center_pos + Vector2(cos(angle), sin(angle)) * distance

		# 使用Tween实现爆开动画
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.set_parallel(true)
		tween.tween_property(number, "global_position", target_pos, 0.5)
		tween.tween_property(number, "scale", Vector2(1.2, 1.2), 0.3).from(Vector2(0.1, 0.1))

		# 添加到场景树后会自动显示


func _on_mode_changed(_old_mode: int, new_mode: int) -> void:
	## 模式变化时更新显示
	visible = (new_mode == Global.OperationMode.DELETE)
