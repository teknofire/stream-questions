extends PanelContainer

signal timer_volume(volume: int)
signal settings_updated

var tween: Tween

func _ready():
	_load_settings()
	show()

func _on_visibility_changed():
	if visible:
		_show_menu()

func toggle_menu():
	if is_visible():
		hide_with_fade()
	else:
		show()

func hide_with_fade():
	if not visible:
		return
	if tween and tween.is_running():
		tween.kill()
		
	self.modulate.a = 1.0 
	
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25) # Fade in over 0.5s
	tween.tween_callback(self.hide)

func _show_menu():
	if tween and tween.is_running():
		tween.kill()
	
	switch_panel(%Settings)
	
	self.modulate.a = 0.0  # Start invisible
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25) # Fade in over 0.5s
	

func _input(event):
	if event.is_action_pressed("menu"):
		toggle_menu()

func _on_quit_pressed():
	get_tree().quit()

func switch_panel(panel: Control):
	var btn:Button = get_node("%%%sButton" % [panel.name])
	btn.button_pressed = true
	
	get_tree().call_group("SettingPanels", "hide")
	panel.show()

func _load_settings():
	_set_input_value(%api_enabled, Global.config.get_value("api", "enabled", false))
	_set_input_value(%api_url, Global.config.get_value("api", "url", "https://questions.teknofire.net"))
	_set_input_value(%api_key, Global.config.get_value("api", "key", ""))
	for item in Global.printer_settings:
		_set_input_value("%printer_"+item, Global.config.get_value("printer", item))
		
	var panel_size = Global.config.get_value("ui", "QuestionPanel_size", Vector2(600, 100))
	_set_input_value(%ui_question_width, panel_size.x)	
	_set_input_value(%ui_question_height, panel_size.y)	

	_set_input_value("%VolumeSlider", Global.config.get_value("timer", "volume_db"))
	_set_input_value("%TimerTitle", Global.config.get_value("timer", "title", "Remaining Time"))

	var duration = Duration.new(Global.config.get_value("timer", "total_duration", 1800))
	_set_input_value("%Hours", duration.hours())
	_set_input_value("%Minutes", duration.minutes())

func _on_settings_pressed():
	switch_panel(%Settings)
	

func _on_save_pressed():
	for item in Global.api_settings:
		Global.config.set_value("api", item, _get_input_value("%api_"+item))
	for item in Global.printer_settings:
		Global.config.set_value("printer", item, _get_input_value("%printer_"+item))	
		
	Global.config.set_value("ui", "QuestionPanel_size", %QuestionPanel.size)
	
	Global.config.set_value("timer", "title", %TimerTitle.text)
	Global.config.set_value("timer", "volume_db", %VolumeSlider.value)
	var d = Duration.new(0)
	d.update(int(%Hours.value), int(%Minutes.value))
	Global.config.set_value("timer", "duration",d.duration)
		
	Global.save_settings()
	settings_updated.emit()

func _set_input_value(input, value):
	var field 
	if typeof(input) == TYPE_OBJECT:
		field = input
	else:	
		field = get_node(input)
	
	if value == null:
		value = ""	
			
	match field.get_class():
		"LineEdit":
			field.text = "%s" % value
		"CheckButton":
			field.button_pressed = value
		"HSlider":
			field.value = value
		"SpinBox":
			field.value = value

func _get_input_value(input):
	var field 
	if typeof(input) == TYPE_OBJECT:
		field = input
	else:	
		field = get_node(input)
	
	if !field:
		return
	
	match field.get_class():
		"LineEdit":
			var v = field.text
			if v.length() == 0:
				v = field.placeholder_text
			
			if v.length() == 0:
				return ""
				
			return v
		"SpinBox":
			return field.value
		"CheckButton":
			return field.button_pressed


func _on_resume_pressed():
	toggle_menu()

func _on_timer_pressed() -> void:
	switch_panel(%Timer)


func _on_volume_slider_value_changed(value: float) -> void:
	timer_volume.emit(value)
