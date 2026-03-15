extends GutTest
## SelectionManager 选中管理器单元测试
## SelectionManager 是自动加载的单例，直接使用

var _item1: Control
var _item2: Control
var _component1: SelectableComponent
var _component2: SelectableComponent


func before_each():
	# 清除单例的选中状态
	SelectionManager.clear_selection()

	# 创建可选中物品1
	_item1 = Control.new()
	_item1.custom_minimum_size = Vector2(100, 100)
	_item1.global_position = Vector2(0, 0)
	_item1.add_to_group("selectable_items")
	add_child_autofree(_item1)

	_component1 = SelectableComponent.new()
	_item1.add_child(_component1)

	# 创建可选中物品2
	_item2 = Control.new()
	_item2.custom_minimum_size = Vector2(100, 100)
	_item2.global_position = Vector2(200, 0)
	_item2.add_to_group("selectable_items")
	add_child_autofree(_item2)

	_component2 = SelectableComponent.new()
	_item2.add_child(_component2)


func after_each():
	# 清除选中状态
	SelectionManager.clear_selection()
	_item1 = null
	_item2 = null
	_component1 = null
	_component2 = null


## === 基本属性测试 ===

func test_has_selected_items_property():
	## 应有选中物品列表属性
	assert_true("selected_items" in SelectionManager, "应有selected_items属性")


func test_default_no_selected_items():
	## 默认没有选中物品
	SelectionManager.clear_selection()
	assert_eq(SelectionManager.selected_items.size(), 0, "默认应无选中物品")


## === 选中方法测试 ===

func test_has_select_item_method():
	## 应有选中物品方法
	assert_true(SelectionManager.has_method("select_item"), "应有select_item方法")


func test_has_deselect_item_method():
	## 应有取消选中方法
	assert_true(SelectionManager.has_method("deselect_item"), "应有deselect_item方法")


func test_has_clear_selection_method():
	## 应有清除所有选中方法
	assert_true(SelectionManager.has_method("clear_selection"), "应有clear_selection方法")


func test_can_select_item():
	## 可以选中物品
	SelectionManager.select_item(_item1)
	assert_eq(SelectionManager.selected_items.size(), 1, "应有1个选中物品")


func test_select_item_marks_as_selected():
	## 选中物品标记为选中
	SelectionManager.select_item(_item1)
	assert_true(_component1.is_selected, "物品应被标记为选中")


func test_can_select_multiple_items():
	## 可以选中多个物品
	SelectionManager.select_item(_item1)
	SelectionManager.select_item(_item2)
	assert_eq(SelectionManager.selected_items.size(), 2, "应有2个选中物品")


func test_clear_selection_deselects_all():
	## 清除选中取消所有选中
	SelectionManager.select_item(_item1)
	SelectionManager.select_item(_item2)
	SelectionManager.clear_selection()

	assert_eq(SelectionManager.selected_items.size(), 0, "应无选中物品")
	assert_false(_component1.is_selected, "物品1应取消选中")
	assert_false(_component2.is_selected, "物品2应取消选中")


## === 框选测试 ===

func test_has_select_in_rect_method():
	## 应有框选方法
	assert_true(SelectionManager.has_method("select_in_rect"), "应有select_in_rect方法")


func test_select_in_rect_selects_items():
	## 框选选中范围内物品
	var rect = Rect2(Vector2(-50, -50), Vector2(200, 200))  # 包含item1
	SelectionManager.select_in_rect(rect)

	assert_eq(SelectionManager.selected_items.size(), 1, "应有1个选中物品")


func test_select_in_rect_multiple_items():
	## 框选选中多个物品
	var rect = Rect2(Vector2(-50, -50), Vector2(400, 200))  # 包含item1和item2
	SelectionManager.select_in_rect(rect)

	assert_eq(SelectionManager.selected_items.size(), 2, "应有2个选中物品")


## === 移动选中物品测试 ===

func test_has_move_selected_items_method():
	## 应有移动选中物品方法
	assert_true(SelectionManager.has_method("move_selected_items"), "应有move_selected_items方法")


func test_move_selected_items():
	## 移动选中物品
	SelectionManager.select_item(_item1)
	var initial_pos = _item1.global_position
	var delta = Vector2(100, 50)

	SelectionManager.move_selected_items(delta)

	assert_eq(_item1.global_position, initial_pos + delta, "物品应移动")


## === 调试所有选中物品测试 ===

func test_has_debug_selected_items_method():
	## 应有调试选中物品方法
	assert_true(SelectionManager.has_method("debug_selected_items"), "应有debug_selected_items方法")
