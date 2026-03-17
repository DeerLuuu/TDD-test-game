extends Resource
## BlueprintResource - 蓝图资源
## 保存面板数据、相对位置、调试信息、总分数

class_name BlueprintResource

## 蓝图名称
@export var blueprint_name: String = ""

## 面板数据列表
## 每个面板数据包含:
## - scene_path: String (场景路径)
## - relative_position: Vector2 (相对于基准点的位置)
## - direction: Vector2 (方向，用于传送带等)
## - output_direction: Vector2 (输出方向，用于OutputComponent)
## - rotation_angle: int (旋转角度，用于分流器)
@export var panels: Array = []

## 总分数（所有面板的购买价格总和）
@export var total_cost: int = 0

## 蓝图创建时间
@export var created_time: Dictionary = {}


func _init() -> void:
	created_time = Time.get_datetime_dict_from_system()


func add_panel(panel_data: Dictionary) -> void:
	## 添加面板数据
	panels.append(panel_data)


func clear_panels() -> void:
	## 清空所有面板数据
	panels.clear()
	total_cost = 0


func get_panel_count() -> int:
	## 获取面板数量
	return panels.size()


func set_total_cost(cost: int) -> void:
	## 设置总分数
	total_cost = cost


func serialize() -> Dictionary:
	## 序列化为字典
	return {
		"blueprint_name": blueprint_name,
		"panels": panels,
		"total_cost": total_cost,
		"created_time": created_time
	}


func deserialize(data: Dictionary) -> void:
	## 从字典反序列化
	blueprint_name = data.get("blueprint_name", "")
	panels = data.get("panels", [])
	total_cost = data.get("total_cost", 0)
	created_time = data.get("created_time", {})
