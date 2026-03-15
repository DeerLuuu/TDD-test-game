extends GutTest
## DebugCursor 调试光标单元测试

var _cursor: DebugCursor
var _parent: Control
var _component: OutputComponent


func before_each():
	# 创建带有OutputComponent的父节点
	_parent = autofree(Control.new())
	_parent.custom_minimum_size = Vector2(100, 100)
	_parent.global_position = Vector2(100, 100)
	_parent.add_to_group("placeable_items")
	add_child_autofree(_parent)

	_component = autofree(OutputComponent.new())
	_parent.add_child(_component)

	# 创建调试光标
	_cursor = autofree(DebugCursor.new())
	add_child_autofree(_cursor)

	# 重置全局状态
	Global.set_click_mode()


func after_each():
	if _cursor:
		_cursor.queue_free()
	if _component:
		_component.queue_free()
	if _parent:
		_parent.queue_free()


## === 基本属性测试 ===

func test_cursor_has_background():
	## 光标应有背景
	assert_not_null(_cursor._background, "应有背景")


func test_cursor_default_invisible():
	## 默认不可见
	assert_false(_cursor.visible, "默认应不可见")


func test_cursor_visible_in_debug_mode():
	## 调试模式下可见
	Global.set_debug_mode()
	await wait_idle_frames(1)
	assert_true(_cursor.visible, "调试模式下应可见")


## === 悬停检测测试 ===

func test_has_hovered_item_property():
	## 应有悬停物品属性
	assert_true("_hovered_item" in _cursor, "应有_hovered_item属性")


func test_default_no_hovered_item():
	## 默认没有悬停物品
	assert_null(_cursor._hovered_item, "默认应无悬停物品")


func test_has_get_output_component_method():
	## 应有获取OutputComponent的方法
	assert_true(_cursor.has_method("_get_output_component"), "应有_get_output_component方法")


func test_get_output_component_finds_component():
	## 能找到OutputComponent
	var found = _cursor._get_output_component(_parent)
	assert_eq(found, _component, "应找到OutputComponent")


## === 拖动测试 ===

func test_has_dragging_item_property():
	## 应有拖动物品属性
	assert_true("_dragging_item" in _cursor, "应有_dragging_item属性")


func test_default_not_dragging():
	## 默认不在拖动
	assert_null(_cursor._dragging_item, "默认不应在拖动")


func test_has_drag_start_pos_property():
	## 应有拖动起始位置属性
	assert_true("_drag_start_pos" in _cursor, "应有_drag_start_pos属性")
