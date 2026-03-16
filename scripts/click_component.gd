extends Node
## ClickComponent 点击组件
## 为面板提供点击功能
## 可配置需要的点击次数，每次点击触发回调，完成后触发完成回调

class_name ClickComponent

## 需要的点击次数
@export var clicks_required: int = 1

## 是否可点击
@export var is_clickable: bool = true

## 当前点击次数
var current_clicks: int = 0

## 点击信号（每次点击触发）
signal on_clicked(current: int, required: int)

## 完成信号（达到点击次数时触发）
signal on_complete()

## 进度变化信号
signal progress_changed(progress: float)


func _ready() -> void:
	add_to_group("click_components")


func on_click() -> bool:
	## 处理点击
	if not is_clickable:
		return false

	current_clicks += 1

	# 发出点击信号
	on_clicked.emit(current_clicks, clicks_required)

	# 发出进度变化信号
	progress_changed.emit(get_progress())

	# 检查是否完成
	if current_clicks >= clicks_required:
		on_complete.emit()
		reset()

	return true


func get_progress() -> float:
	## 获取当前进度（0.0 - 1.0）
	if clicks_required <= 0:
		return 1.0
	return float(current_clicks) / float(clicks_required)


func is_complete() -> bool:
	## 检查是否已完成
	return current_clicks >= clicks_required


func reset() -> void:
	## 重置点击计数
	current_clicks = 0


func set_clicks_required(value: int) -> void:
	## 设置需要的点击次数
	clicks_required = value
	if current_clicks > clicks_required:
		current_clicks = clicks_required


func get_remaining_clicks() -> int:
	## 获取剩余需要的点击次数
	return max(0, clicks_required - current_clicks)
