extends Control
## AdditionPanel 加法面板
## 接收两个同等级数字，加工后输出两数之和的新数字

class_name AdditionPanel

## 状态枚举
enum State {
	EMPTY,        ## 空
	ONE_NUMBER,   ## 有一个数字
	READY,        ## 有两个同等级数字，可以加工
	WAITING       ## 等待相同等级数字
}

## 当前状态
var state: State = State.EMPTY

## 最大数字数量
var max_numbers: int = 2

## 存储的数字
var numbers: Array[NumberObject] = []

## 数字场景
var number_scene: PackedScene = preload("res://scenes/number_object.tscn")

## 点击组件引用
var _click_component: ClickComponent = null
var click_component: ClickComponent:
	get:
		if _click_component == null:
			_click_component = get_node_or_null("ClickComponent")
		return _click_component

## 输出组件引用
var _output_component: OutputComponent = null
var output_component: OutputComponent:
	get:
		if _output_component == null:
			_output_component = get_node_or_null("OutputComponent")
		return _output_component

## 标签引用
@onready var state_label: Label = get_node_or_null("VBoxContainer/StateLabel")


func _ready() -> void:
	add_to_group("addition_panel")
	add_to_group("placeable_items")
	add_to_group("selectable_items")
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 连接点击组件信号
	if click_component:
		click_component.on_complete.connect(_on_click_complete)

	_update_display()


func _process(_delta: float) -> void:
	_auto_detect_numbers()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and Global.is_click_mode():
			if click_component:
				click_component.on_click()
				accept_event()


func accept_number(number: NumberObject) -> bool:
	# 检查对象是否有效
	if not is_instance_valid(number):
		return false

	if numbers.size() >= max_numbers:
		return false

	if numbers.size() == 1:
		# 检查 numbers[0] 是否仍然有效
		if not is_instance_valid(numbers[0]):
			numbers.clear()
		elif number.processed_level != numbers[0].processed_level:
			return false

	numbers.append(number)
	_update_state()
	_move_number_to_slot(number)
	_update_display()
	return true


func remove_number(number: NumberObject) -> void:
	var index = numbers.find(number)
	if index >= 0:
		numbers.remove_at(index)
		_update_state()
		_update_display()


func remove_number_at(index: int) -> void:
	if index >= 0 and index < numbers.size():
		numbers.remove_at(index)
		_update_state()
		_update_display()


func can_add_numbers() -> bool:
	if numbers.size() != 2:
		return false
	# 检查两个数字对象是否有效
	if not is_instance_valid(numbers[0]) or not is_instance_valid(numbers[1]):
		return false
	return numbers[0].processed_level == numbers[1].processed_level


func try_process() -> bool:
	if not can_add_numbers():
		return false
	_do_process()
	return true


func calculate_result() -> int:
	if numbers.size() != 2:
		return 0
	if not is_instance_valid(numbers[0]) or not is_instance_valid(numbers[1]):
		return 0
	return numbers[0].value + numbers[1].value


func get_result_level() -> int:
	if numbers.size() == 0:
		return 0
	if not is_instance_valid(numbers[0]):
		return 0
	return numbers[0].processed_level


func _update_state() -> void:
	# 清理无效的数字对象
	var valid_numbers: Array[NumberObject] = []
	for n in numbers:
		if is_instance_valid(n):
			valid_numbers.append(n)
	numbers = valid_numbers

	match numbers.size():
		0:
			state = State.EMPTY
		1:
			state = State.ONE_NUMBER
		2:
			if numbers[0].processed_level == numbers[1].processed_level:
				state = State.READY
			else:
				state = State.WAITING


func _update_display() -> void:
	if state_label:
		match state:
			State.EMPTY:
				state_label.text = "放入两个数字"
			State.ONE_NUMBER:
				if numbers.size() > 0 and is_instance_valid(numbers[0]):
					state_label.text = "等级 %d\n再放入一个" % numbers[0].processed_level
				else:
					state_label.text = "放入两个数字"
			State.READY:
				if numbers.size() >= 2 and is_instance_valid(numbers[0]) and is_instance_valid(numbers[1]):
					state_label.text = "%d + %d = ?\n点击计算" % [numbers[0].value, numbers[1].value]
				else:
					state_label.text = "放入两个数字"
			State.WAITING:
				state_label.text = "需要同等级数字"


func _on_click_complete() -> void:
	try_process()


func _do_process() -> void:
	var result_value = calculate_result()
	var result_level = get_result_level()

	for number in numbers:
		if is_instance_valid(number):
			number.queue_free()

	numbers.clear()
	_update_state()

	var new_number = number_scene.instantiate()
	new_number.value = result_value
	new_number.processed_level = result_level

	var parent = Global.get_level_parent(3)
	if parent:
		parent.add_child(new_number)
	else:
		get_tree().current_scene.add_child(new_number)

	var spawn_pos: Vector2
	if output_component:
		spawn_pos = output_component.get_output_position() - new_number.size / 2
	else:
		spawn_pos = global_position + size / 2 - new_number.size / 2 + Vector2(0, -80)

	new_number.global_position = spawn_pos
	_apply_pop_animation(new_number)
	_update_display()


func _move_number_to_slot(number: NumberObject) -> void:
	var target_pos = global_position + size / 2 - number.size / 2
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(number, "global_position", target_pos, 0.3)


func _auto_detect_numbers() -> void:
	if numbers.size() >= max_numbers:
		return

	var all_numbers = get_tree().get_nodes_in_group("number_objects")
	var panel_rect = Rect2(global_position, size)

	for number in all_numbers:
		if not is_instance_valid(number):
			continue
		if not number is NumberObject:
			continue
		if number._is_dragging:
			continue
		if numbers.has(number):
			continue

		var number_center = number.global_position + number.size / 2
		if panel_rect.has_point(number_center):
			accept_number(number)
			return


func _apply_pop_animation(number: Control) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	number.scale = Vector2(0.1, 0.1)
	tween.tween_property(number, "scale", Vector2(1, 1), 0.3)
