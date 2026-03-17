extends GutTest
## 蓝图功能单元测试

## === BlueprintResource 测试 ===

func test_blueprint_resource_can_be_created():
	## 蓝图资源应可实例化
	var blueprint = BlueprintResource.new()
	assert_not_null(blueprint, "BlueprintResource应可实例化")


func test_blueprint_resource_has_name_property():
	## 应有名称属性
	var blueprint = BlueprintResource.new()
	assert_true("blueprint_name" in blueprint, "应有blueprint_name属性")


func test_blueprint_resource_has_panels_property():
	## 应有面板数据属性
	var blueprint = BlueprintResource.new()
	assert_true("panels" in blueprint, "应有panels属性")


func test_blueprint_resource_has_total_cost_property():
	## 应有总分数属性
	var blueprint = BlueprintResource.new()
	assert_true("total_cost" in blueprint, "应有total_cost属性")


func test_blueprint_resource_has_add_panel_method():
	## 应有添加面板的方法
	var blueprint = BlueprintResource.new()
	assert_true(blueprint.has_method("add_panel"), "应有add_panel方法")


## === BlueprintManager 测试 ===

func test_blueprint_manager_exists():
	## BlueprintManager应是自动加载单例
	assert_not_null(BlueprintManager, "BlueprintManager应存在")


func test_blueprint_manager_has_save_blueprint_method():
	## 应有保存蓝图的方法
	assert_true(BlueprintManager.has_method("save_blueprint"), "应有save_blueprint方法")


func test_blueprint_manager_has_load_blueprint_method():
	## 应有加载蓝图的方法
	assert_true(BlueprintManager.has_method("load_blueprint"), "应有load_blueprint方法")


func test_blueprint_manager_has_get_all_blueprints_method():
	## 应有获取所有蓝图的方法
	assert_true(BlueprintManager.has_method("get_all_blueprints"), "应有get_all_blueprints方法")


func test_blueprint_manager_has_delete_blueprint_method():
	## 应有删除蓝图的方法
	assert_true(BlueprintManager.has_method("delete_blueprint"), "应有delete_blueprint方法")


func test_blueprint_manager_has_capture_selection_method():
	## 应有捕获选中区域的方法
	assert_true(BlueprintManager.has_method("capture_selection"), "应有capture_selection方法")


func test_blueprint_manager_has_calculate_total_cost_method():
	## 应有计算总分数的方法
	assert_true(BlueprintManager.has_method("calculate_total_cost"), "应有calculate_total_cost方法")


## === Global 蓝图模式测试 ===

func test_global_has_blueprint_mode():
	## Global应有蓝图模式
	assert_true("BLUEPRINT" in Global.OperationMode, "应有BLUEPRINT模式")


func test_global_has_set_blueprint_mode_method():
	## 应有设置蓝图模式的方法
	assert_true(Global.has_method("set_blueprint_mode"), "应有set_blueprint_mode方法")


func test_global_has_is_blueprint_mode_method():
	## 应有判断蓝图模式的方法
	assert_true(Global.has_method("is_blueprint_mode"), "应有is_blueprint_mode方法")


## === 面板蓝图保存测试 ===
## 测试各种面板是否可以被正确保存到蓝图中

func test_score_button_can_be_saved_to_blueprint():
	## ScoreButton应可被保存到蓝图
	var button = autofree(ScoreButton.new())
	button.global_position = Vector2(100, 100)
	var panel_data = BlueprintManager._capture_panel_data(button, Vector2.ZERO)
	assert_eq(panel_data.get("scene_path"), "res://scenes/score_button.tscn", "ScoreButton应返回正确场景路径")


func test_conveyor_belt_can_be_saved_to_blueprint():
	## ConveyorBelt应可被保存到蓝图
	var conveyor = autofree(ConveyorBelt.new())
	conveyor.global_position = Vector2(100, 100)
	conveyor.direction = Vector2.RIGHT
	var panel_data = BlueprintManager._capture_panel_data(conveyor, Vector2.ZERO)
	assert_eq(panel_data.get("scene_path"), "res://scenes/conveyor_belt.tscn", "ConveyorBelt应返回正确场景路径")
	assert_eq(panel_data.get("direction"), Vector2.RIGHT, "应保存方向信息")


func test_splitter_conveyor_can_be_saved_to_blueprint():
	## SplitterConveyor应可被保存到蓝图
	var splitter = autofree(SplitterConveyor.new())
	splitter.global_position = Vector2(100, 100)
	splitter.rotation_angle = 90
	var panel_data = BlueprintManager._capture_panel_data(splitter, Vector2.ZERO)
	assert_eq(panel_data.get("scene_path"), "res://scenes/splitter_conveyor.tscn", "SplitterConveyor应返回正确场景路径")
	assert_eq(panel_data.get("rotation_angle"), 90, "应保存旋转角度")


func test_tri_splitter_conveyor_can_be_saved_to_blueprint():
	## TriSplitterConveyor应可被保存到蓝图
	var tri_splitter = autofree(TriSplitterConveyor.new())
	tri_splitter.global_position = Vector2(100, 100)
	tri_splitter.debug_direction = Vector2.UP
	var panel_data = BlueprintManager._capture_panel_data(tri_splitter, Vector2.ZERO)
	assert_eq(panel_data.get("scene_path"), "res://scenes/tri_splitter_conveyor.tscn", "TriSplitterConveyor应返回正确场景路径")
	assert_eq(panel_data.get("debug_direction"), Vector2.UP, "应保存调试方向")


func test_process_panel_can_be_saved_to_blueprint():
	## ProcessPanel应可被保存到蓝图
	var panel = autofree(ProcessPanel.new())
	panel.global_position = Vector2(100, 100)
	var panel_data = BlueprintManager._capture_panel_data(panel, Vector2.ZERO)
	assert_eq(panel_data.get("scene_path"), "res://scenes/process_panel.tscn", "ProcessPanel应返回正确场景路径")


func test_addition_panel_can_be_saved_to_blueprint():
	## AdditionPanel应可被保存到蓝图
	var panel = autofree(AdditionPanel.new())
	panel.global_position = Vector2(100, 100)
	var panel_data = BlueprintManager._capture_panel_data(panel, Vector2.ZERO)
	assert_eq(panel_data.get("scene_path"), "res://scenes/addition_panel.tscn", "AdditionPanel应返回正确场景路径")


## === 附加模块跳过测试 ===

func test_auto_clicker_is_skipped_in_blueprint():
	## AutoClicker应被跳过
	var clicker = autofree(AutoClicker.new())
	var should_skip = BlueprintManager._should_skip_item(clicker)
	assert_true(should_skip, "AutoClicker应被跳过")


func test_speed_booster_is_skipped_in_blueprint():
	## SpeedBooster应被跳过
	var booster = autofree(SpeedBooster.new())
	var should_skip = BlueprintManager._should_skip_item(booster)
	assert_true(should_skip, "SpeedBooster应被跳过")


func test_collect_panel_is_skipped_in_blueprint():
	## CollectPanel应被跳过
	var panel = autofree(CollectPanel.new())
	var should_skip = BlueprintManager._should_skip_item(panel)
	assert_true(should_skip, "CollectPanel应被跳过")


func test_speed_boost_panel_is_skipped_in_blueprint():
	## SpeedBoostPanel应被跳过
	var panel = autofree(SpeedBoostPanel.new())
	var should_skip = BlueprintManager._should_skip_item(panel)
	assert_true(should_skip, "SpeedBoostPanel应被跳过")


## === 面板价格测试 ===

func test_tri_splitter_conveyor_has_cost():
	## TriSplitterConveyor应有价格
	var cost = BlueprintManager._panel_costs.get("res://scenes/tri_splitter_conveyor.tscn", 0)
	assert_gt(cost, 0, "TriSplitterConveyor应有价格")


func test_all_panels_have_costs():
	## 所有可保存的面板都应有价格
	var panel_paths = [
		"res://scenes/score_button.tscn",
		"res://scenes/conveyor_belt.tscn",
		"res://scenes/splitter_conveyor.tscn",
		"res://scenes/tri_splitter_conveyor.tscn",
		"res://scenes/process_panel.tscn",
		"res://scenes/addition_panel.tscn"
	]
	for path in panel_paths:
		assert_true(BlueprintManager._panel_costs.has(path), "%s应有价格" % path)
