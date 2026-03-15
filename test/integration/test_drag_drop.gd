extends GutTest
## 拖放集成测试

var NumberObjectScene = load('res://scenes/number_object.tscn')
var ScoreDropZoneScene = load('res://scenes/score_drop_zone.tscn')
var _number
var _drop_zone


func before_each():
	# 重置 GameScore
	GameScore.add_score(-GameScore.get_score())

	_number = add_child_autofree(NumberObjectScene.instantiate())
	_drop_zone = add_child_autofree(ScoreDropZoneScene.instantiate())


func test_number_scene_has_correct_structure():
	## 数字场景应有正确结构
	assert_not_null(_number, "数字场景应实例化成功")
	var label = _number.find_child('Label', true, false)
	assert_not_null(label, "应有Label节点")


func test_drop_zone_scene_has_correct_structure():
	## 加分面板场景应有正确结构
	assert_not_null(_drop_zone, "加分面板应实例化成功")
	var label = _drop_zone.find_child('ScoreLabel', true, false)
	assert_not_null(label, "应有ScoreLabel节点")


func test_drop_zone_receives_number():
	## 加分面板应能接收数字并加分
	_number.value = 10

	var initial_score = GameScore.get_score()
	_drop_zone.on_number_dropped(_number)

	assert_eq(GameScore.get_score(), initial_score + 10, "放入数字后分数应增加")


func test_number_get_final_value_calculation():
	## 数字最终分值计算
	_number.value = 5
	_number.processed_level = 2  # 5 × 2^2 = 20

	assert_eq(_number.get_final_value(), 20, "最终分值应为20")
