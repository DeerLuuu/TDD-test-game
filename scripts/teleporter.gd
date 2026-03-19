extends Control
class_name Teleporter
## Teleporter 点对点传送器
## 放置两个配对的传送器可以直接将数字进行传送
## 传送速度比一般传送带慢，传送时间根据距离延长

## 配对ID（相同ID的传送器互为配对）
@export var pair_id: String = ""

## 移动速度（像素/秒）- 比普通传送带慢
@export var speed: float = 50.0

## 基础传送时间（秒）
@export var base_transmit_time: float = 0.5

## 每单位距离增加的传送时间（秒/像素）
@export var distance_time_factor: float = 0.001

## 输出方向
var output_direction: Vector2 = Vector2.RIGHT:
	set(value):
		output_direction = value
		queue_redraw()  # 重绘光球

## 是否正在被拖拽
var _is_being_dragged: bool = false

## 当前传送器上的数字
var numbers: Array[NumberObject] = []

## 正在传送中的数字（数字ID -> 传送进度）
var transmitting_numbers: Dictionary = {}

## 传送目标位置（数字ID -> 目标位置）
var _transmit_target: Dictionary = {}

## 光球动画时间
var _orb_time: float = 0.0

## 缩放动画时间（秒）
const SCALE_ANIM_TIME: float = 0.2

## 移动到中心的速度
const CENTER_SPEED: float = 200.0

## 传送阶段枚举
enum TransmitPhase {
	MOVING_TO_CENTER,  ## 移动到中心
	SHRINKING,         ## 缩小中
	TELEPORTING,       ## 传送中（等待）
	GROWING            ## 放大中
}

## 数字传送状态
var _transmit_states: Dictionary = {}  # number_id -> {phase, start_time, target_pair, target_pos}

## 是否处于调试模式
var _is_debugging: bool = false

## 调试连接线
var _debug_line: Line2D = null

## 调试箭头（指向配对传送器）
var _debug_arrow: Polygon2D = null

## 调试模式连接变化信号
signal pair_changed(new_pair: Teleporter)


func _ready() -> void:
	# 预览状态不加入交互组
	var is_preview = has_meta("is_preview") and get_meta("is_preview")
	if not is_preview:
		add_to_group("placeable_items")
		add_to_group("selectable_items")
		add_to_group("teleporters")

	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	if has_meta("is_preview") and get_meta("is_preview"):
		return

	# 更新光球动画
	_orb_time += delta
	queue_redraw()

	_detect_numbers()
	_process_transmitting_numbers(delta)


func _detect_numbers() -> void:
	## 检测传送器区域内的数字
	var all_numbers = get_tree().get_nodes_in_group("number_objects")
	var teleporter_rect = Rect2(global_position, size)

	for number in all_numbers:
		if not is_instance_valid(number):
			continue

		if number._is_dragging:
			if numbers.has(number):
				remove_number(number)
			continue

		var number_center = number.global_position + number.size / 2
		var is_inside = teleporter_rect.has_point(number_center)

		if is_inside and not numbers.has(number):
			add_number(number)
		elif not is_inside and numbers.has(number):
			remove_number(number)


## 添加数字到传送器
func add_number(number: NumberObject) -> void:
	if number and not numbers.has(number):
		numbers.append(number)
		# 开始传送
		start_transmit(number)


## 从传送器移除数字
func remove_number(number: NumberObject) -> void:
	if number:
		var number_id = number.get_instance_id()
		numbers.erase(number)
		transmitting_numbers.erase(number_id)
		_transmit_states.erase(number_id)
		_transmit_target.erase(number_id)


## 获取配对的传送器
func get_pair() -> Teleporter:
	if pair_id.is_empty():
		return null

	var all_teleporters = get_tree().get_nodes_in_group("teleporters")
	for teleporter in all_teleporters:
		if teleporter != self and teleporter.pair_id == pair_id:
			return teleporter

	return null


## 检查是否已配对
func is_paired() -> bool:
	return get_pair() != null


## 计算传送时间（基于距离）
func calculate_transmit_time(pair: Teleporter) -> float:
	if not pair:
		return base_transmit_time

	# 计算两个传送器中心之间的距离
	var my_center = global_position + size / 2
	var pair_center = pair.global_position + pair.size / 2
	var distance = my_center.distance_to(pair_center)

	# 传送时间 = 基础时间 + 距离 × 距离系数
	return base_transmit_time + distance * distance_time_factor


## 开始传送数字
func start_transmit(number: NumberObject) -> void:
	if not number:
		return

	var pair = get_pair()
	if not pair:
		# 没有配对，不传送
		return

	var number_id = number.get_instance_id()

	# 计算传送时间
	var transmit_time = calculate_transmit_time(pair)

	# 计算目标位置（配对传送器的输出位置）
	var target_pos = pair.global_position + pair.size / 2
	target_pos += pair.output_direction * pair.size.x / 2
	target_pos -= number.size / 2

	# 初始化传送状态
	_transmit_states[number_id] = {
		"phase": TransmitPhase.MOVING_TO_CENTER,
		"start_time": Time.get_ticks_msec() / 1000.0,
		"transmit_end_time": Time.get_ticks_msec() / 1000.0 + transmit_time,
		"target_pair": pair,
		"target_pos": target_pos
	}

	# 记录到transmitting_numbers以保持兼容性
	transmitting_numbers[number_id] = 0.0
	_transmit_target[number_id] = target_pos


## 处理传送中的数字
func _process_transmitting_numbers(delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var numbers_to_remove: Array = []

	for number_id in _transmit_states.keys():
		var state = _transmit_states[number_id]
		var number = _find_number_by_id(number_id)

		if not number or not is_instance_valid(number):
			numbers_to_remove.append(number_id)
			continue

		match state["phase"]:
			TransmitPhase.MOVING_TO_CENTER:
				_process_moving_to_center(number, state, delta)
			TransmitPhase.SHRINKING:
				_process_shrinking(number, state, current_time)
			TransmitPhase.TELEPORTING:
				_process_teleporting(number, state, current_time)
			TransmitPhase.GROWING:
				_process_growing(number, state, current_time, numbers_to_remove)

	# 清理完成的传送
	for number_id in numbers_to_remove:
		_cleanup_transmit(number_id)


## 查找数字对象
func _find_number_by_id(number_id: int) -> NumberObject:
	for n in numbers:
		if n.get_instance_id() == number_id:
			return n
	return null


## 处理移动到中心阶段
func _process_moving_to_center(number: NumberObject, state: Dictionary, delta: float) -> void:
	var my_center = global_position + size / 2
	var number_center = number.global_position + number.size / 2

	var to_center = my_center - number_center
	var distance = to_center.length()

	if distance <= CENTER_SPEED * delta:
		# 已到达中心
		number.global_position = my_center - number.size / 2
		# 进入缩小阶段
		state["phase"] = TransmitPhase.SHRINKING
		state["shrink_start_time"] = Time.get_ticks_msec() / 1000.0
	else:
		# 向中心移动
		var move_dir = to_center.normalized()
		number.global_position += move_dir * CENTER_SPEED * delta


## 处理缩小阶段
func _process_shrinking(number: NumberObject, state: Dictionary, current_time: float) -> void:
	var shrink_start = state.get("shrink_start_time", current_time)
	var elapsed = current_time - shrink_start
	var progress = minf(elapsed / SCALE_ANIM_TIME, 1.0)

	# 缩小到 (0, 0)
	number.scale = Vector2(1.0 - progress, 1.0 - progress)

	if progress >= 1.0:
		# 缩小完成，进入传送阶段
		number.scale = Vector2.ZERO
		state["phase"] = TransmitPhase.TELEPORTING


## 处理传送阶段（等待）
func _process_teleporting(number: NumberObject, state: Dictionary, current_time: float) -> void:
	var transmit_end = state.get("transmit_end_time", current_time)

	if current_time >= transmit_end:
		# 传送完成，移动到目标位置并开始放大
		var target_pos = state.get("target_pos", global_position)
		number.global_position = target_pos
		number.scale = Vector2.ZERO

		state["phase"] = TransmitPhase.GROWING
		state["grow_start_time"] = current_time


## 处理放大阶段
func _process_growing(number: NumberObject, state: Dictionary, current_time: float, numbers_to_remove: Array) -> void:
	var grow_start = state.get("grow_start_time", current_time)
	var elapsed = current_time - grow_start
	var progress = minf(elapsed / SCALE_ANIM_TIME, 1.0)

	# 从 (0, 0) 放大到 (1, 1)
	number.scale = Vector2(progress, progress)

	if progress >= 1.0:
		# 放大完成
		number.scale = Vector2.ONE
		numbers_to_remove.append(number.get_instance_id())


## 清理传送状态
func _cleanup_transmit(number_id: int) -> void:
	_transmit_states.erase(number_id)
	transmitting_numbers.erase(number_id)
	_transmit_target.erase(number_id)
	numbers.erase(_find_number_by_id(number_id))


## 旋转输出方向（顺时针）
func rotate_direction() -> void:
	if output_direction == Vector2.RIGHT:
		output_direction = Vector2.DOWN
	elif output_direction == Vector2.DOWN:
		output_direction = Vector2.LEFT
	elif output_direction == Vector2.LEFT:
		output_direction = Vector2.UP
	else:
		output_direction = Vector2.RIGHT


## 旋转输出方向（逆时针）
func rotate_direction_ccw() -> void:
	if output_direction == Vector2.RIGHT:
		output_direction = Vector2.UP
	elif output_direction == Vector2.UP:
		output_direction = Vector2.LEFT
	elif output_direction == Vector2.LEFT:
		output_direction = Vector2.DOWN
	else:
		output_direction = Vector2.RIGHT


## 根据滚轮方向旋转
func rotate_on_scroll(scroll_direction: float) -> void:
	if not _is_being_dragged:
		return
	if scroll_direction > 0:
		rotate_direction()
	else:
		rotate_direction_ccw()


## 设置拖拽状态
func set_being_dragged(is_dragging: bool) -> void:
	_is_being_dragged = is_dragging


## 处理滚轮输入
func _input(event: InputEvent) -> void:
	if Global.is_path_build_mode():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			@warning_ignore("static_called_on_instance")
			var global_mouse = Global.get_scaled_global_mouse_position(get_viewport())
			var rect = Rect2(global_position, size)
			if rect.has_point(global_mouse):
				rotate_on_scroll(1.0)
				get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			@warning_ignore("static_called_on_instance")
			var global_mouse = Global.get_scaled_global_mouse_position(get_viewport())
			var rect = Rect2(global_position, size)
			if rect.has_point(global_mouse):
				rotate_on_scroll(-1.0)
				get_viewport().set_input_as_handled()


func _draw() -> void:
	## 绘制光球
	var center = size / 2
	var base_radius = minf(size.x, size.y) * 0.3

	# 动画效果：脉动
	var pulse = sin(_orb_time * 3.0) * 0.15 + 1.0
	var radius = base_radius * pulse

	# 外发光层
	for i in range(3, 0, -1):
		var glow_radius = radius + i * 8
		var alpha = 0.15 - i * 0.04
		var color = Color(0.7, 0.3, 1.0, alpha)  # 紫色发光
		draw_circle(center, glow_radius, color)

	# 核心光球
	var core_color = Color(0.9, 0.7, 1.0, 0.9)  # 亮紫色核心
	draw_circle(center, radius * 0.6, core_color)

	# 内部高光
	var highlight_color = Color(1.0, 1.0, 1.0, 0.6)
	draw_circle(center - Vector2(radius * 0.15, radius * 0.15), radius * 0.25, highlight_color)

	# 如果有配对，显示连接指示（小型箭头）
	if is_paired():
		_draw_output_indicator(center, radius)


func _draw_output_indicator(center: Vector2, radius: float) -> void:
	## 绘制输出方向指示器（小型三角形）
	var indicator_distance = radius + 5
	var indicator_pos = center + output_direction * indicator_distance
	var indicator_size = 6.0

	var angle = output_direction.angle()
	var points = PackedVector2Array([
		indicator_pos + output_direction * indicator_size,
		indicator_pos + Vector2(cos(angle + 2.5), sin(angle + 2.5)) * indicator_size,
		indicator_pos + Vector2(cos(angle - 2.5), sin(angle - 2.5)) * indicator_size
	])

	var indicator_color = Color(1.0, 1.0, 1.0, 0.8)
	draw_colored_polygon(points, indicator_color)


## ==================== 调试模式 ====================

## 开始调试模式
func start_debug() -> void:
	_is_debugging = true
	_show_debug_connection()


## 结束调试模式
func end_debug() -> void:
	_is_debugging = false
	_hide_debug_connection()


## 显示调试连接
func _show_debug_connection() -> void:
	# 清除旧的调试显示
	_hide_debug_connection()

	var pair = get_pair()
	if not pair:
		# 没有配对，显示提示
		_show_no_pair_indicator()
		return

	# 创建连接线
	_debug_line = Line2D.new()
	_debug_line.width = 3.0
	_debug_line.default_color = Color(0.8, 0.4, 1.0, 0.8)  # 紫色
	_debug_line.z_index = 100

	# 添加点：从当前传送器中心到配对传送器中心
	var my_center = global_position + size / 2
	var pair_center = pair.global_position + pair.size / 2

	_debug_line.add_point(my_center)
	_debug_line.add_point(pair_center)

	# 添加到场景
	get_tree().current_scene.add_child(_debug_line)

	# 创建箭头指向
	_create_debug_arrow(my_center, pair_center)


## 创建调试箭头（指向配对传送器）
func _create_debug_arrow(from_pos: Vector2, to_pos: Vector2) -> void:
	_debug_arrow = Polygon2D.new()
	_debug_arrow.z_index = 101

	# 计算方向和箭头位置
	var direction = (to_pos - from_pos).normalized()
	var arrow_pos = to_pos - direction * 30  # 在终点前一点

	# 创建三角形箭头
	var angle = direction.angle()
	var arrow_size = 12.0

	var points = PackedVector2Array([
		arrow_pos,
		arrow_pos - Vector2(cos(angle - 0.5), sin(angle - 0.5)) * arrow_size,
		arrow_pos - Vector2(cos(angle + 0.5), sin(angle + 0.5)) * arrow_size
	])

	_debug_arrow.polygon = points
	_debug_arrow.color = Color(0.8, 0.4, 1.0, 1.0)  # 紫色

	get_tree().current_scene.add_child(_debug_arrow)


## 显示无配对提示
func _show_no_pair_indicator() -> void:
	# 创建一个闪烁的边框表示未配对
	var timer = get_tree().create_timer(0.0)
	while _is_debugging and not is_paired():
		# 可以在这里添加视觉效果
		await get_tree().create_timer(0.5).timeout


## 隐藏调试连接
func _hide_debug_connection() -> void:
	if _debug_line:
		_debug_line.queue_free()
		_debug_line = null

	if _debug_arrow:
		_debug_arrow.queue_free()
		_debug_arrow = null


## 更新调试显示（用于配对变化时）
func update_debug_display() -> void:
	if _is_debugging:
		_show_debug_connection()


## 设置配对（调试模式下点击另一个传送器）
func set_pair_to(target: Teleporter) -> void:
	if not _is_debugging:
		return

	if target == self:
		return

	# 生成唯一配对ID
	var new_pair_id = "pair_%d_%d" % [get_instance_id(), target.get_instance_id()]

	# 设置双方的配对ID
	self.pair_id = new_pair_id
	target.pair_id = new_pair_id

	# 发出信号
	pair_changed.emit(target)
	target.pair_changed.emit(self)

	# 更新调试显示
	update_debug_display()
	target.update_debug_display()


## 清除配对
func clear_pair() -> void:
	var pair = get_pair()
	if pair:
		pair.pair_id = ""
		pair.update_debug_display()

	pair_id = ""
	update_debug_display()
	pair_changed.emit(null)


## 检查是否可以调试
func can_debug() -> bool:
	return true


## 调试模式下处理点击
func _gui_input(event: InputEvent) -> void:
	if not _is_debugging:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 在调试模式下点击，通知debug_cursor
			accept_event()
