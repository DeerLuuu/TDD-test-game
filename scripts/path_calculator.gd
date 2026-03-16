class_name PathCalculator extends RefCounted
## PathCalculator - 传送带路径计算器
## 计算两点之间的传送带路径
## 支持遮挡检测和智能路径选择

## 传送带大小（用于计算间距）
const CONVEYOR_SIZE: int = 50


## 计算两点之间的路径（自动判断直线或L型）
## 返回传送带中心位置数组，每个位置间隔50像素
func calculate_path(start: Vector2, end: Vector2) -> Array[Vector2]:
	var path: Array[Vector2] = []

	# 对齐到网格（25x25）
	var snapped_start = Global.snap_position_to_grid(start)
	var snapped_end = Global.snap_position_to_grid(end)

	# 起点终点相同，返回空路径
	if snapped_start == snapped_end:
		return path

	# 判断是直线还是L型
	var dx = snapped_end.x - snapped_start.x
	var dy = snapped_end.y - snapped_start.y

	if absf(dx) < 1.0:
		# 垂直直线
		path = _calculate_straight_path(snapped_start, snapped_end, true)
	elif absf(dy) < 1.0:
		# 水平直线
		path = _calculate_straight_path(snapped_start, snapped_end, false)
	else:
		# L型路径
		path = _calculate_l_path(snapped_start, snapped_end)

	return path


## 计算直线路径
func _calculate_straight_path(start: Vector2, end: Vector2, is_vertical: bool) -> Array[Vector2]:
	var path: Array[Vector2] = []

	var current = start
	var step = CONVEYOR_SIZE

	if is_vertical:
		var direction = 1 if end.y > start.y else -1
		while true:
			path.append(current)
			if absf(current.y - end.y) < 1.0:
				break
			current = Vector2(current.x, current.y + step * direction)
			if direction > 0 and current.y > end.y:
				current.y = end.y
			elif direction < 0 and current.y < end.y:
				current.y = end.y
	else:
		var direction = 1 if end.x > start.x else -1
		while true:
			path.append(current)
			if absf(current.x - end.x) < 1.0:
				break
			current = Vector2(current.x + step * direction, current.y)
			if direction > 0 and current.x > end.x:
				current.x = end.x
			elif direction < 0 and current.x < end.x:
				current.x = end.x

	return path


## 计算L型路径（指定方向）
## horizontal_first: true = 先水平后垂直，false = 先垂直后水平
func _calculate_l_path_with_direction(start: Vector2, end: Vector2, horizontal_first: bool) -> Array[Vector2]:
	var path: Array[Vector2] = []

	var dx = end.x - start.x
	var dy = end.y - start.y
	var step = CONVEYOR_SIZE

	var steps_x = absi(roundi(dx / step))
	var steps_y = absi(roundi(dy / step))
	var dir_x = 1 if dx > 0 else -1
	var dir_y = 1 if dy > 0 else -1

	if horizontal_first:
		# 先水平后垂直
		for i in range(steps_x + 1):
			var pos = Vector2(start.x + i * step * dir_x, start.y)
			path.append(Global.snap_position_to_grid(pos))
		for i in range(1, steps_y + 1):
			var pos = Vector2(end.x, start.y + i * step * dir_y)
			path.append(Global.snap_position_to_grid(pos))
	else:
		# 先垂直后水平
		for i in range(steps_y + 1):
			var pos = Vector2(start.x, start.y + i * step * dir_y)
			path.append(Global.snap_position_to_grid(pos))
		for i in range(1, steps_x + 1):
			var pos = Vector2(start.x + i * step * dir_x, end.y)
			path.append(Global.snap_position_to_grid(pos))

	return path


## 计算L型路径（智能选择遮挡较少的方向）
func _calculate_l_path(start: Vector2, end: Vector2) -> Array[Vector2]:
	var dx = end.x - start.x
	var dy = end.y - start.y
	var step = CONVEYOR_SIZE

	var steps_x = absi(roundi(dx / step))
	var steps_y = absi(roundi(dy / step))

	# 如果两个方向距离相同，默认先水平
	if steps_x >= steps_y:
		return _calculate_l_path_with_direction(start, end, true)
	else:
		return _calculate_l_path_with_direction(start, end, false)


## 计算两个面板之间的传送带路径（带遮挡检测）
## obstacle_checker: 可选的遮挡检查函数，签名为 func(Vector2, Vector2) -> bool
## 会尝试两个方向，选择遮挡较少的路径
func calculate_path_between_panels(
	panel1_pos: Vector2, panel1_size: Vector2,
	panel2_pos: Vector2, panel2_size: Vector2,
	obstacle_checker: Callable = Callable()
) -> Array[Vector2]:

	# 计算两个面板中心
	var center1 = panel1_pos + panel1_size / 2
	var center2 = panel2_pos + panel2_size / 2

	# 计算从面板边缘出发的位置
	var start_pos = _get_edge_position(center1, center2, panel1_size)
	var end_pos = _get_edge_position(center2, center1, panel2_size)

	# 对齐到网格
	start_pos = Global.snap_position_to_grid(start_pos)
	end_pos = Global.snap_position_to_grid(end_pos)

	# 判断是直线还是L型
	var dx = end_pos.x - start_pos.x
	var dy = end_pos.y - start_pos.y

	# 直线路径直接返回
	if absf(dx) < 1.0 or absf(dy) < 1.0:
		return calculate_path(start_pos, end_pos)

	# 如果没有遮挡检查函数，直接使用默认方向
	if not obstacle_checker.is_valid():
		return calculate_path(start_pos, end_pos)

	# L型路径：计算两个方向，选择遮挡较少的
	var path_horizontal_first = _calculate_l_path_with_direction(start_pos, end_pos, true)
	var path_vertical_first = _calculate_l_path_with_direction(start_pos, end_pos, false)

	var obstacles_h = _count_obstacles(path_horizontal_first, obstacle_checker)
	var obstacles_v = _count_obstacles(path_vertical_first, obstacle_checker)

	# 选择遮挡较少的路径
	if obstacles_h <= obstacles_v:
		return path_horizontal_first
	else:
		return path_vertical_first


## 计算路径上的遮挡数量
## obstacle_checker: 遮挡检查函数
func _count_obstacles(path: Array[Vector2], obstacle_checker: Callable) -> int:
	var count = 0
	var conveyor_size = Vector2(CONVEYOR_SIZE, CONVEYOR_SIZE)

	for pos in path:
		if obstacle_checker.call(pos, conveyor_size):
			count += 1

	return count


## 获取面板边缘位置（朝向目标面板）
func _get_edge_position(from_center: Vector2, to_center: Vector2, panel_size: Vector2) -> Vector2:
	var delta = to_center - from_center
	var half_size = panel_size / 2
	var conveyor_offset = CONVEYOR_SIZE

	var edge_pos: Vector2

	if absf(delta.x) >= absf(delta.y):
		if delta.x > 0:
			edge_pos = Vector2(from_center.x + half_size.x + conveyor_offset / 2, from_center.y)
		else:
			edge_pos = Vector2(from_center.x - half_size.x - conveyor_offset / 2, from_center.y)
	else:
		if delta.y > 0:
			edge_pos = Vector2(from_center.x, from_center.y + half_size.y + conveyor_offset / 2)
		else:
			edge_pos = Vector2(from_center.x, from_center.y - half_size.y - conveyor_offset / 2)

	return Global.snap_position_to_grid(edge_pos)


## 获取路径每一段的方向
func get_directions_for_path(path: Array[Vector2]) -> Array[Vector2]:
	var directions: Array[Vector2] = []

	if path.size() < 2:
		return directions

	for i in range(path.size() - 1):
		var delta = path[i + 1] - path[i]
		var direction = _calculate_direction(delta)
		directions.append(direction)

	return directions


## 从位移向量计算方向
func _calculate_direction(delta: Vector2) -> Vector2:
	if absf(delta.x) > absf(delta.y):
		if delta.x > 0:
			return Vector2.RIGHT
		else:
			return Vector2.LEFT
	else:
		if delta.y > 0:
			return Vector2.DOWN
		else:
			return Vector2.UP
	return Vector2.RIGHT


## 计算传送带位置和方向的完整信息
func calculate_conveyor_placements(path: Array[Vector2], directions: Array[Vector2]) -> Array[Dictionary]:
	var placements: Array[Dictionary] = []

	if path.size() < 2:
		return placements

	for i in range(path.size() - 1):
		placements.append({
			"position": path[i],
			"direction": directions[i]
		})

	if path.size() >= 2:
		placements.append({
			"position": path[path.size() - 1],
			"direction": directions[directions.size() - 1]
		})

	return placements


## 保留旧的 L 型路径方法以兼容测试
func calculate_l_path(start: Vector2, end: Vector2, _prefer_horizontal_first: bool = true) -> Array[Vector2]:
	return calculate_path(start, end)
