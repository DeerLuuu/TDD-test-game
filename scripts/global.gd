extends Node
## Global - 全局单例，管理游戏状态和操作模式

## 操作模式枚举
enum OperationMode {
	CLICK,  ## 点击模式
	DRAG    ## 拖动模式
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


## 网格大小
const GRID_SIZE: int = 25


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
