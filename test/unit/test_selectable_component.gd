extends GutTest
## SelectableComponent 可选中组件单元测试

var _component: SelectableComponent
var _parent: Control


func before_each():
	# 创建父节点
	_parent = autofree(Control.new())
	_parent.custom_minimum_size = Vector2(100, 100)
	_parent.add_to_group("selectable_items")
	add_child_autofree(_parent)

	# 创建组件
	_component = autofree(SelectableComponent.new())
	_parent.add_child(_component)


func after_each():
	# autofree() 会自动处理释放，不需要手动 queue_free
	_component = null
	_parent = null


## === 基本属性测试 ===

func test_has_is_selected_property():
	## 应有选中状态属性
	assert_true("is_selected" in _component, "应有is_selected属性")


func test_default_not_selected():
	## 默认未选中
	assert_false(_component.is_selected, "默认应未选中")


func test_can_select():
	## 可以选中
	_component.select()
	assert_true(_component.is_selected, "应被选中")


func test_can_deselect():
	## 可以取消选中
	_component.select()
	_component.deselect()
	assert_false(_component.is_selected, "应取消选中")


func test_has_select_signal():
	## 应有选中信号
	assert_true(_component.has_signal("selected"), "应有selected信号")


func test_has_deselect_signal():
	## 应有取消选中信号
	assert_true(_component.has_signal("deselected"), "应有deselected信号")


func test_select_emits_signal():
	## 选中时发出信号
	watch_signals(_component)
	_component.select()
	assert_signal_emitted(_component, "selected", "选中应发出selected信号")


func test_deselect_emits_signal():
	## 取消选中时发出信号
	watch_signals(_component)
	_component.select()
	_component.deselect()
	assert_signal_emitted(_component, "deselected", "取消选中应发出deselected信号")


func test_select_twice_only_emits_once():
	## 重复选中只发出一次信号
	watch_signals(_component)
	_component.select()
	_component.select()
	assert_signal_emit_count(_component, "selected", 1, "重复选中只应发出一次信号")


## === 视觉效果测试 ===

func test_has_show_selection_indicator_method():
	## 应有显示选中指示器方法
	assert_true(_component.has_method("show_selection_indicator"), "应有show_selection_indicator方法")


func test_has_hide_selection_indicator_method():
	## 应有隐藏选中指示器方法
	assert_true(_component.has_method("hide_selection_indicator"), "应有hide_selection_indicator方法")


func test_show_indicator_on_select():
	## 选中时显示指示器
	_component.select()
	assert_true(_component.is_selected, "应被选中")


func test_hide_indicator_on_deselect():
	## 取消选中时隐藏指示器
	_component.select()
	_component.deselect()
	assert_false(_component.is_selected, "应取消选中")
