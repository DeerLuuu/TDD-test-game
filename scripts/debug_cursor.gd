class_name DebugCursor extends Control
## DebugCursor - 调试模式的光标指示器
## 跟随鼠标，显示绿色半透明区域
## 悬停在有OutputComponent的物品上时可拖动设置输出方向

## 当前悬停的物品
var _hovered_item: Control = null

## 当前拖动设置的物品
var _dragging_item: Control = null

## 拖动起始位置
var _drag_start_pos: Vector2 = Vector2.ZERO

## 背景面板
var _background: Panel = null

## 拖动方向指示线
var _drag_line: Line2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_background()
	_create_drag_line()
	visible = false

	# 连接模式变化信号
	if not Global.mode_changed.is_connected(_on_mode_changed):
		Global.mode_changed.connect(_on_mode_changed)


func _process(_delta: float) -> void:
	if not Global.is_debug_mode():
		visible = false
		_hide_all_items_debug()
		return

	visible = true
	_update_position()
	_update_size()
	_update_hovered_item()
	_update_drag_line()


func _create_background() -> void:
	_background = Panel.new()
	_background.anchor_right = 1.0
	_background.anchor_bottom = 1.0
	add_child(_background)

	# 设置绿色半透明样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 1.0, 0.2, 0.5)  # 绿色半透明
	style.border_color = Color(0.0, 1.0, 0.0, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	_background.add_theme_stylebox_override("panel", style)


func _create_drag_line() -> void:
	_drag_line = Line2D.new()
	_drag_line.width = 3.0
	_drag_line.default_color = Color.GREEN
	_drag_line.visible = false
	add_child(_drag_line)


func _update_position() -> void:
	## 更新位置跟随鼠标
	var viewport = get_viewport()
	if not viewport:
		return

	if _hovered_item:
		# 悬停在物品上时，显示在物品位置
		var canvas_transform = viewport.get_canvas_transform()
		var item_screen_pos = canvas_transform * _hovered_item.global_position
		global_position = item_screen_pos
	else:
		# 显示在鼠标位置（网格对齐）
		@warning_ignore("static_called_on_instance")
		var world_mouse = Global.get_scaled_global_mouse_position(viewport)
		var cursor_size = Vector2(Global.GRID_SIZE, Global.GRID_SIZE)
		@warning_ignore("static_called_on_instance")
		var snapped_pos = Global.snap_position_to_grid(world_mouse - cursor_size / 2)

		var canvas_transform = viewport.get_canvas_transform()
		global_position = canvas_transform * snapped_pos


func _update_size() -> void:
	## 更新大小
	var viewport = get_viewport()
	if not viewport:
		return

	# 获取相机缩放
	var canvas_transform = viewport.get_canvas_transform()
	var zoom = canvas_transform.get_scale().x

	if _hovered_item:
		custom_minimum_size = _hovered_item.size * zoom
		size = _hovered_item.size * zoom
	else:
		custom_minimum_size = Vector2(Global.GRID_SIZE, Global.GRID_SIZE) * zoom
		size = Vector2(Global.GRID_SIZE, Global.GRID_SIZE) * zoom


func _update_hovered_item() -> void:
	## 更新悬停物品检测
	@warning_ignore("static_called_on_instance")
	var world_mouse = Global.get_scaled_global_mouse_position(get_viewport())
	var items = get_tree().get_nodes_in_group("placeable_items")

	# 先隐藏所有物品的调试显示
	for item in items:
		var output_comp = _get_output_component(item)
		if output_comp:
			output_comp.end_debug()

	_hovered_item = null

	for item in items:
		if not is_instance_valid(item):
			continue
		if not item is Control:
			continue

		var rect = Rect2(item.global_position, item.size)
		if rect.has_point(world_mouse):
			# 检查是否有OutputComponent
			var output_comp = _get_output_component(item)
			if output_comp:
				_hovered_item = item
			break

	# 显示所有选中物品的调试箭头
	for item in SelectionManager.selected_items:
		if is_instance_valid(item):
			var output_comp = _get_output_component(item)
			if output_comp:
				output_comp.start_debug()

	# 如果悬停物品未被选中，也显示其调试箭头
	if _hovered_item and _hovered_item not in SelectionManager.selected_items:
		var output_comp = _get_output_component(_hovered_item)
		if output_comp:
			output_comp.start_debug()


func _get_output_component(item: Control) -> OutputComponent:
	## 获取物品的OutputComponent
	for child in item.get_children():
		if child is OutputComponent:
			return child
	return null


func _update_drag_line() -> void:
	## 更新拖动方向指示线
	if not _dragging_item:
		_drag_line.visible = false
		return

	_drag_line.visible = true

	var viewport = get_viewport()
	if not viewport:
		return

	var canvas_transform = viewport.get_canvas_transform()

	# 起始位置（物品中心）
	var item_center = _dragging_item.global_position + _dragging_item.size / 2
	var start_screen = canvas_transform * item_center

	# 结束位置（鼠标位置）
	var end_screen = viewport.get_mouse_position()

	# 转换为本地坐标
	_drag_line.clear_points()
	_drag_line.add_point(start_screen - global_position)
	_drag_line.add_point(end_screen - global_position)


func _input(event: InputEvent) -> void:
	## 处理拖动设置输出方向
	if not Global.is_debug_mode():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _hovered_item:
			# 开始拖动
			_dragging_item = _hovered_item
			_drag_start_pos = _dragging_item.global_position + _dragging_item.size / 2
		elif not event.pressed and _dragging_item:
			# 结束拖动，应用方向
			@warning_ignore("static_called_on_instance")
			var end_pos = Global.get_scaled_global_mouse_position(get_viewport())

			# 计算方向
			var parent_center = _dragging_item.global_position + _dragging_item.size / 2
			var delta = end_pos - parent_center
			var direction = _calculate_direction(delta)

			# 检查是否有多个选中物品
			if SelectionManager.has_selection() and _dragging_item in SelectionManager.selected_items:
				# 应用到所有选中物品
				SelectionManager.apply_debug_direction_to_selected(direction)
			else:
				# 只应用到当前物品
				# 检查是否是传送带
				if _dragging_item is ConveyorBelt:
					_dragging_item.direction = direction
				elif _dragging_item is SplitterConveyor:
					# 分流器：根据方向旋转
					_apply_splitter_rotation(_dragging_item, direction)
				else:
					# 普通物品使用 OutputComponent
					var output_comp = _get_output_component(_dragging_item)
					if output_comp:
						output_comp.set_output_direction(direction)

			_dragging_item = null


func _apply_splitter_rotation(splitter: SplitterConveyor, target_direction: Vector2) -> void:
	## 根据目标方向旋转分流器
	# 目标方向 = 分流后数字要去的方向之一
	# 需要计算对应的旋转角度
	match target_direction:
		Vector2.LEFT:
			splitter.rotation_angle = 0
		Vector2.UP:
			splitter.rotation_angle = 90
		Vector2.RIGHT:
			splitter.rotation_angle = 180
		Vector2.DOWN:
			splitter.rotation_angle = 270
		_:
			return

	# 更新方向和箭头
	splitter._update_directions()
	splitter._update_arrow_layout()
	splitter._update_arrow_textures()


func _calculate_direction(delta: Vector2) -> Vector2:
	## 从拖动向量计算主要方向
	if absf(delta.x) > absf(delta.y):
		# 水平方向
		if delta.x > 0:
			return Vector2.RIGHT
		else:
			return Vector2.LEFT
	else:
		# 垂直方向
		if delta.y > 0:
			return Vector2.DOWN
		else:
			return Vector2.UP


func _hide_all_items_debug() -> void:
	## 隐藏所有物品的调试显示
	var items = get_tree().get_nodes_in_group("placeable_items")
	for item in items:
		var output_comp = _get_output_component(item)
		if output_comp:
			output_comp.end_debug()


func _on_mode_changed(_old_mode: int, new_mode: int) -> void:
	## 模式变化时更新显示
	visible = (new_mode == Global.OperationMode.DEBUG)
	if new_mode != Global.OperationMode.DEBUG:
		_hide_all_items_debug()
		_dragging_item = null
