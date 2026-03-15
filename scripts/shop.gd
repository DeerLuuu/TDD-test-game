extends PanelContainer
## 商店面板 - 管理可购买的物品
class_name Shop

signal item_purchased(item_data: Dictionary)

var _items: Array = []

@onready var item_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/ItemContainer


func _ready() -> void:
	add_to_group("shop_panel")
	_setup_default_items()
	_create_item_widgets()


func _setup_default_items() -> void:
	## 设置默认商品列表
	_items = [
		{
			"name": "加分按钮",
			"cost": 50,
			"scene_path": "res://scenes/score_button.tscn"
		},
		{
			"name": "加分按钮+",
			"cost": 150,
			"scene_path": "res://scenes/score_button.tscn"
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
		"remaining_score": GameScore.get_score()
	}
	item_purchased.emit(result)

	return result


func _on_item_dragged_out(item: ShopItem, global_pos: Vector2, index: int) -> void:
	## 物品拖出商店时的处理
	var result = try_purchase(index)

	if result.success:
		# 在拖放位置创建物品
		_spawn_purchased_item(result.scene_path, global_pos)
	else:
		# 购买失败，显示提示
		_show_purchase_failed(result)


func _spawn_purchased_item(scene_path: String, global_pos: Vector2) -> void:
	## 在指定位置生成购买的物品
	if scene_path.is_empty():
		return

	var scene = load(scene_path)
	if not scene:
		return

	var instance = scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = global_pos - instance.size / 2


func _show_purchase_failed(result: Dictionary) -> void:
	## 显示购买失败提示
	print("购买失败: %s" % result.get("error", "unknown"))
