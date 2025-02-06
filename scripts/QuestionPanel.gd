extends Panel

var drag = false
var offset = Vector2.ZERO
var on_screen = false

#signal location_updated(name: String, location: Vector2)
signal panel_hidden

var shown_location = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	shown_location = Global.config.get_value("ui", name, Vector2(280, 600))
	_resize_panel()

func _resize_panel():
	size = Global.config.get_value("ui", "QuestionPanel_size", Vector2(600,50))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if drag:
		global_position = get_viewport().get_mouse_position() + offset

func _on_gui_input(_event):
	if Input.is_action_pressed("click"):
		if !drag:
			drag = true
			offset = global_position - get_viewport().get_mouse_position()
	else:
		if drag == true:
			drag = false
			shown_location = global_position
			Global.config.set_value("ui", name, global_position)
			Global.save_settings()

func animate_in(_play_audio, message_length, duration):
	var tween = get_tree().create_tween()
	show_panel(tween)
	tween.tween_callback(_play_audio)
	tween.tween_property(%QuestionMessage, "visible_characters", message_length, duration).set_trans(Tween.TRANS_LINEAR)
	animate_out(tween).set_delay(3)
	tween.tween_callback(hide_panel)
	
func show_panel(tween):
	show()	
	on_screen = true 
	return tween.tween_property(self, "global_position", shown_location, 0.2).set_ease(Tween.EASE_OUT)
	
func hide_panel():
	%QuestionMessage.visible_characters = 0
	panel_hidden.emit()
	
func animate_out(tween):
	on_screen = false
	return tween.tween_property(self, "global_position", Vector2(self.global_position.x, %OffscreenTarget.global_position.y), 0.2)

func _on_message_width_text_submitted(new_text):
	size = Vector2(int(new_text), size.y)

func _on_message_height_text_submitted(new_text):
	size = Vector2(size.x, int(new_text))

func _on_show_panel_pressed():
	var tween = get_tree().create_tween()
	
	if on_screen:
		animate_out(tween)
	else:
		show_panel(tween)
