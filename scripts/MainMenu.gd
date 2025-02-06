extends Panel

func _ready():
	switch_panel(%Default)

func toggle_menu():
	if is_visible():
		hide()
	else:
		_show_menu()


func _show_menu():
	%CountdownTimer.load_settings()

	switch_panel(%Default)
	show()
	

func _input(event):
	if event.is_action_pressed("menu"):
		toggle_menu()


func _on_quit_pressed():
	get_tree().quit()

func switch_panel(panel: Control):
	get_tree().call_group("SettingPanels", "hide")
	panel.show()

func _on_settings_pressed():
	for item in Global.api_settings:
		_set_input_value("%api_"+item, Global.config.get_value("api", item))
		
	var panel_size = Global.config.get_value("ui", "QuestionPanel_size", Vector2(600, 100))
	_set_input_value("%ui_question_width", panel_size.x)	
	_set_input_value("%ui_question_height", panel_size.y)	
	
	switch_panel(%Settings)


func _on_save_pressed():
	for item in Global.api_settings:
		Global.config.set_value("api", item, _get_input_value("%api_"+item))

	Global.config.set_value("ui", "QuestionPanel_size", %QuestionPanel.size)
	
	Global.config.set_value("timer", "title", %CountdownTimer.title)
	Global.config.set_value("timer", "volume_db", %CountdownTimer.get_volume())
	Global.config.set_value("timer", "total_duration", %CountdownTimer.total_duration)
	Global.save_settings()
	
	_show_menu()

func _set_input_value(input, value):
	var field = get_node(input)
	
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
	var node_name = input
	var field = get_node(node_name)
	
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
	%CountdownTimer.load_settings()
	
	_set_input_value("%VolumeSlider", %CountdownTimer.get_volume())
	_set_input_value("%TimerTitle", %CountdownTimer.title)

	_set_input_value("%Hours", %CountdownTimer.total_hours())
	_set_input_value("%Minutes", %CountdownTimer.total_minutes())
	switch_panel(%Timer)


func _on_volume_slider_value_changed(value: float) -> void:
	%CountdownTimer.set_volume(int(value))


func _on_hours_value_changed(value: float) -> void:
	print("Hours: ", value)
	%CountdownTimer.set_duration(int(value), int(%Minutes.value))


func _on_minutes_value_changed(value: float) -> void:
	%CountdownTimer.set_duration(int(%Hours.value), int(value))
