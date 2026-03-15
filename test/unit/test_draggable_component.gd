extends GutTest
## DraggableComponent 可拖动组件测试

var DraggableComponent = load('res://scripts/draggable_component.gd')
var _component
var _parent_control


func before_each():
	_parent_control = add_child_autofree(Control.new())
	_component = DraggableComponent.new()
	_parent_control.add_child(_component)
	# 重置Global模式
	Global.current_mode = Global.OperationMode.CLICK


func test_has_enabled_property():
	## 应有enabled属性
	assert_true("enabled" in _component, "应有enabled属性")


func test_default_enabled_is_true():
	## 默认启用
	assert_true(_component.enabled, "默认应启用")


func test_can_disable():
	## 可以禁用
	_component.enabled = false
	assert_false(_component.enabled, "应能禁用")


func test_drag_only_in_drag_mode():
	## 只在拖动模式下可拖动
	Global.current_mode = Global.OperationMode.CLICK
	assert_false(_component._can_drag(), "点击模式不可拖动")
	
	Global.current_mode = Global.OperationMode.DRAG
	assert_true(_component._can_drag(), "拖动模式可拖动")


func test_has_is_dragging_property():
	## 应有is_dragging属性
	assert_true("is_dragging" in _component, "应有is_dragging属性")


func test_has_drag_started_signal():
	## 应有拖动开始信号
	assert_true(_component.has_signal("drag_started"), "应有drag_started信号")


func test_has_drag_ended_signal():
	## 应有拖动结束信号
	assert_true(_component.has_signal("drag_ended"), "应有drag_ended信号")


func test_disabled_component_cannot_drag():
	## 禁用的组件不可拖动
	_component.enabled = false
	Global.current_mode = Global.OperationMode.DRAG
	assert_false(_component._can_drag(), "禁用组件不可拖动")
