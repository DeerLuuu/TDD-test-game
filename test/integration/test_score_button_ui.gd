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

	_button = add_child_autofree(ScoreButtonScene.instantiate())
	_drop_zone = add_child_autofree(ScoreDropZoneScene.instantiate())


func test_scene_has_add_button():
	## 场景应包含生成按钮
	var button = _button.find_child('AddButton', true, false)
	assert_not_null(button, "场景应包含AddButton")


func test_clicking_button_spawns_number():
	## 点击按钮应生成数字
	var initial_child_count = get_tree().current_scene.get_child_count()

	_button.find_child('AddButton', true, false).emit_signal('pressed')

	# 等待一帧让数字生成
	await wait_idle_frames(1)

	# 检查是否有新的数字节点生成
	var new_child_count = get_tree().current_scene.get_child_count()
	assert_gt(new_child_count, initial_child_count, "点击后应生成新数字")


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
