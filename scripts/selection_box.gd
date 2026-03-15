extends Control
## SelectionBox - 框选框
## 长按拖动显示选择框
## 用于框选多个物品

class_name SelectionBox

## 框选开始位置（屏幕坐标）
var _start_pos: Vector2 = Vector2.ZERO

## 是否正在框选
var is_selecting: bool = false

## 框选完成信号
signal selection_complete(rect: Rect2)

## 框选更新信号
signal selection_update(rect: Rect2)

## 背景面板
var _background: Panel = null

## 最小拖动距离才触发框选
const MIN_DRAG_DISTANCE: float = 10.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_create_background()


func _create_background() -> void:
	_background = Panel.new()
	_background.anchor_right = 1.0
	_background.anchor_bottom = 1.0
	add_child(_background)

	# 设置半透明蓝色样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.5, 1.0, 0.3)  # 蓝色半透明
	style.border_color = Color(0.3, 0.6, 1.0, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	_background.add_theme_stylebox_override("panel", style)


func start_selection(start_pos: Vector2) -> void:
	## 开始框选
	_start_pos = start_pos
	is_selecting = true
	visible = true
	global_position = start_pos
	size = Vector2.ZERO


func update_selection(current_pos: Vector2) -> void:
	## 更新框选
	if not is_selecting:
		return

	# 计算矩形
	var rect = _calculate_rect(_start_pos, current_pos)

	# 更新位置和大小
	global_position = rect.position
	size = rect.size

	# 发送更新信号
	selection_update.emit(rect)


func end_selection() -> void:
	## 结束框选
	if not is_selecting:
		return

	# 发送完成信号
	var rect = Rect2(global_position, size)
	selection_complete.emit(rect)

	# 重置状态
	is_selecting = false
	visible = false
	size = Vector2.ZERO


func _calculate_rect(start: Vector2, end: Vector2) -> Rect2:
	## 计算矩形（处理负方向）
	@warning_ignore("narrowing_conversion")
	var min_x = mini(start.x, end.x)
	@warning_ignore("narrowing_conversion")
	var min_y = mini(start.y, end.y)
	@warning_ignore("narrowing_conversion")
	var max_x = maxi(start.x, end.x)
	@warning_ignore("narrowing_conversion")
	var max_y = maxi(start.y, end.y)

	return Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))


func get_selection_rect() -> Rect2:
	## 获取当前框选矩形
	return Rect2(global_position, size)


func get_selection_rect_world() -> Rect2:
	## 获取世界坐标框选矩形
	var viewport = get_viewport()
	if not viewport:
		return Rect2(global_position, size)

	var canvas_transform = viewport.get_canvas_transform()
	var inv_transform = canvas_transform.affine_inverse()

	var world_pos = inv_transform * global_position
	var world_size = size / canvas_transform.get_scale().x

	return Rect2(world_pos, world_size)
