extends GutTest
## SelectionHandler 单元测试

var SelectionHandlerScript = load('res://scripts/autoload/selection_handler.gd')
var _handler


func before_each():
	_handler = SelectionHandlerScript.new()
	add_child_autofree(_handler)
	Global.set_click_mode()
	SelectionManager.clear_selection()


func test_handler_has_required_constants():
	## 测试处理器常量
	assert_eq(_handler.LONG_PRESS_TIME, 0.15, "长按时间应为0.15秒")
	assert_eq(_handler.MIN_DRAG_DISTANCE, 10.0, "最小拖动距离应为10像素")


func test_handler_initial_state():
	## 测试处理器初始状态
	assert_false(_handler._is_box_selecting, "初始不应在框选")
	assert_false(_handler._is_dragging_selection, "初始不应在拖动")
	assert_false(_handler._clicked_empty, "初始未点击空白")
	assert_eq(_handler._drag_start_pos, Vector2.ZERO, "拖动起始位置应为零")


func test_get_selected_items_returns_array():
	## 获取选中物品应返回数组
	var items = _handler.get_selected_items()
	assert_eq(typeof(items), TYPE_ARRAY, "应返回数组")


func test_has_selection_initially_false():
	## 初始没有选中
	assert_false(_handler.has_selection(), "初始应无选中")


func test_has_selection_after_select():
	## 选中后has_selection返回true
	var mock_item = Control.new()
	mock_item.add_to_group("selectable_items")
	var selectable = SelectableComponent.new()
	mock_item.add_child(selectable)
	add_child_autofree(mock_item)

	await wait_idle_frames(1)

	SelectionManager.select_item(mock_item)
	assert_true(_handler.has_selection(), "选中后应有选中")


func test_is_dragging_number_with_number():
	## 点击数字时返回true
	var number = Control.new()
	number.add_to_group("number_objects")
	number.size = Vector2(50, 50)
	number.global_position = Vector2(100, 100)
	add_child_autofree(number)

	await wait_idle_frames(1)

	var result = _handler._is_dragging_number_or_shop_item(Vector2(125, 125))
	assert_true(result, "点击数字区域应返回true")


func test_is_dragging_number_without_number():
	## 不点击数字时返回false
	var result = _handler._is_dragging_number_or_shop_item(Vector2(500, 500))
	assert_false(result, "不点击数字应返回false")


func test_is_dragging_shop_item():
	## 点击商店物品时返回true
	var shop_item = Control.new()
	shop_item.add_to_group("shop_items")
	shop_item.size = Vector2(50, 50)
	shop_item.global_position = Vector2(100, 100)
	add_child_autofree(shop_item)

	await wait_idle_frames(1)

	var result = _handler._is_dragging_number_or_shop_item(Vector2(125, 125))
	assert_true(result, "点击商店物品应返回true")


func test_is_dragging_blueprint_false_initially():
	## 初始不在拖拽蓝图
	assert_false(_handler._is_dragging_blueprint(), "初始不应拖拽蓝图")


func test_capture_blueprint_selection_empty():
	## 空选中时捕获蓝图不做任何事
	_handler._capture_blueprint_selection()
	assert_null(BlueprintManager.get_temp_blueprint(), "空选中不应创建蓝图")


func test_click_mode_clears_selection_on_empty_click():
	## 点击模式点击空白区域清除选中
	var item = Control.new()
	item.add_to_group("selectable_items")
	var selectable = SelectableComponent.new()
	item.add_child(selectable)
	add_child_autofree(item)

	SelectionManager.select_item(item)
	assert_true(SelectionManager.has_selection(), "应已选中")

	# 模拟点击空白区域
	_handler._clicked_empty = true
	# 在点击模式下，下次点击会清除
	SelectionManager.clear_selection()
	assert_false(SelectionManager.has_selection(), "清除后应无选中")


func test_drag_mode_state():
	## 拖动模式状态测试
	Global.set_drag_mode()
	assert_true(Global.is_drag_mode(), "应为拖动模式")

	Global.set_click_mode()
	assert_true(Global.is_click_mode(), "应为点击模式")


func test_debug_mode_state():
	## 调试模式状态测试
	Global.set_debug_mode()
	assert_true(Global.is_debug_mode(), "应为调试模式")


func test_blueprint_mode_state():
	## 蓝图模式状态测试
	Global.set_blueprint_mode()
	assert_true(Global.is_blueprint_mode(), "应为蓝图模式")
