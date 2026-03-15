extends GutTest
## OutputComponent 输出组件单元测试

var _component: OutputComponent
var _parent: Control


func before_each():
	# 创建父节点
	_parent = autofree(Control.new())
	_parent.custom_minimum_size = Vector2(100, 100)
	add_child_autofree(_parent)
	
	# 创建组件
	_component = autofree(OutputComponent.new())
	_parent.add_child(_component)
	
	# 重置全局状态
	Global.set_click_mode()


func after_each():
	if _component:
		_component.queue_free()
	if _parent:
		_parent.queue_free()


## === 基本属性测试 ===

func test_has_output_direction_property():
	## 应有输出方向属性
	assert_true("output_direction" in _component, "应有output_direction属性")


func test_default_output_direction_is_right():
	## 默认输出方向为右
	assert_eq(_component.output_direction, Vector2.RIGHT, "默认输出方向应为右")


func test_has_output_offset_property():
	## 应有输出偏移属性
	assert_true("output_offset" in _component, "应有output_offset属性")


func test_default_output_offset():
	## 默认输出偏移
	assert_eq(_component.output_offset, Vector2(100, 0), "默认输出偏移应为(100, 0)")


func test_has_is_debugging_property():
	## 应有调试状态属性
	assert_true("is_debugging" in _component, "应有is_debugging属性")


func test_default_not_debugging():
	## 默认不在调试状态
	assert_false(_component.is_debugging, "默认不应在调试状态")


## === 方向设置测试 ===

func test_can_set_output_direction():
	## 可以设置输出方向
	_component.output_direction = Vector2.UP
	assert_eq(_component.output_direction, Vector2.UP, "应能设置输出方向为上")


func test_set_direction_updates_offset():
	## 设置方向后自动更新偏移
	_component.output_distance = 100
	_component.set_output_direction(Vector2.UP)
	assert_eq(_component.output_offset, Vector2(0, -100), "向上偏移应为(0, -100)")
	
	_component.set_output_direction(Vector2.DOWN)
	assert_eq(_component.output_offset, Vector2(0, 100), "向下偏移应为(0, 100)")
	
	_component.set_output_direction(Vector2.LEFT)
	assert_eq(_component.output_offset, Vector2(-100, 0), "向左偏移应为(-100, 0)")
	
	_component.set_output_direction(Vector2.RIGHT)
	assert_eq(_component.output_offset, Vector2(100, 0), "向右偏移应为(100, 0)")


func test_has_output_distance_property():
	## 应有输出距离属性
	assert_true("output_distance" in _component, "应有output_distance属性")


func test_default_output_distance():
	## 默认输出距离
	assert_eq(_component.output_distance, 100, "默认输出距离应为100")


## === 输出位置计算测试 ===

func test_has_get_output_position_method():
	## 应有获取输出位置方法
	assert_true(_component.has_method("get_output_position"), "应有get_output_position方法")


func test_get_output_position_returns_vector2():
	## 获取输出位置返回Vector2
	var pos = _component.get_output_position()
	assert_true(pos is Vector2, "应返回Vector2")


func test_get_output_position_relative_to_parent():
	## 输出位置相对于父节点
	_parent.global_position = Vector2(200, 200)
	_parent.size = Vector2(100, 100)  # 直接设置size
	# 等待size生效
	await wait_idle_frames(1)
	
	# 先设置distance，再设置direction（会触发更新）
	_component.output_distance = 50
	_component.set_output_direction(Vector2.RIGHT)
	
	var output_pos = _component.get_output_position()
	# 输出位置应该是父节点中心 + 输出偏移
	# 父节点中心 = global_position + size/2 = (200, 200) + (50, 50) = (250, 250)
	# 输出偏移 = (50, 0)
	# 总计 = (300, 250)
	var expected = Vector2(300, 250)
	assert_eq(output_pos, expected, "输出位置应正确计算")


## === 调试模式测试 ===

func test_has_start_debug_method():
	## 应有开始调试方法
	assert_true(_component.has_method("start_debug"), "应有start_debug方法")


func test_has_end_debug_method():
	## 应有结束调试方法
	assert_true(_component.has_method("end_debug"), "应有end_debug方法")


func test_start_debug_sets_is_debugging():
	## 开始调试设置调试状态
	_component.start_debug()
	assert_true(_component.is_debugging, "开始调试后is_debugging应为true")


func test_end_debug_resets_is_debugging():
	## 结束调试重置调试状态
	_component.start_debug()
	_component.end_debug()
	assert_false(_component.is_debugging, "结束调试后is_debugging应为false")


## === 方向拖动测试 ===

func test_has_get_direction_from_drag_method():
	## 应有从拖动获取方向的方法
	assert_true(_component.has_method("get_direction_from_drag"), "应有get_direction_from_drag方法")


func test_get_direction_from_drag_right():
	## 向右拖动返回右方向
	_parent.global_position = Vector2(100, 100)
	_parent.size = Vector2(100, 100)
	# 父节点中心 = (100, 100) + (50, 50) = (150, 150)
	# 向右拖动需要x方向明显大于y方向
	var drag_end = Vector2(300, 150)  # 明显向右
	var dir = _component.get_direction_from_drag(drag_end)
	assert_eq(dir, Vector2.RIGHT, "向右拖动应返回RIGHT")


func test_get_direction_from_drag_left():
	## 向左拖动返回左方向
	_parent.global_position = Vector2(200, 100)
	_parent.size = Vector2(100, 100)
	# 父节点中心 = (250, 150)
	var drag_end = Vector2(50, 150)  # 明显向左
	var dir = _component.get_direction_from_drag(drag_end)
	assert_eq(dir, Vector2.LEFT, "向左拖动应返回LEFT")


func test_get_direction_from_drag_up():
	## 向上拖动返回上方向
	_parent.global_position = Vector2(100, 200)
	_parent.size = Vector2(100, 100)
	# 父节点中心 = (150, 250)
	var drag_end = Vector2(150, 50)  # 明显向上
	var dir = _component.get_direction_from_drag(drag_end)
	assert_eq(dir, Vector2.UP, "向上拖动应返回UP")


func test_get_direction_from_drag_down():
	## 向下拖动返回下方向
	_parent.global_position = Vector2(100, 100)
	_parent.size = Vector2(100, 100)
	# 父节点中心 = (150, 150)
	var drag_end = Vector2(150, 300)  # 明显向下
	var dir = _component.get_direction_from_drag(drag_end)
	assert_eq(dir, Vector2.DOWN, "向下拖动应返回DOWN")


func test_has_apply_drag_direction_method():
	## 应有应用拖动方向的方法
	assert_true(_component.has_method("apply_drag_direction"), "应有apply_drag_direction方法")


func test_apply_drag_direction_updates_output():
	## 应用拖动方向更新输出方向
	_parent.global_position = Vector2(100, 100)
	_parent.size = Vector2(100, 100)
	# 父节点中心 = (150, 150)
	var drag_end = Vector2(300, 150)  # 明显向右
	
	_component.apply_drag_direction(drag_end)
	
	assert_eq(_component.output_direction, Vector2.RIGHT, "应更新输出方向")
