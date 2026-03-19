class_name TriSplitterConveyor extends Control
## TriSplitterConveyor 三相分流传送带
## 数字从任意方向进入，移动到中心后轮流向三个输出方向分流
##
## 调试模式：
## - 只有一个调试箭头，指向出口1的方向
## - 调试箭头指向上 → 入口在下（隐藏下面箭头），出口: 上、右、左
## - 调试箭头指向下 → 入口在上（隐藏上面箭头），出口: 下、左、右
## - 调试箭头指向左 → 入口在右（隐藏右面箭头），出口: 左、下、上
## - 调试箭头指向右 → 入口在左（隐藏左面箭头），出口: 右、上、下

## 移动速度（像素/秒）
@export var speed: float = 100.0

## 对齐速度（像素/秒）- 移动到中心的速度
@export var align_speed: float = 200.0

## 调试箭头方向（出口1的方向）
var debug_direction: Vector2 = Vector2.DOWN

## 是否正在被拖拽（用于限制滚轮旋转）
var _is_being_dragged: bool = false

## 箭头纹理资源
var arrow_textures: Dictionary = {}

## 金色箭头纹理（用于有SpeedBooster时）
var _gold_arrow_textures: Dictionary = {}

## 输出方向（根据调试方向自动计算）
var output_direction_1: Vector2 = Vector2.DOWN
var output_direction_2: Vector2 = Vector2.LEFT
var output_direction_3: Vector2 = Vector2.RIGHT

## 入口方向
var input_direction: Vector2 = Vector2.UP

## 下次输出方向（1, 2, 3 循环）
var next_output: int = 1

## 当前传送带上的数字
var numbers: Array[NumberObject] = []

## 数字对应的输出方向
var _number_outputs: Dictionary = {}

## 数字是否已对齐到中心
var _number_aligned: Dictionary = {}

## 四个箭头节点引用（懒加载）
## Arrow1: 左方向, Arrow2: 右方向, Arrow3: 上方向, Arrow4: 下方向
var _arrow1: TextureRect = null
var arrow1: TextureRect:
	get:
		if _arrow1 == null:
			_arrow1 = get_node_or_null("BottomRow/Arrow1")
		return _arrow1

var _arrow2: TextureRect = null
var arrow2: TextureRect:
	get:
		if _arrow2 == null:
			_arrow2 = get_node_or_null("BottomRow/Arrow2")
		return _arrow2

var _arrow3: TextureRect = null
var arrow3: TextureRect:
	get:
		if _arrow3 == null:
			_arrow3 = get_node_or_null("HBoxContainer/Arrow3")
		return _arrow3

var _arrow4: TextureRect = null
var arrow4: TextureRect:
	get:
		if _arrow4 == null:
			_arrow4 = get_node_or_null("HBoxContainer/Arrow4")
		return _arrow4

## 输出组件引用（用于调试箭头显示）
var _output_component_1: OutputComponent = null
var output_component_1: OutputComponent:
	get:
		if _output_component_1 == null:
			_output_component_1 = get_node_or_null("OutputComponent1")
		return _output_component_1

var _output_component_2: OutputComponent = null
var output_component_2: OutputComponent:
	get:
		if _output_component_2 == null:
			_output_component_2 = get_node_or_null("OutputComponent2")
		return _output_component_2

var _output_component_3: OutputComponent = null
var output_component_3: OutputComponent:
	get:
		if _output_component_3 == null:
			_output_component_3 = get_node_or_null("OutputComponent3")
		return _output_component_3


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

	# 初始化方向和箭头
	_update_directions_from_debug()
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
	_gold_arrow_textures = {
		Vector2.UP: load("res://assets/arrows/arrow_up_gold.svg"),
		Vector2.DOWN: load("res://assets/arrows/arrow_down_gold.svg"),
		Vector2.LEFT: load("res://assets/arrows/arrow_left_gold.svg"),
		Vector2.RIGHT: load("res://assets/arrows/arrow_right_gold.svg")
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
	match next_output:
		1:
			output = output_direction_1
			next_output = 2
		2:
			output = output_direction_2
			next_output = 3
		3:
			output = output_direction_3
			next_output = 1
		_:
			output = output_direction_1
			next_output = 2
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

	var to_center = splitter_center - number_center
	var distance = to_center.length()

	if distance <= align_speed * delta:
		number.global_position = splitter_center - number.size / 2
		_number_aligned[number_id] = true
	else:
		var move_dir = to_center.normalized()
		number.global_position += move_dir * align_speed * delta


func rotate_on_scroll(scroll_direction: float) -> void:
	## 只有在被拖拽时才能旋转
	if not _is_being_dragged:
		return

	# 顺时针旋转调试方向
	if scroll_direction > 0:
		match debug_direction:
			Vector2.UP:
				set_debug_direction(Vector2.RIGHT)
			Vector2.RIGHT:
				set_debug_direction(Vector2.DOWN)
			Vector2.DOWN:
				set_debug_direction(Vector2.LEFT)
			Vector2.LEFT:
				set_debug_direction(Vector2.UP)
	else:
		match debug_direction:
			Vector2.UP:
				set_debug_direction(Vector2.LEFT)
			Vector2.LEFT:
				set_debug_direction(Vector2.DOWN)
			Vector2.DOWN:
				set_debug_direction(Vector2.RIGHT)
			Vector2.RIGHT:
				set_debug_direction(Vector2.UP)


func set_being_dragged(is_dragging: bool) -> void:
	_is_being_dragged = is_dragging


func set_debug_direction(direction: Vector2) -> void:
	## 设置调试方向（由debug_cursor调用）
	debug_direction = direction
	_update_directions_from_debug()
	_update_arrow_textures()
	_update_output_components()
	# 更新调试箭头显示
	if output_component_1 and is_instance_valid(output_component_1):
		output_component_1.update_debug_arrow()


func _update_directions_from_debug() -> void:
	## 根据调试方向更新输出方向
	## 调试方向 = 出口1方向
	## 入口方向 = 调试方向的反方向
	output_direction_1 = debug_direction
	input_direction = -debug_direction

	# 根据调试方向确定出口2和出口3
	# 出口顺序：调试方向、顺时针下一个、逆时针下一个
	match debug_direction:
		Vector2.LEFT:
			output_direction_2 = Vector2.DOWN
			output_direction_3 = Vector2.UP
		Vector2.UP:
			output_direction_2 = Vector2.RIGHT
			output_direction_3 = Vector2.LEFT
		Vector2.RIGHT:
			output_direction_2 = Vector2.UP
			output_direction_3 = Vector2.DOWN
		Vector2.DOWN:
			output_direction_2 = Vector2.LEFT
			output_direction_3 = Vector2.RIGHT


func _update_arrow_textures() -> void:
	## 更新箭头纹理
	## 入口方向的箭头设置texture为null（隐藏），其他方向显示对应箭头
	if arrow_textures.is_empty():
		_load_arrow_textures()

	var use_gold = _has_speed_booster()
	var textures = _gold_arrow_textures if use_gold else arrow_textures

	# Arrow1 = 左方向
	if arrow1 and is_instance_valid(arrow1):
		if input_direction == Vector2.LEFT:
			arrow1.texture = null
		else:
			arrow1.texture = textures.get(Vector2.LEFT)
		arrow1.visible = true

	# Arrow2 = 右方向
	if arrow2 and is_instance_valid(arrow2):
		if input_direction == Vector2.RIGHT:
			arrow2.texture = null
		else:
			arrow2.texture = textures.get(Vector2.RIGHT)
		arrow2.visible = true

	# Arrow3 = 上方向
	if arrow3 and is_instance_valid(arrow3):
		if input_direction == Vector2.UP:
			arrow3.texture = null
		else:
			arrow3.texture = textures.get(Vector2.UP)
		arrow3.visible = true

	# Arrow4 = 下方向
	if arrow4 and is_instance_valid(arrow4):
		if input_direction == Vector2.DOWN:
			arrow4.texture = null
		else:
			arrow4.texture = textures.get(Vector2.DOWN)
		arrow4.visible = true


func _has_speed_booster() -> bool:
	## 检查是否有SpeedBooster子节点
	for child in get_children():
		if child is SpeedBooster:
			return true
	return false


func update_arrow_color() -> void:
	## 更新箭头颜色（外部调用）
	_update_arrow_textures()


func get_arrow_directions() -> Dictionary:
	## 返回四个箭头的方向（用于测试）
	## 入口方向返回null
	return {
		"arrow1": null if input_direction == Vector2.LEFT else Vector2.LEFT,
		"arrow2": null if input_direction == Vector2.RIGHT else Vector2.RIGHT,
		"arrow3": null if input_direction == Vector2.UP else Vector2.UP,
		"arrow4": null if input_direction == Vector2.DOWN else Vector2.DOWN
	}


func start_debug() -> void:
	## 开始调试模式 - 只显示一个调试箭头（指向debug_direction）
	_update_output_components()
	if output_component_1 and is_instance_valid(output_component_1):
		output_component_1.start_debug()


func end_debug() -> void:
	## 结束调试模式
	if output_component_1 and is_instance_valid(output_component_1):
		output_component_1.end_debug()


func _update_output_components() -> void:
	## 更新输出组件方向
	if output_component_1 and is_instance_valid(output_component_1):
		output_component_1.set_output_direction(output_direction_1)
	if output_component_2 and is_instance_valid(output_component_2):
		output_component_2.set_output_direction(output_direction_2)
	if output_component_3 and is_instance_valid(output_component_3):
		output_component_3.set_output_direction(output_direction_3)


func _update_debug_arrow() -> void:
	## 更新调试箭头显示
	_update_output_components()
	if output_component_1 and is_instance_valid(output_component_1):
		output_component_1.update_debug_arrow()


# 兼容旧代码的属性
var rotation_angle: int = 0:
	get:
		match debug_direction:
			Vector2.LEFT: return 0
			Vector2.UP: return 90
			Vector2.RIGHT: return 180
			Vector2.DOWN: return 270
		return 0
