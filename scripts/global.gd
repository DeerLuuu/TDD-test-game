extends Node
## Global - 全局单例，管理游戏状态和操作模式

## 操作模式枚举
enum OperationMode {
	CLICK,   ## 点击模式
	DRAG,    ## 拖动模式
	DELETE,  ## 删除模式
	DEBUG    ## 调试模式
}

## 模式变化信号
signal mode_changed(old_mode: OperationMode, new_mode: OperationMode)
## 方向变化信号
signal direction_changed(old_direction: Vector2, new_direction: Vector2)

## 当前操作模式
var current_mode: OperationMode = OperationMode.CLICK:
	set(value):
		if current_mode != value:
			var old = current_mode
			current_mode = value
			mode_changed.emit(old, current_mode)

## 拖动方向（用于有朝向物品的放置方向）
var drag_direction: Vector2 = Vector2.RIGHT:
	set(value):
		if drag_direction != value:
			var old = drag_direction
			drag_direction = value
			direction_changed.emit(old, drag_direction)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## 切换到点击模式
func set_click_mode() -> void:
	current_mode = OperationMode.CLICK


## 切换到拖动模式
func set_drag_mode() -> void:
	current_mode = OperationMode.DRAG


## 切换拖动方向（顺时针）
func rotate_drag_direction() -> void:
	if drag_direction == Vector2.RIGHT:
		drag_direction = Vector2.DOWN
	elif drag_direction == Vector2.DOWN:
		drag_direction = Vector2.LEFT
	elif drag_direction == Vector2.LEFT:
		drag_direction = Vector2.UP
	else:
		drag_direction = Vector2.RIGHT


## 是否为点击模式
func is_click_mode() -> bool:
	return current_mode == OperationMode.CLICK


## 是否为拖动模式
func is_drag_mode() -> bool:
	return current_mode == OperationMode.DRAG


## 切换到删除模式
func set_delete_mode() -> void:
	current_mode = OperationMode.DELETE


## 是否为删除模式
func is_delete_mode() -> bool:
	return current_mode == OperationMode.DELETE


## 切换到调试模式
func set_debug_mode() -> void:
	current_mode = OperationMode.DEBUG


## 是否为调试模式
func is_debug_mode() -> bool:
	return current_mode == OperationMode.DEBUG


## 网格大小
const GRID_SIZE: int = 25


## 将节点对齐到网格
static func snap_node_to_grid(node: Node) -> void:
	## 将节点位置对齐到网格
	if not node:
		return

	var pos: Vector2
	if node is Control:
		pos = node.global_position
	elif node is Node2D:
		pos = node.global_position
	else:
		return

	var snapped_pos = Vector2(
		roundi(pos.x / GRID_SIZE) * GRID_SIZE,
		roundi(pos.y / GRID_SIZE) * GRID_SIZE
	)

	if node is Control:
		node.global_position = snapped_pos
	elif node is Node2D:
		node.global_position = snapped_pos


## 将位置对齐到网格并返回
static func snap_position_to_grid(pos: Vector2) -> Vector2:
	## 将位置对齐到网格并返回
	return Vector2(
		roundi(pos.x / GRID_SIZE) * GRID_SIZE,
		roundi(pos.y / GRID_SIZE) * GRID_SIZE
	)


## 获取正确的全局鼠标位置（考虑相机缩放）
static func get_scaled_global_mouse_position(viewport: Viewport) -> Vector2:
	## 考虑相机缩放的全局鼠标位置
	var mouse_pos = viewport.get_mouse_position()
	var canvas_transform = viewport.get_canvas_transform()
	return canvas_transform.affine_inverse() * mouse_pos


## 检测位置是否被占用
## position: 目标位置
## size: 物品大小
## exclude: 排除的物品（通常是自身）
func check_position_occupied(position: Vector2, size: Vector2, exclude: Control = null) -> bool:
	## 检测指定位置是否已有其他物品
	var target_rect = Rect2(position, size)

	# 获取所有可放置物品
	var items = get_tree().get_nodes_in_group("placeable_items")

	for item in items:
		if not is_instance_valid(item):
			continue
		if not item is Control:
			continue
		# 排除自身
		if exclude and item == exclude:
			continue

		# 检测矩形是否重叠
		var item_rect = Rect2(item.global_position, item.size)
		if target_rect.intersects(item_rect):
			return true

	return false


## 计算删除物品后掉落的数值（总和不超过60%）
## 返回1-10之间的随机数值组合
func calculate_drop_values(total_value: int) -> Array:
	var max_drop = int(total_value * randf_range(0.3, 0.6))

	if max_drop < 1:
		return []

	var result = []
	var remaining = max_drop

	# 随机生成1-10之间的数值，直到用完
	while remaining >= 1:
		# 随机选择1-10之间的值，但不能超过剩余值
		var max_val = mini(10, remaining)
		var val = randi_range(1, max_val)
		result.append(val)
		remaining -= val

	return result
