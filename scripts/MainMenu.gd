extends Panel

func toggle_menu():
	if is_visible():
		hide()
	else:
		_show_menu()


func _show_menu():
	%Settings.hide()
	%Default.show()
	show()
	

func _input(event):
	if event.is_action_pressed("menu"):
		toggle_menu()


func _on_quit_pressed():
	get_tree().quit()


func _on_settings_pressed():
	for item in Global.api_settings:
		_set_input_value("%api_"+item, Global.config.get_value("api", item))
		
	var panel_size = Global.config.get_value("ui", "QuestionPanel_size", Vector2(600, 100))
	_set_input_value("%ui_question_width", panel_size.x)	
	_set_input_value("%ui_question_height", panel_size.y)	
	
	%Default.hide()
	%Settings.show()


func _on_save_pressed():
	for item in Global.api_settings:
		Global.config.set_value("api", item, _get_input_value("%api_"+item))

	Global.config.set_value("ui", "QuestionPanel_size", %QuestionPanel.size)
			
	Global.save_settings()
	
	_show_menu()



func _set_input_value(input, value):
	var field = get_node(input)
	
	match field.get_class():
		"LineEdit":
			field.text = "%s" % value
		"CheckButton":
			field.button_pressed = value


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
		"CheckButton":
			return field.button_pressed


func _on_resume_pressed():
	toggle_menu()
