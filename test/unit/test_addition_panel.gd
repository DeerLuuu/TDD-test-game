extends GutTest
## AdditionPanel 加法面板单元测试

var _panel: AdditionPanel
var _click_component: ClickComponent


func before_each():
	_panel = AdditionPanel.new()
	_panel.custom_minimum_size = Vector2(150, 100)
	_panel.size = Vector2(150, 100)

	# 手动添加ClickComponent（单元测试不加载场景）
	_click_component = ClickComponent.new()
	_click_component.clicks_required = 1
	_panel.add_child(_click_component)

	add_child_autofree(_panel)

	# 禁用面板的_process，防止自动检测数字干扰测试
	_panel.set_process(false)

	# 重置全局状态
	Global.set_click_mode()


func after_each():
	# 确保每个测试后清空数组
	if _panel:
		_panel.numbers.clear()


## === 基本属性测试 ===

func test_has_numbers_array():
	## 应有存储数字的数组
	assert_true("numbers" in _panel, "应有numbers属性")


func test_numbers_is_array():
	## 数字数组应为Array类型
	assert_true(_panel.numbers is Array, "numbers应为Array")


func test_numbers_default_empty():
	## 默认数字数组为空
	assert_eq(_panel.numbers.size(), 0, "默认numbers应为空")


func test_has_max_numbers_property():
	## 应有最大数字数量属性
	assert_true("max_numbers" in _panel, "应有max_numbers属性")


func test_max_numbers_is_two():
	## 最大数字数量应为2
	assert_eq(_panel.max_numbers, 2, "max_numbers应为2")


func test_has_click_component():
	## 应有ClickComponent
	assert_not_null(_click_component, "应有ClickComponent")


func test_click_component_clicks_required_is_one():
	## ClickComponent的clicks_required应为1
	assert_eq(_click_component.clicks_required, 1, "clicks_required应为1")


## === 接收数字测试 ===

func test_can_accept_number():
	## 可以接收数字
	var number = _create_test_number()
	_panel.accept_number(number)
	assert_eq(_panel.numbers.size(), 1, "应接收一个数字")


func test_can_accept_two_numbers():
	## 可以接收两个数字
	var number1 = _create_test_number()
	var number2 = _create_test_number()
	_panel.accept_number(number1)
	_panel.accept_number(number2)
	assert_eq(_panel.numbers.size(), 2, "应接收两个数字")


func test_cannot_accept_more_than_max():
	## 不能接收超过最大数量的数字
	var number1 = _create_test_number()
	var number2 = _create_test_number()
	var number3 = _create_test_number()

	_panel.accept_number(number1)
	_panel.accept_number(number2)
	_panel.accept_number(number3)

	assert_eq(_panel.numbers.size(), 2, "不应超过最大数量")


func test_accepts_only_same_level_numbers():
	## 只接收同等级的数字
	var number1 = _create_test_number()
	number1.processed_level = 0
	var number2 = _create_test_number()
	number2.processed_level = 1

	_panel.accept_number(number1)
	var accepted = _panel.accept_number(number2)

	assert_false(accepted, "不同等级数字应被拒绝")
	assert_eq(_panel.numbers.size(), 1, "只应接收同等级数字")


## === 加工测试 ===

func test_process_creates_new_number():
	## 加工后创建新数字
	var number1 = _create_test_number()
	var number2 = _create_test_number()
	_panel.accept_number(number1)
	_panel.accept_number(number2)

	# 触发加工
	_panel._on_click_complete()

	# 应该输出一个新数字
	assert_eq(_panel.numbers.size(), 0, "加工后数字数组应清空")


func test_new_number_value_is_sum():
	## 新数字值为两数之和
	var number1 = _create_test_number()
	number1.value = 3
	var number2 = _create_test_number()
	number2.value = 5

	_panel.accept_number(number1)
	_panel.accept_number(number2)

	var result = _panel.calculate_result()
	assert_eq(result, 8, "结果应为3+5=8")


func test_new_number_level_matches_input():
	## 新数字等级与输入数字相同
	var number1 = _create_test_number()
	number1.processed_level = 2
	var number2 = _create_test_number()
	number2.processed_level = 2

	_panel.accept_number(number1)
	_panel.accept_number(number2)

	var result_level = _panel.get_result_level()
	assert_eq(result_level, 2, "结果等级应为2")


func test_cannot_process_with_one_number():
	## 只有一个数字时不能加工
	var number = _create_test_number()
	_panel.accept_number(number)

	var processed = _panel.try_process()

	assert_false(processed, "只有一个数字时不应加工")


func test_can_process_with_two_same_level_numbers():
	## 两个同等级数字可以加工
	var number1 = _create_test_number()
	number1.processed_level = 1
	var number2 = _create_test_number()
	number2.processed_level = 1

	_panel.accept_number(number1)
	_panel.accept_number(number2)

	var can_process = _panel.can_add_numbers()
	assert_true(can_process, "两个同等级数字应可加工")


func test_cannot_process_with_different_level_numbers():
	## 不同等级数字：第二个会被拒绝，所以只有一个数字
	var number1 = _create_test_number()
	number1.processed_level = 0
	var number2 = _create_test_number()
	number2.processed_level = 1

	_panel.accept_number(number1)
	_panel.accept_number(number2)  # 这个会被拒绝

	var can_process = _panel.can_add_numbers()
	assert_false(can_process, "只有一个数字时不能加工")


## === 移除数字测试 ===

func test_can_remove_number():
	## 可以移除数字
	var number = _create_test_number()
	_panel.accept_number(number)
	_panel.remove_number(number)

	assert_eq(_panel.numbers.size(), 0, "移除后应为空")


func test_remove_number_by_index():
	## 可以通过索引移除数字
	var number1 = _create_test_number()
	var number2 = _create_test_number()
	_panel.accept_number(number1)
	_panel.accept_number(number2)

	_panel.remove_number_at(0)

	assert_eq(_panel.numbers.size(), 1, "应剩一个数字")


## === 显示状态测试 ===

func test_has_state_property():
	## 应有状态属性
	assert_true("state" in _panel, "应有state属性")


func test_state_is_empty_initially():
	## 初始状态为空
	assert_eq(_panel.state, AdditionPanel.State.EMPTY, "初始状态应为EMPTY")


func test_state_changes_on_accept():
	## 接收数字后状态变化
	var number1 = _create_test_number()
	var number2 = _create_test_number()

	_panel.accept_number(number1)
	assert_eq(_panel.state, AdditionPanel.State.ONE_NUMBER, "一个数字状态应为ONE_NUMBER")

	_panel.accept_number(number2)
	assert_eq(_panel.state, AdditionPanel.State.READY, "两个数字状态应为READY")


## === 自动检测数字测试 ===

func test_auto_detects_number_in_range():
	## 自动检测范围内的数字
	var number = _create_test_number()
	number._is_dragging = false
	number.global_position = _panel.global_position + _panel.size / 2 - number.size / 2

	_panel._auto_detect_numbers()
	assert_eq(_panel.numbers.size(), 1, "应自动检测并接收范围内的数字")


func test_does_not_detect_dragging_number():
	## 不会检测正在拖动的数字
	var number = _create_test_number()
	number._is_dragging = true
	number.global_position = _panel.global_position + _panel.size / 2 - number.size / 2

	_panel._auto_detect_numbers()
	assert_eq(_panel.numbers.size(), 0, "不应接收正在拖动的数字")


## === 辅助方法 ===

func _create_test_number() -> NumberObject:
	## 创建测试用数字对象
	var number = NumberObject.new()
	number.value = 1
	number.processed_level = 0
	number.custom_minimum_size = Vector2(50, 50)
	number.size = Vector2(50, 50)
	number._is_dragging = false
	add_child_autofree(number)
	return number
