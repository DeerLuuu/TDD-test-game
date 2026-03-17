extends GutTest
## TriSplitterConveyor 三相分流传送带单元测试

var TriSplitterScript = preload("res://scripts/tri_splitter_conveyor.gd")
var _splitter


func before_each():
	_splitter = autofree(TriSplitterScript.new())
	_splitter._ready()
	Global.set_click_mode()


func test_has_speed_property():
	## 应有speed属性
	assert_true(_splitter.get("speed") != null, "应有speed属性")


func test_default_speed():
	## 默认速度应大于0
	assert_true(_splitter.speed > 0, "速度应大于0")


func test_has_debug_direction_property():
	## 应有debug_direction属性
	assert_true(_splitter.get("debug_direction") != null, "应有debug_direction属性")


func test_initial_debug_direction_is_down():
	## 初始调试方向应为下
	assert_eq(_splitter.debug_direction, Vector2.DOWN, "初始调试方向应为下")


func test_has_input_direction_property():
	## 应有input_direction属性
	assert_true(_splitter.get("input_direction") != null, "应有input_direction属性")


func test_initial_input_direction_is_up():
	## 初始入口方向应为上（调试方向的反方向）
	assert_eq(_splitter.input_direction, Vector2.UP, "初始入口方向应为上")


func test_has_three_output_directions():
	## 应有三个输出方向
	assert_true(_splitter.get("output_direction_1") != null, "应有output_direction_1")
	assert_true(_splitter.get("output_direction_2") != null, "应有output_direction_2")
	assert_true(_splitter.get("output_direction_3") != null, "应有output_direction_3")


func test_initial_output_directions():
	## 初始输出方向（debug_direction=DOWN）: 下、左、右
	assert_eq(_splitter.output_direction_1, Vector2.DOWN, "初始输出方向1应为下")
	assert_eq(_splitter.output_direction_2, Vector2.LEFT, "初始输出方向2应为左")
	assert_eq(_splitter.output_direction_3, Vector2.RIGHT, "初始输出方向3应为右")


func test_has_next_output_property():
	## 应有next_output属性（1, 2, 3 循环）
	assert_true(_splitter.get("next_output") != null, "应有next_output属性")


func test_initial_next_output_is_one():
	## 初始下次输出应为1
	assert_eq(_splitter.next_output, 1, "初始next_output应为1")


func test_get_next_output_rotates():
	## get_next_output应轮流返回三个输出方向
	var dir1 = _splitter.get_next_output()
	var dir2 = _splitter.get_next_output()
	var dir3 = _splitter.get_next_output()
	var dir4 = _splitter.get_next_output()

	assert_eq(dir1, Vector2.DOWN, "第一次应为下")
	assert_eq(dir2, Vector2.LEFT, "第二次应为左")
	assert_eq(dir3, Vector2.RIGHT, "第三次应为右")
	assert_eq(dir4, Vector2.DOWN, "第四次应回到下")


func test_has_set_debug_direction_method():
	## 应有set_debug_direction方法
	assert_true(_splitter.has_method("set_debug_direction"), "应有set_debug_direction方法")


func test_set_debug_direction_changes_output_directions():
	## 设置调试方向应改变输出方向
	_splitter.set_debug_direction(Vector2.LEFT)
	assert_eq(_splitter.output_direction_1, Vector2.LEFT, "调试方向左时方向1应为左")
	assert_eq(_splitter.output_direction_2, Vector2.DOWN, "调试方向左时方向2应为下")
	assert_eq(_splitter.output_direction_3, Vector2.UP, "调试方向左时方向3应为上")
	assert_eq(_splitter.input_direction, Vector2.RIGHT, "调试方向左时入口应为右")


func test_set_debug_direction_up():
	## 设置调试方向为上
	_splitter.set_debug_direction(Vector2.UP)
	assert_eq(_splitter.output_direction_1, Vector2.UP, "调试方向上时方向1应为上")
	assert_eq(_splitter.output_direction_2, Vector2.RIGHT, "调试方向上时方向2应为右")
	assert_eq(_splitter.output_direction_3, Vector2.LEFT, "调试方向上时方向3应为左")
	assert_eq(_splitter.input_direction, Vector2.DOWN, "调试方向上时入口应为下")


func test_set_debug_direction_right():
	## 设置调试方向为右
	_splitter.set_debug_direction(Vector2.RIGHT)
	assert_eq(_splitter.output_direction_1, Vector2.RIGHT, "调试方向右时方向1应为右")
	assert_eq(_splitter.output_direction_2, Vector2.UP, "调试方向右时方向2应为上")
	assert_eq(_splitter.output_direction_3, Vector2.DOWN, "调试方向右时方向3应为下")
	assert_eq(_splitter.input_direction, Vector2.LEFT, "调试方向右时入口应为左")


func test_has_add_number_method():
	## 应有add_number方法
	assert_true(_splitter.has_method("add_number"), "应有add_number方法")


func test_has_remove_number_method():
	## 应有remove_number方法
	assert_true(_splitter.has_method("remove_number"), "应有remove_number方法")


func test_has_get_center_position_method():
	## 应有get_center_position方法
	assert_true(_splitter.has_method("get_center_position"), "应有get_center_position方法")


func test_has_four_arrow_properties():
	## 应有四个箭头属性
	assert_true("arrow1" in _splitter, "应有arrow1属性")
	assert_true("arrow2" in _splitter, "应有arrow2属性")
	assert_true("arrow3" in _splitter, "应有arrow3属性")
	assert_true("arrow4" in _splitter, "应有arrow4属性")


func test_has_start_debug_method():
	## 应有start_debug方法
	assert_true(_splitter.has_method("start_debug"), "应有start_debug方法")


func test_has_end_debug_method():
	## 应有end_debug方法
	assert_true(_splitter.has_method("end_debug"), "应有end_debug方法")


func test_has_set_being_dragged_method():
	## 应有set_being_dragged方法
	assert_true(_splitter.has_method("set_being_dragged"), "应有set_being_dragged方法")


func test_has_is_being_dragged_property():
	## 应有_is_being_dragged属性
	assert_true(_splitter.get("_is_being_dragged") != null, "应有_is_being_dragged属性")


func test_is_being_dragged_defaults_to_false():
	## 默认不在拖拽状态
	assert_false(_splitter._is_being_dragged, "默认_is_being_dragged应为false")


func test_has_rotate_on_scroll_method():
	## 应有rotate_on_scroll方法
	assert_true(_splitter.has_method("rotate_on_scroll"), "应有rotate_on_scroll方法")


func test_can_rotate_on_scroll_when_being_dragged():
	## 拖拽状态下可以滚轮旋转
	_splitter.set_being_dragged(true)
	_splitter.rotate_on_scroll(1.0)
	assert_eq(_splitter.debug_direction, Vector2.LEFT, "拖拽状态下滚轮应能旋转")


func test_cannot_rotate_on_scroll_when_not_being_dragged():
	## 非拖拽状态下不能滚轮旋转
	_splitter.set_being_dragged(false)
	_splitter.rotate_on_scroll(1.0)
	assert_eq(_splitter.debug_direction, Vector2.DOWN, "非拖拽状态下滚轮不应旋转")


func test_has_align_speed_property():
	## 应有align_speed属性
	assert_true(_splitter.get("align_speed") != null, "应有align_speed属性")


func test_align_speed_greater_than_zero():
	## 对齐速度应大于0
	assert_true(_splitter.align_speed > 0, "对齐速度应大于0")


func test_add_number_sets_output_direction():
	## 添加数字时应分配输出方向
	var number = autofree(NumberObject.new())
	number.size = Vector2(30, 30)

	_splitter.add_number(number)
	assert_true(_splitter.numbers.has(number), "数字应在数组中")


func test_get_next_output_increments():
	## get_next_output应递增next_output
	_splitter.get_next_output()
	assert_eq(_splitter.next_output, 2, "调用后next_output应为2")
	_splitter.get_next_output()
	assert_eq(_splitter.next_output, 3, "调用后next_output应为3")
	_splitter.get_next_output()
	assert_eq(_splitter.next_output, 1, "调用后next_output应回到1")


func test_has_get_arrow_directions_method():
	## 应有get_arrow_directions方法
	assert_true(_splitter.has_method("get_arrow_directions"), "应有get_arrow_directions方法")


func test_get_arrow_directions_returns_four():
	## get_arrow_directions应返回四个方向
	var dirs = _splitter.get_arrow_directions()
	assert_true(dirs.has("arrow1"), "应有arrow1")
	assert_true(dirs.has("arrow2"), "应有arrow2")
	assert_true(dirs.has("arrow3"), "应有arrow3")
	assert_true(dirs.has("arrow4"), "应有arrow4")


func test_initial_arrow_directions():
	## 初始(debug_direction=DOWN, input_direction=UP)
	## Arrow3应为null（入口在上）
	var dirs = _splitter.get_arrow_directions()
	assert_eq(dirs["arrow1"], Vector2.LEFT, "Arrow1应为左")
	assert_eq(dirs["arrow2"], Vector2.RIGHT, "Arrow2应为右")
	assert_null(dirs["arrow3"], "Arrow3应为null(入口方向上)")
	assert_eq(dirs["arrow4"], Vector2.DOWN, "Arrow4应为下")


func test_debug_direction_left_arrow_directions():
	## 调试方向左，入口在右，Arrow2应为null
	_splitter.set_debug_direction(Vector2.LEFT)
	var dirs = _splitter.get_arrow_directions()
	assert_eq(dirs["arrow1"], Vector2.LEFT, "Arrow1应为左")
	assert_null(dirs["arrow2"], "Arrow2应为null(入口方向右)")
	assert_eq(dirs["arrow3"], Vector2.UP, "Arrow3应为上")
	assert_eq(dirs["arrow4"], Vector2.DOWN, "Arrow4应为下")


func test_debug_direction_up_arrow_directions():
	## 调试方向上，入口在下，Arrow4应为null
	_splitter.set_debug_direction(Vector2.UP)
	var dirs = _splitter.get_arrow_directions()
	assert_eq(dirs["arrow1"], Vector2.LEFT, "Arrow1应为左")
	assert_eq(dirs["arrow2"], Vector2.RIGHT, "Arrow2应为右")
	assert_eq(dirs["arrow3"], Vector2.UP, "Arrow3应为上")
	assert_null(dirs["arrow4"], "Arrow4应为null(入口方向下)")


func test_debug_direction_right_arrow_directions():
	## 调试方向右，入口在左，Arrow1应为null
	_splitter.set_debug_direction(Vector2.RIGHT)
	var dirs = _splitter.get_arrow_directions()
	assert_null(dirs["arrow1"], "Arrow1应为null(入口方向左)")
	assert_eq(dirs["arrow2"], Vector2.RIGHT, "Arrow2应为右")
	assert_eq(dirs["arrow3"], Vector2.UP, "Arrow3应为上")
	assert_eq(dirs["arrow4"], Vector2.DOWN, "Arrow4应为下")


func test_rotation_angle_is_computed():
	## rotation_angle应根据debug_direction计算
	_splitter.set_debug_direction(Vector2.LEFT)
	assert_eq(_splitter.rotation_angle, 0, "调试方向左时角度应为0")
	
	_splitter.set_debug_direction(Vector2.UP)
	assert_eq(_splitter.rotation_angle, 90, "调试方向上时角度应为90")
	
	_splitter.set_debug_direction(Vector2.RIGHT)
	assert_eq(_splitter.rotation_angle, 180, "调试方向右时角度应为180")
	
	_splitter.set_debug_direction(Vector2.DOWN)
	assert_eq(_splitter.rotation_angle, 270, "调试方向下时角度应为270")