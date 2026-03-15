extends Node
## SelectableComponent - 可选中组件
## 为面板或按钮添加选中功能
## 显示黄色边框表示选中状态

class_name SelectableComponent

## 是否选中
var is_selected: bool = false:
	set(value):
		if is_selected != value:
			is_selected = value
			if is_selected:
				selected.emit()
				show_selection_indicator()
			else:
				deselected.emit()
				hide_selection_indicator()

## 选中信号
signal selected

## 取消选中信号
signal deselected

## 选中边框
var _selection_border: PanelContainer = null

## 边框颜色
const BORDER_COLOR: Color = Color.YELLOW
const BORDER_WIDTH: int = 3


func select() -> void:
	## 选中
	if not is_selected:
		is_selected = true


func deselect() -> void:
	## 取消选中
	if is_selected:
		is_selected = false


func toggle() -> void:
	## 切换选中状态
	if is_selected:
		deselect()
	else:
		select()


func show_selection_indicator() -> void:
	## 显示选中指示器（黄色边框）
	var parent = get_parent()
	if not parent or not parent is Control:
		return
	
	if _selection_border:
		return  # 已经存在
	
	# 创建边框
	_selection_border = PanelContainer.new()
	_selection_border.name = "SelectionBorder"
	_selection_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 设置边框样式
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = BORDER_COLOR
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(2)
	_selection_border.add_theme_stylebox_override("panel", style)
	
	# 设置位置和大小（覆盖父节点）
	_selection_border.anchor_right = 1.0
	_selection_border.anchor_bottom = 1.0
	_selection_border.offset_left = -BORDER_WIDTH
	_selection_border.offset_top = -BORDER_WIDTH
	_selection_border.offset_right = BORDER_WIDTH
	_selection_border.offset_bottom = BORDER_WIDTH
	
	parent.add_child(_selection_border)


func hide_selection_indicator() -> void:
	## 隐藏选中指示器
	if _selection_border:
		_selection_border.queue_free()
		_selection_border = null


func get_parent_item() -> Control:
	## 获取父节点物品
	return get_parent() as Control
