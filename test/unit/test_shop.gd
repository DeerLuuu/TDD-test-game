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
