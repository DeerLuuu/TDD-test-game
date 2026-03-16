extends GutTest
## PathCalculator L型路径计算器单元测试
## 测试两点之间的L型路径计算

const PathCalculatorScript = preload("res://scripts/path_calculator.gd")

var _calculator: RefCounted


func before_each():
	_calculator = PathCalculatorScript.new()


func test_has_calculate_l_path_method():
	## 应有计算L型路径的方法
	assert_true(_calculator.has_method("calculate_l_path"), "应有calculate_l_path方法")


func test_calculate_horizontal_path():
	## 水平直线路径
	var start = Vector2(0, 0)
	var end = Vector2(100, 0)
	var path = _calculator.calculate_l_path(start, end)
	
	# 应返回网格位置数组
	assert_not_null(path, "应返回路径")
	assert_gt(path.size(), 0, "路径应有节点")


func test_calculate_vertical_path():
	## 垂直直线路径
	var start = Vector2(0, 0)
	var end = Vector2(0, 100)
	var path = _calculator.calculate_l_path(start, end)
	
	assert_not_null(path, "应返回路径")
	assert_gt(path.size(), 0, "路径应有节点")


func test_calculate_l_shaped_path_horizontal_first():
	## L型路径（先水平后垂直）
	var start = Vector2(0, 0)
	var end = Vector2(100, 100)
	var path = _calculator.calculate_l_path(start, end)
	
	# 路径应从起点开始
	assert_eq(path[0], start, "路径应从起点开始")
	# 路径应以终点结束
	assert_eq(path[path.size() - 1], end, "路径应以终点结束")


func test_path_follows_grid():
	## 路径应遵循网格对齐
	var start = Vector2(0, 0)
	var end = Vector2(75, 50)  # 非网格对齐的终点
	var path = _calculator.calculate_l_path(start, end)
	
	# 所有路径点应该是对齐到网格的
	for point in path:
		assert_eq(fmod(point.x, Global.GRID_SIZE), 0.0, "X坐标应对齐网格")
		assert_eq(fmod(point.y, Global.GRID_SIZE), 0.0, "Y坐标应对齐网格")


func test_path_contains_intermediate_points():
	## 路径应包含中间点
	var start = Vector2(0, 0)
	var end = Vector2(100, 50)
	var path = _calculator.calculate_l_path(start, end)
	
	# 路径应包含起点、终点和中间转折点
	assert_gte(path.size(), 2, "路径应至少包含起点和终点")


func test_has_get_directions_method():
	## 应有获取方向的方法
	assert_true(_calculator.has_method("get_directions_for_path"), "应有get_directions_for_path方法")


func test_get_directions_for_horizontal_path():
	## 水平路径的方向
	var start = Vector2(0, 0)
	var end = Vector2(100, 0)
	var path = _calculator.calculate_l_path(start, end)
	var directions = _calculator.get_directions_for_path(path)
	
	# 应返回每个路段的方向
	assert_eq(directions.size(), path.size() - 1, "方向数量应为路径节点数-1")


func test_same_start_and_end_returns_empty():
	## 起点和终点相同时返回空路径
	var start = Vector2(50, 50)
	var path = _calculator.calculate_l_path(start, start)
	
	assert_eq(path.size(), 0, "起点终点相同时应返回空路径")


func test_path_with_grid_size():
	## 使用Grid Size作为步长的路径
	var start = Vector2(0, 0)
	var end = Vector2(50, 50)  # 两格距离
	var path = _calculator.calculate_l_path(start, end)
	
	# 路径步长应该是GRID_SIZE
	for i in range(path.size() - 1):
		var delta = path[i + 1] - path[i]
		var is_horizontal = absf(delta.x) > 0 and absf(delta.y) < 0.1
		var is_vertical = absf(delta.y) > 0 and absf(delta.x) < 0.1
		assert_true(is_horizontal or is_vertical, "每次只能沿一个方向移动")


func test_calculate_path_from_panels():
	## 从两个面板计算路径（面板有大小，需要计算中心点）
	var panel1_pos = Vector2(0, 0)
	var panel1_size = Vector2(50, 50)
	var panel2_pos = Vector2(150, 100)
	var panel2_size = Vector2(50, 50)
	
	var path = _calculator.calculate_path_between_panels(
		panel1_pos, panel1_size,
		panel2_pos, panel2_size
	)
	
	assert_not_null(path, "应返回路径")
	assert_gt(path.size(), 0, "路径应有节点")


func test_has_calculate_path_between_panels_method():
	## 应有计算面板间路径的方法
	assert_true(_calculator.has_method("calculate_path_between_panels"), "应有calculate_path_between_panels方法")
