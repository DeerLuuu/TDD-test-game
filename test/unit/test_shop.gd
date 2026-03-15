extends GutTest
## Shop 商店面板单元测试

var Shop = load('res://scripts/shop.gd')
var _shop


func before_each():
	_shop = autofree(Shop.new())
	# 重置 GameScore
	GameScore.add_score(-GameScore.get_score())


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
	GameScore.add_score(100)
	_shop.add_item({"name": "test_item", "cost": 50, "scene_path": "res://test.tscn"})

	var result = _shop.try_purchase(0)

	assert_true(result.success, "购买应成功，错误: %s" % result.get("error", ""))
	assert_eq(GameScore.get_score(), 50, "应扣除50分")


func test_cannot_purchase_when_not_enough_score():
	## 分数不足时无法购买
	GameScore.add_score(30)
	_shop.add_item({"name": "expensive_item", "cost": 100, "scene_path": "res://test.tscn"})

	var result = _shop.try_purchase(0)

	assert_false(result.success, "购买应失败")
	assert_eq(GameScore.get_score(), 30, "分数不应变化")


func test_purchase_returns_item_info():
	## 购买成功返回物品信息
	GameScore.add_score(100)
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


func test_has_snap_to_grid_method():
	## 应有网格对齐方法
	assert_true(_shop.has_method("snap_to_grid"), "应有snap_to_grid方法")


func test_snap_to_grid_aligns_position():
	## 网格对齐应正确工作
	# 100 / 25 = 4.0 -> round(4.0) = 4 -> 4 * 25 = 100
	var pos = Vector2(100, 100)
	var snapped = _shop.snap_to_grid(pos, 25)

	assert_eq(snapped, Vector2(100, 100), "100应对齐到100")


func test_snap_to_grid_rounds_position():
	## 网格对齐应四舍五入到最近网格
	# 105 / 25 = 4.2 -> round = 4 -> 4 * 25 = 100
	# 110 / 25 = 4.4 -> round = 4 -> 4 * 25 = 100
	var pos = Vector2(105, 110)
	var snapped = _shop.snap_to_grid(pos, 25)

	assert_eq(snapped, Vector2(100, 100), "应对齐到最近网格")


func test_snap_to_grid_exact_multiple():
	## 恰好是网格倍数的位置应保持不变
	var pos = Vector2(100, 125)  # 100 = 4*25, 125 = 5*25
	var snapped = _shop.snap_to_grid(pos, 25)

	assert_eq(snapped, Vector2(100, 125), "网格倍数应保持不变")

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
