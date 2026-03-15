extends Node
## OutputComponent - 输出组件
## 为面板或按钮添加输出方向和位置功能
## 用于调试模式下设置输出方向

class_name OutputComponent

## 输出方向
var output_direction: Vector2 = Vector2.RIGHT:
	set(value):
		output_direction = value
		_update_output_offset()

## 输出距离（从父节点中心的距离）
@export var output_distance: int = 100

## 输出偏移（自动根据方向计算）
var output_offset: Vector2 = Vector2(100, 0)

## 是否正在调试
var is_debugging: bool = false

## 输出方向变化信号
signal output_direction_changed(new_direction: Vector2)

## 调试箭头显示
var _debug_arrow: Control = null


func _ready() -> void:
	_update_output_offset()


func _update_output_offset() -> void:
	## 根据方向更新偏移
	output_offset = output_direction * output_distance
	output_direction_changed.emit(output_direction)


func set_output_direction(direction: Vector2) -> void:
	## 设置输出方向
	output_direction = direction
	_update_output_offset()


func get_output_position() -> Vector2:
	## 获取输出位置（世界坐标）
	var parent = get_parent()
	if not parent:
		return Vector2.ZERO
	
	# 返回父节点中心 + 输出偏移
	if parent is Control:
		return parent.global_position + parent.size / 2 + output_offset
	elif parent is Node2D:
		return parent.global_position + output_offset
	
	return Vector2.ZERO


func start_debug() -> void:
	## 开始调试模式
	is_debugging = true
	_show_debug_arrow()


func end_debug() -> void:
	## 结束调试模式
	is_debugging = false
	_hide_debug_arrow()


func _show_debug_arrow() -> void:
	## 显示调试箭头
	if _debug_arrow:
		return
	
	var parent = get_parent()
	if not parent or not parent is Control:
		return
	
	# 创建箭头显示，位置设置为父节点中心
	_debug_arrow = Control.new()
	_debug_arrow.name = "DebugArrow"
	_debug_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 设置位置为父节点中心（相对于父节点）
	_debug_arrow.position = parent.size / 2
	
	# 创建线条（从中心点开始）
	var line = Line2D.new()
	line.add_point(Vector2.ZERO)
	line.add_point(output_offset)
	line.width = 3.0
	line.default_color = Color.GREEN
	_debug_arrow.add_child(line)
	
	# 创建箭头末端
	var end_pos = output_offset
	var arrow_size = 10.0
	
	var arrow = Polygon2D.new()
	var angle = output_direction.angle()
	var arrow_points = PackedVector2Array([
		end_pos,
		end_pos - Vector2(cos(angle - 0.5), sin(angle - 0.5)) * arrow_size,
		end_pos - Vector2(cos(angle + 0.5), sin(angle + 0.5)) * arrow_size
	])
	arrow.polygon = arrow_points
	arrow.color = Color.GREEN
	_debug_arrow.add_child(arrow)
	
	# 添加到父节点
	parent.add_child(_debug_arrow)


func _hide_debug_arrow() -> void:
	## 隐藏调试箭头
	if _debug_arrow:
		_debug_arrow.queue_free()
		_debug_arrow = null


func get_direction_from_drag(drag_end_pos: Vector2) -> Vector2:
	## 从拖动终点获取方向
	var parent = get_parent()
	if not parent:
		return Vector2.RIGHT
	
	var parent_center: Vector2
	if parent is Control:
		parent_center = parent.global_position + parent.size / 2
	else:
		parent_center = parent.global_position
	
	var delta = drag_end_pos - parent_center
	
	# 判断主要方向
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


func apply_drag_direction(drag_end_pos: Vector2) -> void:
	## 应用拖动方向
	var new_direction = get_direction_from_drag(drag_end_pos)
	set_output_direction(new_direction)
	
	# 更新调试箭头
	if is_debugging and _debug_arrow:
		_hide_debug_arrow()
		_show_debug_arrow()


func update_debug_arrow() -> void:
	## 更新调试箭头显示
	if is_debugging:
		_hide_debug_arrow()
		_show_debug_arrow()
