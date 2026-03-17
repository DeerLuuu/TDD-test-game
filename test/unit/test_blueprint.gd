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
