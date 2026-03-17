extends Control
## SpeedBooster 速度加速器
## 属于背景层，必须依附于传送带类型面板
## 自动调整大小为比父节点大border_margin*2像素
## 增加父节点的移动速度

class_name SpeedBooster

## 速度加成（像素/秒）
@export var speed_boost: float = 50.0

## 边距（每边扩展的像素数）
var _border_margin: int = 4
@export var border_margin: int:
	get:
		return _border_margin
	set(value):
		_border_margin = value
		if is_inside_tree():
			_update_size_and_position()

## 是否激活
@export var is_active: bool = true

## 原始速度（用于移除加成时恢复）
var _original_speed: float = 0.0

## 是否已应用加成
var _boost_applied: bool = false


func _ready() -> void:
	add_to_group("speed_booster")
	z_index = -1
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 检查是否为预览状态
	if has_meta("is_preview") and get_meta("is_preview"):
		return

	# 更新大小和位置
	_update_size_and_position()

	# 连接父节点的resized信号
	if get_parent():
		if get_parent().has_signal("resized"):
			if not get_parent().resized.is_connected(_update_size_and_position):
				get_parent().resized.connect(_update_size_and_position)

		# 自动应用速度加成
		apply_boost(get_parent())


func _exit_tree() -> void:
	# 退出场景树时移除速度加成
	if _boost_applied and get_parent():
		remove_boost(get_parent())


func _update_size_and_position() -> void:
	## 更新大小和位置以匹配父节点
	var parent = get_parent()
	if not parent:
		return

	# 父节点必须是Control类型
	if not parent is Control:
		return

	# 获取父节点大小
	var parent_size = parent.size
	if parent_size.x <= 0 or parent_size.y <= 0:
		parent_size = parent.custom_minimum_size

	# 如果父节点大小仍然为零，跳过更新
	if parent_size.x <= 0 or parent_size.y <= 0:
		return

	# 设置大小为父节点大小加上边距*2
	custom_minimum_size = parent_size + Vector2(_border_margin * 2, _border_margin * 2)
	size = custom_minimum_size

	# 设置位置为向左上偏移border_margin
	position = Vector2(-_border_margin, -_border_margin)


func _is_valid_conveyor(node: Node) -> bool:
	## 检查节点是否是有效的传送带类型
	return node is ConveyorBelt or node is SplitterConveyor or node is TriSplitterConveyor


func apply_boost(target: Node) -> bool:
	## 应用速度加成到目标
	if not _is_valid_conveyor(target):
		return false

	if _boost_applied:
		return false

	# 保存原始速度
	_original_speed = target.speed
	# 应用加成
	target.speed += speed_boost
	_boost_applied = true

	return true


func remove_boost(target: Node) -> bool:
	## 从目标移除速度加成
	if not _is_valid_conveyor(target):
		return false

	if not _boost_applied:
		return false

	# 恢复原始速度
	target.speed = _original_speed
	_boost_applied = false

	return true


func has_valid_parent() -> bool:
	## 检查父节点是否是有效的传送带
	return _is_valid_conveyor(get_parent())


func set_active(active: bool) -> void:
	## 设置是否激活
	is_active = active

	if not is_active and _boost_applied and get_parent():
		remove_boost(get_parent())
	elif is_active and not _boost_applied and get_parent():
		apply_boost(get_parent())
