extends Camera2D
## GameCamera 游戏相机
## 支持WASD移动相机，+/-缩放

class_name GameCamera

## 移动速度（像素/秒）
@export var move_speed: float = 500.0

## 边缘滚动边距
@export var edge_margin: int = 50

## 是否启用边缘滚动
@export var edge_scrolling: bool = false

## 缩放速度
@export var zoom_speed: float = 0.2

## 最小缩放
@export var min_zoom: float = 0.5

## 最大缩放
@export var max_zoom: float = 3.0


func _process(delta: float) -> void:
	_handle_movement(delta)
	_handle_zoom()


func _handle_movement(delta: float) -> void:
	## 处理WASD移动
	var direction = _get_movement_input()

	if direction != Vector2.ZERO:
		global_position += direction * move_speed * delta


func _get_movement_input() -> Vector2:
	## 获取移动输入方向
	var direction = Vector2.ZERO

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1

	return direction.normalized()


func _handle_zoom() -> void:
	## 处理+/-缩放
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_KP_ADD):
		zoom_in()
	elif Input.is_key_pressed(KEY_MINUS) or Input.is_key_pressed(KEY_KP_SUBTRACT):
		zoom_out()


func zoom_in() -> void:
	## 放大
	var new_zoom = zoom.x + zoom_speed
	zoom = Vector2(new_zoom, new_zoom)
	_clamp_zoom()


func zoom_out() -> void:
	## 缩小
	var new_zoom = zoom.x - zoom_speed
	zoom = Vector2(new_zoom, new_zoom)
	_clamp_zoom()


func _clamp_zoom() -> void:
	## 限制缩放范围
	var clamped_zoom = clampf(zoom.x, min_zoom, max_zoom)
	zoom = Vector2(clamped_zoom, clamped_zoom)


func change_zoom(delta: float) -> void:
	## 改变缩放（供外部调用）
	var new_zoom = zoom.x + delta
	zoom = Vector2(new_zoom, new_zoom)
	_clamp_zoom()


func move_camera(direction: Vector2) -> void:
	## 移动相机（供外部调用）
	global_position += direction
