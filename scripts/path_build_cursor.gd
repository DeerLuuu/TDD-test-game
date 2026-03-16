class_name PathBuildCursor extends Control
## PathBuildCursor - 铺路模式的光标指示器
## 完全参考异形工厂的传送带放置逻辑
##
## 工作流程：
## 1. 单击 - 在鼠标位置放置单个传送带
## 2. 拖动 - 按住左键拖动，松开时放置传送带
##    - 直线拖动 = 直线路径
##    - 斜向拖动 = L型路径（先走主轴方向）
## 3. R键 - 旋转当前预览的传送带方向
## 4. 右键 - 取消当前操作

## 路径计算器
var _path_calculator: RefCounted = null

## 当前拖动的起始位置（世界坐标，已对齐）
var _drag_start_pos: Vector2 = Vector2.ZERO

## 是否正在拖动
var _is_dragging: bool = false

## 预览传送带列表
var _preview_conveyors: Array[Control] = []

## 传送带场景
var _conveyor_scene: PackedScene = preload("res://scenes/conveyor_belt.tscn")

## 传送带价格（与商店一致）
const CONVEYOR_COST: int = 100

## 传送带层级（与商店一致）
const CONVEYOR_LEVEL: int = 2

## 当前传送带方向（用于单击放置）
var _current_direction: Vector2 = Vector2.RIGHT

## 背景面板（框框）
var _background: Panel = null

## 方向指示箭头
var _direction_arrow: TextureRect = null

## 上一次预览的终点位置（避免重复生成）
var _last_preview_end: Vector2 = Vector2.ZERO

## 最小拖动距离（像素）
const MIN_DRAG_DISTANCE: float = 30.0

## 传送带大小
const CONVEYOR_SIZE: int = 50

## 箭头纹理
var _arrow_textures: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_path_calculator()
	_create_background()
	_create_direction_arrow()
	_load_arrow_textures()
	visible = false

	# 连接模式变化信号
	if not Global.mode_changed.is_connected(_on_mode_changed):
		Global.mode_changed.connect(_on_mode_changed)


func _create_path_calculator() -> void:
	_path_calculator = PathCalculator.new()


func _create_background() -> void:
	_background = Panel.new()
	_background.anchor_right = 1.0
	_background.anchor_bottom = 1.0
	add_child(_background)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.8, 1.0, 0.4)
	style.border_color = Color(0.0, 0.9, 1.0, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	_background.add_theme_stylebox_override("panel", style)


func _create_direction_arrow() -> void:
	_direction_arrow = TextureRect.new()
	_direction_arrow.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_direction_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_direction_arrow.custom_minimum_size = Vector2(20, 20)
	_direction_arrow.visible = false
	add_child(_direction_arrow)


func _load_arrow_textures() -> void:
	_arrow_textures = {
		Vector2.RIGHT: preload("res://assets/arrows/arrow_right.svg"),
		Vector2.LEFT: preload("res://assets/arrows/arrow_left.svg"),
		Vector2.UP: preload("res://assets/arrows/arrow_up.svg"),
		Vector2.DOWN: preload("res://assets/arrows/arrow_down.svg")
	}


func _process(_delta: float) -> void:
	if not Global.is_path_build_mode():
		visible = false
		_clear_previews()
		_is_dragging = false
		return

	visible = true
	_update_background()
	_update_preview()
	_update_direction_arrow()


func _update_background() -> void:
	var viewport = get_viewport()
	if not viewport:
		_background.visible = false
		return

	var canvas_transform = viewport.get_canvas_transform()
	var camera = viewport.get_camera_2d()
	var zoom = Vector2(1, 1)
	if camera:
		zoom = camera.zoom

	# 获取鼠标位置并对齐到网格（中心点对齐，与其他面板一致）
	@warning_ignore("static_called_on_instance")
	var world_mouse = Global.get_scaled_global_mouse_position(viewport)
	var conveyor_size = Vector2(CONVEYOR_SIZE, CONVEYOR_SIZE)
	@warning_ignore("static_called_on_instance")
	var snapped_pos = Global.snap_position_to_grid(world_mouse - conveyor_size / 2)

	var screen_pos = canvas_transform * snapped_pos
	global_position = screen_pos
	custom_minimum_size = conveyor_size * zoom
	size = conveyor_size * zoom
	_background.visible = true


func _input(event: InputEvent) -> void:
	if not Global.is_path_build_mode():
		return

	# R键旋转方向
	if event is InputEventKey and event.keycode == KEY_R and event.pressed:
		_rotate_direction()
		_update_preview_directions()
		get_viewport().set_input_as_handled()
		return

	# 右键取消
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and _is_dragging:
			_cancel_drag()
			get_viewport().set_input_as_handled()
			return

	# 左键处理
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		else:
			_end_drag()


func _rotate_direction() -> void:
	## 顺时针旋转方向：右 -> 下 -> 左 -> 上 -> 右
	match _current_direction:
		Vector2.RIGHT: _current_direction = Vector2.DOWN
		Vector2.DOWN: _current_direction = Vector2.LEFT
		Vector2.LEFT: _current_direction = Vector2.UP
		Vector2.UP: _current_direction = Vector2.RIGHT


func _update_preview_directions() -> void:
	## 更新所有预览传送带的方向
	for preview in _preview_conveyors:
		if is_instance_valid(preview):
			preview.direction = _current_direction


func _start_drag() -> void:
	## 开始拖动
	var viewport = get_viewport()
	if not viewport:
		return

	@warning_ignore("static_called_on_instance")
	var world_mouse = Global.get_scaled_global_mouse_position(viewport)
	var conveyor_size = Vector2(CONVEYOR_SIZE, CONVEYOR_SIZE)
	@warning_ignore("static_called_on_instance")
	_drag_start_pos = Global.snap_position_to_grid(world_mouse - conveyor_size / 2)
	_is_dragging = true
	_last_preview_end = Vector2.ZERO


func _end_drag() -> void:
	## 结束拖动
	if not _is_dragging:
		return

	var viewport = get_viewport()
	if not viewport:
		_is_dragging = false
		return

	@warning_ignore("static_called_on_instance")
	var world_mouse = Global.get_scaled_global_mouse_position(viewport)
	var drag_distance = world_mouse.distance_to(_drag_start_pos)

	# 判断是单击还是拖动
	if drag_distance < MIN_DRAG_DISTANCE:
		# 单击：放置单个传送带
		_place_single_conveyor()
	else:
		# 拖动：放置传送带路径
		_place_all_previews()

	_is_dragging = false
	_drag_start_pos = Vector2.ZERO
	_last_preview_end = Vector2.ZERO


func _cancel_drag() -> void:
	## 取消拖动
	_is_dragging = false
	_drag_start_pos = Vector2.ZERO
	_last_preview_end = Vector2.ZERO
	_clear_previews()


func _update_preview() -> void:
	## 更新预览（拖动时实时更新）
	if not _is_dragging:
		_clear_previews()
		return

	var viewport = get_viewport()
	if not viewport:
		return

	@warning_ignore("static_called_on_instance")
	var world_mouse = Global.get_scaled_global_mouse_position(viewport)
	var drag_distance = world_mouse.distance_to(_drag_start_pos)

	# 如果拖动距离太小，不生成预览
	if drag_distance < MIN_DRAG_DISTANCE:
		_clear_previews()
		return

	var conveyor_size = Vector2(CONVEYOR_SIZE, CONVEYOR_SIZE)
	@warning_ignore("static_called_on_instance")
	var end_pos = Global.snap_position_to_grid(world_mouse - conveyor_size / 2)

	# 如果终点没变，不需要重新生成
	if end_pos == _last_preview_end and _preview_conveyors.size() > 0:
		return

	_last_preview_end = end_pos

	# 生成路径预览（支持直线和L型）
	_generate_path_preview(_drag_start_pos, end_pos)


func _generate_path_preview(start_pos: Vector2, end_pos: Vector2) -> void:
	## 生成路径预览（支持直线和L型）
	_clear_previews()

	if start_pos == end_pos:
		return

	var delta = end_pos - start_pos
	var is_horizontal_dominant = absf(delta.x) >= absf(delta.y)

	# 判断是否需要L型路径
	@warning_ignore("integer_division")
	var need_l_shape = absf(delta.x) > CONVEYOR_SIZE / 2 and absf(delta.y) > CONVEYOR_SIZE / 2

	if need_l_shape:
		# L型路径
		_generate_l_path_preview(start_pos, end_pos, is_horizontal_dominant)
	else:
		# 直线路径
		_generate_line_preview(start_pos, end_pos)


func _generate_line_preview(start_pos: Vector2, end_pos: Vector2) -> void:
	## 生成直线路径预览
	var path = _calculate_line_path(start_pos, end_pos)
	_create_preview_conveyors(path)


func _generate_l_path_preview(start_pos: Vector2, end_pos: Vector2, horizontal_first: bool) -> void:
	## 生成L型路径预览
	var path = _calculate_l_path(start_pos, end_pos, horizontal_first)
	_create_preview_conveyors(path)


func _calculate_line_path(start_pos: Vector2, end_pos: Vector2) -> Array[Vector2]:
	## 计算从起点到终点的直线路径
	var path: Array[Vector2] = []
	var delta = end_pos - start_pos

	# 确定方向
	if absf(delta.x) >= absf(delta.y):
		# 水平方向
		_current_direction = Vector2.RIGHT if delta.x >= 0 else Vector2.LEFT
		var dir = 1 if delta.x >= 0 else -1
		var count = absi(roundi(delta.x / CONVEYOR_SIZE))
		for i in range(count + 1):
			var pos = Vector2(start_pos.x + i * CONVEYOR_SIZE * dir, start_pos.y)
			path.append(pos)
	else:
		# 垂直方向
		_current_direction = Vector2.DOWN if delta.y >= 0 else Vector2.UP
		var dir = 1 if delta.y >= 0 else -1
		var count = absi(roundi(delta.y / CONVEYOR_SIZE))
		for i in range(count + 1):
			var pos = Vector2(start_pos.x, start_pos.y + i * CONVEYOR_SIZE * dir)
			path.append(pos)

	return path


func _calculate_l_path(start_pos: Vector2, end_pos: Vector2, horizontal_first: bool) -> Array[Vector2]:
	## 计算L型路径
	var path: Array[Vector2] = []

	var dx = end_pos.x - start_pos.x
	var dy = end_pos.y - start_pos.y
	var steps_x = absi(roundi(dx / CONVEYOR_SIZE))
	var steps_y = absi(roundi(dy / CONVEYOR_SIZE))
	var dir_x = 1 if dx >= 0 else -1
	var dir_y = 1 if dy >= 0 else -1

	if horizontal_first:
		# 先水平后垂直
		# 水平段
		for i in range(steps_x + 1):
			var pos = Vector2(start_pos.x + i * CONVEYOR_SIZE * dir_x, start_pos.y)
			path.append(pos)
		# 垂直段（跳过起点）
		for i in range(1, steps_y + 1):
			var pos = Vector2(end_pos.x, start_pos.y + i * CONVEYOR_SIZE * dir_y)
			path.append(pos)
	else:
		# 先垂直后水平
		# 垂直段
		for i in range(steps_y + 1):
			var pos = Vector2(start_pos.x, start_pos.y + i * CONVEYOR_SIZE * dir_y)
			path.append(pos)
		# 水平段（跳过起点）
		for i in range(1, steps_x + 1):
			var pos = Vector2(start_pos.x + i * CONVEYOR_SIZE * dir_x, end_pos.y)
			path.append(pos)

	return path


func _create_preview_conveyors(path: Array[Vector2]) -> void:
	## 根据路径创建预览传送带
	if path.is_empty():
		return

	# 计算每个传送带的方向
	var current_score = GameScore.get_score()
	var conveyor_size = Vector2(CONVEYOR_SIZE, CONVEYOR_SIZE)

	var valid_count = 0
	for i in range(path.size()):
		var pos = path[i]

		# 计算这个传送带的方向
		var direction: Vector2
		if i < path.size() - 1:
			# 根据下一个位置计算方向
			var next_pos = path[i + 1]
			var delta = next_pos - pos
			if absf(delta.x) > absf(delta.y):
				direction = Vector2.RIGHT if delta.x > 0 else Vector2.LEFT
			else:
				direction = Vector2.DOWN if delta.y > 0 else Vector2.UP
		else:
			# 最后一个传送带使用前一个的方向
			direction = _current_direction

		# 检查位置是否已被占用
		@warning_ignore("static_called_on_instance")
		if Global.check_position_occupied(pos, conveyor_size):
			continue

		var preview = _conveyor_scene.instantiate()
		preview.set_meta("is_preview", true)

		valid_count += 1
		var can_afford = valid_count * CONVEYOR_COST <= current_score
		if can_afford:
			preview.modulate = Color(0.2, 0.8, 1.0, 0.6)
		else:
			preview.modulate = Color(1.0, 0.3, 0.3, 0.6)

		preview.global_position = pos
		preview.direction = direction

		var parent = Global.get_level_parent(CONVEYOR_LEVEL)
		if parent:
			parent.add_child(preview)
		else:
			get_tree().current_scene.add_child(preview)

		_preview_conveyors.append(preview)


func _update_direction_arrow() -> void:
	## 更新方向指示箭头
	if not _arrow_textures.has(_current_direction):
		return

	_direction_arrow.texture = _arrow_textures[_current_direction]
	_direction_arrow.visible = not _is_dragging  # 拖动时隐藏

	if _is_dragging:
		return

	var viewport = get_viewport()
	if not viewport:
		return

	var canvas_transform = viewport.get_canvas_transform()
	var camera = viewport.get_camera_2d()
	var zoom = Vector2(1, 1)
	if camera:
		zoom = camera.zoom

	# 箭头显示在框框中心（中心点对齐）
	@warning_ignore("static_called_on_instance")
	var world_mouse = Global.get_scaled_global_mouse_position(viewport)
	var conveyor_size = Vector2(CONVEYOR_SIZE, CONVEYOR_SIZE)
	@warning_ignore("static_called_on_instance")
	var center_pos = Global.snap_position_to_grid(world_mouse - conveyor_size / 2) + conveyor_size / 2

	var screen_center = canvas_transform * center_pos
	_direction_arrow.global_position = screen_center - _direction_arrow.size / 2


func _place_single_conveyor() -> void:
	## 放置单个传送带
	var viewport = get_viewport()
	if not viewport:
		return

	var current_score = GameScore.get_score()
	if current_score < CONVEYOR_COST:
		return

	@warning_ignore("static_called_on_instance")
	var world_mouse = Global.get_scaled_global_mouse_position(viewport)
	var conveyor_size = Vector2(CONVEYOR_SIZE, CONVEYOR_SIZE)
	@warning_ignore("static_called_on_instance")
	var pos = Global.snap_position_to_grid(world_mouse - conveyor_size / 2)

	# 检查位置是否已被占用
	@warning_ignore("static_called_on_instance")
	if Global.check_position_occupied(pos, conveyor_size):
		return

	# 放置传送带
	var conveyor = _conveyor_scene.instantiate()
	conveyor.global_position = pos
	conveyor.direction = _current_direction

	var parent = Global.get_level_parent(CONVEYOR_LEVEL)
	if parent:
		parent.add_child(conveyor)
	else:
		get_tree().current_scene.add_child(conveyor)

	# 添加到交互组（与商店一致）
	conveyor.add_to_group("placeable_items")
	conveyor.add_to_group("selectable_items")

	# 扣除分数
	GameScore.add_score(-CONVEYOR_COST)


func _clear_previews() -> void:
	## 清除所有预览
	for preview in _preview_conveyors:
		if is_instance_valid(preview):
			preview.queue_free()

	_preview_conveyors.clear()


func _place_all_previews() -> void:
	## 放置所有预览传送带
	var current_score = GameScore.get_score()
	@warning_ignore("integer_division")
	var max_placeable = current_score / CONVEYOR_COST

	var placed_count = 0
	for i in range(mini(_preview_conveyors.size(), max_placeable)):
		var preview = _preview_conveyors[i]
		if is_instance_valid(preview):
			# 移除预览标记
			preview.set_meta("is_preview", false)
			preview.modulate = Color(1, 1, 1, 1)
			# 添加到交互组（与商店一致）
			preview.add_to_group("placeable_items")
			preview.add_to_group("selectable_items")
			placed_count += 1

	if placed_count > 0:
		GameScore.add_score(-placed_count * CONVEYOR_COST)

	# 移除分数不足的预览
	for i in range(placed_count, _preview_conveyors.size()):
		var preview = _preview_conveyors[i]
		if is_instance_valid(preview):
			preview.queue_free()

	_preview_conveyors.clear()


func _on_mode_changed(_old_mode: int, new_mode: int) -> void:
	visible = (new_mode == Global.OperationMode.PATH_BUILD)
	if new_mode != Global.OperationMode.PATH_BUILD:
		_clear_previews()
		_is_dragging = false
