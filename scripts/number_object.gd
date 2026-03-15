extends Control
## 数字对象 - 可拖动的数字
class_name NumberObject

@export var value: int = 1
@export var processed_level: int = 0

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

@onready var label: Label = $Label


func _ready() -> void:
	add_to_group("number_objects")
	# 启用输入处理
	set_process_input(true)
	_update_display()

func _process(_delta: float) -> void:
	if _is_dragging:
		global_position = get_global_mouse_position() - _drag_offset

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			_is_dragging = true
			_drag_offset = get_local_mouse_position()
		elif event.is_released():
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
	## 检查是否放入加分面板
	var drop_zones = get_tree().get_nodes_in_group("score_drop_zone")
	for zone in drop_zones:
		var rect = Rect2(zone.global_position, zone.size)
		if rect.has_point(global_position + size / 2):
			zone.on_number_dropped(self)
			return
