extends Control
## AutoClicker 自动点击面板
## 属于背景层，必须依附于带有ClickComponent的面板
## 自动调整大小为比父节点大border_margin*2像素
## 自动触发父节点的ClickComponent点击

class_name AutoClicker

## 点击间隔（秒）
@export var click_interval: float = 2.0

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

## 计时器
var _timer: float = 0.0

## 点击组件引用
var _parent_click_component: ClickComponent = null


func _ready() -> void:
	add_to_group("auto_clicker")
	z_index = -1
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 检查是否为预览状态
	if has_meta("is_preview") and get_meta("is_preview"):
		return

	# 获取父节点的ClickComponent
	_get_parent_click_component()

	# 更新大小和位置
	_update_size_and_position()

	# 连接父节点的resized信号
	if get_parent():
		if get_parent().has_signal("resized"):
			if not get_parent().resized.is_connected(_update_size_and_position):
				get_parent().resized.connect(_update_size_and_position)


func _process(delta: float) -> void:
	if not is_active:
		return

	_timer += delta

	if _timer >= click_interval:
		_timer = 0.0
		trigger_click()


func _get_parent_click_component() -> void:
	## 获取父节点的ClickComponent
	var parent = get_parent()
	if not parent:
		return

	for child in parent.get_children():
		if child is ClickComponent:
			_parent_click_component = child
			return


func _update_size_and_position() -> void:
	## 更新大小和位置以匹配父节点
	var parent = get_parent()
	if not parent:
		return

	# 父节点必须是Control类型
	if not parent is Control:
		return

	# 获取父节点大小（优先使用size，其次使用custom_minimum_size）
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


func trigger_click() -> bool:
	## 触发父节点的ClickComponent点击
	if not _parent_click_component:
		_get_parent_click_component()

	if not _parent_click_component:
		return false

	# 触发点击
	return _parent_click_component.on_click()


func has_valid_parent() -> bool:
	## 检查父节点是否有有效的ClickComponent
	if not _parent_click_component:
		_get_parent_click_component()
	return _parent_click_component != null


func set_interval(new_interval: float) -> void:
	## 设置点击间隔
	click_interval = new_interval


func set_active(active: bool) -> void:
	## 设置是否激活
	is_active = active
	if not active:
		_timer = 0.0
