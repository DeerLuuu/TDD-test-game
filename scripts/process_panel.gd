extends Control
## 加工面板 - 接收数字，点击加工后提升数字等级
## 使用ClickComponent处理点击计数逻辑
class_name ProcessPanel

## 当前正在加工的数字
var current_number: NumberObject = null

## 是否正在加工
var processing: bool = false

## 等待队列
var waiting_queue: Array = []

## 最近加工完成的数字（防止被重新检测）
var _recently_completed: NumberObject = null

## 正在移动输出数字
var _is_moving_output: bool = false

## 进度条引用
@onready var progress_bar: ProgressBar = get_node_or_null("VBoxContainer/ProgressBar")

## 点击提示标签
@onready var click_label: Label = get_node_or_null("VBoxContainer/ClickLabel")

## 输出组件引用
var _output_component: OutputComponent = null
var output_component: OutputComponent:
	get:
		if _output_component == null:
			_output_component = get_node_or_null("OutputComponent")
		return _output_component

## 点击组件引用
var _click_component: ClickComponent = null
var click_component: ClickComponent:
	get:
		if _click_component == null:
			_click_component = get_node_or_null("ClickComponent")
		return _click_component


func _ready() -> void:
	add_to_group("process_panel")
	add_to_group("placeable_items")
	add_to_group("selectable_items")
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 连接点击组件信号
	if click_component:
		click_component.on_clicked.connect(_on_click_progress)
		click_component.on_complete.connect(_on_click_complete)

	_update_display()


func _process(_delta: float) -> void:
	# 自动检测范围内的数字
	_auto_detect_numbers()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 点击模式下执行加工
			if Global.is_click_mode():
				on_click()
				accept_event()


func _auto_detect_numbers() -> void:
	## 自动检测范围内的数字
	# 如果正在加工或正在移动输出，不检测
	if processing or _is_moving_output:
		return

	# 获取所有数字
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
		# 跳过已经是当前加工的数字
		if number == current_number:
			continue
		# 跳过最近加工完成的数字
		if number == _recently_completed:
			continue

		# 检测数字中心是否在面板范围内
		var number_center = number.global_position + number.size / 2
		if panel_rect.has_point(number_center):
			# 清除最近完成的标记
			_recently_completed = null
			accept_number(number)
			return  # 一次只接收一个数字


func _update_display() -> void:
	## 更新显示
	if click_label:
		if processing:
			var current = 0
			var required = 3
			if click_component:
				current = click_component.current_clicks
				required = click_component.clicks_required
			click_label.text = "%d/%d" % [current, required]
		else:
			click_label.text = "点击加工"

	if progress_bar:
		if processing and current_number:
			# 有数字时显示进度条并更新进度
			progress_bar.visible = true
			var progress = 0.0
			if click_component:
				progress = click_component.get_progress() * 100.0
			progress_bar.value = progress
		else:
			# 没有数字时隐藏进度条
			progress_bar.visible = false


func on_click() -> void:
	## 处理点击
	if not processing or not current_number:
		return

	# 使用点击组件处理点击
	if click_component:
		click_component.on_click()


func _on_click_progress(_current: int, _required: int) -> void:
	## 点击进度更新
	_update_display()


func _on_click_complete() -> void:
	## 点击完成时触发加工
	_complete_processing()


func accept_number(number: NumberObject) -> void:
	## 接收数字进入加工
	if processing or _is_moving_output:
		# 已经在加工中或正在移动输出，加入等待队列
		queue_number(number)
		return

	# 设置当前数字
	current_number = number
	processing = true

	# 标记数字正在被加工
	number._is_being_processed = true

	# 重置点击组件
	if click_component:
		click_component.reset()
		click_component.is_clickable = true

	# 移动数字到面板中心
	_move_number_to_center(number)

	_update_display()


func queue_number(number: NumberObject) -> void:
	## 将数字加入等待队列
	if number not in waiting_queue:
		waiting_queue.append(number)


func _move_number_to_center(number: NumberObject) -> void:
	## 移动数字到面板中心（使用Tween动画）
	var target_pos = global_position + size / 2 - number.size / 2

	# 使用Tween移动
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(number, "global_position", target_pos, 0.3)


func _complete_processing() -> void:
	## 完成加工
	if not current_number:
		return

	# 加工数字
	current_number.process()

	# 重置数字的加工标记
	current_number._is_being_processed = false

	# 标记正在移动输出
	_is_moving_output = true

	# 记录最近完成的数字（防止被自动检测重新接收）
	_recently_completed = current_number

	# 重置加工状态（但保持 _is_moving_output）
	current_number = null
	processing = false

	# 禁用点击组件
	if click_component:
		click_component.is_clickable = false

	_update_display()

	# 移动数字到输出位置并等待完成
	var number_to_move = _recently_completed
	await _move_number_to_output_async(number_to_move)

	# 移动完成，清除标记
	_is_moving_output = false
	_recently_completed = null

	# 处理等待队列
	_process_next_in_queue()


func _move_number_to_output_async(number: NumberObject) -> void:
	## 移动数字到输出位置（面板上方），异步等待完成
	var output_offset = Vector2(0, -80)  # 默认值
	if output_component:
		output_offset = output_component.output_offset

	var output_pos = global_position + size / 2 - number.size / 2 + output_offset

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(number, "global_position", output_pos, 0.4)

	await tween.finished


func _process_next_in_queue() -> void:
	## 处理等待队列中的下一个数字
	if waiting_queue.is_empty():
		return

	var next_number = waiting_queue.pop_front()
	if is_instance_valid(next_number):
		accept_number(next_number)


func can_accept_number() -> bool:
	## 检查是否可以接收数字
	return not processing


func remove_number(number: NumberObject) -> void:
	## 从加工面板中取出数字
	if current_number != number:
		return

	# 重置数字的加工标记
	number._is_being_processed = false

	# 重置状态
	current_number = null
	processing = false
	_is_moving_output = false
	_recently_completed = null

	# 重置点击组件
	if click_component:
		click_component.reset()
		click_component.is_clickable = false

	_update_display()

	# 处理等待队列
	_process_next_in_queue()


func reset() -> void:
	## 重置面板状态
	if current_number and is_instance_valid(current_number):
		# 将当前数字移出
		var output_off = Vector2(0, -80)  # 默认值
		if output_component:
			output_off = output_component.output_offset
		current_number.global_position = global_position + size / 2 + output_off

	current_number = null
	processing = false
	waiting_queue.clear()

	# 重置点击组件
	if click_component:
		click_component.reset()
		click_component.is_clickable = false

	_update_display()
