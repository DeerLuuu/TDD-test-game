extends Node
## SelectionHandler - 选中处理器
## 处理框选、单选、批量移动、批量调试等逻辑

## 框选框引用
var _selection_box: SelectionBox = null

## 是否正在框选
var _is_box_selecting: bool = false

## 是否正在拖动选中物品
var _is_dragging_selection: bool = false

## 是否点击了空白区域
var _clicked_empty: bool = false

## 拖动起始位置（世界坐标）
var _drag_start_pos: Vector2 = Vector2.ZERO

## 框选起始位置（屏幕坐标）
var _box_select_start_pos: Vector2 = Vector2.ZERO

## 框选起始时间
var _box_select_start_time: float = 0.0

## 长按触发时间
const LONG_PRESS_TIME: float = 0.15

## 最小拖动距离
const MIN_DRAG_DISTANCE: float = 10.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 等待场景加载完成
	await get_tree().process_frame
	_find_selection_box()


func _find_selection_box() -> void:
	## 查找框选框
	var boxes = get_tree().get_nodes_in_group("selection_box")
	if boxes.size() > 0:
		_selection_box = boxes[0]
	else:
		# 尝试从场景中查找
		var scene = get_tree().current_scene
		if scene:
			_selection_box = scene.find_child("SelectionBox", true, true)

	if _selection_box:
		_selection_box.selection_complete.connect(_on_selection_complete)
		_selection_box.selection_update.connect(_on_selection_update)


func _input(event: InputEvent) -> void:
	## 处理输入事件
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_mouse_pressed(event)
		else:
			_on_mouse_released(event)
	elif event is InputEventMouseMotion:
		_on_mouse_moved(event)


func _on_mouse_pressed(event: InputEventMouseButton) -> void:
	## 鼠标按下
	var viewport = get_viewport()
	if not viewport:
		return

	# 屏幕坐标（用于框选框显示）
	var screen_pos = viewport.get_mouse_position()
	_box_select_start_pos = screen_pos

	# 世界坐标（用于拖动计算）
	@warning_ignore("static_called_on_instance")
	var world_mouse = Global.get_scaled_global_mouse_position(viewport)
	@warning_ignore("static_called_on_instance")
	_drag_start_pos = Global.snap_position_to_grid(world_mouse)

	_box_select_start_time = Time.get_ticks_msec() / 1000.0
	_clicked_empty = false

	# 检查是否点击了数字或商店物品（不触发选框）
	if _is_dragging_number_or_shop_item(world_mouse):
		return

	# 检查是否点击了可选中物品
	var clicked_item = _get_item_at_position(event.position)

	if clicked_item:
		# 点击了物品
		if Global.is_click_mode():
			# 点击模式：切换选中
			if Input.is_key_pressed(KEY_CTRL):
				# Ctrl+点击：切换选中
				SelectionManager.toggle_item(clicked_item)
			elif clicked_item in SelectionManager.selected_items:
				# 点击已选中物品：准备拖动
				_is_dragging_selection = true
			else:
				# 点击未选中物品：单独选中
				SelectionManager.clear_selection()
				SelectionManager.select_item(clicked_item)
		elif Global.is_drag_mode():
			# 拖动模式：准备拖动选中物品
			if clicked_item in SelectionManager.selected_items:
				_is_dragging_selection = true
				SelectionManager.show_drag_preview()
			else:
				SelectionManager.clear_selection()
				SelectionManager.select_item(clicked_item)
				_is_dragging_selection = true
				SelectionManager.show_drag_preview()
		elif Global.is_debug_mode():
			# 调试模式：批量调试
			if Input.is_key_pressed(KEY_CTRL):
				SelectionManager.toggle_item(clicked_item)
			elif clicked_item in SelectionManager.selected_items:
				# 启动所有选中物品的调试
				SelectionManager.debug_selected_items()
			else:
				SelectionManager.clear_selection()
				SelectionManager.select_item(clicked_item)
				SelectionManager.debug_selected_items()
	else:
		# 点击空白区域
		_clicked_empty = true
		if Global.is_click_mode() or Global.is_drag_mode() or Global.is_debug_mode():
			# 清除选中
			SelectionManager.clear_selection()


func _on_mouse_released(_event: InputEventMouseButton) -> void:
	## 鼠标释放
	# 结束框选
	if _is_box_selecting and _selection_box:
		_selection_box.end_selection()
		_is_box_selecting = false

	# 结束拖动并应用移动
	if _is_dragging_selection and SelectionManager.has_selection():
		var viewport = get_viewport()
		if viewport and Global.is_drag_mode():
			@warning_ignore("static_called_on_instance")
			var world_mouse = Global.get_scaled_global_mouse_position(viewport)
			@warning_ignore("static_called_on_instance")
			var snapped_mouse = Global.snap_position_to_grid(world_mouse)
			var delta = snapped_mouse - _drag_start_pos

			# 应用最终位置
			if delta != Vector2.ZERO:
				SelectionManager.move_selected_items(delta)

		# 隐藏预览
		SelectionManager.hide_drag_preview()

	_is_dragging_selection = false
	_clicked_empty = false


func _on_mouse_moved(_event: InputEventMouseMotion) -> void:
	## 鼠标移动
	if not _is_dragging_selection and not _is_box_selecting and _clicked_empty:
		# 检查是否应该开始框选（只在空白区域点击后）
		var viewport = get_viewport()
		if viewport:
			var mouse_pos = viewport.get_mouse_position()
			var distance = mouse_pos.distance_to(_box_select_start_pos)

			if distance > MIN_DRAG_DISTANCE:
				var current_time = Time.get_ticks_msec() / 1000.0
				var elapsed = current_time - _box_select_start_time

				# 长按后开始框选（排除删除模式和铺路模式）
				if elapsed >= LONG_PRESS_TIME and not Global.is_delete_mode() and not Global.is_path_build_mode():
					_start_box_selection(_box_select_start_pos)

	# 更新框选
	if _is_box_selecting and _selection_box:
		var viewport = get_viewport()
		if viewport:
			_selection_box.update_selection(viewport.get_mouse_position())

	# 拖动选中物品
	if _is_dragging_selection and SelectionManager.has_selection():
		if Global.is_drag_mode():
			var viewport = get_viewport()
			if viewport:
				@warning_ignore("static_called_on_instance")
				var world_mouse = Global.get_scaled_global_mouse_position(viewport)
				@warning_ignore("static_called_on_instance")
				var snapped_mouse = Global.snap_position_to_grid(world_mouse)
				var delta = snapped_mouse - _drag_start_pos

				# 更新预览位置而不是实际物品
				SelectionManager.update_drag_preview(delta)
	else:
		# 更新拖动起始位置（未开始拖动时跟踪鼠标）
		if Global.is_drag_mode() and SelectionManager.has_selection():
			var viewport = get_viewport()
			if viewport:
				@warning_ignore("static_called_on_instance")
				var world_mouse = Global.get_scaled_global_mouse_position(viewport)
				@warning_ignore("static_called_on_instance")
				_drag_start_pos = Global.snap_position_to_grid(world_mouse)


func _start_box_selection(start_pos: Vector2) -> void:
	## 开始框选
	if not _selection_box:
		return

	# 如果不是Ctrl模式，先清除选中
	if not Input.is_key_pressed(KEY_CTRL):
		SelectionManager.clear_selection()

	_is_box_selecting = true
	_selection_box.start_selection(start_pos)


func _on_selection_update(_rect: Rect2) -> void:
	## 框选更新
	# 实时高亮框选范围内的物品
	pass


func _on_selection_complete(_rect: Rect2) -> void:
	## 框选完成
	if not _selection_box:
		return

	# 获取世界坐标矩形
	var world_rect = _selection_box.get_selection_rect_world()

	# 选中范围内物品
	SelectionManager.select_in_rect(world_rect)


func _get_item_at_position(_screen_pos: Vector2) -> Control:
	## 获取指定位置的物品
	var viewport = get_viewport()
	if not viewport:
		return null

	@warning_ignore("static_called_on_instance")
	var world_pos = Global.get_scaled_global_mouse_position(viewport)

	var items = get_tree().get_nodes_in_group("selectable_items")
	for item in items:
		if not is_instance_valid(item):
			continue
		if not item is Control:
			continue

		var rect = Rect2(item.global_position, item.size)
		if rect.has_point(world_pos):
			return item

	return null


func _is_dragging_number_or_shop_item(world_pos: Vector2) -> bool:
	## 检查是否点击了数字、商店物品或商店面板（这些不触发选框）
	# 检查数字
	var numbers = get_tree().get_nodes_in_group("number_objects")
	for number in numbers:
		if not is_instance_valid(number):
			continue
		if not number is Control:
			continue

		var rect = Rect2(number.global_position, number.size)
		if rect.has_point(world_pos):
			return true

	# 检查商店物品
	var shop_items = get_tree().get_nodes_in_group("shop_items")
	for shop_item in shop_items:
		if not is_instance_valid(shop_item):
			continue
		if not shop_item is Control:
			continue

		var rect = Rect2(shop_item.global_position, shop_item.size)
		if rect.has_point(world_pos):
			return true

	# 检查商店面板（使用屏幕坐标）
	var shop_panels = get_tree().get_nodes_in_group("shop_panel")
	var viewport = get_viewport()
	if viewport:
		var screen_pos = viewport.get_mouse_position()
		for panel in shop_panels:
			if not is_instance_valid(panel):
				continue
			if not panel is Control:
				continue

			var rect = Rect2(panel.global_position, panel.size)
			if rect.has_point(screen_pos):
				return true

	return false


func get_selected_items() -> Array:
	## 获取选中物品列表
	return SelectionManager.selected_items


func has_selection() -> bool:
	## 是否有选中物品
	return SelectionManager.has_selection()
