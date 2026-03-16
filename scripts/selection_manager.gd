extends Node
## SelectionManager - 选中管理器
## 管理所有可选中物品的选中状态
## 处理框选、单选、批量操作

## 选中的物品列表
var selected_items: Array[Control] = []

## 拖动预览节点列表
var _drag_previews: Array[Control] = []

## 选中变化信号
signal selection_changed(items: Array)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func select_item(item: Control) -> void:
	## 选中物品
	if not is_instance_valid(item):
		return
	if item in selected_items:
		return

	var component = _get_selectable_component(item)
	if component and is_instance_valid(component):
		component.select()
		selected_items.append(item)
		selection_changed.emit(selected_items)


func deselect_item(item: Control) -> void:
	## 取消选中物品
	if not is_instance_valid(item):
		return
	if item not in selected_items:
		return

	var component = _get_selectable_component(item)
	if component and is_instance_valid(component):
		component.deselect()
		selected_items.erase(item)
		selection_changed.emit(selected_items)

func toggle_item(item: Control) -> void:
	## 切换物品选中状态
	if item in selected_items:
		deselect_item(item)
	else:
		select_item(item)


func clear_selection() -> void:
	## 清除所有选中
	for item in selected_items.duplicate():
		if is_instance_valid(item):
			var component = _get_selectable_component(item)
			if component and is_instance_valid(component):
				component.deselect()

	selected_items.clear()
	selection_changed.emit(selected_items)

func select_in_rect(rect: Rect2) -> void:
	## 框选范围内的物品
	var items = get_tree().get_nodes_in_group("selectable_items")

	for item in items:
		if not is_instance_valid(item):
			continue
		if not item is Control:
			continue

		# 检测物品中心是否在范围内
		var item_center = item.global_position + item.size / 2
		if rect.has_point(item_center):
			select_item(item)


func select_in_rect_replace(rect: Rect2) -> void:
	## 框选范围内的物品（替换当前选中）
	clear_selection()
	select_in_rect(rect)


func move_selected_items(delta: Vector2) -> void:
	## 移动所有选中物品
	for item in selected_items:
		if is_instance_valid(item):
			item.global_position += delta


func debug_selected_items() -> void:
	## 调试所有选中物品（启动输出组件调试）
	for item in selected_items:
		if not is_instance_valid(item):
			continue

		var output_comp = _get_output_component(item)
		if output_comp:
			output_comp.start_debug()


func apply_debug_direction_to_selected(direction: Vector2) -> void:
	## 应用调试方向到所有选中物品
	for item in selected_items:
		if not is_instance_valid(item):
			continue

		# 传送带特殊处理
		var conveyor = _get_conveyor_belt(item)
		if conveyor:
			conveyor.direction = direction
			continue

		# 分流传送带特殊处理：根据方向旋转
		var splitter = _get_splitter_conveyor(item)
		if splitter:
			_calculate_splitter_rotation(splitter, direction)
			continue

		# 普通物品使用 OutputComponent
		var output_comp = _get_output_component(item)
		if output_comp:
			output_comp.set_output_direction(direction)


func _calculate_splitter_rotation(splitter: SplitterConveyor, target_direction: Vector2) -> void:
	## 根据目标方向计算分流器需要的旋转
	# 目标方向 = 分流后数字要去的方向之一
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


func stop_debug_selected_items() -> void:
	## 停止调试所有选中物品
	for item in selected_items:
		if not is_instance_valid(item):
			continue

		var output_comp = _get_output_component(item)
		if output_comp:
			output_comp.end_debug()


func has_selection() -> bool:
	## 是否有选中物品
	return selected_items.size() > 0


func get_selection_count() -> int:
	## 获取选中数量
	return selected_items.size()


func show_drag_preview() -> void:
	## 显示拖动预览
	hide_drag_preview()  # 先清除之前的预览

	for item in selected_items:
		if not is_instance_valid(item):
			continue

		var preview = _create_preview_for_item(item)
		if preview:
			_drag_previews.append(preview)
			get_tree().current_scene.add_child(preview)


func update_drag_preview(delta: Vector2) -> void:
	## 更新拖动预览位置
	for i in range(_drag_previews.size()):
		if is_instance_valid(_drag_previews[i]) and is_instance_valid(selected_items[i]):
			_drag_previews[i].global_position = selected_items[i].global_position + delta


func hide_drag_preview() -> void:
	## 隐藏拖动预览
	for preview in _drag_previews:
		if is_instance_valid(preview):
			preview.queue_free()
	_drag_previews.clear()


func _create_preview_for_item(item: Control) -> Control:
	## 为物品创建预览副本
	var preview = Control.new()
	preview.size = item.size
	preview.global_position = item.global_position
	preview.modulate = Color(0.5, 1.0, 0.5, 0.5)  # 绿色半透明

	# 创建背景
	var bg = Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.5, 1.0, 0.5, 0.3)
	style.border_color = Color(0.3, 0.8, 0.3, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	bg.add_theme_stylebox_override("panel", style)

	preview.add_child(bg)
	return preview


func _get_selectable_component(item: Control) -> SelectableComponent:
	## 获取物品的可选中组件
	if not is_instance_valid(item):
		return null
	for child in item.get_children():
		if child is SelectableComponent and is_instance_valid(child):
			return child
	return null


func _get_output_component(item: Control) -> OutputComponent:
	## 获取物品的输出组件
	if not is_instance_valid(item):
		return null
	for child in item.get_children():
		if child is OutputComponent and is_instance_valid(child):
			return child
	return null


func _get_conveyor_belt(item: Control) -> ConveyorBelt:
	## 获取物品作为传送带（如果是传送带的话）
	if not is_instance_valid(item):
		return null
	if item is ConveyorBelt:
		return item
	return null


func _get_splitter_conveyor(item: Control) -> SplitterConveyor:
	## 获取物品作为分流传送带（如果是分流器的话）
	if not is_instance_valid(item):
		return null
	if item is SplitterConveyor:
		return item
	return null
