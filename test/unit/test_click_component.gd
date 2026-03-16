extends GutTest
## ClickComponent 点击组件单元测试

var _click_component: ClickComponent
var _parent: Control


func before_each():
	# 创建父节点
	_parent = Control.new()
	_parent.custom_minimum_size = Vector2(100, 100)
	_parent.size = Vector2(100, 100)
	add_child(_parent)

	# 创建点击组件
	_click_component = ClickComponent.new()
	_click_component.clicks_required = 3  # 设置为3次点击，避免自动重置
	_parent.add_child(_click_component)


func after_each():
	if _click_component:
		_click_component.queue_free()
	if _parent:
		_parent.queue_free()


## === 基本属性测试 ===

func test_has_clicks_required_property():
	## 应有点击次数要求属性
	assert_true("clicks_required" in _click_component, "应有clicks_required属性")


func test_default_clicks_required():
	## 默认需要1次点击
	var comp = ClickComponent.new()
	assert_eq(comp.clicks_required, 1, "默认需要1次点击")
	comp.queue_free()


func test_has_current_clicks_property():
	## 应有当前点击次数属性
	assert_true("current_clicks" in _click_component, "应有current_clicks属性")


func test_default_current_clicks_is_zero():
	## 默认点击次数为0
	assert_eq(_click_component.current_clicks, 0, "默认current_clicks应为0")


func test_has_is_clickable_property():
	## 应有是否可点击属性
	assert_true("is_clickable" in _click_component, "应有is_clickable属性")


func test_default_is_clickable():
	## 默认可点击
	assert_true(_click_component.is_clickable, "默认is_clickable应为true")


## === 点击功能测试 ===

func test_has_on_click_method():
	## 应有点击方法
	assert_true(_click_component.has_method("on_click"), "应有on_click方法")


func test_on_click_increments_counter():
	## 点击增加计数（clicks_required=3，不会立即重置）
	_click_component.on_click()
	assert_eq(_click_component.current_clicks, 1, "点击后计数应为1")


func test_on_click_does_not_increment_when_not_clickable():
	## 不可点击时不增加计数
	_click_component.is_clickable = false
	_click_component.on_click()
	assert_eq(_click_component.current_clicks, 0, "不可点击时计数不应增加")


func test_on_click_returns_true():
	## 点击返回true表示成功
	var result = _click_component.on_click()
	assert_true(result, "点击应返回true")


func test_on_click_returns_false_when_not_clickable():
	## 不可点击时返回false
	_click_component.is_clickable = false
	var result = _click_component.on_click()
	assert_false(result, "不可点击时点击应返回false")


## === 进度测试 ===

func test_has_get_progress_method():
	## 应有获取进度方法
	assert_true(_click_component.has_method("get_progress"), "应有get_progress方法")


func test_get_progress_returns_zero_initially():
	## 初始进度为0
	assert_eq(_click_component.get_progress(), 0.0, "初始进度应为0")


func test_get_progress_returns_correct_value():
	## 进度计算正确
	_click_component.current_clicks = 1
	assert_eq(_click_component.get_progress(), 1.0/3.0, "进度应为1/3")


func test_get_progress_returns_one_when_complete():
	## 完成时进度为1
	_click_component.current_clicks = 3
	assert_eq(_click_component.get_progress(), 1.0, "完成时进度应为1")


## === 完成检测测试 ===

func test_has_is_complete_method():
	## 应有完成检测方法
	assert_true(_click_component.has_method("is_complete"), "应有is_complete方法")


func test_is_complete_returns_false_initially():
	## 初始未完成
	assert_false(_click_component.is_complete(), "初始应未完成")


func test_is_complete_returns_true_when_clicks_reached():
	## 达到点击次数后完成
	_click_component.current_clicks = 3
	assert_true(_click_component.is_complete(), "达到点击次数后应完成")


## === 重置测试 ===

func test_has_reset_method():
	## 应有重置方法
	assert_true(_click_component.has_method("reset"), "应有reset方法")


func test_reset_clears_current_clicks():
	## 重置清空当前点击次数
	_click_component.current_clicks = 5
	_click_component.reset()
	assert_eq(_click_component.current_clicks, 0, "重置后current_clicks应为0")


## === 信号测试 ===

func test_has_click_signal():
	## 应有点击信号
	assert_true(_click_component.has_signal("on_clicked"), "应有on_clicked信号")


func test_has_complete_signal():
	## 应有完成信号
	assert_true(_click_component.has_signal("on_complete"), "应有on_complete信号")


func test_click_signal_emitted():
	## 点击时发出信号
	watch_signals(_click_component)
	_click_component.on_click()
	assert_signal_emitted(_click_component, "on_clicked")


func test_complete_signal_emitted():
	## 完成时发出信号
	_click_component.clicks_required = 1
	watch_signals(_click_component)
	_click_component.on_click()
	assert_signal_emitted(_click_component, "on_complete")


## === 进度变化信号测试 ===

func test_has_progress_changed_signal():
	## 应有进度变化信号
	assert_true(_click_component.has_signal("progress_changed"), "应有progress_changed信号")


func test_progress_changed_signal_emitted():
	## 进度变化时发出信号
	watch_signals(_click_component)
	_click_component.on_click()
	assert_signal_emitted(_click_component, "progress_changed")
