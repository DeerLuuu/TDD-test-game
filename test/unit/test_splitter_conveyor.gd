extends GutTest
## SplitterConveyor 分流传送带单元测试
## 测试分流传送带的分流逻辑

const SplitterConveyorScript = preload("res://scripts/splitter_conveyor.gd")

var _splitter: Control


func before_each():
	_splitter = SplitterConveyorScript.new()
	_splitter.custom_minimum_size = Vector2(50, 50)
	_splitter.size = Vector2(50, 50)
	add_child_autofree(_splitter)
	_splitter.set_process(false)


## === 基本属性测试 ===

func test_has_splitter_conveyor_class():
	assert_not_null(_splitter, "SplitterConveyor应可实例化")


func test_has_rotation_property():
	assert_true("rotation_angle" in _splitter, "应有rotation_angle属性")


func test_default_rotation_is_zero():
	assert_eq(_splitter.rotation_angle, 0, "默认旋转角度应为0")


func test_has_speed_property():
	assert_true("speed" in _splitter, "应有speed属性")


func test_speed_greater_than_zero():
	assert_gt(_splitter.speed, 0, "速度应大于0")


func test_has_align_speed_property():
	assert_true("align_speed" in _splitter, "应有align_speed属性")


func test_align_speed_greater_than_zero():
	assert_gt(_splitter.align_speed, 0, "对齐速度应大于0")


## === 输出方向测试 ===

func test_has_output_direction_1():
	assert_true("output_direction_1" in _splitter, "应有output_direction_1属性")


func test_has_output_direction_2():
	assert_true("output_direction_2" in _splitter, "应有output_direction_2属性")


func test_default_output_directions():
	assert_eq(_splitter.output_direction_1, Vector2.LEFT, "默认输出方向1应为左")
	assert_eq(_splitter.output_direction_2, Vector2.RIGHT, "默认输出方向2应为右")


func test_has_next_output_property():
	assert_true("next_output" in _splitter, "应有next_output属性")


func test_next_output_defaults_to_1():
	assert_eq(_splitter.next_output, "1", "下次输出默认应为1")


## === 分配逻辑测试 ===

func test_has_get_next_output_method():
	assert_true(_splitter.has_method("get_next_output"), "应有get_next_output方法")


func test_get_next_output_alternates():
	var first = _splitter.get_next_output()
	var second = _splitter.get_next_output()
	var third = _splitter.get_next_output()

	assert_eq(first, Vector2.LEFT, "第一次应为左")
	assert_eq(second, Vector2.RIGHT, "第二次应为右")
	assert_eq(third, Vector2.LEFT, "第三次应为左")


## === 数字管理测试 ===

func test_has_numbers_array():
	assert_true("numbers" in _splitter, "应有numbers属性")


func test_numbers_default_empty():
	assert_eq(_splitter.numbers.size(), 0, "默认numbers应为空")


func test_has_add_number_method():
	assert_true(_splitter.has_method("add_number"), "应有add_number方法")


func test_add_number_adds_to_array():
	var number = _create_test_number()
	_splitter.add_number(number)
	assert_eq(_splitter.numbers.size(), 1, "应有一个数字")


func test_has_remove_number_method():
	assert_true(_splitter.has_method("remove_number"), "应有remove_number方法")


func test_remove_number_removes_from_array():
	var number = _create_test_number()
	_splitter.add_number(number)
	_splitter.remove_number(number)
	assert_eq(_splitter.numbers.size(), 0, "应为空")


## === 移动数字测试 ===

func test_has_move_numbers_method():
	assert_true(_splitter.has_method("_move_numbers"), "应有_move_numbers方法")


func test_numbers_move_towards_output():
	_splitter.size = Vector2(50, 50)
	_splitter.global_position = Vector2(100, 100)
	_splitter.speed = 100
	_splitter.align_speed = 1000

	var number = _create_test_number()
	number.global_position = Vector2(110, 100)
	number.size = Vector2(50, 50)
	_splitter.add_number(number)
	_splitter._number_aligned[number.get_instance_id()] = true

	var initial_pos = number.global_position.x
	_splitter._move_numbers(0.1)

	assert_lt(number.global_position.x, initial_pos, "数字应向左移动")


func test_second_number_moves_right():
	_splitter.size = Vector2(50, 50)
	_splitter.global_position = Vector2(100, 100)
	_splitter.speed = 100
	_splitter.align_speed = 1000

	var number1 = _create_test_number()
	number1.global_position = Vector2(110, 100)
	number1.size = Vector2(50, 50)
	_splitter.add_number(number1)
	_splitter._number_aligned[number1.get_instance_id()] = true
	_splitter._move_numbers(0.5)

	var number2 = _create_test_number()
	number2.global_position = Vector2(110, 100)
	number2.size = Vector2(50, 50)
	_splitter.add_number(number2)
	_splitter._number_aligned[number2.get_instance_id()] = true

	var initial_pos = number2.global_position.x
	_splitter._move_numbers(0.1)

	assert_gt(number2.global_position.x, initial_pos, "第二个数字应向右移动")


## === 对齐到中心测试 ===

func test_has_align_to_center_method():
	assert_true(_splitter.has_method("_align_to_center"), "应有_align_to_center方法")


func test_number_aligns_to_center():
	_splitter.size = Vector2(50, 50)
	_splitter.global_position = Vector2(100, 100)
	_splitter.align_speed = 1000

	var number = _create_test_number()
	number.global_position = Vector2(80, 80)  # 偏离中心
	number.size = Vector2(50, 50)
	_splitter.add_number(number)

	var number_id = number.get_instance_id()
	assert_false(_splitter._number_aligned.get(number_id, false), "初始应未对齐")

	# 对齐一帧
	_splitter._align_to_center(number, 1.0)

	assert_true(_splitter._number_aligned.get(number_id, false), "应对齐")


## === 旋转功能测试 ===

func test_has_rotate_method():
	assert_true(_splitter.has_method("rotate_direction"), "应有rotate_direction方法")


func test_rotate_increments_rotation():
	_splitter.rotate_direction()
	assert_eq(_splitter.rotation_angle, 90, "旋转后角度应为90")


func test_rotation_wraps_at_360():
	_splitter.rotation_angle = 270
	_splitter.rotate_direction()
	assert_eq(_splitter.rotation_angle, 0, "360度后应归零")


func test_has_rotate_direction_ccw_method():
	assert_true(_splitter.has_method("rotate_direction_ccw"), "应有rotate_direction_ccw方法")


func test_rotate_ccw_decrements_rotation():
	_splitter.rotate_direction_ccw()
	assert_eq(_splitter.rotation_angle, 270, "逆时针旋转后角度应为270")


func test_has_rotate_on_scroll_method():
	assert_true(_splitter.has_method("rotate_on_scroll"), "应有rotate_on_scroll方法")


func test_rotate_on_scroll_clockwise():
	_splitter.rotate_on_scroll(1.0)
	assert_eq(_splitter.rotation_angle, 90, "滚轮向上应顺时针旋转")


func test_rotate_on_scroll_counter_clockwise():
	_splitter.rotate_on_scroll(-1.0)
	assert_eq(_splitter.rotation_angle, 270, "滚轮向下应逆时针旋转")


## === 旋转更新输出方向测试 ===

func test_rotation_updates_output_directions():
	# 默认出口在左和右
	assert_eq(_splitter.output_direction_1, Vector2.LEFT, "默认输出方向1为左")
	assert_eq(_splitter.output_direction_2, Vector2.RIGHT, "默认输出方向2为右")

	# 旋转90度后出口在上和下
	_splitter.rotate_direction()
	assert_eq(_splitter.output_direction_1, Vector2.UP, "旋转90度后输出方向1为上")
	assert_eq(_splitter.output_direction_2, Vector2.DOWN, "旋转90度后输出方向2为下")

	# 旋转180度后出口在右和左（交换）
	_splitter.rotate_direction()
	assert_eq(_splitter.output_direction_1, Vector2.RIGHT, "旋转180度后输出方向1为右")
	assert_eq(_splitter.output_direction_2, Vector2.LEFT, "旋转180度后输出方向2为左")

	# 旋转270度后出口在下和上
	_splitter.rotate_direction()
	assert_eq(_splitter.output_direction_1, Vector2.DOWN, "旋转270度后输出方向1为下")
	assert_eq(_splitter.output_direction_2, Vector2.UP, "旋转270度后输出方向2为上")

	# 旋转360度回到原点
	_splitter.rotate_direction()
	assert_eq(_splitter.output_direction_1, Vector2.LEFT, "旋转360度后输出方向1为左")
	assert_eq(_splitter.output_direction_2, Vector2.RIGHT, "旋转360度后输出方向2为右")


## === 箭头方向测试 ===

func test_has_get_arrow_directions_method():
	assert_true(_splitter.has_method("get_arrow_directions"), "应有get_arrow_directions方法")


func test_default_arrow_directions():
	var dirs = _splitter.get_arrow_directions()
	assert_eq(dirs.arrow1, Vector2.LEFT, "默认箭头1指向左")
	assert_eq(dirs.arrow2, Vector2.RIGHT, "默认箭头2指向右")


func test_arrow_directions_after_90_degree_rotation():
	_splitter.rotate_direction()
	var dirs = _splitter.get_arrow_directions()
	assert_eq(dirs.arrow1, Vector2.UP, "旋转90度箭头1指向上")
	assert_eq(dirs.arrow2, Vector2.DOWN, "旋转90度箭头2指向下")


func test_arrow_directions_after_180_degree_rotation():
	_splitter.rotation_angle = 180
	_splitter._update_directions()
	var dirs = _splitter.get_arrow_directions()
	assert_eq(dirs.arrow1, Vector2.RIGHT, "旋转180度箭头1指向右")
	assert_eq(dirs.arrow2, Vector2.LEFT, "旋转180度箭头2指向左")


func test_arrow_directions_after_270_degree_rotation():
	_splitter.rotation_angle = 270
	_splitter._update_directions()
	var dirs = _splitter.get_arrow_directions()
	assert_eq(dirs.arrow1, Vector2.DOWN, "旋转270度箭头1指向下")
	assert_eq(dirs.arrow2, Vector2.UP, "旋转270度箭头2指向上")


## === 输出组件测试 ===

func test_has_output_component_1():
	assert_true("output_component_1" in _splitter, "应有output_component_1属性")


func test_has_output_component_2():
	assert_true("output_component_2" in _splitter, "应有output_component_2属性")


## === 辅助方法 ===

func _create_test_number() -> NumberObject:
	var number = NumberObject.new()
	number.value = 1
	number.processed_level = 0
	number.custom_minimum_size = Vector2(50, 50)
	number.size = Vector2(50, 50)
	number._is_dragging = false
	add_child_autofree(number)
	return number