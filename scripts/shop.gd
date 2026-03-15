extends PanelContainer
## 商店面板 - 管理可购买的物品
class_name Shop

signal item_purchased(item_data: Dictionary)

var _items: Array = []

@onready var item_container: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/ItemContainer
@onready var mode_label: Label = $MarginContainer/VBoxContainer/ModeContainer/ModeLabel
@onready var direction_btn: Button = $MarginContainer/VBoxContainer/ModeContainer/DirectionButton

@export var level_node_arr : Array[Node2D]

func _ready() -> void:
	add_to_group("shop_panel")
	_setup_default_items()
	_create_item_widgets()
	_update_mode_ui()
	_update_direction_ui()
	# 连接Global信号
	Global.mode_changed.connect(_on_mode_changed)
	Global.direction_changed.connect(_on_direction_changed)
	# 连接方向按钮信号
	if direction_btn:
		direction_btn.pressed.connect(_on_direction_button_pressed)


func _on_direction_button_pressed() -> void:
	## 方向按钮点击事件
	rotate_drag_direction()


func _unhandled_input(event: InputEvent) -> void:
	## 处理全局快捷键
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Z:
				Global.set_click_mode()
				get_viewport().set_input_as_handled()
			KEY_X:
				Global.set_drag_mode()
				get_viewport().set_input_as_handled()
			KEY_C:
				Global.set_delete_mode()
				get_viewport().set_input_as_handled()
			KEY_V:
				Global.set_debug_mode()
				get_viewport().set_input_as_handled()


func _on_mode_changed(_old_mode: int, _new_mode: int) -> void:
	_update_mode_ui()


func _on_direction_changed(_old_dir: Vector2, _new_dir: Vector2) -> void:
	_update_direction_ui()


func _update_mode_ui() -> void:
	## 更新模式显示
	if mode_label:
		if Global.is_click_mode():
			mode_label.text = "模式: 点击 (Z/X/C/V切换)"
		elif Global.is_drag_mode():
			mode_label.text = "模式: 拖动 (Z/X/C/V切换)"
		elif Global.is_delete_mode():
			mode_label.text = "模式: 删除 (Z/X/C/V切换)"
		else:
			mode_label.text = "模式: 调试 (Z/X/C/V切换)"


func _update_direction_ui() -> void:
	## 更新方向按钮显示
	if direction_btn:
		var dir_text = ""
		match Global.drag_direction:
			Vector2.RIGHT: dir_text = "→"
			Vector2.LEFT: dir_text = "←"
			Vector2.UP: dir_text = "↑"
			Vector2.DOWN: dir_text = "↓"
		direction_btn.text = "方向: " + dir_text


func _setup_default_items() -> void:
	## 设置默认商品列表
	_items = [
		{
			"name": "加分按钮",
			"cost": 50,
			"scene_path": "res://scenes/score_button.tscn",
			"level": 2
		},
		{
			"name": "传送带",
			"cost": 100,
			"scene_path": "res://scenes/conveyor_belt.tscn",
			"level": 2
		},
		{
			"name": "收集面板",
			"cost": 80,
			"scene_path": "res://scenes/collect_panel.tscn",
			"level": 2
		},
		{
			"name": "加工面板",
			"cost": 150,
			"scene_path": "res://scenes/process_panel.tscn",
			"level": 2
		}
	]


func _create_item_widgets() -> void:
	## 创建物品UI
	if not item_container:
		return

	for child in item_container.get_children():
		child.queue_free()

	var ShopItemScene = preload("res://scenes/shop_item.tscn")

	for i in _items.size():
		var item_data = _items[i]
		var item_widget = ShopItemScene.instantiate()
		item_widget.item_name = item_data.name
		item_widget.cost = item_data.cost
		item_widget.scene_path = item_data.scene_path

		item_widget.dragged_out.connect(_on_item_dragged_out.bind(i))

		item_container.add_child(item_widget)


func add_item(item_data: Dictionary) -> void:
	## 添加物品到商店
	_items.append(item_data)
	_create_item_widgets()


func get_items() -> Array:
	## 获取所有物品
	return _items


func try_purchase(index: int) -> Dictionary:
	## 尝试购买物品
	if index < 0 or index >= _items.size():
		return {"success": false, "error": "invalid_index"}

	var item_data = _items[index]

	var current_score = GameScore.get_score()
	var cost = item_data.get("cost", 0)

	if current_score < cost:
		return {
			"success": false,
			"cost": cost,
			"current_score": current_score,
			"error": "insufficient_funds"
		}

	# 扣除分数
	GameScore.add_score(-cost)

	# 发出购买成功信号
	var result = {
		"success": true,
		"item_name": item_data.get("name", "unknown"),
		"cost": cost,
		"scene_path": item_data.get("scene_path", ""),
		"level": item_data.get("level", 2),
		"remaining_score": GameScore.get_score()
	}
	item_purchased.emit(result)

	return result


func _on_item_dragged_out(_item: ShopItem, global_pos: Vector2, index: int) -> void:
	## 物品拖出商店时的处理
	var result = try_purchase(index)

	if result.success:
		# 在拖放位置创建物品（传入价格用于退款）
		_spawn_purchased_item(result.scene_path, global_pos, result.level, result.cost)
	else:
		# 购买失败，显示提示
		_show_purchase_failed(result)


func _spawn_purchased_item(scene_path: String, global_pos: Vector2, level: int = 2, cost: int = 0) -> void:
	## 在指定位置生成购买的物品
	if scene_path.is_empty():
		return

	var scene = load(scene_path)
	if not scene:
		return

	var instance = scene.instantiate()

	# 对齐网格
	@warning_ignore("static_called_on_instance")
	var snapped_pos = Global.snap_position_to_grid(global_pos)

	# 根据层级选择父节点
	var parent = _get_level_parent(level)
	if parent:
		parent.add_child(instance)
	else:
		get_tree().current_scene.add_child(instance)

	# 等待一帧让size正确初始化
	await get_tree().process_frame

	var target_pos = snapped_pos - instance.size / 2

	# 检测位置是否被占用
	if Global.check_position_occupied(target_pos, instance.size, instance):
		# 位置被占用，移除物品并退款
		instance.queue_free()
		if cost > 0:
			GameScore.add_score(cost)
		return

	instance.global_position = target_pos

	# 如果是有朝向的物品（如传送带），设置方向
	if instance is ConveyorBelt:
		instance.direction = Global.drag_direction

	# 添加到可放置物品组
	instance.add_to_group("placeable_items")


func toggle_mode() -> void:
	## 切换操作模式
	if Global.is_click_mode():
		Global.set_drag_mode()
	else:
		Global.set_click_mode()


func rotate_drag_direction() -> void:
	## 旋转拖动方向
	Global.rotate_drag_direction()


func _get_level_parent(level: int) -> Node:
	var index = level - 1
	if level_node_arr.size() > index and level_node_arr[index]:
		return level_node_arr[index]
	return null


func _show_purchase_failed(result: Dictionary) -> void:
	## 显示购买失败提示
	print("购买失败: %s" % result.get("error", "unknown"))
