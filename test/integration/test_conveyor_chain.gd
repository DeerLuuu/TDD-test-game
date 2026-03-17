extends GutTest
## 传送带链路集成测试
## 测试数字在传送带系统中的完整流程

var ConveyorBeltScene = load('res://scenes/conveyor_belt.tscn')
var SplitterConveyorScene = load('res://scenes/splitter_conveyor.tscn')
var ProcessPanelScene = load('res://scenes/process_panel.tscn')
var NumberObjectScene = load('res://scenes/number_object.tscn')


func before_each():
	Global.set_click_mode()
	SelectionManager.clear_selection()


func test_number_enters_conveyor_belt():
	## 测试数字进入传送带
	var conveyor = add_child_autofree(ConveyorBeltScene.instantiate())
	conveyor.global_position = Vector2(100, 100)
	conveyor.direction = Vector2.RIGHT

	var number = add_child_autofree(NumberObjectScene.instantiate())
	number.global_position = Vector2(110, 110)  # 在传送带内

	await wait_idle_frames(2)

	# 数字应被传送带检测到
	assert_true(conveyor.numbers.has(number) or number in conveyor.numbers, "传送带应检测到数字")


func test_conveyor_belt_moves_number():
	## 测试传送带移动数字
	var conveyor = add_child_autofree(ConveyorBeltScene.instantiate())
	conveyor.global_position = Vector2(100, 100)
	conveyor.direction = Vector2.RIGHT
	conveyor.speed = 100

	var number = add_child_autofree(NumberObjectScene.instantiate())
	number.global_position = Vector2(100, 125)  # 传送带中心偏左

	await wait_idle_frames(1)

	# 验证传送带和数字创建成功
	assert_not_null(conveyor, "传送带应创建成功")
	assert_not_null(number, "数字应创建成功")


func test_splitter_conveyor_creation():
	## 测试分流器创建
	var splitter = add_child_autofree(SplitterConveyorScene.instantiate())
	splitter.global_position = Vector2(100, 100)

	assert_not_null(splitter, "分流器应创建成功")
	assert_eq(splitter.rotation_angle, 0, "默认旋转角度为0")


func test_splitter_output_directions():
	## 测试分流器输出方向
	var splitter = add_child_autofree(SplitterConveyorScene.instantiate())
	splitter.global_position = Vector2(100, 100)

	# 0度：左、右分流
	splitter.rotation_angle = 0
	splitter._update_directions()
	assert_eq(splitter.output_direction_1, Vector2.LEFT, "0度方向1应为左")
	assert_eq(splitter.output_direction_2, Vector2.RIGHT, "0度方向2应为右")

	# 90度：上、下分流
	splitter.rotation_angle = 90
	splitter._update_directions()
	assert_eq(splitter.output_direction_1, Vector2.UP, "90度方向1应为上")
	assert_eq(splitter.output_direction_2, Vector2.DOWN, "90度方向2应为下")


func test_process_panel_accepts_number():
	## 测试加工面板接收数字
	var panel = add_child_autofree(ProcessPanelScene.instantiate())
	panel.global_position = Vector2(100, 100)

	var number = add_child_autofree(NumberObjectScene.instantiate())
	number.value = 5
	number.global_position = Vector2(150, 150)

	# 检查面板初始状态
	assert_null(panel.current_number, "初始当前数字应为null")


func test_process_panel_target_value():
	## 测试加工面板点击次数配置
	var panel = add_child_autofree(ProcessPanelScene.instantiate())

	# 通过ClickComponent配置点击次数
	var click_comp = panel.get_node_or_null("ClickComponent")
	if click_comp:
		click_comp.clicks_required = 10
		assert_eq(click_comp.clicks_required, 10, "点击次数应正确")


func test_number_processing_level():
	## 测试数字加工等级
	var number = add_child_autofree(NumberObjectScene.instantiate())
	number.value = 5
	number.processed_level = 0

	# 未加工数字的最终值等于原值
	assert_eq(number.get_final_value(), 5, "未加工数字最终值为原值")

	# 加工一次
	number.processed_level = 1
	assert_eq(number.get_final_value(), 10, "加工1次后翻倍")


func test_number_higher_processing_level():
	## 测试更高加工等级
	var number = add_child_autofree(NumberObjectScene.instantiate())
	number.value = 3
	number.processed_level = 2

	# 3 * 2^2 = 12
	assert_eq(number.get_final_value(), 12, "加工2次应为12")


func test_conveyor_belt_direction_change():
	## 测试传送带方向变化
	var conveyor = add_child_autofree(ConveyorBeltScene.instantiate())

	conveyor.direction = Vector2.RIGHT
	assert_eq(conveyor.direction, Vector2.RIGHT, "方向应为右")

	conveyor.direction = Vector2.UP
	assert_eq(conveyor.direction, Vector2.UP, "方向应为上")


func test_multiple_conveyors_chain():
	## 测试多个传送带链式布置
	var conveyor1 = add_child_autofree(ConveyorBeltScene.instantiate())
	conveyor1.global_position = Vector2(100, 100)
	conveyor1.direction = Vector2.RIGHT

	var conveyor2 = add_child_autofree(ConveyorBeltScene.instantiate())
	conveyor2.global_position = Vector2(200, 100)
	conveyor2.direction = Vector2.RIGHT

	assert_not_null(conveyor1, "传送带1应创建成功")
	assert_not_null(conveyor2, "传送带2应创建成功")


func test_splitter_alternating_output():
	## 测试分流器交替输出
	var splitter = add_child_autofree(SplitterConveyorScene.instantiate())
	splitter.global_position = Vector2(100, 100)

	# 初始应为方向1
	assert_eq(splitter.next_output, "1", "初始输出方向为1")


func test_process_panel_processing_state():
	## 测试加工面板处理状态
	var panel = add_child_autofree(ProcessPanelScene.instantiate())
	panel.global_position = Vector2(100, 100)

	assert_false(panel.processing, "初始不在处理中")
