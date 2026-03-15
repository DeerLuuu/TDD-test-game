extends Control
## 分数按钮场景 - UI控制器

@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var add_button: Button = $VBoxContainer/AddButton

var _score_system: ScoreSystem


func _ready() -> void:
	_score_system = ScoreSystem.new()
	_update_display()
	add_button.pressed.connect(_on_add_button_pressed)


func _on_add_button_pressed() -> void:
	_score_system.on_button_pressed()
	_update_display()


func _update_display() -> void:
	score_label.text = str(_score_system.get_score())


func get_score_system() -> ScoreSystem:
	return _score_system
