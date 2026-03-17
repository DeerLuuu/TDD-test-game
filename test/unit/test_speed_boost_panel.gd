extends GutTest
## SpeedBoostPanel 加速面板单元测试

var _panel


func before_each():
	_panel = add_child_autofree(SpeedBoostPanel.new())


func after_each():
	_panel = null


## === 基本属性测试 ===

func test_has_speed_boost_panel_class():
	## SpeedBoostPanel应可实例化
	assert_not_null(_panel, "SpeedBoostPanel应可实例化")


func test_has_duration_property():
	## 应有持续时间属性
	assert_true("duration" in _panel, "应有duration属性")


func test_default_duration_is_30_seconds():
	## 默认持续时间应为30秒
	assert_eq(_panel.duration, 30.0, "默认持续时间应为30秒")


func test_has_boost_range_property():
	## 应有加速范围属性
	assert_true("boost_range" in _panel, "应有boost_range属性")


func test_default_boost_range():
	## 默认加速范围应为合理值
	assert_gt(_panel.boost_range, 0, "加速范围应大于0")


func test_has_is_one_time_property():
	## 应有一次性行属性
	assert_true("is_one_time" in _panel, "应有is_one_time属性")


func test_default_is_one_time():
	## 默认应为一次性
	assert_true(_panel.is_one_time, "默认应为一次性")


## === 方法测试 ===

func test_has_find_auto_clickers_in_range_method():
	## 应有查找范围内自动点击器的方法
	assert_true(_panel.has_method("find_auto_clickers_in_range"), "应有find_auto_clickers_in_range方法")


func test_has_boost_auto_clickers_method():
	## 应有加速自动点击器的方法
	assert_true(_panel.has_method("boost_auto_clickers"), "应有boost_auto_clickers方法")


func test_has_apply_boost_method():
	## 应有应用加速的方法
	assert_true(_panel.has_method("apply_boost"), "应有apply_boost方法")


func test_has_end_boost_method():
	## 应有结束加速的方法
	assert_true(_panel.has_method("end_boost"), "应有end_boost方法")


func test_has_start_boost_method():
	## 应有开始加速的方法
	assert_true(_panel.has_method("start_boost"), "应有start_boost方法")


## === 加速效果测试 ===

func test_boost_doubles_click_frequency():
	## 加速应使点击频率翻倍（间隔减半）
	var auto_clicker = AutoClicker.new()
	auto_clicker.click_interval = 2.0
	add_child_autofree(auto_clicker)

	# 记录原始间隔
	var original_interval = auto_clicker.click_interval

	# 应用加速
	_panel.apply_boost([auto_clicker])

	# 间隔应减半
	assert_eq(auto_clicker.click_interval, original_interval / 2.0, "加速后间隔应减半")


func test_find_auto_clickers_in_range_returns_array():
	## 查找范围内自动点击器应返回数组
	_panel.global_position = Vector2(0, 0)
	_panel.size = Vector2(100, 100)
	_panel.boost_range = 150

	var result = _panel.find_auto_clickers_in_range()
	assert_true(result is Array, "应返回数组")


func test_end_boost_restores_original_interval():
	## 结束加速应恢复原始间隔
	var auto_clicker = AutoClicker.new()
	auto_clicker.click_interval = 2.0
	add_child_autofree(auto_clicker)

	var original_interval = auto_clicker.click_interval

	# 应用加速（会记录到_affected_auto_clickers）
	_panel.apply_boost([auto_clicker])
	
	# 使用正确的数据格式调用end_boost
	var affected_data = [{
		"clicker": auto_clicker,
		"original_interval": original_interval
	}]
	_panel.end_boost(affected_data)

	# 间隔应恢复
	assert_eq(auto_clicker.click_interval, original_interval, "结束后应恢复原始间隔")


func test_has_affected_auto_clickers_property():
	## 应有记录受影响自动点击器的属性
	assert_true("_affected_auto_clickers" in _panel, "应有_affected_auto_clickers属性")
