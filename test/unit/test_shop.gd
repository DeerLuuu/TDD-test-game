extends GutTest
## Shop 商店面板单元测试

var _shop


func before_each():
	_shop = autofree(Shop.new())
	# 重置 GameScore 到初始状态
	GameScore.add_score(-GameScore.get_score() + 100)


func test_get_items_returns_array():
	## get_items应返回数组
	var items = _shop.get_items()
	assert_not_null(items, "应返回物品数组")


func test_can_add_item():
	## 可以添加物品
	_shop.add_item({"name": "item1", "cost": 50, "scene_path": "res://test.tscn"})

	var items = _shop.get_items()
	assert_eq(items.size(), 1, "应有1个物品")


func test_can_purchase_item_by_index():
	## 可以通过索引购买物品
	# 初始分数已经是100
	_shop.add_item({"name": "test_item", "cost": 50, "scene_path": "res://test.tscn"})

	var result = _shop.try_purchase(0)

	assert_true(result.success, "购买应成功，错误: %s" % result.get("error", ""))
	assert_eq(GameScore.get_score(), 50, "应扣除50分")


func test_cannot_purchase_when_not_enough_score():
	## 分数不足时无法购买
	# 先把分数减到30
	GameScore.add_score(-70)
	_shop.add_item({"name": "expensive_item", "cost": 100, "scene_path": "res://test.tscn"})

	var result = _shop.try_purchase(0)

	assert_false(result.success, "购买应失败")
	assert_eq(GameScore.get_score(), 30, "分数不应变化")


func test_purchase_returns_item_info():
	## 购买成功返回物品信息
	# 初始分数已经是100
	_shop.add_item({
		"name": "score_button",
		"cost": 50,
		"scene_path": "res://scenes/score_button.tscn"
	})

	var result = _shop.try_purchase(0)
	assert_true(result.success, "购买应成功")
	assert_eq(result.item_name, "score_button", "应返回物品名称")


func test_item_has_level_property():
	## 物品数据应有level属性
	_shop.add_item({
		"name": "test_item",
		"cost": 50,
		"scene_path": "res://test.tscn",
		"level": 2
	})

	var items = _shop.get_items()
	assert_eq(items[0].get("level", 1), 2, "物品应有level属性")


func test_global_has_snap_position_to_grid():
	## Global应有网格对齐方法
	assert_true(Global.has_method("snap_position_to_grid"), "Global应有snap_position_to_grid方法")


func test_snap_to_grid_aligns_position():
	## 网格对齐应正确工作
	# 100 / 50 = 2.0 -> round(2.0) = 2 -> 2 * 50 = 100
	var pos = Vector2(100, 100)
	@warning_ignore("static_called_on_instance", "shadowed_global_identifier")
	var snapped = Global.snap_position_to_grid(pos)

	assert_eq(snapped, Vector2(100, 100), "100应对齐到100")


func test_snap_to_grid_rounds_position():
	## 网格对齐应四舍五入到最近网格
	# 120 / 50 = 2.4 -> round = 2 -> 2 * 50 = 100
	# 130 / 50 = 2.6 -> round = 3 -> 3 * 50 = 150
	var pos = Vector2(120, 130)
	@warning_ignore("static_called_on_instance", "shadowed_global_identifier")
	var snapped = Global.snap_position_to_grid(pos)

	assert_eq(snapped, Vector2(100, 150), "应对齐到最近网格")


func test_snap_to_grid_exact_multiple():
	## 恰好是网格倍数的位置应保持不变
	var pos = Vector2(100, 150)  # 100 = 2*50, 150 = 3*50
	@warning_ignore("static_called_on_instance", "shadowed_global_identifier")
	var snapped = Global.snap_position_to_grid(pos)

	assert_eq(snapped, Vector2(100, 150), "网格倍数应保持不变")

func test_default_level_is_2():
	## 默认层级应为2（正常按钮与面板）
	GameScore.add_score(100)
	_shop.add_item({
		"name": "test_item",
		"cost": 50,
		"scene_path": "res://scenes/score_button.tscn"
	})

	var result = _shop.try_purchase(0)
	# 如果没有指定level，应该返回默认值2
	assert_eq(result.get("level", 2), 2, "默认层级应为2")


func test_default_items_have_category():
	## 默认商品应有分类属性
	_shop._setup_default_items()
	var items = _shop.get_items()
	assert_true(items.size() > 0, "应有默认商品")
	for item in items:
		assert_true(item.has("category"), "商品应有category属性: %s" % item.get("name", "unknown"))


func test_category_enum_exists():
	## Category枚举应存在
	assert_true(Shop.Category.ALL == 0, "Category.ALL应为0")
	assert_true(Shop.Category.PROCESS == 1, "Category.PROCESS应为1")
	assert_true(Shop.Category.SKILL == 2, "Category.SKILL应为2")
	assert_true(Shop.Category.MODULE == 3, "Category.MODULE应为3")
	assert_true(Shop.Category.TRANSPORT == 4, "Category.TRANSPORT应为4")


func test_set_category_method_exists():
	## 应有设置分类的方法
	assert_true(_shop.has_method("_set_category"), "应有_set_category方法")


func test_category_names_constant_exists():
	## CATEGORY_NAMES常量应存在
	assert_not_null(Shop.CATEGORY_NAMES, "CATEGORY_NAMES应存在")
	assert_eq(Shop.CATEGORY_NAMES[Shop.Category.ALL], "全部", "ALL分类名称应为'全部'")
	assert_eq(Shop.CATEGORY_NAMES[Shop.Category.PROCESS], "加工", "PROCESS分类名称应为'加工'")
	assert_eq(Shop.CATEGORY_NAMES[Shop.Category.SKILL], "技能", "SKILL分类名称应为'技能'")
	assert_eq(Shop.CATEGORY_NAMES[Shop.Category.MODULE], "模块", "MODULE分类名称应为'模块'")
	assert_eq(Shop.CATEGORY_NAMES[Shop.Category.TRANSPORT], "运输", "TRANSPORT分类名称应为'运输'")
