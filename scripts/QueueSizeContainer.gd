extends MarginContainer

var drag = false
var offset = Vector2.ZERO

func _ready():
	var pos = Global.config.get_value("ui", name, Vector2(0, 0))
	if pos:
		global_position = pos

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if drag:
		global_position = get_viewport().get_mouse_position() + offset

func animate():
	pivot_offset = get_size()/2
		
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(0.3, 1), 0.4).set_trans(Tween.TRANS_SINE )
	tween.tween_property(self, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	rotation = 0

func _on_gui_input(_event):
	if Input.is_action_pressed("click"):
		if !drag:
			drag = true
			Global.dragging.emit()
			offset = global_position - get_viewport().get_mouse_position()
	else:
		if drag:
			drag = false
			Global.dropped.emit()
			Global.config.set_value("ui", name, global_position)
			Global.save_settings()
