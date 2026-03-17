extends Node
## BlueprintManager - 蓝图管理器
## 管理蓝图的保存、加载、删除
## 自动加载单例

## 蓝图保存路径
const BLUEPRINT_SAVE_PATH = "user://blueprints/"

## 蓝图列表变化信号
signal blueprints_changed()

## 所有蓝图
var _blueprints: Array[BlueprintResource] = []

## 当前临时捕获的蓝图数据
var _temp_blueprint: BlueprintResource = null

## 面板价格映射
var _panel_costs: Dictionary = {
	"res://scenes/score_button.tscn": 50,
	"res://scenes/conveyor_belt.tscn": 100,
	"res://scenes/splitter_conveyor.tscn": 150,
	"res://scenes/tri_splitter_conveyor.tscn": 200,
	"res://scenes/process_panel.tscn": 150,
	"res://scenes/addition_panel.tscn": 120,
	"res://scenes/auto_clicker.tscn": 200
}


func _ready() -> void:
	# 确保保存目录存在
	_ensure_save_directory()
	# 加载所有蓝图
	_load_all_blueprints()


func _ensure_save_directory() -> void:
	## 确保保存目录存在
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("blueprints"):
		dir.make_dir("blueprints")


func _load_all_blueprints() -> void:
	## 加载所有蓝图
	_blueprints.clear()
	var dir = DirAccess.open(BLUEPRINT_SAVE_PATH)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var blueprint = load(BLUEPRINT_SAVE_PATH + file_name)
			if blueprint and blueprint is BlueprintResource:
				_blueprints.append(blueprint)
		file_name = dir.get_next()
	dir.list_dir_end()


func save_blueprint(blueprint: BlueprintResource) -> bool:
	## 保存蓝图到文件
	if not blueprint or blueprint.blueprint_name.is_empty():
		return false

	# 生成文件名
	var file_name = blueprint.blueprint_name.validate_filename()
	if file_name.is_empty():
		file_name = "blueprint_" + str(Time.get_ticks_msec())

	var save_path = BLUEPRINT_SAVE_PATH + file_name + ".tres"

	# 保存资源
	var result = ResourceSaver.save(blueprint, save_path)
	if result == OK:
		# 更新列表
		var existing_index = -1
		for i in _blueprints.size():
			if _blueprints[i].blueprint_name == blueprint.blueprint_name:
				existing_index = i
				break

		if existing_index >= 0:
			_blueprints[existing_index] = blueprint
		else:
			_blueprints.append(blueprint)

		blueprints_changed.emit()
		return true

	return false


func load_blueprint(blueprint_name: String) -> BlueprintResource:
	## 加载指定名称的蓝图
	for blueprint in _blueprints:
		if blueprint.blueprint_name == blueprint_name:
			return blueprint
	return null


func delete_blueprint(blueprint_name: String) -> bool:
	## 删除指定名称的蓝图
	var file_name = blueprint_name.validate_filename()
	var file_path = BLUEPRINT_SAVE_PATH + file_name + ".tres"

	var dir = DirAccess.open(BLUEPRINT_SAVE_PATH)
	if dir and dir.file_exists(file_name + ".tres"):
		var result = dir.remove(file_name + ".tres")
		if result == OK:
			# 从列表中移除
			for i in _blueprints.size():
				if _blueprints[i].blueprint_name == blueprint_name:
					_blueprints.remove_at(i)
					break
			blueprints_changed.emit()
			return true

	return false


func get_all_blueprints() -> Array[BlueprintResource]:
	## 获取所有蓝图
	return _blueprints


func capture_selection(selected_items: Array, base_position: Vector2) -> BlueprintResource:
	## 捕获选中区域内的面板数据
	_temp_blueprint = BlueprintResource.new()
	_temp_blueprint.clear_panels()

	for item in selected_items:
		if not is_instance_valid(item):
			continue
		if not item is Control:
			continue

		# 跳过不需要记录的面板类型
		if _should_skip_item(item):
			continue

		var panel_data = _capture_panel_data(item, base_position)
		if not panel_data.is_empty():
			_temp_blueprint.add_panel(panel_data)

	# 计算总分数
	_temp_blueprint.total_cost = calculate_total_cost(_temp_blueprint.panels)

	return _temp_blueprint


func _should_skip_item(item: Control) -> bool:
	## 判断是否应该跳过该面板
	# 跳过技能类面板
	if item is CollectPanel or item is SpeedBoostPanel:
		return true
	# 跳过附加模块（AutoClicker和SpeedBooster依附于父节点）
	if item is AutoClicker or item is SpeedBooster:
		return true
	# 跳过加分面板
	if item.is_in_group("score_drop_zone"):
		return true
	# 跳过数字对象
	if item is NumberObject:
		return true

	return false


func _capture_panel_data(item: Control, base_position: Vector2) -> Dictionary:
	## 捕获单个面板的数据
	var panel_data = {}

	# 获取场景路径
	var scene_path = _get_scene_path(item)
	if scene_path.is_empty():
		return {}

	panel_data["scene_path"] = scene_path
	panel_data["relative_position"] = item.global_position - base_position

	# 获取方向信息（用于传送带）
	if item is ConveyorBelt:
		panel_data["direction"] = item.direction

	# 获取旋转角度（用于分流器）
	if item is SplitterConveyor:
		panel_data["rotation_angle"] = item.rotation_angle

	# 获取调试方向（用于三相分流器）
	if item is TriSplitterConveyor:
		panel_data["debug_direction"] = item.debug_direction

	# 获取输出组件的方向
	var output_comp = _get_output_component(item)
	if output_comp:
		panel_data["output_direction"] = output_comp.output_direction

	return panel_data


func _get_scene_path(item: Control) -> String:
	## 获取面板的场景路径
	# 根据类型判断场景路径
	if item is ScoreButton:
		return "res://scenes/score_button.tscn"
	if item is TriSplitterConveyor:
		return "res://scenes/tri_splitter_conveyor.tscn"
	if item is SplitterConveyor:
		return "res://scenes/splitter_conveyor.tscn"
	if item is ConveyorBelt:
		return "res://scenes/conveyor_belt.tscn"
	if item is ProcessPanel:
		return "res://scenes/process_panel.tscn"
	if item is AdditionPanel:
		return "res://scenes/addition_panel.tscn"

	return ""


func _get_output_component(item: Control) -> OutputComponent:
	## 获取面板的输出组件
	for child in item.get_children():
		if child is OutputComponent:
			return child
	return null


func calculate_total_cost(panels: Array) -> int:
	## 计算面板列表的总分数
	var total = 0
	for panel_data in panels:
		var scene_path = panel_data.get("scene_path", "")
		if _panel_costs.has(scene_path):
			total += _panel_costs[scene_path]
	return total


func get_temp_blueprint() -> BlueprintResource:
	## 获取临时捕获的蓝图
	return _temp_blueprint


func clear_temp_blueprint() -> void:
	## 清空临时蓝图
	_temp_blueprint = null


func spawn_blueprint(blueprint: BlueprintResource, spawn_position: Vector2, deduct_score: bool = true) -> bool:
	## 在指定位置生成蓝图中的所有面板
	if not blueprint or blueprint.panels.is_empty():
		return false

	# 检查分数是否足够
	if deduct_score:
		var current_score = GameScore.get_score()
		if current_score < blueprint.total_cost:
			return false

	# 生成所有面板
	for panel_data in blueprint.panels:
		_spawn_panel(panel_data, spawn_position)

	# 扣除分数
	if deduct_score:
		GameScore.add_score(-blueprint.total_cost)

	return true


func _spawn_panel(panel_data: Dictionary, base_position: Vector2) -> void:
	## 生成单个面板
	var scene_path = panel_data.get("scene_path", "")
	if scene_path.is_empty():
		return

	var scene = load(scene_path)
	if not scene:
		return

	var instance = scene.instantiate()
	if not instance:
		return

	# 获取层级
	var level = 2  # 默认Level2
	if scene_path == "res://scenes/auto_clicker.tscn":
		# AutoClicker特殊处理，需要找到目标面板
		# 暂时跳过AutoClicker
		instance.queue_free()
		return

	# 添加到场景
	var parent = Global.get_level_parent(level)
	if parent:
		parent.add_child(instance)
	else:
		var scene_root = get_tree().current_scene if get_tree().current_scene else get_tree().root
		scene_root.add_child(instance)

	# 设置位置
	var relative_pos = panel_data.get("relative_position", Vector2.ZERO)
	instance.global_position = base_position + relative_pos

	# 设置方向（传送带）
	if instance is ConveyorBelt and panel_data.has("direction"):
		instance.direction = panel_data["direction"]

	# 设置旋转角度（分流器）
	if instance is SplitterConveyor and not instance is TriSplitterConveyor:
		if panel_data.has("rotation_angle"):
			instance.rotation_angle = panel_data["rotation_angle"]
			instance._update_directions()
			instance._update_arrow_layout()
			instance._update_arrow_textures()

	# 设置调试方向（三相分流器）
	if instance is TriSplitterConveyor and panel_data.has("debug_direction"):
		instance.set_debug_direction(panel_data["debug_direction"])

	# 设置输出方向
	if panel_data.has("output_direction"):
		var output_comp = _get_output_component(instance)
		if output_comp:
			output_comp.set_output_direction(panel_data["output_direction"])

	# 添加到可放置物品组
	instance.add_to_group("placeable_items")
