extends GutTest
## GameCamera 相机测试

var _camera


func before_each():
	_camera = add_child_autofree(GameCamera.new())


func test_has_speed_property():
	## 应有移动速度属性
	assert_true("move_speed" in _camera, "应有move_speed属性")


func test_default_speed():
	## 默认速度应大于0
	assert_gt(_camera.move_speed, 0.0, "移动速度应大于0")


func test_has_move_method():
	## 应有移动方法
	assert_true(_camera.has_method("move_camera"), "应有move_camera方法")


func test_move_camera_changes_position():
	## 移动相机应改变位置
	var initial_pos = _camera.global_position
	_camera.move_camera(Vector2(10, 0))
	assert_ne(_camera.global_position, initial_pos, "移动后位置应改变")


func test_has_process_method():
	## 应有_process方法处理WASD输入
	assert_true(_camera.has_method("_process"), "应有_process方法")


func test_has_input_actions():
	## 应定义输入动作映射
	# 检查是否有WASD相关的输入处理
	assert_true(_camera.has_method("_get_movement_input") or "move_speed" in _camera, "应有移动输入处理")


## === 缩放功能测试 ===

func test_has_zoom_property():
	## 应有缩放属性
	assert_true("zoom" in _camera or "zoom_level" in _camera, "应有缩放属性")


func test_has_zoom_speed_property():
	## 应有缩放速度属性
	assert_true("zoom_speed" in _camera, "应有zoom_speed属性")


func test_has_min_max_zoom():
	## 应有最小最大缩放限制
	assert_true("min_zoom" in _camera, "应有min_zoom属性")
	assert_true("max_zoom" in _camera, "应有max_zoom属性")


func test_has_zoom_method():
	## 应有缩放方法
	assert_true(_camera.has_method("zoom_in") or _camera.has_method("change_zoom"), "应有缩放方法")


func test_default_zoom_is_one():
	## 默认缩放应为1
	assert_eq(_camera.zoom, Vector2(1, 1), "默认缩放应为1")


func test_zoom_in_increases_zoom():
	## 放大应增加缩放值
	var initial_zoom = _camera.zoom.x
	_camera.zoom_in()
	assert_gt(_camera.zoom.x, initial_zoom, "放大后缩放值应增加")


func test_zoom_out_decreases_zoom():
	## 缩小应减少缩放值
	_camera.zoom = Vector2(2, 2)
	var initial_zoom = _camera.zoom.x
	_camera.zoom_out()
	assert_lt(_camera.zoom.x, initial_zoom, "缩小后缩放值应减少")


func test_zoom_clamped_to_min():
	## 缩放应限制在最小值
	_camera.min_zoom = 0.5
	_camera.zoom = Vector2(0.3, 0.3)
	_camera._clamp_zoom()
	assert_gte(_camera.zoom.x, 0.5, "缩放不应小于最小值")


func test_zoom_clamped_to_max():
	## 缩放应限制在最大值
	_camera.max_zoom = 3.0
	_camera.zoom = Vector2(5.0, 5.0)
	_camera._clamp_zoom()
	assert_lte(_camera.zoom.x, 3.0, "缩放不应大于最大值")
