extends GutTest
## 分数系统测试 - TDD Red阶段
## 测试点击按钮添加分数的功能

var ScoreSystem = load('res://scripts/score_system.gd')
var _score_system


func before_each():
	_score_system = autofree(ScoreSystem.new())


func test_initial_score_should_be_zero():
	## 初始分数应该为0
	assert_eq(_score_system.get_score(), 0, "初始分数应该为0")


func test_score_should_increase_when_button_clicked():
	## 点击按钮后分数应该增加
	_score_system.on_button_pressed()
	assert_eq(_score_system.get_score(), 1, "点击一次后分数应该为1")


func test_score_should_accumulate_on_multiple_clicks():
	## 多次点击分数应该累加
	_score_system.on_button_pressed()
	_score_system.on_button_pressed()
	_score_system.on_button_pressed()
	assert_eq(_score_system.get_score(), 3, "点击三次后分数应该为3")


func test_score_should_increase_by_custom_amount():
	## 点击按钮应该可以增加指定分数
	_score_system.add_score(10)
	assert_eq(_score_system.get_score(), 10, "增加10分后分数应该为10")


func test_score_should_not_be_negative():
	## 分数不应该为负数（负数输入应被忽略）
	_score_system.add_score(-5)
	assert_true(_score_system.get_score() >= 0, "分数不应该为负数")
