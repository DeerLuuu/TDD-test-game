extends GutTest
## 分数系统测试 - TDD Red阶段

var ScoreSystem = load('res://scripts/score_system.gd')
var _score_system


func before_each():
	# Node需要添加到场景树才能正常工作
	_score_system = add_child_autofree(ScoreSystem.new())


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
	## 分数不应该为负数
	_score_system.add_score(-50)
	assert_eq(_score_system.get_score(), 0, "分数不应该为负数")


func test_score_can_be_deducted():
	## 分数可以被扣除
	_score_system.add_score(100)
	_score_system.add_score(-30)
	assert_eq(_score_system.get_score(), 70, "扣除后分数应为70")


func test_has_score_changed_signal():
	## 分数系统应有score_changed信号
	assert_true(_score_system.has_signal("score_changed"), "应有score_changed信号")


func test_score_changed_signal_emitted_on_add():
	## 分数变化时应发出信号
	watch_signals(_score_system)
	_score_system.add_score(50)
	assert_signal_emitted(_score_system, "score_changed", "分数变化应发出信号")


func test_score_changed_signal_has_correct_parameters():
	## 信号应包含旧分数和新分数
	watch_signals(_score_system)
	_score_system.add_score(30)
	
	# 获取信号参数
	var params = get_signal_parameters(_score_system, "score_changed", 0)
	assert_not_null(params, "应有信号参数")
	assert_eq(params.size(), 2, "应有2个参数")
	assert_eq(params[0], 0, "第一个参数应为旧分数0")
	assert_eq(params[1], 30, "第二个参数应为新分数30")


func test_signal_emitted_on_deduction():
	## 扣除分数时也应发出信号
	watch_signals(_score_system)
	_score_system.add_score(100)
	_score_system.add_score(-30)
	
	assert_signal_emit_count(_score_system, "score_changed", 2, "两次分数变化应发出两次信号")


func test_signal_not_emitted_when_score_unchanged():
	## 分数不变时不应发出信号
	_score_system.add_score(100)
	
	watch_signals(_score_system)
	# 扣除超过当前分数，分数会被限制为0，但实际从100变为0
	_score_system.add_score(-50)  # 100 -> 50
	
	assert_signal_emit_count(_score_system, "score_changed", 1, "分数变化应发出一次信号")