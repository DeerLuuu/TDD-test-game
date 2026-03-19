extends GutTest
## Teleporter 点对点传送器单元测试

var _teleporter: Teleporter


func before_each():
	_teleporter = add_child_autofree(Teleporter.new())


## === 基础属性测试 ===

func test_has_pair_id_property():
	## 应有配对ID属性
	assert_true("pair_id" in _teleporter, "应有pair_id属性")


func test_pair_id_default_value():
	## 配对ID默认应为空字符串
	assert_eq(_teleporter.pair_id, "", "pair_id默认应为空字符串")


func test_has_speed_property():
	## 应有速度属性
	assert_true("speed" in _teleporter, "应有speed属性")


func test_default_speed_slower_than_conveyor():
	## 默认速度应比普通传送带慢
	var conveyor = add_child_autofree(ConveyorBelt.new())
	assert_lt(_teleporter.speed, conveyor.speed, "传送器速度应比普通传送带慢")


func test_has_numbers_array():
	## 应有数字数组存储当前传送器上的数字
	assert_true("numbers" in _teleporter, "应有numbers属性")


func test_has_transmitting_numbers_dictionary():
	## 应有正在传送中的数字字典（存储传送进度）
	assert_true("transmitting_numbers" in _teleporter, "应有transmitting_numbers属性")


## === 配对功能测试 ===

func test_has_get_pair_method():
	## 应有获取配对传送器的方法
	assert_true(_teleporter.has_method("get_pair"), "应有get_pair方法")


func test_get_pair_returns_null_when_no_pair():
	## 没有配对时返回null
	var pair = _teleporter.get_pair()
	assert_null(pair, "没有配对时应返回null")


func test_has_is_paired_method():
	## 应有检查是否已配对的方法
	assert_true(_teleporter.has_method("is_paired"), "应有is_paired方法")


func test_is_paired_returns_false_when_no_pair():
	## 没有配对时返回false
	assert_false(_teleporter.is_paired(), "没有配对时应返回false")


## === 数字管理测试 ===

func test_add_number():
	## 可以添加数字到传送器
	var number = partial_double(NumberObject).new()
	add_child_autofree(number)
	_teleporter.add_number(number)
	assert_eq(_teleporter.numbers.size(), 1, "应有一个数字")


func test_remove_number():
	## 可以移除数字
	var number = partial_double(NumberObject).new()
	add_child_autofree(number)
	_teleporter.add_number(number)
	_teleporter.remove_number(number)
	assert_eq(_teleporter.numbers.size(), 0, "应无数字")


## === 传送时间计算测试 ===

func test_has_calculate_transmit_time_method():
	## 应有计算传送时间的方法
	assert_true(_teleporter.has_method("calculate_transmit_time"), "应有calculate_transmit_time方法")


func test_transmit_time_increases_with_distance():
	## 传送时间应随距离增加
	_teleporter.global_position = Vector2(0, 0)
	_teleporter.size = Vector2(50, 50)

	# 短距离
	var short_distance_pair = add_child_autofree(Teleporter.new())
	short_distance_pair.global_position = Vector2(100, 0)
	short_distance_pair.size = Vector2(50, 50)
	_teleporter.pair_id = "test"
	short_distance_pair.pair_id = "test"

	var short_time = _teleporter.calculate_transmit_time(short_distance_pair)

	# 长距离
	var long_distance_pair = add_child_autofree(Teleporter.new())
	long_distance_pair.global_position = Vector2(500, 0)
	long_distance_pair.size = Vector2(50, 50)
	long_distance_pair.pair_id = "test2"
	_teleporter.pair_id = "test2"

	var long_time = _teleporter.calculate_transmit_time(long_distance_pair)

	assert_gt(long_time, short_time, "长距离传送时间应更长")


func test_has_base_transmit_time_property():
	## 应有基础传送时间属性
	assert_true("base_transmit_time" in _teleporter, "应有base_transmit_time属性")


func test_base_transmit_time_greater_than_zero():
	## 基础传送时间应大于0
	assert_gt(_teleporter.base_transmit_time, 0.0, "基础传送时间应大于0")


## === 传送功能测试 ===

func test_has_start_transmit_method():
	## 应有开始传送的方法
	assert_true(_teleporter.has_method("start_transmit"), "应有start_transmit方法")


func test_number_enters_teleporter_starts_transmit():
	## 数字进入传送器后开始传送
	_teleporter.size = Vector2(50, 50)
	_teleporter.global_position = Vector2(100, 100)
	_teleporter.pair_id = "test_pair"

	# 创建配对传送器
	var pair = add_child_autofree(Teleporter.new())
	pair.size = Vector2(50, 50)
	pair.global_position = Vector2(300, 100)
	pair.pair_id = "test_pair"

	# 注册到场景树
	_teleporter.add_to_group("teleporters")
	pair.add_to_group("teleporters")

	var number = partial_double(NumberObject).new()
	add_child_autofree(number)
	number.global_position = Vector2(105, 105)
	number.size = Vector2(30, 30)

	_teleporter.add_number(number)

	# 检查是否开始传送
	assert_true(_teleporter.transmitting_numbers.has(number.get_instance_id()), "数字应开始传送")


func test_teleported_number_appears_at_pair_position():
	## 传送完成后数字应出现在配对传送器位置
	_teleporter.size = Vector2(50, 50)
	_teleporter.global_position = Vector2(100, 100)
	_teleporter.pair_id = "test_pair"
	_teleporter.base_transmit_time = 0.01  # 极短时间方便测试

	var pair = add_child_autofree(Teleporter.new())
	pair.size = Vector2(50, 50)
	pair.global_position = Vector2(300, 100)
	pair.pair_id = "test_pair"
	pair.base_transmit_time = 0.01

	_teleporter.add_to_group("teleporters")
	pair.add_to_group("teleporters")

	var number = partial_double(NumberObject).new()
	add_child_autofree(number)
	number.global_position = Vector2(110, 110)
	number.size = Vector2(30, 30)

	_teleporter.add_number(number)
	_teleporter.start_transmit(number)

	# 手动调用_process模拟传送过程（测试环境不会自动运行_process）
	# 需要足够时间完成所有阶段：移动到中心、缩小(0.2s)、传送等待、放大(0.2s)
	for i in range(30):
		_teleporter._process_transmitting_numbers(0.05)

	# 数字应在配对传送器的输出位置附近
	var expected_x = pair.global_position.x + pair.size.x / 2 - number.size.x / 2
	assert_almost_eq(number.global_position.x, expected_x, 10.0, "数字X位置应在配对传送器附近")
	# 数字缩放应恢复为(1, 1)
	assert_eq(number.scale, Vector2.ONE, "数字缩放应恢复为(1, 1)")


## === 输出方向测试 ===

func test_has_output_direction_property():
	## 应有输出方向属性
	assert_true("output_direction" in _teleporter, "应有output_direction属性")


func test_default_output_direction_is_right():
	## 默认输出方向应为右
	assert_eq(_teleporter.output_direction, Vector2.RIGHT, "默认输出方向应为右")


func test_has_rotate_direction_method():
	## 应有旋转方向方法
	assert_true(_teleporter.has_method("rotate_direction"), "应有rotate_direction方法")


## === 交互测试 ===

func test_has_is_being_dragged_property():
	## 应有_is_being_dragged属性
	assert_true("_is_being_dragged" in _teleporter, "应有_is_being_dragged属性")


func test_has_set_being_dragged_method():
	## 应有设置拖拽状态的方法
	assert_true(_teleporter.has_method("set_being_dragged"), "应有set_being_dragged方法")


func test_has_rotate_on_scroll_method():
	## 应有滚轮旋转方法
	assert_true(_teleporter.has_method("rotate_on_scroll"), "应有rotate_on_scroll方法")


func test_cannot_rotate_on_scroll_when_not_dragging():
	## 非拖拽状态下滚轮不能旋转
	_teleporter.set_being_dragged(false)
	_teleporter.output_direction = Vector2.RIGHT
	_teleporter.rotate_on_scroll(1.0)
	assert_eq(_teleporter.output_direction, Vector2.RIGHT, "非拖拽状态下不应旋转")


func test_can_rotate_on_scroll_when_dragging():
	## 拖拽状态下滚轮可以旋转
	_teleporter.set_being_dragged(true)
	_teleporter.output_direction = Vector2.RIGHT
	_teleporter.rotate_on_scroll(1.0)
	assert_eq(_teleporter.output_direction, Vector2.DOWN, "拖拽状态下应能旋转")
