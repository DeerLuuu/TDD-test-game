extends Control
## 分数放置面板 - 接收拖入的数字并加分
class_name ScoreDropZone

@onready var score_label: Label = $VBoxContainer/ScoreLabel
const GRID_SIZE: int = 25

func _ready() -> void:
	add_to_group("score_drop_zone")
	add_to_group("placeable_items")
	# 连接分数变化信号
	if not GameScore.score_changed.is_connected(_on_score_changed):
		GameScore.score_changed.connect(_on_score_changed)
	_snap_to_grid()
	_update_display()


func _process(_delta: float) -> void:
	# 检测传送带送入的数字
	_detect_numbers()


func _detect_numbers() -> void:
	## 检测进入加分面板区域的数字
	var all_numbers = get_tree().get_nodes_in_group("number_objects")
	var zone_rect = Rect2(global_position, size)

	for number in all_numbers:
		if not is_instance_valid(number):
			continue

		# 跳过正在被拖动的数字（手动拖放的由on_number_dropped处理）
		if number._is_dragging:
			continue

		# 获取数字的中心点
		var number_center = number.global_position + number.size / 2

		# 检测数字是否在区域内
		if zone_rect.has_point(number_center):
			on_number_dropped(number)
			return  # 每帧只处理一个数字


func _exit_tree() -> void:
	# 断开信号连接
	if GameScore.score_changed.is_connected(_on_score_changed):
		GameScore.score_changed.disconnect(_on_score_changed)


func on_number_dropped(number: NumberObject) -> void:
	## 数字放入时加分
	if number:
		var points = number.get_final_value()
		GameScore.add_score(points)
		# 数字对象释放
		number.queue_free()


func _on_score_changed(_old_score: int, new_score: int) -> void:
	## 分数变化时更新显示
	_update_display()

func _snap_to_grid() -> void:
	## 对齐网格
	var snapped_pos = Vector2(
		roundi(global_position.x / GRID_SIZE) * GRID_SIZE,
		roundi(global_position.y / GRID_SIZE) * GRID_SIZE
	)
	global_position = snapped_pos

func _update_display() -> void:
	## 更新分数显示
	if score_label:
		score_label.text = "分数: %d" % GameScore.get_score()


func get_score() -> int:
	## 获取当前分数
	return GameScore.get_score()
