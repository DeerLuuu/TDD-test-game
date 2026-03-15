extends GutTest
## Global单例单元测试

func before_each():
	# 重置Global状态
	Global.current_mode = Global.OperationMode.CLICK
	Global.drag_direction = Vector2.RIGHT


func test_has_operation_mode_enum():
	## 应有操作模式枚举
	assert_true("OperationMode" in Global, "应有OperationMode枚举")


func test_has_click_mode():
	## 应有点击模式
	assert_eq(Global.OperationMode.CLICK, 0, "点击模式应为0")


func test_has_drag_mode():
	## 应有拖动模式
	assert_eq(Global.OperationMode.DRAG, 1, "拖动模式应为1")


func test_has_current_mode():
	## 应有当前模式属性
	assert_true("current_mode" in Global, "应有current_mode属性")


func test_initial_mode_is_click():
	## 初始模式应为点击模式
	assert_eq(Global.current_mode, Global.OperationMode.CLICK, "初始模式应为点击模式")


func test_can_change_mode():
	## 可以切换模式
	Global.current_mode = Global.OperationMode.DRAG
	assert_eq(Global.current_mode, Global.OperationMode.DRAG, "应能切换到拖动模式")
	# 恢复
	Global.current_mode = Global.OperationMode.CLICK


func test_has_drag_direction():
	## 应有拖动方向属性
	assert_true("drag_direction" in Global, "应有drag_direction属性")


func test_initial_drag_direction_is_right():
	## 初始拖动方向应为右
	assert_eq(Global.drag_direction, Vector2.RIGHT, "初始拖动方向应为右")


func test_has_signal_mode_changed():
	## 应有模式变化信号
	assert_true(Global.has_signal("mode_changed"), "应有mode_changed信号")


func test_has_signal_direction_changed():
	## 应有方向变化信号
	assert_true(Global.has_signal("direction_changed"), "应有direction_changed信号")


## === 位置冲突检测测试 ===

func test_has_check_position_occupied_method():
	## 应有检测位置占用方法
	assert_true(Global.has_method("check_position_occupied"), "应有check_position_occupied方法")


func test_check_position_occupied_returns_false_when_empty():
	## 空位置应返回false
	var result = Global.check_position_occupied(Vector2(100, 100), Vector2(50, 50))
	assert_false(result, "空位置应返回false")


func test_check_position_occupied_returns_true_when_occupied():
	## 被占用的位置应返回true
	# 创建一个模拟物品
	var mock_item = Control.new()
	mock_item.size = Vector2(50, 50)
	mock_item.global_position = Vector2(100, 100)
	mock_item.name = "MockItem"
	add_child_autofree(mock_item)

	# 标记为可检测物品
	mock_item.add_to_group("placeable_items")

	await wait_idle_frames(1)

	var result = Global.check_position_occupied(Vector2(100, 100), Vector2(50, 50))
	assert_true(result, "被占用的位置应返回true")


func test_check_position_occupied_ignores_self():
	## 检测时应能忽略指定物品自身
	var mock_item = Control.new()
	mock_item.size = Vector2(50, 50)
	mock_item.global_position = Vector2(100, 100)
	mock_item.name = "MockItem"
	add_child_autofree(mock_item)
	mock_item.add_to_group("placeable_items")

	await wait_idle_frames(1)

	# 忽略自身时应该返回false
	var result = Global.check_position_occupied(Vector2(100, 100), Vector2(50, 50), mock_item)
	assert_false(result, "忽略自身时应返回false")


func test_check_position_occupied_respects_grid():
	## 检测应考虑网格对齐
	var mock_item = Control.new()
	mock_item.size = Vector2(50, 50)
	mock_item.global_position = Vector2(100, 100)
	mock_item.name = "MockItem"
	add_child_autofree(mock_item)
	mock_item.add_to_group("placeable_items")

	await wait_idle_frames(1)

	# 检测相近位置（网格范围内）
	var result = Global.check_position_occupied(Vector2(110, 110), Vector2(50, 50))
	assert_true(result, "相近网格位置应被检测为占用")
