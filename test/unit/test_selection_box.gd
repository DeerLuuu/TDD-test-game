extends GutTest
## SelectionBox 框选框单元测试

var _selection_box: SelectionBox


func before_each():
	_selection_box = autofree(SelectionBox.new())
	add_child_autofree(_selection_box)


func after_each():
	_selection_box = null


## === 基本属性测试 ===

func test_has_is_selecting_property():
	## 应有选中状态属性
	assert_true("is_selecting" in _selection_box, "应有is_selecting属性")


func test_default_not_selecting():
	## 默认未选中
	assert_false(_selection_box.is_selecting, "默认应未选中")


func test_has_selection_complete_signal():
	## 应有框选完成信号
	assert_true(_selection_box.has_signal("selection_complete"), "应有selection_complete信号")


func test_has_selection_update_signal():
	## 应有框选更新信号
	assert_true(_selection_box.has_signal("selection_update"), "应有selection_update信号")


## === 方法测试 ===

func test_has_start_selection_method():
	## 应有开始框选方法
	assert_true(_selection_box.has_method("start_selection"), "应有start_selection方法")


func test_has_update_selection_method():
	## 应有更新框选方法
	assert_true(_selection_box.has_method("update_selection"), "应有update_selection方法")


func test_has_end_selection_method():
	## 应有结束框选方法
	assert_true(_selection_box.has_method("end_selection"), "应有end_selection方法")


func test_start_selection_sets_selecting():
	## 开始框选设置选中状态
	_selection_box.start_selection(Vector2(100, 100))
	assert_true(_selection_box.is_selecting, "开始框选后应处于选中状态")


func test_start_selection_sets_visible():
	## 开始框选设置可见
	_selection_box.start_selection(Vector2(100, 100))
	assert_true(_selection_box.visible, "开始框选后应可见")


func test_end_selection_clears_selecting():
	## 结束框选清除选中状态
	_selection_box.start_selection(Vector2(100, 100))
	_selection_box.end_selection()
	assert_false(_selection_box.is_selecting, "结束框选后应清除选中状态")


func test_end_selection_sets_hidden():
	## 结束框选设置不可见
	_selection_box.start_selection(Vector2(100, 100))
	_selection_box.end_selection()
	assert_false(_selection_box.visible, "结束框选后应不可见")


## === 信号测试 ===

func test_end_selection_emits_signal():
	## 结束框选发出信号
	watch_signals(_selection_box)
	_selection_box.start_selection(Vector2(100, 100))
	_selection_box.end_selection()
	assert_signal_emitted(_selection_box, "selection_complete", "结束框选应发出信号")


func test_update_selection_emits_signal():
	## 更新框选发出信号
	watch_signals(_selection_box)
	_selection_box.start_selection(Vector2(100, 100))
	_selection_box.update_selection(Vector2(200, 200))
	assert_signal_emitted(_selection_box, "selection_update", "更新框选应发出信号")


## === 矩形计算测试 ===

func test_has_get_selection_rect_method():
	## 应有获取框选矩形方法
	assert_true(_selection_box.has_method("get_selection_rect"), "应有get_selection_rect方法")


func test_has_get_selection_rect_world_method():
	## 应有获取世界坐标框选矩形方法
	assert_true(_selection_box.has_method("get_selection_rect_world"), "应有get_selection_rect_world方法")
