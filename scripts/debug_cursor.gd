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

## 传送器配对：第一个选中的传送器
var _teleporter_pair_first: Teleporter = null


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
	var viewport = get_tree().root.get_viewport()
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
	var viewport = get_tree().root.get_viewport()
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
	var viewport = get_tree().root.get_viewport()
	@warning_ignore("static_called_on_instance")
	var world_mouse = Global.get_scaled_global_mouse_position(viewport)
	var items = get_tree().get_nodes_in_group("placeable_items")

	# 先隐藏所有物品的调试显示
	for item in items:
		_end_item_debug(item)

	_hovered_item = null

	for item in items:
		if not is_instance_valid(item):
			continue
		if not item is Control:
			continue

		var rect = Rect2(item.global_position, item.size)
		if rect.has_point(world_mouse):
			# 检查是否可调试（有OutputComponent或者是分流器）
			if _can_debug_item(item):
				_hovered_item = item
			break

	# 显示所有选中物品的调试箭头
	for item in SelectionManager.selected_items:
		if is_instance_valid(item):
			_start_item_debug(item)

	# 如果悬停物品未被选中，也显示其调试箭头
	if _hovered_item and _hovered_item not in SelectionManager.selected_items:
		_start_item_debug(_hovered_item)


func _get_output_component(item: Control) -> OutputComponent:
	## 获取物品的OutputComponent
	for child in item.get_children():
		if child is OutputComponent:
			return child
	return null


func _can_debug_item(item: Control) -> bool:
	## 检查物品是否可以被调试
	# 传送器类型有专门的调试方法
	if item is Teleporter:
		return true
	# 分流器类型有特殊的调试方法
	if item is SplitterConveyor or item is TriSplitterConveyor:
		return true
	# 普通物品检查是否有OutputComponent
	return _get_output_component(item) != null


func _start_item_debug(item: Control) -> void:
	## 启动物品的调试显示
	if item is Teleporter:
		# 传送器有专门的调试方法
		item.start_debug()
	elif item is SplitterConveyor or item is TriSplitterConveyor:
		# 分流器有专门的start_debug方法
		item.start_debug()
	else:
		# 普通物品使用OutputComponent
		var output_comp = _get_output_component(item)
		if output_comp:
			output_comp.start_debug()


func _end_item_debug(item: Control) -> void:
	## 结束物品的调试显示
	if item is Teleporter:
		# 传送器有专门的调试方法
		item.end_debug()
	elif item is SplitterConveyor or item is TriSplitterConveyor:
		# 分流器有专门的end_debug方法
		item.end_debug()
	else:
		# 普通物品使用OutputComponent
		var output_comp = _get_output_component(item)
		if output_comp:
			output_comp.end_debug()


func _update_drag_line() -> void:
	## 更新拖动方向指示线
	if not _dragging_item:
		_drag_line.visible = false
		return

	_drag_line.visible = true

	var viewport = get_tree().root.get_viewport()
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
	## 处理拖动设置输出方向和传送器配对
	if not Global.is_debug_mode():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 开始拖动 - 直接检测鼠标位置下的物品
			var item = _get_item_at_mouse()
			if item and _can_debug_item(item):
				# 传送器特殊处理：点击配对
				if item is Teleporter:
					_handle_teleporter_click(item)
				else:
					_dragging_item = item
					_drag_start_pos = _dragging_item.global_position + _dragging_item.size / 2
		elif not event.pressed and _dragging_item:
			# 结束拖动，应用方向
			var viewport = get_tree().root.get_viewport()
			@warning_ignore("static_called_on_instance")
			var end_pos = Global.get_scaled_global_mouse_position(viewport)

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
				elif _dragging_item is TriSplitterConveyor:
					# 三相分流器：根据方向旋转
					_apply_tri_splitter_rotation(_dragging_item, direction)
				else:
					# 普通物品使用 OutputComponent
					var output_comp = _get_output_component(_dragging_item)
					if output_comp:
						output_comp.set_output_direction(direction)

			_dragging_item = null


## 处理传送器点击（调试模式下配对）
func _handle_teleporter_click(teleporter: Teleporter) -> void:
	if _teleporter_pair_first == null:
		# 第一次点击：选中第一个传送器
		_teleporter_pair_first = teleporter
		# 高亮显示（可以添加视觉效果）
	elif _teleporter_pair_first == teleporter:
		# 点击同一个传送器：取消配对
		_teleporter_pair_first.clear_pair()
		_teleporter_pair_first = null
	else:
		# 第二次点击：配对两个传送器
		_teleporter_pair_first.set_pair_to(teleporter)
		_teleporter_pair_first = null


func _get_item_at_mouse() -> Control:
	## 获取鼠标位置下的可调试物品
	var viewport = get_tree().root.get_viewport()
	if not viewport:
		return null

	@warning_ignore("static_called_on_instance")
	var world_mouse = Global.get_scaled_global_mouse_position(viewport)
	var items = get_tree().get_nodes_in_group("placeable_items")

	for item in items:
		if not is_instance_valid(item):
			continue
		if not item is Control:
			continue

		var rect = Rect2(item.global_position, item.size)
		if rect.has_point(world_mouse):
			return item

	return null


func _apply_splitter_rotation(splitter: SplitterConveyor, target_direction: Vector2) -> void:
	## 根据目标方向旋转分流器
	# 目标方向 = 分流后数字要去的方向之一
	# 需要计算对应的旋转角度
	
	# 使用 is_equal_approx 避免精度问题
	var is_left = target_direction.is_equal_approx(Vector2.LEFT)
	var is_up = target_direction.is_equal_approx(Vector2.UP)
	var is_right = target_direction.is_equal_approx(Vector2.RIGHT)
	var is_down = target_direction.is_equal_approx(Vector2.DOWN)
	
	if is_left:
		splitter.rotation_angle = 0
	elif is_up:
		splitter.rotation_angle = 90
	elif is_right:
		splitter.rotation_angle = 180
	elif is_down:
		splitter.rotation_angle = 270
	else:
		return

	# 更新方向和箭头
	splitter._update_directions()
	splitter._update_arrow_layout()
	splitter._update_arrow_textures()
	# 更新调试箭头显示
	splitter.update_debug_arrows()


func _apply_tri_splitter_rotation(tri_splitter: TriSplitterConveyor, target_direction: Vector2) -> void:
	## 根据拖动方向设置三相分流器的调试方向
	## 调试方向 = 出口1方向
	## 入口方向 = 调试方向的反方向
	tri_splitter.set_debug_direction(target_direction)


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
		_end_item_debug(item)


func _on_mode_changed(_old_mode: int, new_mode: int) -> void:
	## 模式变化时更新显示
	visible = (new_mode == Global.OperationMode.DEBUG)
	if new_mode != Global.OperationMode.DEBUG:
		_hide_all_items_debug()
		_dragging_item = null
		_teleporter_pair_first = null  # 清理传送器配对状态
