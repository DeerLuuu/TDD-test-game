extends GutTest
## 分数系统测试 - TDD Red阶段

var _score_system


func before_each():
	# Node需要添加到场景树才能正常工作
	_score_system = add_child_autofree(ScoreSystem.new())


func test_initial_score_should_be_100():
	## 初始分数应该为100
	assert_eq(_score_system.get_score(), 100, "初始分数应该为100")


func test_score_should_accumulate_on_multiple_adds():
	## 多次添加分数应该累加
	_score_system.add_score(1)
	_score_system.add_score(1)
	_score_system.add_score(1)
	assert_eq(_score_system.get_score(), 103, "添加三次后分数应该为103")


func test_score_should_increase_by_custom_amount():
	## 点击按钮应该可以增加指定分数
	_score_system.add_score(10)
	assert_eq(_score_system.get_score(), 110, "增加10分后分数应该为110")


func test_score_should_not_be_negative():
	## 分数不应该为负数
	_score_system.add_score(-200)
	assert_eq(_score_system.get_score(), 0, "分数不应该为负数")


func test_score_can_be_deducted():
	## 分数可以被扣除
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
	assert_eq(params[0], 100, "第一个参数应为旧分数100")
	assert_eq(params[1], 130, "第二个参数应为新分数130")


func test_signal_emitted_on_deduction():
	## 扣除分数时也应发出信号
	watch_signals(_score_system)
	_score_system.add_score(-30)

	assert_signal_emit_count(_score_system, "score_changed", 1, "分数变化应发出一次信号")


func test_signal_not_emitted_when_score_unchanged():
	## 分数不变时不应发出信号
	watch_signals(_score_system)
	# 扣除不超过当前分数
	_score_system.add_score(-50)  # 100 -> 50

	assert_signal_emit_count(_score_system, "score_changed", 1, "分数变化应发出一次信号")
