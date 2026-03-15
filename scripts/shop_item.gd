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

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var cost_label: Label = $VBoxContainer/CostLabel


func _ready() -> void:
	add_to_group("shop_items")
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(true)
	_update_display()


func _process(_delta: float) -> void:
	if _is_dragging and _preview:
		_preview.global_position = get_global_mouse_position() - _preview.size / 2


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
		_preview.global_position = get_global_mouse_position() - _preview.size / 2
		get_tree().current_scene.add_child(_preview)


func _create_preview_control() -> Control:
	## 创建预览控件
	var preview = PanelContainer.new()
	preview.custom_minimum_size = Vector2(120, 60)

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

	for shop in shops:
		var rect = Rect2(shop.global_position, shop.size)
		if rect.has_point(get_global_mouse_position()):
			is_outside = false
			break

	if is_outside:
		dragged_out.emit(self, get_global_mouse_position())
