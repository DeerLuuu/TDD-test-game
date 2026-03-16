extends Node
## 分数系统 - 管理游戏分数（自动加载单例）
class_name ScoreSystem

## 分数变化信号 - 参数: 旧分数, 新分数
signal score_changed(old_score: int, new_score: int)

var _score: int = 100:
	set(v):
		var old_socre : int = _score
		_score = v
		if _score < 0: _score = 0
		score_changed.emit(old_socre, _score)

func get_score() -> int:
	return _score

func add_score(amount: int) -> void:
	_score += amount
