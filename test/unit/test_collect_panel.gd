extends GutTest
## CollectPanel 收集面板单元测试

var _panel


func before_each():
	_panel = add_child_autofree(CollectPanel.new())


func test_has_collect_method():
	## 应有收集方法
	assert_true(_panel.has_method("collect_numbers"), "应有collect_numbers方法")


func test_has_collected_numbers_property():
	## 应有已收集数字属性
	assert_true("collected_numbers" in _panel, "应有collected_numbers属性")


func test_collected_numbers_initially_empty():
	## 初始收集数字应为空
	assert_eq(_panel.collected_numbers.size(), 0, "初始应无收集数字")


func test_has_send_to_drop_zone_method():
	## 应有发送到加分面板方法
	assert_true(_panel.has_method("send_to_drop_zone"), "应有send_to_drop_zone方法")


func test_has_is_one_time_property():
	## 应有一次性行属性
	assert_true("is_one_time" in _panel, "应有is_one_time属性")


func test_default_is_one_time():
	## 默认应为一次性
	assert_true(_panel.is_one_time, "默认应为一次性")


func test_has_collect_and_send_method():
	## 应有收集并发送方法
	assert_true(_panel.has_method("collect_and_send"), "应有collect_and_send方法")


func test_collects_numbers_in_range():
	## 应收集面板范围内的数字
	# 创建测试数字
	var number1 = partial_double(NumberObject).new()
	number1.global_position = Vector2(10, 10)
	number1.size = Vector2(50, 50)
	add_child_autofree(number1)

	var number2 = partial_double(NumberObject).new()
	number2.global_position = Vector2(300, 300)  # 超出范围
	number2.size = Vector2(50, 50)
	add_child_autofree(number2)

	_panel.global_position = Vector2(0, 0)
	_panel.size = Vector2(200, 200)

	_panel.collect_numbers()

	# 只应该收集number1
	assert_eq(_panel.collected_numbers.size(), 1, "应只收集面板范围内的数字")


func test_has_collect_animation_method():
	## 应有收集动画方法
	assert_true(_panel.has_method("play_collect_animation"), "应有play_collect_animation方法")


func test_removes_self_after_send():
	## 发送后应标记为删除（一次性）
	_panel.is_one_time = true
	# 模拟发送完成
	_panel._on_send_complete()
	# 检查是否正在删除中或已无效
	await wait_idle_frames(1)
	assert_true(not is_instance_valid(_panel) or _panel.is_queued_for_deletion(), "一次性面板发送后应删除")


## === 加工中数字保护测试 ===

func test_does_not_collect_number_being_processed():
	## 不应收集正在被加工面板加工的数字
	var number = NumberObject.new()
	number.global_position = Vector2(10, 10)
	number.size = Vector2(50, 50)
	number._is_being_processed = true  # 标记为正在加工
	add_child_autofree(number)

	_panel.global_position = Vector2(0, 0)
	_panel.size = Vector2(200, 200)

	_panel.collect_numbers()

	assert_eq(_panel.collected_numbers.size(), 0, "不应收集正在加工中的数字")


func test_does_not_collect_number_being_added():
	## 不应收集正在被加法面板加工的数字
	var number = NumberObject.new()
	number.global_position = Vector2(10, 10)
	number.size = Vector2(50, 50)
	number._is_being_processed = true  # 标记为正在加工
	add_child_autofree(number)

	_panel.global_position = Vector2(0, 0)
	_panel.size = Vector2(200, 200)

	_panel.collect_numbers()

	assert_eq(_panel.collected_numbers.size(), 0, "不应收集正在加法面板中的数字")
