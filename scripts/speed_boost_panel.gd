extends Control
## SpeedBoostPanel 加速面板
## 放置后加速范围内所有面板的自动点击器（点击频率翻倍），持续一定时间

class_name SpeedBoostPanel

## 加速持续时间（秒）
@export var duration: float = 30.0

## 加速范围（像素）
@export var boost_range: float = 200.0

## 是否为一次性
@export var is_one_time: bool = true

## 是否已触发
var _has_triggered: bool = false

## 受影响的自动点击器及其原始间隔
var _affected_auto_clickers: Array = []

## 加速计时器
var _boost_timer: float = 0.0

## 是否正在加速中
var _is_boosting: bool = false


func _ready() -> void:
	add_to_group("placeable_items")
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 检查是否为预览状态
	if has_meta("is_preview") and get_meta("is_preview"):
		return

	# 延迟触发加速，等待放置动画完成
	await get_tree().create_timer(0.1).timeout
	start_boost()


func _process(delta: float) -> void:
	if not _is_boosting:
		return

	_boost_timer += delta

	# 更新UI显示剩余时间
	_update_timer_display()

	# 检查是否有自动点击器离开了范围
	_check_auto_clickers_in_range()

	if _boost_timer >= duration:
		end_boost(_affected_auto_clickers.duplicate())
		_on_boost_complete()


func start_boost() -> void:
	## 开始加速
	if _has_triggered:
		return
	_has_triggered = true
	_is_boosting = true
	_boost_timer = 0.0

	# 查找范围内的自动点击器
	var auto_clickers = find_auto_clickers_in_range()

	if auto_clickers.is_empty():
		_on_boost_complete()
		return

	# 应用加速
	boost_auto_clickers(auto_clickers)


func find_auto_clickers_in_range() -> Array:
	## 查找范围内的所有自动点击器
	var result: Array = []

	var all_auto_clickers = get_tree().get_nodes_in_group("auto_clicker")
	var panel_center = global_position + size / 2

	for auto_clicker in all_auto_clickers:
		if not is_instance_valid(auto_clicker):
			continue
		if not auto_clicker is AutoClicker:
			continue

		# 计算自动点击器中心到面板中心的距离
		var clicker_center = auto_clicker.global_position + auto_clicker.size / 2
		var distance = panel_center.distance_to(clicker_center)

		if distance <= boost_range:
			result.append(auto_clicker)

	return result


func _check_auto_clickers_in_range() -> void:
	## 检查被加速的自动点击器是否仍在范围内，离开范围的恢复原始间隔
	var panel_center = global_position + size / 2
	var to_remove: Array = []

	for data in _affected_auto_clickers:
		if not is_instance_valid(data.clicker):
			to_remove.append(data)
			continue

		var clicker_center = data.clicker.global_position + data.clicker.size / 2
		var distance = panel_center.distance_to(clicker_center)

		# 如果离开了范围，恢复原始间隔
		if distance > boost_range:
			data.clicker.set_interval(data.original_interval)
			to_remove.append(data)

	# 从受影响列表中移除
	for data in to_remove:
		_affected_auto_clickers.erase(data)


func boost_auto_clickers(auto_clickers: Array) -> void:
	## 加速指定的自动点击器
	apply_boost(auto_clickers)


func apply_boost(auto_clickers: Array) -> void:
	## 应用加速效果（点击频率翻倍，即间隔减半）
	for auto_clicker in auto_clickers:
		if not is_instance_valid(auto_clicker):
			continue

		# 记录原始间隔
		var original_interval = auto_clicker.click_interval

		# 添加到受影响列表
		_affected_auto_clickers.append({
			"clicker": auto_clicker,
			"original_interval": original_interval
		})

		# 设置新间隔（减半）
		auto_clicker.set_interval(original_interval / 2.0)


func end_boost(auto_clickers_data: Array) -> void:
	## 结束加速效果
	_is_boosting = false

	for data in auto_clickers_data:
		if not is_instance_valid(data.clicker):
			continue

		# 恢复原始间隔
		data.clicker.set_interval(data.original_interval)

	_affected_auto_clickers.clear()


func _update_timer_display() -> void:
	## 更新计时器显示
	var timer_label = get_node_or_null("Panel/VBoxContainer/TimerLabel")
	if timer_label:
		var remaining = duration - _boost_timer
		timer_label.text = "%.1fs" % remaining


func _on_boost_complete() -> void:
	## 加速完成后的处理
	# 一次性面板完成后删除
	if is_one_time:
		queue_free()
