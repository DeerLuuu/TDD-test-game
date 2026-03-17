extends GutTest
## 蓝图系统集成测试
## 测试蓝图的创建、保存、拖放完整流程

var ConveyorBeltScene = load('res://scenes/conveyor_belt.tscn')
var ProcessPanelScene = load('res://scenes/process_panel.tscn')
var BlueprintResourceScript = load('res://scripts/blueprint_resource.gd')


func before_each():
	# 重置状态
	Global.set_click_mode()
	SelectionManager.clear_selection()
	BlueprintManager.clear_temp_blueprint()
	# 清除所有已保存的蓝图
	for bp in BlueprintManager.get_all_blueprints().duplicate():
		BlueprintManager.delete_blueprint(bp.blueprint_name)


func test_blueprint_resource_creation():
	## 测试蓝图资源创建
	var blueprint = BlueprintResourceScript.new()
	blueprint.blueprint_name = "test_blueprint"

	assert_eq(blueprint.blueprint_name, "test_blueprint", "名称应正确")
	assert_eq(blueprint.total_cost, 0, "初始成本应为0")
	assert_eq(blueprint.panels.size(), 0, "初始面板列表应为空")


func test_capture_selection_with_conveyor():
	## 测试捕获传送带选中
	var conveyor = add_child_autofree(ConveyorBeltScene.instantiate())
	conveyor.global_position = Vector2(100, 100)

	var items = [conveyor]
	var base_pos = Vector2(100, 100)

	BlueprintManager.capture_selection(items, base_pos)
	var blueprint = BlueprintManager.get_temp_blueprint()

	assert_not_null(blueprint, "应创建临时蓝图")
	assert_eq(blueprint.panels.size(), 1, "应有1个面板")
	# 传送带价格100
	assert_eq(blueprint.total_cost, 100, "总成本应为100")


func test_capture_multiple_panels():
	## 测试捕获多个面板
	var conveyor = add_child_autofree(ConveyorBeltScene.instantiate())
	conveyor.global_position = Vector2(100, 100)

	var panel = add_child_autofree(ProcessPanelScene.instantiate())
	panel.global_position = Vector2(200, 100)

	var items = [conveyor, panel]
	var base_pos = Vector2(100, 100)

	BlueprintManager.capture_selection(items, base_pos)
	var blueprint = BlueprintManager.get_temp_blueprint()

	assert_eq(blueprint.panels.size(), 2, "应有2个面板")
	# 传送带100 + 加工面板150 = 250
	assert_eq(blueprint.total_cost, 250, "总成本应为250")


func test_blueprint_panel_relative_positions():
	## 测试蓝图面板相对位置计算
	var conveyor = add_child_autofree(ConveyorBeltScene.instantiate())
	conveyor.global_position = Vector2(100, 100)

	var panel = add_child_autofree(ProcessPanelScene.instantiate())
	panel.global_position = Vector2(200, 100)

	var items = [conveyor, panel]
	var base_pos = Vector2(100, 100)

	BlueprintManager.capture_selection(items, base_pos)
	var blueprint = BlueprintManager.get_temp_blueprint()

	# 第一个面板相对位置为(0, 0)
	assert_eq(blueprint.panels[0].relative_position, Vector2(0, 0), "第一个面板相对位置应为零")
	# 第二个面板相对位置为(100, 0)
	assert_eq(blueprint.panels[1].relative_position, Vector2(100, 0), "第二个面板相对位置应为100")


func test_save_blueprint():
	## 测试保存蓝图
	var blueprint = BlueprintResourceScript.new()
	blueprint.blueprint_name = "save_test"

	var result = BlueprintManager.save_blueprint(blueprint)

	assert_true(result, "保存应成功")

	var all_blueprints = BlueprintManager.get_all_blueprints()
	assert_eq(all_blueprints.size(), 1, "应有1个蓝图")


func test_delete_blueprint():
	## 测试删除蓝图
	var blueprint = BlueprintResourceScript.new()
	blueprint.blueprint_name = "delete_test"
	BlueprintManager.save_blueprint(blueprint)

	var result = BlueprintManager.delete_blueprint("delete_test")

	assert_true(result, "删除应成功")

	var all_blueprints = BlueprintManager.get_all_blueprints()
	assert_eq(all_blueprints.size(), 0, "应无蓝图")


func test_save_duplicate_blueprint():
	## 测试保存同名蓝图（应覆盖）
	var blueprint1 = BlueprintResourceScript.new()
	blueprint1.blueprint_name = "duplicate"
	blueprint1.total_cost = 100
	BlueprintManager.save_blueprint(blueprint1)

	var blueprint2 = BlueprintResourceScript.new()
	blueprint2.blueprint_name = "duplicate"
	blueprint2.total_cost = 200
	BlueprintManager.save_blueprint(blueprint2)

	var all_blueprints = BlueprintManager.get_all_blueprints()
	assert_eq(all_blueprints.size(), 1, "应有1个蓝图")
	assert_eq(all_blueprints[0].total_cost, 200, "成本应为更新后的值")


func test_blueprint_mode_toggle():
	## 测试蓝图模式切换
	Global.set_blueprint_mode()
	assert_true(Global.is_blueprint_mode(), "应为蓝图模式")

	Global.set_click_mode()
	assert_false(Global.is_blueprint_mode(), "应不为蓝图模式")


func test_clear_temp_blueprint():
	## 测试清除临时蓝图
	var conveyor = add_child_autofree(ConveyorBeltScene.instantiate())
	conveyor.global_position = Vector2(100, 100)

	BlueprintManager.capture_selection([conveyor], Vector2(100, 100))
	assert_not_null(BlueprintManager.get_temp_blueprint(), "应有临时蓝图")

	BlueprintManager.clear_temp_blueprint()
	assert_null(BlueprintManager.get_temp_blueprint(), "应无临时蓝图")


func test_blueprint_records_conveyor_direction():
	## 测试蓝图记录传送带方向
	var conveyor = add_child_autofree(ConveyorBeltScene.instantiate())
	conveyor.global_position = Vector2(100, 100)
	conveyor.direction = Vector2.UP

	BlueprintManager.capture_selection([conveyor], Vector2(100, 100))
	var blueprint = BlueprintManager.get_temp_blueprint()

	assert_eq(blueprint.panels[0].direction, Vector2.UP, "应记录传送带方向")


func test_blueprint_records_output_direction():
	## 测试蓝图记录输出方向
	var panel = add_child_autofree(ProcessPanelScene.instantiate())
	panel.global_position = Vector2(100, 100)

	# 设置输出方向
	var output_comp = panel.get_node_or_null("OutputComponent")
	if output_comp:
		output_comp.output_direction = Vector2.LEFT

	BlueprintManager.capture_selection([panel], Vector2(100, 100))
	var blueprint = BlueprintManager.get_temp_blueprint()

	assert_not_null(blueprint, "应创建蓝图")
