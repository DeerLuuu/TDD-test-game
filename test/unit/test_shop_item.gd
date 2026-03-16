extends GutTest
## ShopItem 商店物品单元测试

var ShopItemScene = load('res://scenes/shop_item.tscn')
var _item


func before_each():
	_item = add_child_autofree(ShopItemScene.instantiate())
	# 重置 GameScore 到初始状态
	GameScore.add_score(-GameScore.get_score() + 100)


func test_initial_name_is_set():
	## 初始名称应可设置
	_item.item_name = "测试物品"
	assert_eq(_item.item_name, "测试物品", "名称应正确设置")


func test_initial_cost_is_set():
	## 初始价格应可设置
	_item.cost = 100
	assert_eq(_item.cost, 100, "价格应正确设置")


func test_initial_scene_is_set():
	## 初始场景路径应可设置
	_item.scene_path = "res://test.tscn"
	assert_eq(_item.scene_path, "res://test.tscn", "场景路径应正确设置")


func test_can_afford_returns_true_when_enough_score():
	## 分数足够时can_afford返回true
	# 初始分数已经是100

	assert_true(_item.can_afford(GameScore.get_score()), "分数足够应返回true")


func test_can_afford_returns_false_when_not_enough_score():
	## 分数不足时can_afford返回false
	# 先把分数减到50
	GameScore.add_score(-50)
	_item.cost = 100

	assert_false(_item.can_afford(GameScore.get_score()), "分数不足应返回false")


func test_purchase_deducts_score():
	## 购买扣除分数
	# 初始分数已经是100
	_item.cost = 50

	var result = _item.purchase(GameScore.get_score())

	assert_true(result.success, "购买应成功")
	assert_eq(result.remaining_score, 50, "应扣除50分")


func test_has_drag_preview_method():
	## 应有创建拖拽预览的方法
	assert_true(_item.has_method("_create_drag_preview"), "应有创建预览方法")


func test_drag_preview_created_when_dragging():
	## 拖拽时应创建预览
	await wait_idle_frames(1)

	# 模拟开始拖拽
	_item._start_drag()
	await wait_idle_frames(1)

	# 检查是否有预览节点
	var preview = _item.get_drag_preview()
	assert_not_null(preview, "拖拽时应创建预览")


func test_drag_preview_is_scene_instance():
	## 预览应是对应场景的实例
	await wait_idle_frames(1)

	_item.scene_path = "res://scenes/number_object.tscn"
	_item._start_drag()
	await wait_idle_frames(1)

	var preview = _item.get_drag_preview()
	assert_not_null(preview, "应创建预览")
	# 预览应该是NumberObject类型
	assert_true(preview is NumberObject or preview.get_child_count() > 0, "预览应是对应场景的实例")


func test_drag_preview_is_translucent():
	## 预览应是半透明的
	await wait_idle_frames(1)

	_item.scene_path = "res://scenes/number_object.tscn"
	_item._start_drag()
	await wait_idle_frames(1)

	var preview = _item.get_drag_preview()
	if preview:
		# 预览透明度应在0.5-0.9之间
		assert_true(preview.modulate.a > 0.5 and preview.modulate.a < 0.9, "预览应半透明")


func test_drag_preview_fallback_when_no_scene():
	## 无场景路径时使用默认样式预览
	await wait_idle_frames(1)

	_item.scene_path = ""
	_item._start_drag()
	await wait_idle_frames(1)

	var preview = _item.get_drag_preview()
	assert_not_null(preview, "无场景时应有默认预览")


func test_drag_preview_removed_after_drop():
	## 放下后预览应消失
	await wait_idle_frames(1)

	_item._start_drag()
	await wait_idle_frames(1)

	_item._end_drag()
	await wait_idle_frames(1)

	# 预览应被删除
	assert_true(_item._preview == null, "放下后预览应消失")
