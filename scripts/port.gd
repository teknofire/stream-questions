extends LineEdit

signal ws_port_changed

# Called when the node enters the scene tree for the first time.
func _ready():
	text = Global.config.get_value("ws", "port", "9000")


func _on_focus_exited():
	Global.config.set_value("ws", "port", text)
	ws_port_changed.emit()
