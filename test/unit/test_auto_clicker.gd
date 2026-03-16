extends GutTest
## AutoClicker 自动点击面板单元测试

var _auto_clicker: AutoClicker
var _parent_panel: Control
var _click_component: ClickComponent


func before_each():
	# 创建父节点（模拟面板）
	_parent_panel = autofree(Control.new())
	_parent_panel.custom_minimum_size = Vector2(100, 50)
	# 手动设置size以确保测试立即可用
	_parent_panel.size = Vector2(100, 50)
	add_child_autofree(_parent_panel)

	# 添加ClickComponent（设置较高的clicks_required避免自动重置）
	_click_component = autofree(ClickComponent.new())
	_click_component.clicks_required = 10  # 设置为10，避免点击后立即重置
	_parent_panel.add_child(_click_component)

	# 创建自动点击器
	_auto_clicker = autofree(AutoClicker.new())
	_parent_panel.add_child(_auto_clicker)

	# 重置全局状态
	Global.set_click_mode()


func after_each():
	if _auto_clicker:
		_auto_clicker.queue_free()
	if _parent_panel:
		_parent_panel.queue_free()


## === 基本属性测试 ===

func test_has_click_interval_property():
	## 应有点击间隔属性
	assert_true("click_interval" in _auto_clicker, "应有click_interval属性")


func test_default_click_interval():
	## 默认点击间隔
	assert_eq(_auto_clicker.click_interval, 2.0, "默认点击间隔应为2.0秒")


func test_has_timer_property():
	## 应有计时器属性
	assert_true("_timer" in _auto_clicker, "应有_timer属性")


func test_default_timer_is_zero():
	## 默认计时器为0
	assert_eq(_auto_clicker._timer, 0.0, "默认_timer应为0")


func test_has_is_active_property():
	## 应有是否激活属性
	assert_true("is_active" in _auto_clicker, "应有is_active属性")


func test_default_is_active():
	## 默认是激活状态
	assert_true(_auto_clicker.is_active, "默认is_active应为true")


## === 大小自动调整测试 ===

func test_size_adjusts_to_parent():
	## 大小应自动调整为比父节点大4像素（每边）
	await wait_idle_frames(1)

	var expected_width = _parent_panel.size.x + 8
	var expected_height = _parent_panel.size.y + 8

	assert_eq(_auto_clicker.size.x, expected_width, "宽度应比父节点大8像素")
	assert_eq(_auto_clicker.size.y, expected_height, "高度应比父节点大8像素")


func test_position_centered_on_parent():
	## 位置应在父节点中心对齐（向左上偏移4像素）
	await wait_idle_frames(1)

	var expected_pos = Vector2(-4, -4)
	assert_eq(_auto_clicker.position, expected_pos, "位置应向左上偏移4像素")


## === 层级测试 ===

func test_z_index_is_negative():
	## z_index应为负数（在父节点下方显示）
	assert_lt(_auto_clicker.z_index, 0, "z_index应为负数")


func test_z_index_is_minus_one():
	## z_index应为-1
	assert_eq(_auto_clicker.z_index, -1, "z_index应为-1")


## === 自动点击功能测试 ===

func test_auto_clicker_in_group():
	## 应在auto_clicker组中
	assert_true(_auto_clicker.is_in_group("auto_clicker"), "应在auto_clicker组中")


func test_timer_increments_in_process():
	## 计时器在_process中递增
	_auto_clicker._timer = 0.0
	_auto_clicker._process(0.5)
	assert_eq(_auto_clicker._timer, 0.5, "计时器应增加0.5")


func test_timer_resets_after_interval():
	## 计时器达到间隔后重置
	_auto_clicker.click_interval = 1.0
	_auto_clicker._timer = 0.0
	_auto_clicker._process(1.0)
	assert_eq(_auto_clicker._timer, 0.0, "计时器达到间隔后应重置")


func test_does_not_tick_when_not_active():
	## 未激活时不计时
	_auto_clicker.is_active = false
	_auto_clicker._timer = 0.0
	_auto_clicker._process(0.5)
	assert_eq(_auto_clicker._timer, 0.0, "未激活时计时器不应增加")


## === 触发点击测试 ===

func test_has_trigger_click_method():
	## 应有触发点击方法
	assert_true(_auto_clicker.has_method("trigger_click"), "应有trigger_click方法")


func test_trigger_click_returns_true_with_click_component():
	## 有ClickComponent时返回true
	var result = _auto_clicker.trigger_click()
	assert_true(result, "有ClickComponent时应返回true")


func test_trigger_click_increments_parent_click_counter():
	## 触发点击应增加父节点ClickComponent计数
	var initial_clicks = _click_component.current_clicks
	_auto_clicker.trigger_click()
	# clicks_required=10，点击后不会重置
	assert_eq(_click_component.current_clicks, initial_clicks + 1, "ClickComponent计数应增加")


func test_has_valid_parent_method():
	## 应有检查有效父节点方法
	assert_true(_auto_clicker.has_method("has_valid_parent"), "应有has_valid_parent方法")


func test_has_valid_parent_returns_true_with_click_component():
	## 有ClickComponent时has_valid_parent返回true
	assert_true(_auto_clicker.has_valid_parent(), "有ClickComponent时应返回true")


func test_trigger_click_returns_false_without_click_component():
	## 没有ClickComponent时返回false
	# 创建一个没有ClickComponent的父节点
	var panel_without_click = autofree(Control.new())
	panel_without_click.size = Vector2(100, 50)
	add_child_autofree(panel_without_click)

	var clicker = autofree(AutoClicker.new())
	panel_without_click.add_child(clicker)

	await wait_idle_frames(1)

	var result = clicker.trigger_click()
	assert_false(result, "没有ClickComponent时应返回false")


## === 边距配置测试 ===

func test_has_border_margin_property():
	## 应有边距配置属性
	assert_true("border_margin" in _auto_clicker, "应有border_margin属性")


func test_default_border_margin():
	## 默认边距为4像素
	assert_eq(_auto_clicker.border_margin, 4, "默认边距应为4像素")


func test_size_uses_border_margin():
	## 大小应使用border_margin计算
	_auto_clicker.border_margin = 8
	await wait_idle_frames(1)

	var expected_width = _parent_panel.size.x + 16
	var expected_height = _parent_panel.size.y + 16

	assert_eq(_auto_clicker.size.x, expected_width, "宽度应使用border_margin计算")
	assert_eq(_auto_clicker.size.y, expected_height, "高度应使用border_margin计算")


## === 父节点变化响应测试 ===

func test_updates_size_on_parent_resize():
	## 父节点大小变化时更新大小
	await wait_idle_frames(1)

	# 改变父节点大小
	_parent_panel.custom_minimum_size = Vector2(200, 100)
	_parent_panel.reset_size()

	await wait_idle_frames(1)

	var expected_width = _parent_panel.size.x + 8
	var expected_height = _parent_panel.size.y + 8

	assert_eq(_auto_clicker.size.x, expected_width, "父节点大小变化后应更新宽度")
	assert_eq(_auto_clicker.size.y, expected_height, "父节点大小变化后应更新高度")
