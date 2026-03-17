extends GutTest
## SpeedBooster 速度加速器单元测试

var SpeedBoosterScript = preload("res://scripts/speed_booster.gd")
var _booster


func before_each():
	_booster = autofree(SpeedBoosterScript.new())


func test_has_speed_boost_property():
	## 应有速度加成属性
	assert_true(_booster.get("speed_boost") != null, "应有speed_boost属性")


func test_default_speed_boost():
	## 默认速度加成应为50
	assert_eq(_booster.speed_boost, 50, "默认速度加成应为50")


func test_has_border_margin_property():
	## 应有边距属性
	assert_true(_booster.get("border_margin") != null, "应有border_margin属性")


func test_has_is_active_property():
	## 应有激活状态属性
	assert_true(_booster.get("is_active") != null, "应有is_active属性")


func test_has_set_active_method():
	## 应有设置激活状态的方法
	assert_true(_booster.has_method("set_active"), "应有set_active方法")


func test_has_apply_boost_method():
	## 应有应用加成的方法
	assert_true(_booster.has_method("apply_boost"), "应有apply_boost方法")


func test_has_remove_boost_method():
	## 应有移除加成的方法
	assert_true(_booster.has_method("remove_boost"), "应有remove_boost方法")


func test_can_apply_boost_to_conveyor():
	## 应能给传送带应用速度加成
	var conveyor = autofree(ConveyorBelt.new())
	conveyor.speed = 100.0
	_booster.apply_boost(conveyor)
	assert_eq(conveyor.speed, 150.0, "传送带速度应增加50")


func test_can_remove_boost_from_conveyor():
	## 应能从传送带移除速度加成
	var conveyor = autofree(ConveyorBelt.new())
	conveyor.speed = 100.0
	_booster.apply_boost(conveyor)
	_booster.remove_boost(conveyor)
	assert_eq(conveyor.speed, 100.0, "传送带速度应恢复原值")


func test_can_boost_splitter_conveyor():
	## 应能给分流器应用速度加成
	var splitter = autofree(SplitterConveyor.new())
	splitter.speed = 100.0
	_booster.apply_boost(splitter)
	assert_eq(splitter.speed, 150.0, "分流器速度应增加")


func test_can_boost_tri_splitter_conveyor():
	## 应能给三相分流器应用速度加成
	var tri_splitter = autofree(TriSplitterConveyor.new())
	tri_splitter.speed = 100.0
	_booster.apply_boost(tri_splitter)
	assert_eq(tri_splitter.speed, 150.0, "三相分流器速度应增加")


func test_speed_boost_can_be_customized():
	## 速度加成可以自定义
	_booster.speed_boost = 100.0
	var conveyor = autofree(ConveyorBelt.new())
	conveyor.speed = 100.0
	_booster.apply_boost(conveyor)
	assert_eq(conveyor.speed, 200.0, "传送带速度应增加100")
