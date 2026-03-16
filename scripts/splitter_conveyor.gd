class_name SplitterConveyor extends Control
## SplitterConveyor 分流传送带
## 数字从任意方向进入，移动到中心后交替向两个输出方向分流
## 0°/180°: 左右分流
## 90°/270°: 上下分流

## 移动速度（像素/秒）
@export var speed: float = 100.0

## 对齐速度（像素/秒）- 移动到中心的速度
@export var align_speed: float = 200.0

## 旋转角度 (0, 90, 180, 270)
var rotation_angle: int = 0

## 箭头纹理资源
var arrow_textures: Dictionary = {}

## BoxContainer引用
var _box_container: BoxContainer = null
var box_container: BoxContainer:
	get:
		if _box_container == null:
			_box_container = get_node_or_null("BoxContainer")
		return _box_container

## 左箭头节点引用（懒加载）
var _left_arrow: TextureRect = null
var left_arrow: TextureRect:
	get:
		if _left_arrow == null:
			_left_arrow = get_node_or_null("%LeftArrow")
		return _left_arrow

## 右箭头节点引用（懒加载）
var _right_arrow: TextureRect = null
var right_arrow: TextureRect:
	get:
		if _right_arrow == null:
			_right_arrow = get_node_or_null("%RightArrow")
		return _right_arrow

## 输出方向（根据旋转角度自动计算）
var output_direction_1: Vector2 = Vector2.LEFT
var output_direction_2: Vector2 = Vector2.RIGHT

## 下次输出方向（"1" 或 "2"）
var next_output: String = "1"

## 当前传送带上的数字
var numbers: Array[NumberObject] = []

## 数字对应的输出方向
var _number_outputs: Dictionary = {}

## 数字是否已对齐到中心
var _number_aligned: Dictionary = {}

## 输出组件引用
var _output_component_1: OutputComponent = null
var output_component_1: OutputComponent:
	get:
		if _output_component_1 == null:
			_output_component_1 = get_node_or_null("LeftOutputComponent")
		return _output_component_1

var _output_component_2: OutputComponent = null
var output_component_2: OutputComponent:
	get:
		if _output_component_2 == null:
			_output_component_2 = get_node_or_null("RightOutputComponent")
		return _output_component_2

## 输入输出组件（用于调试显示入口方向）
var _input_output_component: OutputComponent = null
var input_output_component: OutputComponent:
	get:
		if _input_output_component == null:
			_input_output_component = get_node_or_null("InputOutputComponent")
		return _input_output_component


func _ready() -> void:
	_load_arrow_textures()

	# 预览状态不加入交互组
	var is_preview = has_meta("is_preview") and get_meta("is_preview")
	if not is_preview:
		add_to_group("placeable_items")
		add_to_group("selectable_items")

	mouse_filter = Control.MOUSE_FILTER_STOP

	if is_preview:
		return

	# 更新方向和箭头
	_update_directions()
	_update_arrow_layout()
	_update_arrow_textures()


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


func _load_arrow_textures() -> void:
	arrow_textures = {
		Vector2.UP: load("res://assets/arrows/arrow_up.svg"),
		Vector2.DOWN: load("res://assets/arrows/arrow_down.svg"),
		Vector2.LEFT: load("res://assets/arrows/arrow_left.svg"),
		Vector2.RIGHT: load("res://assets/arrows/arrow_right.svg")
	}


func _process(delta: float) -> void:
	if has_meta("is_preview") and get_meta("is_preview"):
		return

	_move_numbers(delta)
	_detect_numbers()


func _detect_numbers() -> void:
	var all_numbers = get_tree().get_nodes_in_group("number_objects")
	var conveyor_rect = Rect2(global_position, size)

	for number in all_numbers:
		if not is_instance_valid(number):
			continue

		if number._is_dragging:
			if numbers.has(number):
				remove_number(number)
			continue

		var number_center = number.global_position + number.size / 2
		var is_inside = conveyor_rect.has_point(number_center)

		if is_inside and not numbers.has(number):
			add_number(number)
		elif not is_inside and numbers.has(number):
			remove_number(number)


func add_number(number: NumberObject) -> void:
	if number and not numbers.has(number):
		numbers.append(number)
		var output_dir = get_next_output()
		_number_outputs[number.get_instance_id()] = output_dir
		_number_aligned[number.get_instance_id()] = false


func remove_number(number: NumberObject) -> void:
	if number:
		numbers.erase(number)
		_number_outputs.erase(number.get_instance_id())
		_number_aligned.erase(number.get_instance_id())


func get_next_output() -> Vector2:
	var output: Vector2
	if next_output == "1":
		output = output_direction_1
		next_output = "2"
	else:
		output = output_direction_2
		next_output = "1"
	return output


func get_center_position() -> Vector2:
	return global_position + size / 2


func _move_numbers(delta: float) -> void:
	for number in numbers:
		if is_instance_valid(number) and not number._is_dragging:
			var number_id = number.get_instance_id()

			if not _number_aligned.get(number_id, false):
				_align_to_center(number, delta)
			else:
				var output_dir = _number_outputs.get(number_id, output_direction_1)
				number.global_position += output_dir * speed * delta


func _align_to_center(number: NumberObject, delta: float) -> void:
	var number_id = number.get_instance_id()
	var number_center = number.global_position + number.size / 2
	var splitter_center = get_center_position()

	# 计算到中心的距离
	var to_center = splitter_center - number_center
	var distance = to_center.length()

	if distance <= align_speed * delta:
		# 已到达中心，精确对齐
		number.global_position = splitter_center - number.size / 2
		_number_aligned[number_id] = true
	else:
		# 向中心移动
		var move_dir = to_center.normalized()
		number.global_position += move_dir * align_speed * delta


func rotate_direction() -> void:
	rotation_angle = (rotation_angle + 90) % 360
	_update_directions()
	_update_arrow_layout()
	_update_arrow_textures()


func rotate_direction_ccw() -> void:
	rotation_angle = (rotation_angle - 90 + 360) % 360
	_update_directions()
	_update_arrow_layout()
	_update_arrow_textures()


func rotate_on_scroll(scroll_direction: float) -> void:
	if scroll_direction > 0:
		rotate_direction()
	else:
		rotate_direction_ccw()


func _update_directions() -> void:
	## 根据旋转角度更新输出方向
	match rotation_angle:
		0:
			output_direction_1 = Vector2.LEFT
			output_direction_2 = Vector2.RIGHT
		90:
			output_direction_1 = Vector2.UP
			output_direction_2 = Vector2.DOWN
		180:
			output_direction_1 = Vector2.RIGHT
			output_direction_2 = Vector2.LEFT
		270:
			output_direction_1 = Vector2.DOWN
			output_direction_2 = Vector2.UP

	_update_output_components()


func _update_output_components() -> void:
	if output_component_1 and is_instance_valid(output_component_1):
		output_component_1.set_output_direction(output_direction_1)
	if output_component_2 and is_instance_valid(output_component_2):
		output_component_2.set_output_direction(output_direction_2)
	# 输入组件显示默认方向（向上）
	if input_output_component and is_instance_valid(input_output_component):
		input_output_component.set_output_direction(Vector2.UP)


func _update_arrow_layout() -> void:
	## 更新箭头布局（水平或垂直）
	if box_container and is_instance_valid(box_container):
		# 0°/180°: 水平布局，显示左右箭头
		# 90°/270°: 垂直布局，显示上下箭头
		match rotation_angle:
			0, 180:
				box_container.vertical = false
			90, 270:
				box_container.vertical = true


func _update_arrow_textures() -> void:
	## 更新箭头纹理
	if arrow_textures.is_empty():
		_load_arrow_textures()

	# 根据旋转角度确定箭头纹理
	match rotation_angle:
		0:
			# 左右分流：左箭头指向左，右箭头指向右
			if left_arrow and is_instance_valid(left_arrow):
				left_arrow.texture = arrow_textures.get(Vector2.LEFT)
			if right_arrow and is_instance_valid(right_arrow):
				right_arrow.texture = arrow_textures.get(Vector2.RIGHT)
		90:
			# 上下分流：左箭头指向上，右箭头指向下
			if left_arrow and is_instance_valid(left_arrow):
				left_arrow.texture = arrow_textures.get(Vector2.UP)
			if right_arrow and is_instance_valid(right_arrow):
				right_arrow.texture = arrow_textures.get(Vector2.DOWN)
		180:
			# 左右分流（反向）：左箭头指向右，右箭头指向左
			if left_arrow and is_instance_valid(left_arrow):
				left_arrow.texture = arrow_textures.get(Vector2.LEFT)
			if right_arrow and is_instance_valid(right_arrow):
				right_arrow.texture = arrow_textures.get(Vector2.RIGHT)
		270:
			# 上下分流（反向）：左箭头指向下，右箭头指向上
			if left_arrow and is_instance_valid(left_arrow):
				left_arrow.texture = arrow_textures.get(Vector2.UP)
			if right_arrow and is_instance_valid(right_arrow):
				right_arrow.texture = arrow_textures.get(Vector2.DOWN)


func get_arrow_directions() -> Dictionary:
	## 返回两个箭头的方向（用于测试）
	match rotation_angle:
		0:
			return {"arrow1": Vector2.LEFT, "arrow2": Vector2.RIGHT}
		90:
			return {"arrow1": Vector2.UP, "arrow2": Vector2.DOWN}
		180:
			return {"arrow1": Vector2.RIGHT, "arrow2": Vector2.LEFT}
		270:
			return {"arrow1": Vector2.DOWN, "arrow2": Vector2.UP}
		_:
			return {"arrow1": Vector2.LEFT, "arrow2": Vector2.RIGHT}
