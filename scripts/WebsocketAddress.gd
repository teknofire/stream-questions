extends LineEdit


# Called when the node enters the scene tree for the first time.
func _ready():
	_on_port_text_changed(Global.config.get_value("ws", "port", "[PORT]"))

func _on_port_text_changed(port):
	text = "ws://localhost:%s/" % port
