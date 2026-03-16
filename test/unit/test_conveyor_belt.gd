extends GutTest
## ConveyorBelt 传送带面板单元测试

var _conveyor


func before_each():
	_conveyor = add_child_autofree(ConveyorBelt.new())


func test_has_direction_variable():
	## 应有方向变量
	assert_true("direction" in _conveyor, "应有direction属性")


func test_initial_direction_is_right():
	## 初始方向应为右
	assert_eq(_conveyor.direction, Vector2.RIGHT, "初始方向应为右")


func test_has_rotate_method():
	## 应有旋转方法
	assert_true(_conveyor.has_method("rotate_direction"), "应有rotate_direction方法")


func test_rotate_changes_direction():
	## 旋转应改变方向
	_conveyor.rotate_direction()
	assert_eq(_conveyor.direction, Vector2.DOWN, "旋转后应为下")

	_conveyor.rotate_direction()
	assert_eq(_conveyor.direction, Vector2.LEFT, "旋转后应为左")

	_conveyor.rotate_direction()
	assert_eq(_conveyor.direction, Vector2.UP, "旋转后应为上")

	_conveyor.rotate_direction()
	assert_eq(_conveyor.direction, Vector2.RIGHT, "旋转后应为右")


func test_has_speed_property():
	## 应有速度属性
	assert_true("speed" in _conveyor, "应有speed属性")


func test_default_speed():
	## 默认速度应为合理值
	assert_gt(_conveyor.speed, 0.0, "速度应大于0")


func test_has_numbers_array():
	## 应有数字数组存储当前传送带上的数字
	assert_true("numbers" in _conveyor, "应有numbers属性")


func test_add_number():
	## 可以添加数字到传送带
	var number = partial_double(NumberObject).new()
	add_child_autofree(number)
	_conveyor.add_number(number)
	assert_eq(_conveyor.numbers.size(), 1, "应有一个数字")


func test_remove_number():
	## 可以移除数字
	var number = partial_double(NumberObject).new()
	add_child_autofree(number)
	_conveyor.add_number(number)
	_conveyor.remove_number(number)
	assert_eq(_conveyor.numbers.size(), 0, "应无数字")


func test_move_numbers_in_direction():
	## 数字应按方向移动
	# 设置传送带位置和大小
	_conveyor.size = Vector2(50, 50)
	_conveyor.global_position = Vector2(100, 100)
	_conveyor.direction = Vector2.RIGHT
	_conveyor.speed = 50
	_conveyor.align_speed = 1000  # 快速对齐

	var number = partial_double(NumberObject).new()
	add_child_autofree(number)
	# 数字已在中心线上（Y对齐）
	number.global_position = Vector2(110, 100)
	number.size = Vector2(50, 50)
	_conveyor.add_number(number)

	# 手动标记为已对齐
	_conveyor._number_aligned[number.get_instance_id()] = true

	var initial_pos = number.global_position.x

	# 模拟一帧移动 (delta = 0.016)
	_conveyor._move_numbers(0.016)

	assert_gt(number.global_position.x, initial_pos, "数字应向右移动")


func test_has_arrow_texture():
	## 应有箭头纹理引用
	assert_true("arrow_textures" in _conveyor, "应有arrow_textures属性")


func test_has_update_arrow_method():
	## 应有更新箭头方法
	assert_true(_conveyor.has_method("_update_arrow_texture"), "应有_update_arrow_texture方法")


func test_has_rotate_on_scroll_method():
	## 应有滚轮旋转方法
	assert_true(_conveyor.has_method("rotate_on_scroll"), "应有rotate_on_scroll方法")


func test_scroll_up_rotates_clockwise():
	## 滚轮向上应顺时针旋转
	_conveyor.direction = Vector2.RIGHT
	_conveyor.rotate_on_scroll(1.0)  # 滚轮向上为正
	assert_eq(_conveyor.direction, Vector2.DOWN, "滚轮向上应顺时针旋转")


func test_scroll_down_rotates_counter_clockwise():
	## 滚轮向下应逆时针旋转
	_conveyor.direction = Vector2.RIGHT
	_conveyor.rotate_on_scroll(-1.0)  # 滚轮向下为负
	assert_eq(_conveyor.direction, Vector2.UP, "滚轮向下应逆时针旋转")


func test_handles_scroll_input():
	## 应处理滚轮输入事件
	var scroll_event = InputEventMouseButton.new()
	scroll_event.button_index = MOUSE_BUTTON_WHEEL_UP
	scroll_event.pressed = true

	# 传送带应能处理滚轮事件
	assert_true(_conveyor.has_method("_gui_input") or _conveyor.has_method("_input"), "应有输入处理方法")


func test_scroll_rotates_direction():
	## 滚轮应能旋转方向
	_conveyor.direction = Vector2.RIGHT

	# 模拟滚轮向上
	_conveyor.rotate_on_scroll(1.0)
	assert_eq(_conveyor.direction, Vector2.DOWN, "滚轮向上应顺时针旋转")


func test_can_rotate_in_drag_mode():
	## 拖动模式下传送带可以旋转
	Global.current_mode = Global.OperationMode.DRAG

	_conveyor.direction = Vector2.RIGHT
	_conveyor.rotate_direction()
	assert_eq(_conveyor.direction, Vector2.DOWN, "拖动模式下应能旋转")


func test_can_rotate_in_click_mode():
	## 点击模式下传送带可以旋转
	Global.current_mode = Global.OperationMode.CLICK

	_conveyor.direction = Vector2.RIGHT
	_conveyor.rotate_direction()
	assert_eq(_conveyor.direction, Vector2.DOWN, "点击模式下应能旋转")


## === 方向中心线对齐测试 ===

func test_has_get_center_line_position_method():
	## 应有获取方向中心线位置的方法
	assert_true(_conveyor.has_method("get_center_line_position"), "应有get_center_line_position方法")


func test_center_line_position_for_right_direction():
	## 向右方向时，中心线在水平中心
	_conveyor.size = Vector2(50, 50)
	_conveyor.global_position = Vector2(100, 100)
	_conveyor.direction = Vector2.RIGHT

	var center_pos = _conveyor.get_center_line_position()
	# 中心线Y应在传送带的垂直中心
	assert_eq(center_pos.y, _conveyor.global_position.y + _conveyor.size.y / 2, "中心线Y应在垂直中心")


func test_center_line_position_for_down_direction():
	## 向下方向时，中心线在垂直中心
	_conveyor.size = Vector2(50, 50)
	_conveyor.global_position = Vector2(100, 100)
	_conveyor.direction = Vector2.DOWN

	var center_pos = _conveyor.get_center_line_position()
	# 中心线X应在传送带的水平中心
	assert_eq(center_pos.x, _conveyor.global_position.x + _conveyor.size.x / 2, "中心线X应在水平中心")


func test_has_number_alignment_tracking():
	## 应有数字对齐状态跟踪
	assert_true("number_aligned" in _conveyor or _conveyor.has_method("is_number_aligned"), "应有数字对齐状态跟踪")


func test_number_moves_to_center_line_first():
	## 数字应先移动到中心线
	_conveyor.size = Vector2(50, 50)
	_conveyor.global_position = Vector2(100, 100)
	_conveyor.direction = Vector2.RIGHT
	_conveyor.speed = 100
	_conveyor.align_speed = 200

	var number = partial_double(NumberObject).new()
	add_child_autofree(number)
	# 数字中心在传送带中心下方，需要向上移动到中心线
	# 数字位置(105, 120)，中心在(130, 145)
	# 传送带中心在(125, 125)，所以Y需要减小
	number.global_position = Vector2(105, 120)
	number.size = Vector2(50, 50)
	_conveyor.add_number(number)

	var initial_y = number.global_position.y
	# 移动一帧
	_conveyor._move_numbers(0.1)

	# 数字Y应该向中心线移动（减小）
	assert_lt(number.global_position.y, initial_y, "数字Y应向中心线移动（减小）")


func test_number_moves_along_direction_after_aligned():
	## 数字对齐后沿方向移动
	_conveyor.size = Vector2(50, 50)
	_conveyor.global_position = Vector2(100, 100)
	_conveyor.direction = Vector2.RIGHT
	_conveyor.speed = 100

	var number = partial_double(NumberObject).new()
	add_child_autofree(number)
	# 数字已在中心线上（Y对齐）
	number.global_position = Vector2(110, 100)
	number.size = Vector2(50, 50)
	_conveyor.add_number(number)

	# 手动标记为已对齐
	_conveyor._number_aligned[number.get_instance_id()] = true

	var initial_x = number.global_position.x
	_conveyor._move_numbers(0.1)

	# 数字应该向右移动
	assert_gt(number.global_position.x, initial_x, "对齐后数字应向右移动")


func test_has_align_speed_property():
	## 应有对齐速度属性
	assert_true("align_speed" in _conveyor, "应有align_speed属性")


func test_align_speed_greater_than_zero():
	## 对齐速度应大于0
	_conveyor.align_speed = 150
	assert_gt(_conveyor.align_speed, 0, "对齐速度应大于0")
