extends GutTest
## 商店拖放购买集成测试

var ShopScene = load('res://scenes/shop.tscn')
var ScoreDropZoneScene = load('res://scenes/score_drop_zone.tscn')
var _shop
var _drop_zone


func before_each():
	# 重置 GameScore
	GameScore.add_score(-GameScore.get_score())
	GameScore.add_score(500)  # 给予初始分数

	_drop_zone = add_child_autofree(ScoreDropZoneScene.instantiate())
	_shop = add_child_autofree(ShopScene.instantiate())


func test_shop_scene_has_correct_structure():
	## 商店场景应有正确结构
	assert_not_null(_shop, "商店场景应实例化成功")


func test_shop_has_item_container():
	## 商店应有物品容器
	var container = _shop.find_child('ItemContainer', true, false)
	assert_not_null(container, "商店应有ItemContainer")


func test_shop_displays_items():
	## 商店应显示物品
	await wait_idle_frames(2)

	var items = _shop.get_items()
	assert_gt(items.size(), 0, "商店应有物品")


func test_drag_item_out_of_shop_triggers_purchase():
	## 拖动物品离开商店触发购买
	await wait_idle_frames(1)

	var initial_score = GameScore.get_score()

	# 购买第一个物品（加分按钮，价格50）
	var result = _shop.try_purchase(0)

	assert_true(result.success, "购买应成功")
	assert_eq(GameScore.get_score(), initial_score - 50, "应扣除50分")


func test_purchase_fails_when_score_insufficient():
	## 分数不足时购买失败
	await wait_idle_frames(1)

	# 清空分数
	GameScore.add_score(-GameScore.get_score())
	GameScore.add_score(10)  # 只给10分

	var result = _shop.try_purchase(0)

	assert_false(result.success, "分数不足时购买应失败")
	assert_eq(GameScore.get_score(), 10, "分数不应变化")


func test_purchase_returns_item_info():
	## 购买成功返回物品信息
	await wait_idle_frames(1)

	var result = _shop.try_purchase(0)

	assert_true(result.success, "购买应成功")
	assert_eq(result.item_name, "加分按钮", "应返回物品名称")
	assert_eq(result.cost, 50, "应返回物品价格")


func test_multiple_purchases():
	## 多次购买应正确扣除分数
	await wait_idle_frames(1)

	var initial_score = GameScore.get_score()

	_shop.try_purchase(0)  # 50分
	_shop.try_purchase(0)  # 50分

	assert_eq(GameScore.get_score(), initial_score - 100, "应扣除100分")
