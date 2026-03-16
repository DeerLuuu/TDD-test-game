extends Control
class_name ConveyorBelt
## ConveyorBelt 传送带面板
## 可旋转面板，上方数字按当前方向移动
## 支持点击模式和拖动模式

## 四个方向的箭头纹理
@export var arrow_textures: Dictionary = {}

## 移动速度（像素/秒）
@export var speed: float = 100.0

## 对齐速度（像素/秒）- 移动到中心线的速度
@export var align_speed: float = 200.0

## 当前方向
var direction: Vector2 = Vector2.RIGHT:
	set(value):
		direction = value
		_update_arrow_texture()
		_sync_output_direction()

## 当前传送带上的数字
var numbers: Array[NumberObject] = []

## 数字是否已对齐到中心线
var _number_aligned: Dictionary = {}

## 箭头显示节点
var _arrow_display: TextureRect = null

## 输出组件引用
var _output_component: OutputComponent = null
var output_component: OutputComponent:
	get:
		if _output_component == null:
			_output_component = get_node_or_null("OutputComponent")
		return _output_component


func _ready() -> void:
	# 预览传送带不加入交互组
	var is_preview = has_meta("is_preview") and get_meta("is_preview")
	if not is_preview:
		add_to_group("placeable_items")
		add_to_group("selectable_items")

	# 初始化箭头纹理字典
	if arrow_textures.is_empty():
		arrow_textures = {
			Vector2.RIGHT: preload("res://assets/arrows/arrow_right.svg"),
			Vector2.LEFT: preload("res://assets/arrows/arrow_left.svg"),
			Vector2.UP: preload("res://assets/arrows/arrow_up.svg"),
			Vector2.DOWN: preload("res://assets/arrows/arrow_down.svg")
		}
	# 尝试获取箭头显示节点
	_arrow_display = get_node_or_null("TextureRect")
	# 启用鼠标输入处理
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_arrow_texture()

	# 检查是否为预览状态
	if has_meta("is_preview") and get_meta("is_preview"):
		return


func _process(delta: float) -> void:
	# 预览状态下不执行任何逻辑
	if has_meta("is_preview") and get_meta("is_preview"):
		return

	_move_numbers(delta)
	_detect_numbers()


func _detect_numbers() -> void:
	## 检测传送带区域内的数字
	var all_numbers = get_tree().get_nodes_in_group("number_objects")
	var conveyor_rect = Rect2(global_position, size)

	for number in all_numbers:
		if not is_instance_valid(number):
			continue

		# 跳过正在被拖动的数字
		if number._is_dragging:
			if numbers.has(number):
				remove_number(number)
			continue

		# 获取数字的中心点
		var number_center = number.global_position + number.size / 2
		var is_inside = conveyor_rect.has_point(number_center)

		if is_inside and not numbers.has(number):
			# 数字进入传送带
			add_number(number)
		elif not is_inside and numbers.has(number):
			# 数字离开传送带
			remove_number(number)


func _input(event: InputEvent) -> void:
	## 处理滚轮输入（旋转传送带方向）
	# 在铺路模式下不处理滚轮，避免冲突
	if Global.is_path_build_mode():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			# 检查鼠标是否在本节点内
			@warning_ignore("static_called_on_instance")
			var global_mouse = Global.get_scaled_global_mouse_position(get_viewport())
			var rect = Rect2(global_position, size)
			if rect.has_point(global_mouse):
				rotate_on_scroll(1.0)
				get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			# 检查鼠标是否在本节点内
			@warning_ignore("static_called_on_instance")
			var global_mouse = Global.get_scaled_global_mouse_position(get_viewport())
			var rect = Rect2(global_position, size)
			if rect.has_point(global_mouse):
				rotate_on_scroll(-1.0)
				get_viewport().set_input_as_handled()


## 旋转方向（顺时针：右 -> 下 -> 左 -> 上 -> 右）
func rotate_direction() -> void:
	if direction == Vector2.RIGHT:
		direction = Vector2.DOWN
	elif direction == Vector2.DOWN:
		direction = Vector2.LEFT
	elif direction == Vector2.LEFT:
		direction = Vector2.UP
	else:
		direction = Vector2.RIGHT


## 旋转方向（逆时针：右 -> 上 -> 左 -> 下 -> 右）
func rotate_direction_ccw() -> void:
	if direction == Vector2.RIGHT:
		direction = Vector2.UP
	elif direction == Vector2.UP:
		direction = Vector2.LEFT
	elif direction == Vector2.LEFT:
		direction = Vector2.DOWN
	else:
		direction = Vector2.RIGHT


## 根据滚轮方向旋转
func rotate_on_scroll(scroll_direction: float) -> void:
	## scroll_direction > 0: 滚轮向上，顺时针旋转
	## scroll_direction < 0: 滚轮向下，逆时针旋转
	if scroll_direction > 0:
		rotate_direction()
	else:
		rotate_direction_ccw()


## 添加数字到传送带
func add_number(number: NumberObject) -> void:
	if number and not numbers.has(number):
		numbers.append(number)
		# 新数字默认未对齐
		_number_aligned[number.get_instance_id()] = false


## 从传送带移除数字
func remove_number(number: NumberObject) -> void:
	if number:
		numbers.erase(number)
		_number_aligned.erase(number.get_instance_id())


## 获取方向中心线位置（传送带中心点）
func get_center_line_position() -> Vector2:
	## 返回传送带的中心位置
	return global_position + size / 2


## 检查数字是否已对齐
func is_number_aligned(number: NumberObject) -> bool:
	return _number_aligned.get(number.get_instance_id(), false)


## 按当前方向移动所有数字
func _move_numbers(delta: float) -> void:
	for number in numbers:
		if is_instance_valid(number) and not number._is_dragging:
			var number_id = number.get_instance_id()

			# 检查是否需要先对齐
			if not _number_aligned.get(number_id, false):
				# 先移动到中心线
				_align_to_center_line(number, delta)
			else:
				# 已对齐，沿方向移动
				number.global_position += direction * speed * delta


## 将数字对齐到方向中心线
func _align_to_center_line(number: NumberObject, delta: float) -> void:
	## 计算数字中心位置
	var number_center = number.global_position + number.size / 2
	## 传送带中心位置
	var conveyor_center = get_center_line_position()

	## 根据方向确定需要对齐的轴
	var align_axis: String  # "x" 或 "y"
	var target_pos: float
	var current_pos: float

	if direction == Vector2.LEFT or direction == Vector2.RIGHT:
		# 水平方向移动，需要对齐Y轴
		align_axis = "y"
		target_pos = conveyor_center.y
		current_pos = number_center.y
	else:
		# 垂直方向移动，需要对齐X轴
		align_axis = "x"
		target_pos = conveyor_center.x
		current_pos = number_center.x

	## 计算距离和移动量
	var distance = absf(target_pos - current_pos)
	var move_amount = align_speed * delta

	if distance <= move_amount:
		# 已到达中心线，精确对齐
		if align_axis == "y":
			number.global_position.y = target_pos - number.size.y / 2
		else:
			number.global_position.x = target_pos - number.size.x / 2
		# 标记为已对齐
		_number_aligned[number.get_instance_id()] = true
	else:
		# 向中心线移动
		if align_axis == "y":
			if current_pos < target_pos:
				number.global_position.y += move_amount
			else:
				number.global_position.y -= move_amount
		else:
			if current_pos < target_pos:
				number.global_position.x += move_amount
			else:
				number.global_position.x -= move_amount


## 更新箭头纹理显示
func _update_arrow_texture() -> void:
	if _arrow_display and arrow_textures.has(direction):
		_arrow_display.texture = arrow_textures[direction]


func _sync_output_direction() -> void:
	## 同步输出方向
	if output_component:
		output_component.set_output_direction(direction)
