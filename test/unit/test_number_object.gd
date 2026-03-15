extends GutTest
## NumberObject 单元测试

var NumberObjectScene = load('res://scenes/number_object.tscn')
var _number


func before_each():
	_number = add_child_autofree(NumberObjectScene.instantiate())


func test_initial_value_is_one():
	## 数字初始值为1
	assert_eq(_number.value, 1, "数字初始值应为1")


func test_initial_processed_level_is_zero():
	## 初始加工等级为0
	assert_eq(_number.processed_level, 0, "初始加工等级应为0")


func test_get_final_value_returns_correct_value():
	## 最终分数 = value × (2 ^ processed_level)
	_number.value = 5
	assert_eq(_number.get_final_value(), 5, "加工等级0时最终分数=value")

	_number.processed_level = 1
	assert_eq(_number.get_final_value(), 10, "加工等级1时最终分数=value×2")

	_number.processed_level = 2
	assert_eq(_number.get_final_value(), 20, "加工等级2时最终分数=value×4")


func test_process_increases_level():
	## 加工增加等级
	_number.process()
	assert_eq(_number.processed_level, 1, "加工后等级应为1")

	_number.process()
	assert_eq(_number.processed_level, 2, "再次加工后等级应为2")