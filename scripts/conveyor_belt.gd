extends Control
class_name ConveyorBelt
## ConveyorBelt 传送带面板
## 可旋转面板，上方数字按当前方向移动
## 支持点击模式和拖动模式

## 网格大小
const GRID_SIZE: int = 25

## 四个方向的箭头纹理
@export var arrow_textures: Dictionary = {}

## 移动速度（像素/秒）
@export var speed: float = 100.0

## 当前方向
var direction: Vector2 = Vector2.RIGHT:
	set(value):
		direction = value
		_update_arrow_texture()

## 当前传送带上的数字
var numbers: Array[NumberObject] = []

## 拖动状态
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_preview: Control = null
var _original_position: Vector2 = Vector2.ZERO

## 箭头显示节点
var _arrow_display: TextureRect = null


func _ready() -> void:
	add_to_group("placeable_items")
	# 检查是否为预览状态
	if has_meta("is_preview") and get_meta("is_preview"):
		return

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


func _process(delta: float) -> void:
	# 预览状态下不执行任何逻辑
	if has_meta("is_preview") and get_meta("is_preview"):
		return

	_move_numbers(delta)
	_detect_numbers()
	# 拖动时更新预览位置
	if _is_dragging and _drag_preview:
		var target_pos = get_global_mouse_position() - _drag_offset
		var snapped_pos = _calculate_snapped_position(target_pos)
		_drag_preview.global_position = snapped_pos


func _calculate_snapped_position(pos: Vector2) -> Vector2:
	## 计算网格对齐后的位置
	return Vector2(
		roundi(pos.x / GRID_SIZE) * GRID_SIZE,
		roundi(pos.y / GRID_SIZE) * GRID_SIZE
	)


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


func _gui_input(event: InputEvent) -> void:
	## 点击模式下不处理拖动，只让事件传递
	# 点击模式下传送带不可拖动，只有拖动模式可以
	pass


func _input(event: InputEvent) -> void:
	## 处理拖动模式下的拖动
	if Global.is_drag_mode():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 检查鼠标是否在本节点内
				var rect = Rect2(global_position, size)
				if rect.has_point(get_global_mouse_position()):
					_start_drag()
			else:
				if _is_dragging:
					_end_drag()

	## 处理滚轮输入（两种模式下都可旋转）
	if _is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			rotate_on_scroll(1.0)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			rotate_on_scroll(-1.0)
			get_viewport().set_input_as_handled()


func _start_drag() -> void:
	## 开始拖动
	_is_dragging = true
	_drag_offset = get_local_mouse_position()
	_original_position = global_position
	_create_drag_preview()


func _end_drag() -> void:
	## 结束拖动
	if _drag_preview:
		# 检测目标位置是否被占用
		var target_pos = _drag_preview.global_position
		if Global.check_position_occupied(target_pos, size, self):
			# 位置被占用，回到原位置
			global_position = _original_position
		else:
			# 移动到预览位置
			global_position = target_pos
		_remove_drag_preview()
	_is_dragging = false


func _create_drag_preview() -> void:
	## 创建拖动预览
	_drag_preview = Control.new()
	_drag_preview.size = size

	# 创建背景
	var bg = Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	_drag_preview.add_child(bg)

	# 设置半透明
	_drag_preview.modulate.a = 0.5
	_drag_preview.modulate = Color(0.5, 1.0, 0.5, 0.5)  # 绿色半透明

	# 设置初始位置
	var target_pos = get_global_mouse_position() - _drag_offset
	_drag_preview.global_position = _calculate_snapped_position(target_pos)

	# 添加到场景
	get_tree().current_scene.add_child(_drag_preview)


func _remove_drag_preview() -> void:
	## 移除拖动预览
	if _drag_preview:
		_drag_preview.queue_free()
		_drag_preview = null

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


## 从传送带移除数字
func remove_number(number: NumberObject) -> void:
	if number:
		numbers.erase(number)


## 按当前方向移动所有数字
func _move_numbers(delta: float) -> void:
	for number in numbers:
		if is_instance_valid(number) and not number._is_dragging:
			number.global_position += direction * speed * delta


## 更新箭头纹理显示
func _update_arrow_texture() -> void:
	if _arrow_display and arrow_textures.has(direction):
		_arrow_display.texture = arrow_textures[direction]
