extends Panel

var drag = false
var offset = Vector2.ZERO

signal location_updated(name: String, location: Vector2)
signal panel_hidden

var shown_location = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	shown_location = Global.config.get_value("ui", name, Vector2(280, 600))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if drag:
		global_position = get_viewport().get_mouse_position() + offset

func _on_gui_input(event):
	if Input.is_action_pressed("click"):
		if !drag:
			drag = true
			offset = global_position - get_viewport().get_mouse_position()
	else:
		drag = false
		shown_location = global_position
		Global.config.set_value("ui", name, global_position)
		Global.config.save_settings()

func animate_in(_play_audio, message_length, duration):
	show()
	
	var tween = get_tree().create_tween()

	tween.tween_property(self, "global_position", shown_location, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_play_audio)
	tween.tween_property(%QuestionMessage, "visible_characters", message_length, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(animate_out).set_delay(3)	
	
func animate_out():
	var tween = get_tree().create_tween()	
	tween.tween_property(self, "global_position", Vector2(self.global_position.x, %OffscreenTarget.global_position.y), 0.2)
	%QuestionMessage.visible_characters = 0
	panel_hidden.emit()

