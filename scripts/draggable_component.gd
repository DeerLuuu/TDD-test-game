extends Node
## DraggableComponent - 可拖动组件
## 添加到Control节点使其在拖动模式下可拖动

## 拖动开始信号
signal drag_started()
## 拖动结束信号
signal drag_ended()

## 是否启用
@export var enabled: bool = true

## 是否正在拖动
var is_dragging: bool = false

## 拖动偏移
var _drag_offset: Vector2 = Vector2.ZERO

## 父节点引用
@onready var _parent: Control = get_parent() as Control


func _ready() -> void:
	# 确保父节点可以接收输入
	if _parent:
		_parent.mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	if is_dragging and _parent:
		_parent.global_position = _parent.get_global_mouse_position() - _drag_offset


func _input(event: InputEvent) -> void:
	if not enabled or not _parent:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 检查鼠标是否在父节点内
			if _can_drag() and _is_mouse_in_parent():
				_start_drag()
		else:
			if is_dragging:
				_end_drag()


func _can_drag() -> bool:
	## 检查是否可以拖动
	return enabled and Global.is_drag_mode()


func _is_mouse_in_parent() -> bool:
	## 检查鼠标是否在父节点内
	if not _parent:
		return false
	var rect = Rect2(_parent.global_position, _parent.size)
	return rect.has_point(_parent.get_global_mouse_position())


func _start_drag() -> void:
	## 开始拖动
	is_dragging = true
	_drag_offset = _parent.get_local_mouse_position()
	drag_started.emit()


func _end_drag() -> void:
	## 结束拖动
	is_dragging = false
	drag_ended.emit()
