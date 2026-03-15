extends Control
## 数字对象 - 可拖动的数字
class_name NumberObject

@export var value: int = 1
@export var processed_level: int = 0

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

@onready var label: Label = get_node_or_null("Label")


func _ready() -> void:
	add_to_group("number_objects")
	# 启用输入处理
	set_process_input(true)
	_update_display()

func _process(_delta: float) -> void:
	if _is_dragging:
		# 使用考虑相机缩放的全局鼠标位置
		@warning_ignore("static_called_on_instance")
		global_position = Global.get_scaled_global_mouse_position(get_viewport()) - _drag_offset

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			# 检查是否在加工面板中，如果是则取出
			_check_and_remove_from_process_panel()
			_is_dragging = true
			_drag_offset = get_local_mouse_position()
			accept_event()


func _input(event: InputEvent) -> void:
	## 确保释放事件被捕获
	if _is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_is_dragging = false
			_check_drop_zone()


func get_final_value() -> int:
	## 最终分数 = value × (2 ^ processed_level)
	return value * (1 << processed_level)


func process() -> void:
	## 加工一次
	processed_level += 1
	_update_display()


func _update_display() -> void:
	## 更新显示
	if label:
		label.text = str(value)

		# 根据加工等级改变颜色
		match processed_level:
			0: label.add_theme_color_override("font_color", Color.WHITE)
			1: label.add_theme_color_override("font_color", Color.GREEN)
			2: label.add_theme_color_override("font_color", Color.BLUE)
			3: label.add_theme_color_override("font_color", Color.PURPLE)
			4: label.add_theme_color_override("font_color", Color.GOLD)
			_: label.add_theme_color_override("font_color", Color.HOT_PINK)


func _check_drop_zone() -> void:
	## 检查是否放入加分面板或加工面板
	# 先检查加工面板
	var process_panels = get_tree().get_nodes_in_group("process_panel")
	for panel in process_panels:
		var rect = Rect2(panel.global_position, panel.size)
		if rect.has_point(global_position + size / 2):
			panel.accept_number(self)
			return

	# 再检查加分面板
	var drop_zones = get_tree().get_nodes_in_group("score_drop_zone")
	for zone in drop_zones:
		var rect = Rect2(zone.global_position, zone.size)
		if rect.has_point(global_position + size / 2):
			zone.on_number_dropped(self)
			return


func _check_and_remove_from_process_panel() -> void:
	## 检查是否在加工面板中，如果是则取出
	var process_panels = get_tree().get_nodes_in_group("process_panel")
	for panel in process_panels:
		if panel.current_number == self:
			panel.remove_number(self)
			return
