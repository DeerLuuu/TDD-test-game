class_name ScoreButton extends Control
## 分数按钮场景 - 点击生成可拖动数字
## 拖动模式下可拖动按钮本身

@export var number_scene: PackedScene

## 拖动状态
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _drag_preview: Control = null
var _original_position: Vector2 = Vector2.ZERO

## ClickComponent引用
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


func _ready() -> void:
	add_to_group("placeable_items")
	add_to_group("selectable_items")
	if number_scene == null:
		number_scene = preload("res://scenes/number_object.tscn")
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 连接ClickComponent的完成信号
	if click_component:
		click_component.on_complete.connect(_on_click_completed)


func _process(_delta: float) -> void:
	# 拖动时更新预览位置
	if _is_dragging and _drag_preview:
		@warning_ignore("static_called_on_instance")
		var global_mouse = Global.get_scaled_global_mouse_position(get_viewport())
		var target_pos = global_mouse - _drag_offset
		@warning_ignore("static_called_on_instance")
		var snapped_pos = Global.snap_position_to_grid(target_pos)
		_drag_preview.global_position = snapped_pos


func _gui_input(event: InputEvent) -> void:
	## 处理点击输入
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and Global.is_click_mode():
			if click_component:
				click_component.on_click()
				accept_event()


func _input(event: InputEvent) -> void:
	## 拖动模式下拖动按钮
	if Global.is_drag_mode():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 检查鼠标是否在本节点内
				@warning_ignore("static_called_on_instance")
				var global_mouse = Global.get_scaled_global_mouse_position(get_viewport())
				var rect = Rect2(global_position, size)
				if rect.has_point(global_mouse):
					_start_drag()
			else:
				if _is_dragging:
					_end_drag()


func _start_drag() -> void:
	## 开始拖动
	_is_dragging = true
	_drag_offset = get_local_mouse_position()
	_original_position = global_position


func _end_drag() -> void:
	## 结束拖动
	if _drag_preview:
		# 检测目标位置是否被占用
		var target_pos = _drag_preview.global_position
		if Global.check_position_occupied(target_pos, size, self):
			# 位置被占用，回到原位置
			global_position = _original_position
		else:
			# 移动到预览位置
			global_position = target_pos
	_is_dragging = false


func _on_click_completed() -> void:
	## ClickComponent点击完成时生成数字
	_spawn_number()


func _spawn_number() -> void:
	## 生成一个数字对象在输出方向
	var number = number_scene.instantiate()

	# 获取Level3父节点（层级3），如果不存在则使用 current_scene 或 root
	var parent = Global.get_level_parent(3)
	if not parent:
		parent = get_tree().current_scene if get_tree().current_scene else get_tree().root
	parent.add_child(number)

	# 获取生成位置
	var spawn_pos: Vector2
	if output_component:
		# 使用输出组件的位置
		spawn_pos = output_component.get_output_position() - number.size / 2
	else:
		# 默认在按钮正上方
		var button_center = global_position + size / 2
		var spawn_y_offset = -size.y - number.size.y / 2 - 10
		spawn_pos = Vector2(
			button_center.x - number.size.x / 2 + randf_range(-30, 30),
			button_center.y + spawn_y_offset
		)

	number.global_position = spawn_pos

	# 应用弹出动画
	_apply_pop_animation(number)


func _apply_pop_animation(number: Control) -> void:
	## 弹出动画效果
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)

	# 缩放动画
	number.scale = Vector2(0.1, 0.1)
	tween.tween_property(number, "scale", Vector2(1, 1), 0.3)
