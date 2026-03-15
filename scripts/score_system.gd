extends RefCounted
## 分数系统 - 管理游戏分数
class_name ScoreSystem

var _score: int = 0


func get_score() -> int:
	return _score


func on_button_pressed() -> void:
	_score += 1


func add_score(amount: int) -> void:
	if amount > 0:
		_score += amount
