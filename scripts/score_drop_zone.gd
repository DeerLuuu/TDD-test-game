extends Control
## 分数放置面板 - 接收拖入的数字并加分
class_name ScoreDropZone

@onready var score_label: Label = $VBoxContainer/ScoreLabel


func _ready() -> void:
	add_to_group("score_drop_zone")
	# 连接分数变化信号
	if not GameScore.score_changed.is_connected(_on_score_changed):
		GameScore.score_changed.connect(_on_score_changed)
	_update_display()


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


func _update_display() -> void:
	## 更新分数显示
	if score_label:
		score_label.text = "分数: %d" % GameScore.get_score()


func get_score() -> int:
	## 获取当前分数
	return GameScore.get_score()
