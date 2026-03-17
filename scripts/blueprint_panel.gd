extends Control
## BlueprintPanel - 蓝图界面面板
## 显示蓝图列表，支持保存、拖动放置

class_name BlueprintPanel

## 是否展开
var _is_expanded: bool = false

## 展开时的位置偏移
const EXPANDED_OFFSET: float = -250.0

## 收起时的位置偏移（只露出一部分）
const COLLAPSED_OFFSET: float = -40.0

## 动画持续时间
const TWEEN_DURATION: float = 0.3

## 蓝图列表容器
@onready var blueprint_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/BlueprintList

## 保存弹窗
@onready var save_dialog: Control = $SaveDialog

## 名称输入框
@onready var name_input: LineEdit = $SaveDialog/Panel/VBoxContainer/NameInput

## 面板背景
@onready var panel_bg: Panel = $Panel

## 标题按钮
@onready var title_button: Button = $Panel/VBoxContainer/TitleButton

## 当前拖动的蓝图
var _dragging_blueprint: BlueprintResource = null

## 预览面板列表
var _preview_panels: Array = []

## 蓝图边界
var _blueprint_bounds: Rect2 = Rect2()


## 是否正在拖拽蓝图
func is_dragging_blueprint() -> bool:
	return _dragging_blueprint != null and not _preview_panels.is_empty()


func _ready() -> void:
	add_to_group("blueprint_panel")
	# 连接BlueprintManager信号
	BlueprintManager.blueprints_changed.connect(_on_blueprints_changed)
	# 初始位置（收起状态）
	position.y = get_viewport().size.y + COLLAPSED_OFFSET
	# 初始化蓝图列表
	_refresh_blueprint_list()


func _process(_delta: float) -> void:
	# 处理蓝图拖动放置
	if _dragging_blueprint:
		_update_drag_preview()


func _on_blueprints_changed() -> void:
	## 蓝图列表变化
	_refresh_blueprint_list()


func _refresh_blueprint_list() -> void:
	## 刷新蓝图列表
	if not blueprint_list:
		return

	# 清空现有列表
	for child in blueprint_list.get_children():
		child.queue_free()

	# 添加所有蓝图
	var blueprints = BlueprintManager.get_all_blueprints()
	for blueprint in blueprints:
		var item = _create_blueprint_item(blueprint)
		blueprint_list.add_child(item)


func _create_blueprint_item(blueprint: BlueprintResource) -> Control:
	## 创建蓝图列表项
	var item = HBoxContainer.new()
	item.custom_minimum_size = Vector2(220, 40)

	# 背景面板
	var bg = Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.3, 0.4, 0.8)
	style.border_color = Color(0.3, 0.5, 0.7, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	bg.add_theme_stylebox_override("panel", style)
	item.add_child(bg)

	# 名称标签
	var name_label = Label.new()
	name_label.text = blueprint.blueprint_name
	name_label.custom_minimum_size = Vector2(100, 0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.add_child(name_label)

	# 分数标签
	var cost_label = Label.new()
	cost_label.text = str(blueprint.total_cost)
	cost_label.custom_minimum_size = Vector2(50, 0)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	item.add_child(cost_label)

	# 删除按钮
	var delete_btn = Button.new()
	delete_btn.text = "X"
	delete_btn.custom_minimum_size = Vector2(30, 30)
	delete_btn.pressed.connect(_on_delete_blueprint.bind(blueprint.blueprint_name))
	item.add_child(delete_btn)

	# 存储蓝图引用
	item.set_meta("blueprint", blueprint)

	# 添加拖动检测
	item.gui_input.connect(_on_blueprint_item_gui_input.bind(item, blueprint))

	return item


func _on_blueprint_item_gui_input(event: InputEvent, item: Control, blueprint: BlueprintResource) -> void:
	## 处理蓝图项的输入事件
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 开始拖动
			_dragging_blueprint = blueprint
			_create_drag_preview(item)
			accept_event()


func _create_drag_preview(_source_item: Control) -> void:
	## 创建拖动预览（使用真实面板实例）
	if not _dragging_blueprint or _dragging_blueprint.panels.is_empty():
		return

	# 计算蓝图的边界框
	_blueprint_bounds = _calculate_blueprint_bounds()
	if _blueprint_bounds.size == Vector2.ZERO:
		return

	_preview_panels.clear()

	# 获取放置层级的父节点
	var parent = Global.get_level_parent(2)
	if not parent:
		parent = get_tree().current_scene if get_tree().current_scene else get_tree().root

	# 为每个面板创建真实预览实例
	for panel_data in _dragging_blueprint.panels:
		var panel_preview = _create_real_panel_preview(panel_data)
		if panel_preview:
			parent.add_child(panel_preview)
			# 在添加到场景树后更新方向显示
			_update_panel_direction(panel_preview, panel_data)
			_preview_panels.append(panel_preview)

	# 更新预览位置
	_update_drag_preview()


func _update_panel_direction(panel: Control, panel_data: Dictionary) -> void:
	## 更新面板的方向显示（在添加到场景树后调用）
	# 传送带方向
	if panel is ConveyorBelt and panel_data.has("direction"):
		panel.direction = panel_data["direction"]
	# 分流器旋转角度
	if panel is SplitterConveyor and panel_data.has("rotation_angle"):
		panel.rotation_angle = panel_data["rotation_angle"]
		# 需要手动调用更新方法（预览状态下_ready会提前返回）
		panel._update_directions()
		panel._update_arrow_layout()
		panel._update_arrow_textures()
	# 输出组件方向
	if panel_data.has("output_direction"):
		var output_comp = _get_output_component(panel)
		if output_comp:
			output_comp.output_direction = panel_data["output_direction"]


func _calculate_blueprint_bounds() -> Rect2:
	## 计算蓝图中所有面板的边界框
	if not _dragging_blueprint or _dragging_blueprint.panels.is_empty():
		return Rect2()

	var min_pos = Vector2.INF
	var max_pos = Vector2(-INF, -INF)

	# 面板默认大小
	const DEFAULT_PANEL_SIZE = Vector2(50, 50)

	for panel_data in _dragging_blueprint.panels:
		var pos = panel_data.get("relative_position", Vector2.ZERO)
		min_pos = Vector2(minf(min_pos.x, pos.x), minf(min_pos.y, pos.y))
		max_pos = Vector2(maxf(max_pos.x, pos.x + DEFAULT_PANEL_SIZE.x), maxf(max_pos.y, pos.y + DEFAULT_PANEL_SIZE.y))

	if min_pos == Vector2.INF:
		return Rect2()

	return Rect2(min_pos, max_pos - min_pos)


func _create_real_panel_preview(panel_data: Dictionary) -> Control:
	## 创建真实面板预览实例
	var scene_path = panel_data.get("scene_path", "")
	if scene_path.is_empty():
		return null

	var scene = load(scene_path)
	if not scene:
		return null

	var instance = scene.instantiate()
	if not instance:
		return null

	# 标记为预览
	instance.set_meta("is_preview", true)

	# 设置为半透明
	instance.modulate = Color(1, 1, 1, 0.7)

	# 禁用输入
	instance.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 方向设置在添加到场景树后进行（见_update_panel_direction）

	return instance


func _update_drag_preview() -> void:
	## 更新拖动预览位置（考虑相机缩放）
	if _preview_panels.is_empty():
		return

	var viewport = get_viewport()
	if not viewport:
		return

	# 获取世界坐标鼠标位置
	@warning_ignore("static_called_on_instance")
	var world_mouse = Global.get_scaled_global_mouse_position(viewport)

	# 对齐到网格
	@warning_ignore("static_called_on_instance")
	var snapped_mouse = Global.snap_position_to_grid(world_mouse)

	# 计算放置基准点（以蓝图中心为基准）
	var blueprint_center = _blueprint_bounds.position + _blueprint_bounds.size / 2
	var spawn_base = snapped_mouse - blueprint_center + _blueprint_bounds.position

	# 更新每个预览面板的位置
	for i in _preview_panels.size():
		var panel = _preview_panels[i]
		if not is_instance_valid(panel):
			continue

		var panel_data = _dragging_blueprint.panels[i]
		var relative_pos = panel_data.get("relative_position", Vector2.ZERO)
		panel.global_position = spawn_base + relative_pos


func _end_drag_preview() -> void:
	## 结束拖动预览
	for panel in _preview_panels:
		if is_instance_valid(panel):
			panel.queue_free()
	_preview_panels.clear()
	_blueprint_bounds = Rect2()


func _input(event: InputEvent) -> void:
	## 处理鼠标释放
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and _dragging_blueprint:
			# 检查是否拖回蓝图面板（取消放置）
			if _is_mouse_over_panel():
				# 取消放置
				_end_drag_preview()
				_dragging_blueprint = null
			else:
				# 放置蓝图
				_place_blueprint()
				_end_drag_preview()
				_dragging_blueprint = null


func _is_mouse_over_panel() -> bool:
	## 检查鼠标是否在蓝图面板上
	var viewport = get_viewport()
	if not viewport:
		return false

	var screen_pos = viewport.get_mouse_position()
	var panel_rect = Rect2(global_position, $Panel.size)
	return panel_rect.has_point(screen_pos)


func _place_blueprint() -> void:
	## 放置蓝图
	if not _dragging_blueprint or _preview_panels.is_empty():
		return

	var viewport = get_viewport()
	if not viewport:
		return

	# 获取鼠标世界坐标
	@warning_ignore("static_called_on_instance")
	var world_mouse = Global.get_scaled_global_mouse_position(viewport)
	@warning_ignore("static_called_on_instance")
	var snapped_mouse = Global.snap_position_to_grid(world_mouse)

	# 计算放置位置（以蓝图中心为基准）
	var blueprint_center = _blueprint_bounds.position + _blueprint_bounds.size / 2
	var spawn_pos = snapped_mouse - blueprint_center + _blueprint_bounds.position

	# 检查分数是否足够
	var current_score = GameScore.get_score()
	if current_score < _dragging_blueprint.total_cost:
		# 分数不足，显示提示
		print("分数不足！需要 %d，当前 %d" % [_dragging_blueprint.total_cost, current_score])
		return

	# 生成蓝图
	BlueprintManager.spawn_blueprint(_dragging_blueprint, spawn_pos, true)


func _on_delete_blueprint(blueprint_name: String) -> void:
	## 删除蓝图
	BlueprintManager.delete_blueprint(blueprint_name)


func toggle_panel() -> void:
	## 切换面板展开/收起状态
	_is_expanded = not _is_expanded
	_animate_panel()


func _animate_panel() -> void:
	## 动画移动面板
	var target_y = get_viewport().size.y + (EXPANDED_OFFSET if _is_expanded else COLLAPSED_OFFSET)

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position:y", target_y, TWEEN_DURATION)


func _on_title_button_pressed() -> void:
	## 标题按钮点击
	toggle_panel()


func show_save_dialog() -> void:
	## 显示保存弹窗
	if save_dialog:
		save_dialog.visible = true
		if name_input:
			name_input.clear()
			name_input.grab_focus()


func hide_save_dialog() -> void:
	## 隐藏保存弹窗
	if save_dialog:
		save_dialog.visible = false


func _on_save_button_pressed() -> void:
	## 保存按钮点击
	var blueprint = BlueprintManager.get_temp_blueprint()
	if not blueprint:
		return

	if name_input and not name_input.text.is_empty():
		blueprint.blueprint_name = name_input.text
		if BlueprintManager.save_blueprint(blueprint):
			BlueprintManager.clear_temp_blueprint()
			hide_save_dialog()
			# 清除选中
			SelectionManager.clear_selection()


func _on_cancel_button_pressed() -> void:
	## 取消按钮点击
	BlueprintManager.clear_temp_blueprint()
	hide_save_dialog()


func _get_output_component(panel: Control) -> OutputComponent:
	## 获取面板的输出组件
	if not is_instance_valid(panel):
		return null
	for child in panel.get_children():
		if child is OutputComponent and is_instance_valid(child):
			return child
	return null
