extends Control
## 商店物品 - 可拖动的商店物品
class_name ShopItem

signal dragged_out(item: ShopItem, global_pos: Vector2)

@export var item_name: String = "物品"
@export var cost: int = 100
@export var scene_path: String = ""

var _is_dragging: bool = false
var _drag_start_pos: Vector2
var _drag_offset: Vector2
var _preview: Control = null

## AutoClicker专用：当前悬停的目标面板
var _auto_clicker_target: Control = null

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var cost_label: Label = $VBoxContainer/CostLabel


func _ready() -> void:
	add_to_group("shop_items")
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	_update_display()


func _process(_delta: float) -> void:
	if _is_dragging and _preview:
		@warning_ignore("static_called_on_instance")
		var global_mouse = Global.get_scaled_global_mouse_position(get_viewport())

		# AutoClicker特殊处理
		if _is_auto_clicker():
			_update_auto_clicker_preview(global_mouse)
		else:
			var target_pos = global_mouse - _preview.size / 2
			@warning_ignore("static_called_on_instance")
			var snapped_pos = Global.snap_position_to_grid(target_pos)
			_preview.global_position = snapped_pos


func _is_auto_clicker() -> bool:
	## 检查是否是自动点击器
	return scene_path.find("auto_clicker") != -1


func _update_auto_clicker_preview(global_mouse: Vector2) -> void:
	## 更新AutoClicker预览
	# 查找悬停的目标面板/按钮
	_auto_clicker_target = _find_auto_clicker_target(global_mouse)

	if _auto_clicker_target:
		# 匹配目标大小
		var target_size = _auto_clicker_target.size + Vector2(8, 8)  # 边距4*2
		_preview.custom_minimum_size = target_size
		_preview.size = target_size
		# 对齐到目标位置
		_preview.global_position = _auto_clicker_target.global_position - Vector2(4, 4)
	else:
		# 默认大小
		var default_size = Vector2(50, 50)
		_preview.custom_minimum_size = default_size
		_preview.size = default_size
		# 对齐到网格
		@warning_ignore("static_called_on_instance")
		var snapped_pos = Global.snap_position_to_grid(global_mouse - default_size / 2)
		_preview.global_position = snapped_pos


func _find_auto_clicker_target(global_mouse: Vector2) -> Control:
	## 查找可以放置AutoClicker的目标（必须带有ClickComponent）
	var items = get_tree().get_nodes_in_group("placeable_items")

	for item in items:
		if not is_instance_valid(item):
			continue
		if not item is Control:
			continue
		# 排除AutoClicker自身
		if item is AutoClicker:
			continue
		if item.is_in_group("score_drop_zone"):
			continue

		# 检查是否有ClickComponent
		if not _has_click_component(item):
			continue

		var rect = Rect2(item.global_position, item.size)
		if rect.has_point(global_mouse):
			return item

	return null


func _has_click_component(item: Control) -> bool:
	## 检查物品是否有ClickComponent
	for child in item.get_children():
		if child is ClickComponent:
			return true
	return false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
			accept_event()
		else:
			if _is_dragging:
				_end_drag()
				accept_event()


func _input(event: InputEvent) -> void:
	if _is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_end_drag()


func can_afford(available_score: int) -> bool:
	## 检查分数是否足够
	return available_score >= cost


func purchase(available_score: int) -> Dictionary:
	## 执行购买，返回结果
	if not can_afford(available_score):
		return {"success": false, "remaining_score": available_score}

	return {
		"success": true,
		"remaining_score": available_score - cost,
		"item_name": item_name,
		"scene_path": scene_path
	}


func _update_display() -> void:
	## 更新显示
	if name_label:
		name_label.text = item_name
	if cost_label:
		cost_label.text = "%d分" % cost


func _start_drag() -> void:
	## 开始拖拽
	_is_dragging = true
	_drag_start_pos = global_position
	_drag_offset = get_local_mouse_position()
	_create_drag_preview()


func _end_drag() -> void:
	## 结束拖拽
	_is_dragging = false
	_check_drag_out()
	_remove_drag_preview()


func _create_drag_preview() -> void:
	## 创建拖拽预览
	_preview = _create_preview_control()
	if _preview:
		_preview.modulate.a = 0.7  # 半透明
		@warning_ignore("static_called_on_instance")
		var global_mouse = Global.get_scaled_global_mouse_position(get_viewport())
		_preview.global_position = global_mouse - _preview.size / 2
		get_tree().current_scene.add_child(_preview)


func _create_preview_control() -> Control:
	## 创建预览控件 - 优先使用对应场景
	if scene_path != "" and ResourceLoader.exists(scene_path):
		var scene_resource = load(scene_path)
		if scene_resource is PackedScene:
			var instance = scene_resource.instantiate()
			if instance is Control:
				# 标记为预览，禁用功能
				instance.set_meta("is_preview", true)
				instance.set_process(false)
				instance.set_physics_process(false)
				return instance

	# Fallback: 创建默认样式预览
	return _create_fallback_preview()


func _create_fallback_preview() -> Control:
	## 创建默认预览样式
	var preview = PanelContainer.new()
	preview.custom_minimum_size = Vector2(120, 60)

	# AutoClicker特殊样式
	if _is_auto_clicker():
		preview.custom_minimum_size = Vector2(50, 50)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.0, 0.0, 0.3)
		style.border_color = Color(1.0, 0.8, 0.2, 0.8)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		preview.add_theme_stylebox_override("panel", style)

		# 添加图标
		var icon = Label.new()
		icon.text = "⚡"
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 24)
		icon.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 0.9))
		preview.add_child(icon)

		return preview

	var vbox = VBoxContainer.new()
	preview.add_child(vbox)

	var name_lbl = Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = item_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	var cost_lbl = Label.new()
	cost_lbl.name = "CostLabel"
	cost_lbl.text = "%d分" % cost
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cost_lbl)

	# 添加样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	style.border_color = Color(0.4, 0.4, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	preview.add_theme_stylebox_override("panel", style)

	return preview


func _remove_drag_preview() -> void:
	## 移除拖拽预览
	if _preview:
		_preview.queue_free()
		_preview = null


func get_drag_preview() -> Control:
	## 获取当前预览控件
	return _preview


func _check_drag_out() -> void:
	## 检查是否拖出了商店区域
	var shops = get_tree().get_nodes_in_group("shop_panel")
	var is_outside = true

	# 使用屏幕坐标检测是否在商店内（CanvasLayer坐标不受相机缩放影响）
	var screen_mouse = get_viewport().get_mouse_position()

	for shop in shops:
		var rect = Rect2(shop.global_position, shop.size)
		if rect.has_point(screen_mouse):
			is_outside = false
			break

	if is_outside:
		# 放置物品时使用缩放后的世界坐标
		@warning_ignore("static_called_on_instance")
		var global_mouse = Global.get_scaled_global_mouse_position(get_viewport())

		# AutoClicker特殊处理：传递目标信息
		if _is_auto_clicker() and _auto_clicker_target:
			dragged_out.emit(self, global_mouse)
		else:
			dragged_out.emit(self, global_mouse)
