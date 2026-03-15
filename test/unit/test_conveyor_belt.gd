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
	var number = partial_double(NumberObject).new()
	add_child_autofree(number)
	number.global_position = Vector2(100, 100)
	_conveyor.add_number(number)

	var initial_pos = number.global_position
	_conveyor.direction = Vector2.RIGHT
	_conveyor.speed = 50

	# 模拟一帧移动 (delta = 0.016)
	_conveyor._move_numbers(0.016)

	assert_gt(number.global_position.x, initial_pos.x, "数字应向右移动")


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


func test_can_be_dragged():
	## 应支持拖动
	assert_true("is_dragging" in _conveyor or "_is_dragging" in _conveyor, "应有拖动状态变量")


func test_scroll_rotates_while_dragging():
	## 拖动时滚轮应能旋转方向
	_conveyor._is_dragging = true
	_conveyor.direction = Vector2.RIGHT

	# 模拟滚轮向上
	_conveyor.rotate_on_scroll(1.0)
	assert_eq(_conveyor.direction, Vector2.DOWN, "拖动时滚轮向上应顺时针旋转")


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
