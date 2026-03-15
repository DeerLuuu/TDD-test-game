extends GutTest
## ProcessPanel 加工面板单元测试

var _panel: ProcessPanel
var _number: NumberObject


func before_each():
	_panel = autofree(ProcessPanel.new())
	_panel.custom_minimum_size = Vector2(100, 100)

	# 手动添加OutputComponent（因为单元测试不加载场景）
	var output_comp = OutputComponent.new()
	output_comp.name = "OutputComponent"
	_panel.add_child(output_comp)

	add_child_autofree(_panel)

	_number = autofree(NumberObject.new())
	_number.value = 5
	_number.custom_minimum_size = Vector2(50, 50)
	add_child_autofree(_number)

	# 重置全局状态
	Global.set_click_mode()


func after_each():
	if _panel:
		_panel.queue_free()
	if _number:
		_number.queue_free()


## === 基本属性测试 ===

func test_has_clicks_required_property():
	## 应有加工次数属性
	assert_true("clicks_required" in _panel, "应有clicks_required属性")


func test_has_current_number_property():
	## 应有当前加工数字属性
	assert_true("current_number" in _panel, "应有current_number属性")


func test_has_current_clicks_property():
	## 应有当前点击次数属性
	assert_true("current_clicks" in _panel, "应有current_clicks属性")


func test_default_clicks_required():
	## 默认需要点击次数
	assert_eq(_panel.clicks_required, 3, "默认需要3次点击")


func test_default_current_number_is_null():
	## 默认没有正在加工的数字
	assert_null(_panel.current_number, "默认current_number应为null")


func test_default_current_clicks_is_zero():
	## 默认点击次数为0
	assert_eq(_panel.current_clicks, 0, "默认current_clicks应为0")


func test_has_processing_property():
	## 应有是否正在加工属性
	assert_true("processing" in _panel, "应有processing属性")


func test_default_not_processing():
	## 默认不在加工中
	assert_false(_panel.processing, "默认不应在加工中")


## === 接收数字测试 ===

func test_can_accept_number():
	## 可以接收数字
	_panel.accept_number(_number)
	assert_eq(_panel.current_number, _number, "应持有数字实例")


func test_accept_number_moves_to_center():
	## 接收数字时数字移动到面板中心
	# 设置初始位置远离面板
	_number.global_position = Vector2(500, 500)

	_panel.accept_number(_number)

	# 等待Tween动画完成
	await wait_seconds(0.5)

	# 数字应该在面板中心附近（考虑数字自身大小）
	var panel_center = _panel.global_position + _panel.size / 2
	var number_center = _number.global_position + _number.size / 2
	assert_almost_eq(number_center.x, panel_center.x, 10.0, "数字X应在面板中心")
	assert_almost_eq(number_center.y, panel_center.y, 10.0, "数字Y应在面板中心")


func test_accept_number_sets_processing():
	## 接收数字后开始加工状态
	_panel.accept_number(_number)
	assert_true(_panel.processing, "接收数字后应在加工中")


func test_cannot_accept_number_when_processing():
	## 加工中不能接收新数字
	_panel.accept_number(_number)

	var new_number = autofree(NumberObject.new())
	new_number.value = 10

	_panel.accept_number(new_number)
	assert_eq(_panel.current_number, _number, "仍应是原来的数字")


func test_number_is_not_destroyed_on_accept():
	## 数字进入面板时不会被销毁
	_panel.accept_number(_number)
	assert_true(is_instance_valid(_number), "数字应仍然有效")


## === 点击加工测试 ===

func test_click_increments_counter():
	## 点击增加计数
	_panel.accept_number(_number)
	_panel.on_click()
	assert_eq(_panel.current_clicks, 1, "点击后计数应为1")


func test_multiple_clicks():
	## 多次点击（设置更高的点击次数避免触发完成）
	_panel.clicks_required = 5
	_panel.accept_number(_number)

	_panel.on_click()
	assert_eq(_panel.current_clicks, 1, "第一次点击后计数应为1")
	_panel.on_click()
	assert_eq(_panel.current_clicks, 2, "第二次点击后计数应为2")
	_panel.on_click()
	assert_eq(_panel.current_clicks, 3, "第三次点击后计数应为3")

func test_click_does_not_work_without_number():
	## 没有数字时点击无效
	_panel.on_click()
	assert_eq(_panel.current_clicks, 0, "没有数字时点击不应增加计数")


func test_process_completes_after_required_clicks():
	## 达到所需点击次数后完成加工
	_panel.clicks_required = 2
	_panel.accept_number(_number)

	_panel.on_click()
	_panel.on_click()

	# 等待输出动画完成
	await wait_seconds(0.5)

	assert_eq(_number.processed_level, 1, "数字加工等级应+1")


func test_process_resets_after_completion():
	## 加工完成后重置状态
	_panel.clicks_required = 1
	_panel.accept_number(_number)

	_panel.on_click()

	# 等待输出动画完成（异步）
	await wait_seconds(0.6)

	assert_null(_panel.current_number, "完成后current_number应重置")
	assert_eq(_panel.current_clicks, 0, "完成后current_clicks应重置")
	assert_false(_panel.processing, "完成后processing应为false")


## === 加工等级测试 ===

func test_processed_level_increases():
	## 加工等级增加
	var initial_level = _number.processed_level
	_panel.clicks_required = 1
	_panel.accept_number(_number)
	_panel.on_click()

	# 等待动画完成
	await wait_seconds(0.5)

	assert_eq(_number.processed_level, initial_level + 1, "加工等级应+1")


## === 排队机制测试 ===

func test_queued_number_enters_after_completion():
	## 加工完成后等待的数字进入
	_panel.clicks_required = 1
	_panel.accept_number(_number)

	# 模拟另一个数字尝试进入
	var waiting_number = autofree(NumberObject.new())
	waiting_number.value = 10
	_panel.queue_number(waiting_number)

	# 完成当前加工
	_panel.on_click()

	# 等待动画完成
	await wait_seconds(0.5)

	assert_eq(_panel.current_number, waiting_number, "等待的数字应进入加工")


func test_has_waiting_queue():
	## 应有等待队列
	assert_true("waiting_queue" in _panel, "应有waiting_queue属性")


func test_queue_is_array():
	## 等待队列是数组
	assert_true(_panel.waiting_queue is Array, "waiting_queue应为数组")


## === 输出位置测试 ===

func test_has_output_component():
	## 应有输出组件
	# 在单元测试中手动添加了OutputComponent
	assert_not_null(_panel.output_component, "应有output_component")


func test_output_component_has_offset():
	## 输出组件应有输出偏移
	assert_not_null(_panel.output_component, "output_component不应为null")
	assert_true("output_offset" in _panel.output_component, "输出组件应有output_offset属性")


## === 自动检测数字测试 ===

func test_auto_detects_number_in_range():
	## 自动检测范围内的数字
	# 将数字放到面板范围内
	_number.global_position = _panel.global_position + _panel.size / 2 - _number.size / 2

	# 等待一帧让_process执行
	await wait_idle_frames(1)

	assert_eq(_panel.current_number, _number, "应自动接收范围内的数字")


func test_does_not_detect_dragging_number():
	## 不会检测正在拖动的数字
	_number.global_position = _panel.global_position + _panel.size / 2 - _number.size / 2
	_number._is_dragging = true

	await wait_idle_frames(1)

	assert_null(_panel.current_number, "不应接收正在拖动的数字")


func test_auto_detect_after_processing_complete():
	## 加工完成后自动检测下一个数字
	_panel.clicks_required = 1
	_number.global_position = _panel.global_position + _panel.size / 2 - _number.size / 2

	# 等待自动检测
	await wait_idle_frames(1)
	assert_eq(_panel.current_number, _number, "应自动接收第一个数字")

	# 完成加工（异步等待输出动画完成）
	_panel.on_click()
	await wait_seconds(0.6)

	# 第一个数字应该已移出，面板应为空
	assert_null(_panel.current_number, "完成后current_number应重置")

	# 放置第二个数字在范围内（此时面板已空闲）
	var second_number = autofree(NumberObject.new())
	second_number.value = 10
	second_number.custom_minimum_size = Vector2(50, 50)
	second_number.global_position = _panel.global_position + _panel.size / 2 - second_number.size / 2
	add_child_autofree(second_number)

	# 等待自动检测
	await wait_idle_frames(2)
	assert_eq(_panel.current_number, second_number, "应自动接收第二个数字")


## === 取出数字测试 ===

func test_can_remove_number_from_panel():
	## 可以从加工面板中取出数字
	_panel.accept_number(_number)
	assert_eq(_panel.current_number, _number, "数字应在面板中")

	_panel.remove_number(_number)

	assert_null(_panel.current_number, "取出后current_number应为null")
	assert_false(_panel.processing, "取出后processing应为false")


func test_remove_number_resets_clicks():
	## 取出数字后重置点击计数
	_panel.accept_number(_number)
	_panel.on_click()
	_panel.on_click()
	assert_eq(_panel.current_clicks, 2, "应有2次点击")

	_panel.remove_number(_number)

	assert_eq(_panel.current_clicks, 0, "取出后点击计数应重置")
