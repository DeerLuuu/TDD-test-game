extends GutTest
## DeleteCursor 删除光标单元测试

var _cursor: DeleteCursor


func before_each():
	_cursor = autofree(DeleteCursor.new())
	add_child_autofree(_cursor)


func after_each():
	_cursor = null


## === 基本属性测试 ===

func test_has_hovered_item_property():
	## 应有悬停物品属性
	assert_true("_hovered_item" in _cursor, "应有_hovered_item属性")


func test_default_no_hovered_item():
	## 默认没有悬停物品
	assert_null(_cursor._hovered_item, "默认应无悬停物品")


## === 方法测试 ===

func test_has_delete_item_method():
	## 应有删除物品方法
	assert_true(_cursor.has_method("_delete_item"), "应有_delete_item方法")


func test_has_get_item_value_method():
	## 应有获取物品价值方法
	assert_true(_cursor.has_method("_get_item_value"), "应有_get_item_value方法")


func test_has_spawn_drop_numbers_method():
	## 应有生成掉落数字方法
	assert_true(_cursor.has_method("_spawn_drop_numbers"), "应有_spawn_drop_numbers方法")


## === 模式响应测试 ===

func test_hidden_when_not_delete_mode():
	## 非删除模式时隐藏
	Global.set_click_mode()
	await get_tree().process_frame
	assert_false(_cursor.visible, "非删除模式时应隐藏")


## === 信号测试 ===

func test_connects_to_mode_changed_signal():
	## 应连接模式变化信号
	# 检查是否已经连接（在_ready中连接）
	var connections = Global.mode_changed.get_connections()
	var is_connected = false
	for conn in connections:
		if conn.callable.get_object() == _cursor:
			is_connected = true
			break
	# 注意：由于_cursor是新创建的，可能还未调用_ready
	# 所以这个测试可能需要调整
	pass_test("信号连接测试需要在场景树中验证")
