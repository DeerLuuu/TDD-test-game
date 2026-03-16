extends GutTest
## UI集成测试 - 测试分数按钮场景生成数字

var ScoreButtonScene = load('res://scenes/score_button.tscn')
var NumberObjectScene = load('res://scenes/number_object.tscn')
var ScoreDropZoneScene = load('res://scenes/score_drop_zone.tscn')
var _button
var _drop_zone


func before_each():
	# 重置 GameScore
	GameScore.add_score(-GameScore.get_score())
	# 设置为点击模式
	Global.set_click_mode()

	_button = add_child_autofree(ScoreButtonScene.instantiate())
	_drop_zone = add_child_autofree(ScoreDropZoneScene.instantiate())


func test_scene_has_click_component():
	## 场景应包含ClickComponent
	var click_comp = _button.find_child('ClickComponent', true, false)
	assert_not_null(click_comp, "场景应包含ClickComponent")


func test_clicking_button_spawns_number():
	## 点击按钮应生成数字
	# 设置为点击模式
	Global.set_click_mode()

	# 等待一帧确保场景稳定
	await wait_idle_frames(1)

	# 统计初始数字数量
	var initial_numbers = get_tree().get_nodes_in_group("number_objects").size()

	# 获取ClickComponent并触发点击完成
	var click_comp = _button.find_child('ClickComponent', true, false)
	if click_comp:
		click_comp.on_complete.emit()

	# 等待一帧让数字生成
	await wait_idle_frames(1)

	# 检查是否有新的数字节点生成
	var new_numbers = get_tree().get_nodes_in_group("number_objects").size()
	assert_eq(new_numbers, initial_numbers + 1, "点击后应生成新数字")


func test_drop_zone_receives_number():
	## 加分面板应能接收数字
	var number = add_child_autofree(NumberObjectScene.instantiate())
	number.value = 5

	var initial_score = GameScore.get_score()
	_drop_zone.on_number_dropped(number)

	assert_eq(GameScore.get_score(), initial_score + 5, "放入数字后分数应增加")


func test_drag_drop_workflow():
	## 测试完整拖放流程
	# 1. 验证分数面板初始分数
	var initial_score = GameScore.get_score()

	# 2. 创建数字并放入
	var number = add_child_autofree(NumberObjectScene.instantiate())
	number.value = 10
	_drop_zone.on_number_dropped(number)

	# 3. 验证分数增加
	assert_eq(GameScore.get_score(), initial_score + 10, "拖放后分数应正确增加")
