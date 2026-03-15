extends GutTest
## ScoreDropZone 单元测试

var ScoreDropZoneScene = load('res://scenes/score_drop_zone.tscn')
var NumberObjectScene = load('res://scenes/number_object.tscn')
var _drop_zone


func before_each():
	# 重置 GameScore
	GameScore.add_score(-GameScore.get_score())
	_drop_zone = add_child_autofree(ScoreDropZoneScene.instantiate())


func test_has_score_display():
	## 应有分数显示
	assert_not_null(_drop_zone, "应能创建实例")


func test_on_number_dropped_adds_score():
	## 数字放入时加分
	var number = autofree(NumberObjectScene.instantiate())
	number.value = 10

	_drop_zone.on_number_dropped(number)
	assert_eq(GameScore.get_score(), 10, "放入数字后应加10分")


func test_on_number_dropped_with_processed_level():
	## 加工后的数字应按倍率加分
	var number = autofree(NumberObjectScene.instantiate())
	number.value = 5
	number.processed_level = 2  # 5 × 2^2 = 20

	_drop_zone.on_number_dropped(number)
	assert_eq(GameScore.get_score(), 20, "加工等级2的数字应加20分")


func test_multiple_drops_accumulate():
	## 多次放入数字应累加
	var number1 = autofree(NumberObjectScene.instantiate())
	number1.value = 5

	var number2 = autofree(NumberObjectScene.instantiate())
	number2.value = 3
	number2.processed_level = 1  # 3 × 2 = 6

	_drop_zone.on_number_dropped(number1)
	_drop_zone.on_number_dropped(number2)
	assert_eq(GameScore.get_score(), 11, "5+6=11分")


func test_display_updates_on_score_change():
	## 分数变化时显示应更新
	await wait_idle_frames(1)

	var label = _drop_zone.find_child("ScoreLabel", true, false)
	assert_not_null(label, "应有ScoreLabel")

	# 直接修改分数
	GameScore.add_score(100)

	# 等待信号处理
	await wait_idle_frames(1)

	# 检查显示是否更新
	assert_eq(label.text, "分数: 100", "显示应更新为100")


func test_listens_to_score_changed_signal():
	## 应监听分数变化信号
	await wait_idle_frames(1)

	# 检查信号是否连接
	var connections = GameScore.score_changed.get_connections()
	var is_connected = false
	for conn in connections:
		if conn.callable.get_object() == _drop_zone:
			is_connected = true
			break

	assert_true(is_connected, "应连接到score_changed信号")


func test_external_score_change_updates_display():
	## 外部修改分数时显示应更新
	await wait_idle_frames(1)

	var label = _drop_zone.find_child("ScoreLabel", true, false)

	# 模拟外部修改（如商店购买）
	GameScore.add_score(50)
	await wait_idle_frames(1)
	assert_eq(label.text, "分数: 50", "外部修改后显示应更新")

	GameScore.add_score(-20)
	await wait_idle_frames(1)
	assert_eq(label.text, "分数: 30", "扣除后显示应更新")
