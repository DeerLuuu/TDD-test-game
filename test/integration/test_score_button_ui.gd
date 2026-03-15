extends GutTest
## UI集成测试 - 测试分数按钮场景

var ScoreButtonScene = load('res://scenes/score_button.tscn')
var _scene


func before_each():
	_scene = add_child_autofree(ScoreButtonScene.instantiate())


func test_scene_has_score_label():
	## 场景应包含分数标签
	var label = _scene.find_child('ScoreLabel', true, false)
	assert_not_null(label, "场景应包含ScoreLabel")


func test_scene_has_add_button():
	## 场景应包含添加分数按钮
	var button = _scene.find_child('AddButton', true, false)
	assert_not_null(button, "场景应包含AddButton")


func test_score_label_shows_initial_zero():
	## 分数标签初始显示0
	var label = _scene.find_child('ScoreLabel', true, false)
	assert_eq(label.text, "0", "初始分数显示应为0")


func test_clicking_button_increases_score():
	## 点击按钮分数增加
	var label = _scene.find_child('ScoreLabel', true, false)
	var button = _scene.find_child('AddButton', true, false)
	
	button.emit_signal('pressed')
	assert_eq(label.text, "1", "点击后分数显示应为1")


func test_clicking_button_multiple_times():
	## 多次点击按钮分数累加
	var label = _scene.find_child('ScoreLabel', true, false)
	var button = _scene.find_child('AddButton', true, false)
	
	for i in range(5):
		button.emit_signal('pressed')
	
	assert_eq(label.text, "5", "点击5次后分数显示应为5")
