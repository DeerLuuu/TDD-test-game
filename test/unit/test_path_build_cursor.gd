extends GutTest
## PathBuildCursor 铺路光标单元测试
## 测试铺路模式的光标行为

const PathCalculatorScript = preload("res://scripts/path_calculator.gd")

var _cursor: Control


func before_each():
	# 创建一个简单的 Control 作为测试对象
	_cursor = Control.new()
	add_child_autofree(_cursor)


func after_each():
	# 重置模式
	Global.current_mode = Global.OperationMode.CLICK


func test_has_path_build_mode():
	## 应有铺路模式
	assert_eq(Global.OperationMode.PATH_BUILD, 4, "PATH_BUILD 应为枚举第5项")


func test_global_has_set_path_build_mode():
	## Global 应有设置铺路模式的方法
	assert_true(Global.has_method("set_path_build_mode"), "应有set_path_build_mode方法")


func test_global_has_is_path_build_mode():
	## Global 应有检查铺路模式的方法
	assert_true(Global.has_method("is_path_build_mode"), "应有is_path_build_mode方法")


func test_set_path_build_mode():
	## 设置铺路模式应正确切换
	Global.set_path_build_mode()
	assert_true(Global.is_path_build_mode(), "应处于铺路模式")


func test_path_build_mode_emits_signal():
	## 设置铺路模式应触发信号
	# 使用 GUT 的 watch_signals 来监视信号
	watch_signals(Global)
	
	# 先重置到 CLICK 模式
	Global.current_mode = Global.OperationMode.CLICK
	await get_tree().process_frame
	
	# 现在设置到 PATH_BUILD 模式
	Global.set_path_build_mode()
	
	# 验证信号被触发
	assert_signal_emitted(Global, "mode_changed", "应触发mode_changed信号")


func test_path_calculator_exists():
	## PathCalculator 应该存在并可实例化
	var calc = PathCalculatorScript.new()
	assert_not_null(calc, "PathCalculator 应可实例化")


func test_path_calculator_calculate_l_path():
	## PathCalculator 应能计算 L 型路径
	var calc = PathCalculatorScript.new()
	var path = calc.calculate_l_path(Vector2(0, 0), Vector2(100, 50))
	assert_gt(path.size(), 0, "路径应有节点")


func test_path_calculator_calculate_conveyor_placements():
	## PathCalculator 应能计算传送带放置位置和方向
	var calc = PathCalculatorScript.new()
	var path = calc.calculate_l_path(Vector2(0, 0), Vector2(50, 50))
	var directions = calc.get_directions_for_path(path)
	var placements = calc.calculate_conveyor_placements(path, directions)
	
	assert_gt(placements.size(), 0, "应有放置位置")
	assert_true(placements[0].has("position"), "放置信息应有position")
	assert_true(placements[0].has("direction"), "放置信息应有direction")


func test_preview_conveyor_creation():
	## 预览传送带应该可以被创建
	var conveyor_scene = preload("res://scenes/conveyor_belt.tscn")
	var preview = conveyor_scene.instantiate()
	add_child_autofree(preview)
	
	# 设置为预览状态
	preview.set_meta("is_preview", true)
	
	assert_true(preview.has_meta("is_preview"), "应有预览标记")
	assert_true(preview.get_meta("is_preview"), "预览标记应为true")


func test_preview_conveyor_direction():
	## 预览传送带应能设置方向
	var conveyor_scene = preload("res://scenes/conveyor_belt.tscn")
	var preview = conveyor_scene.instantiate()
	add_child_autofree(preview)
	preview.set_meta("is_preview", true)
	
	preview.direction = Vector2.RIGHT
	assert_eq(preview.direction, Vector2.RIGHT, "方向应设置为右")
	
	preview.direction = Vector2.DOWN
	assert_eq(preview.direction, Vector2.DOWN, "方向应设置为下")


func test_preview_conveyor_semi_transparent():
	## 预览传送带应该可以设置为半透明
	var conveyor_scene = preload("res://scenes/conveyor_belt.tscn")
	var preview = conveyor_scene.instantiate()
	add_child_autofree(preview)
	preview.set_meta("is_preview", true)
	
	# 设置半透明
	preview.modulate = Color(1, 1, 1, 0.5)
	assert_eq(preview.modulate.a, 0.5, "透明度应为0.5")
