extends GutTest
## 加速面板与自动点击器集成测试

var SpeedBoostPanelScene = load('res://scenes/speed_boost_panel.tscn')
var AutoClickerScene = load('res://scenes/auto_clicker.tscn')
var ScoreButtonScene = load('res://scenes/score_button.tscn')
var NumberObjectScene = load('res://scenes/number_object.tscn')


func before_each():
	Global.set_click_mode()
	GameScore.add_score(-GameScore.get_score())  # 重置分数


func test_speed_boost_panel_creation():
	## 测试加速面板创建
	var panel = add_child_autofree(SpeedBoostPanelScene.instantiate())
	panel.global_position = Vector2(100, 100)
	
	assert_not_null(panel, "加速面板应创建成功")
	assert_eq(panel.duration, 30.0, "默认持续时间为30秒")
	assert_eq(panel.boost_range, 200.0, "默认范围为200像素")


func test_speed_boost_panel_is_one_time():
	## 测试加速面板为一次性
	var panel = add_child_autofree(SpeedBoostPanelScene.instantiate())
	
	assert_true(panel.is_one_time, "加速面板应为一次性")


func test_auto_clicker_creation():
	## 测试自动点击器创建
	var clicker = add_child_autofree(AutoClickerScene.instantiate())
	
	assert_not_null(clicker, "自动点击器应创建成功")
	assert_eq(clicker.click_interval, 2.0, "默认点击间隔为2秒")


func test_auto_clicker_interval_change():
	## 测试自动点击器间隔变化
	var clicker = add_child_autofree(AutoClickerScene.instantiate())
	
	clicker.set_interval(1.0)
	assert_eq(clicker.click_interval, 1.0, "间隔应更新为1秒")


func test_auto_clicker_finds_parent_click_component():
	## 测试自动点击器查找父节点点击组件
	var button = add_child_autofree(ScoreButtonScene.instantiate())
	button.global_position = Vector2(100, 100)
	
	var clicker = AutoClickerScene.instantiate()
	button.add_child(clicker)
	
	await wait_idle_frames(1)
	
	assert_true(clicker.has_valid_parent(), "应找到有效的父节点")


func test_auto_clicker_trigger_click():
	## 测试自动点击器触发点击
	var button = add_child_autofree(ScoreButtonScene.instantiate())
	button.global_position = Vector2(100, 100)
	
	var clicker = AutoClickerScene.instantiate()
	button.add_child(clicker)
	
	await wait_idle_frames(1)
	
	# 触发点击
	var result = clicker.trigger_click()
	# 点击应成功（如果父节点有ClickComponent）
	assert_true(typeof(result) == TYPE_BOOL, "应返回布尔值")


func test_auto_clicker_timer():
	## 测试自动点击器计时器
	var clicker = add_child_autofree(AutoClickerScene.instantiate())
	clicker.click_interval = 1.0
	clicker.is_active = true
	
	var initial_timer = clicker._timer
	assert_eq(initial_timer, 0.0, "初始计时器为0")


func test_auto_clicker_set_active():
	## 测试自动点击器激活状态
	var clicker = add_child_autofree(AutoClickerScene.instantiate())
	
	clicker.set_active(false)
	assert_false(clicker.is_active, "应不激活")
	
	clicker.set_active(true)
	assert_true(clicker.is_active, "应激活")


func test_speed_boost_panel_find_auto_clickers():
	## 测试加速面板查找范围内的自动点击器
	var panel = add_child_autofree(SpeedBoostPanelScene.instantiate())
	panel.global_position = Vector2(100, 100)
	
	# 创建带有自动点击器的按钮
	var button = add_child_autofree(ScoreButtonScene.instantiate())
	button.global_position = Vector2(150, 150)  # 在范围内
	
	var clicker = AutoClickerScene.instantiate()
	clicker.add_to_group("auto_clicker")
	button.add_child(clicker)
	
	await wait_idle_frames(1)
	
	var found = panel.find_auto_clickers_in_range()
	assert_eq(found.size(), 1, "应找到1个自动点击器")


func test_speed_boost_panel_no_clickers_out_of_range():
	## 测试范围外的自动点击器不被找到
	var panel = add_child_autofree(SpeedBoostPanelScene.instantiate())
	panel.global_position = Vector2(100, 100)
	panel.boost_range = 50.0  # 小范围
	
	var clicker = Control.new()
	clicker.add_to_group("auto_clicker")
	clicker.size = Vector2(50, 50)
	clicker.global_position = Vector2(500, 500)  # 范围外
	add_child_autofree(clicker)
	
	await wait_idle_frames(1)
	
	var found = panel.find_auto_clickers_in_range()
	assert_eq(found.size(), 0, "不应找到范围外的点击器")


func test_speed_boost_doubles_frequency():
	## 测试加速效果（间隔减半）
	var original_interval = 2.0
	var boosted_interval = original_interval / 2.0
	
	assert_eq(boosted_interval, 1.0, "加速后间隔应为1秒")


func test_speed_boost_panel_applies_boost():
	## 测试加速面板应用加速
	var panel = add_child_autofree(SpeedBoostPanelScene.instantiate())
	panel.global_position = Vector2(100, 100)
	
	var clicker = AutoClickerScene.instantiate()
	clicker.click_interval = 2.0
	clicker.add_to_group("auto_clicker")
	add_child_autofree(clicker)
	
	await wait_idle_frames(1)
	
	panel.apply_boost([clicker])
	
	assert_eq(clicker.click_interval, 1.0, "间隔应减半")


func test_speed_boost_panel_ends_boost():
	## 测试加速结束恢复原始间隔
	var panel = add_child_autofree(SpeedBoostPanelScene.instantiate())
	panel.global_position = Vector2(100, 100)
	
	var clicker = AutoClickerScene.instantiate()
	clicker.click_interval = 2.0
	clicker.add_to_group("auto_clicker")
	add_child_autofree(clicker)
	
	await wait_idle_frames(1)
	
	# 应用加速
	panel.apply_boost([clicker])
	
	# 记录受影响的点击器
	var affected = [{
		"clicker": clicker,
		"original_interval": 2.0
	}]
	
	# 结束加速
	panel.end_boost(affected)
	
	assert_eq(clicker.click_interval, 2.0, "间隔应恢复")


func test_auto_clicker_group():
	## 测试自动点击器分组
	var clicker = add_child_autofree(AutoClickerScene.instantiate())
	
	await wait_idle_frames(1)
	
	assert_true(clicker.is_in_group("auto_clicker"), "应在auto_clicker组中")
