extends Control
## CollectPanel 一次性收集面板
## 放置后收集范围内所有数字，然后发送到加分面板

class_name CollectPanel

## 是否为一次性
@export var is_one_time: bool = true

## 已收集的数字
var collected_numbers: Array[NumberObject] = []

## 是否已触发
var _has_triggered: bool = false

## 收集动画持续时间
const COLLECT_DURATION: float = 0.5

## 输出组件引用
var _output_component: OutputComponent = null
var output_component: OutputComponent:
	get:
		if _output_component == null:
			_output_component = get_node_or_null("OutputComponent")
		return _output_component


func _ready() -> void:
	add_to_group("placeable_items")
	add_to_group("selectable_items")
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 检查是否为预览状态
	if has_meta("is_preview") and get_meta("is_preview"):
		return

	# 延迟触发收集，等待放置动画完成
	await get_tree().create_timer(0.1).timeout
	collect_and_send()


func collect_and_send() -> void:
	## 收集并发送数字到加分面板
	if _has_triggered:
		return
	_has_triggered = true

	# 收集范围内的数字
	collect_numbers()

	# 如果没有收集到数字，直接删除
	if collected_numbers.is_empty():
		_on_send_complete()
		return

	# 播放收集动画
	await play_collect_animation()

	# 发送到加分面板
	await send_to_drop_zone()

	# 一次性面板发送后删除
	if is_one_time:
		_on_send_complete()


func collect_numbers() -> void:
	## 收集面板范围内的所有数字
	var all_numbers = get_tree().get_nodes_in_group("number_objects")
	var panel_rect = Rect2(global_position, size)

	for number in all_numbers:
		if not is_instance_valid(number):
			continue
		if not number is NumberObject:
			continue

		# 跳过正在被拖动的数字
		if number._is_dragging:
			continue

		# 检测数字中心是否在面板范围内
		var number_center = number.global_position + number.size / 2
		if panel_rect.has_point(number_center):
			collected_numbers.append(number)
			# 禁用数字的所有输入处理，防止用户拖动
			number._is_dragging = true
			number.set_process(false)
			number.mouse_filter = Control.MOUSE_FILTER_IGNORE

func play_collect_animation() -> void:
	## 播放收集动画 - 数字先集中到面板中心区域
	if collected_numbers.is_empty():
		return

	var panel_center = global_position + size / 2

	# 第一阶段：数字集中到面板中心区域
	var gather_tween = create_tween()
	gather_tween.set_parallel(true)

	for i in collected_numbers.size():
		var number = collected_numbers[i]
		if not is_instance_valid(number):
			continue

		# 计算中心区域的随机位置（面板中心周围的小范围）
		var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		var target_pos = panel_center + offset - number.size / 2

		gather_tween.tween_property(number, "global_position", target_pos, 0.3)
		gather_tween.tween_property(number, "scale", Vector2(0.8, 0.8), 0.3)

	await gather_tween.finished

	# 短暂暂停
	await get_tree().create_timer(0.1).timeout


func send_to_drop_zone() -> void:
	## 发送收集的数字到加分面板
	if collected_numbers.is_empty():
		return

	# 获取加分面板
	var drop_zones = get_tree().get_nodes_in_group("score_drop_zone")
	if drop_zones.is_empty():
		# 没有加分面板，释放数字
		for number in collected_numbers:
			if is_instance_valid(number):
				number._is_dragging = false
				number.queue_free()
		return

	var drop_zone = drop_zones[0]
	var target_pos = drop_zone.global_position + drop_zone.size / 2

	# 计算总价值
	var total_value = 0
	for number in collected_numbers:
		if is_instance_valid(number):
			total_value += number.get_final_value()

	# 第二阶段：所有数字一起飞向加分面板
	var send_tween = create_tween()
	send_tween.set_parallel(true)
	send_tween.set_ease(Tween.EASE_IN_OUT)
	send_tween.set_trans(Tween.TRANS_QUAD)

	for number in collected_numbers:
		if not is_instance_valid(number):
			continue

		# 计算目标位置（加分面板中心附近的随机位置）
		var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		var final_pos = target_pos + offset - number.size / 2

		send_tween.tween_property(number, "global_position", final_pos, 0.5)
		send_tween.tween_property(number, "modulate:a", 0.0, 0.5)

	await send_tween.finished

	# 直接触发加分
	GameScore.add_score(total_value)

	# 释放数字并恢复标记
	for number in collected_numbers:
		if is_instance_valid(number):
			number._is_dragging = false
			number.queue_free()


func _on_send_complete() -> void:
	## 发送完成后的处理
	queue_free()
