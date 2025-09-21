extends Control

var clicked: Node
var play_error_count = 0
var playing_question = false
var playing_replay = false

func _ready():
	get_tree().get_root().set_transparent_background(true)
	QuestionApi.setup(%HTTPManager)
	QuestionApi.stats_updated.connect(%QueueSize.update_counts)
	
	Global.dragging.connect(show_cross)
	Global.dropped.connect(hide_cross)
	
	%UpdateTimer.start()
	update_queue_count()
	
	start_ws()
	
	#var setup_successful: bool = await Twitch.setup()
	#if setup_successful:
		#print("Twitch Service successfully set up and authenticated!")
		#await get_self_info()
	#else:
		#printerr("Twitch Service setup Failed")

func stop_ws():
	%WebsocketServer.stop()
	
func start_ws():
	var ws_port = int(Global.config.get_value('ws', 'port'))
	if ws_port > 0:
		%WebsocketServer.listen(ws_port)	

#func get_self_info():
	#var current_user: TwitchUser = await Twitch.get_current_user()
	#if current_user:
		#print("Authenticated as: %s (ID: %s)" %[current_user.display_name, current_user.id])
	#else:
		#printerr("Count not get current user info")

func show_message(message: String):
	%Message.text = message


func update_queue_count():
	print("update queue count")
	QuestionApi.fetch_stats()	

func _on_question_failed():
	playing_replay = false
	if !$AudioStreamPlayer2D.is_playing():
		play_error_count += 1
		if (play_error_count % 2) == 0:
			$AudioStreamPlayer2D.stream = preload("res://assets/sad_trombone.wav")
		else:
			$AudioStreamPlayer2D.stream = preload("res://assets/Error.wav")
		$AudioStreamPlayer2D.play()


func show_cross() -> void:
	%CenterCross.show()
	
func hide_cross() -> void:
	%CenterCross.hide()

func _on_question_fetched(question, audiofile):
	playing_question = true 
	
	var file = FileAccess.open(audiofile, FileAccess.READ)
	var sound = AudioStreamMP3.new()
	sound.data = file.get_buffer(file.get_length())

	$AudioStreamPlayer2D.stream = sound	
	%QuestionMessage.text = question
	%QuestionPanel.animate_in(_play_audio, question.length(), sound.get_length())


func _play_audio():
	$AudioStreamPlayer2D.play()		


func _on_timer_timeout():
	play_error_count = 0
	update_queue_count()


func _on_question_panel_hidden():
	if !playing_replay:
		QuestionApi.next_question()
	playing_question = false
	playing_replay = false

func _on_clear_cache_pressed():
	QuestionApi.clear_cache()

func _on_websocket_server_timer(command: String) -> void:
	match command:
		"start":
			%CountdownTimer.start_timer()
		"stop":
			%CountdownTimer.stop_timer()
		"reset":
			%CountdownTimer.reset_timer()
		"complete":
			%CountdownTimer.complete_timer()
		"toggle":
			if %CountdownTimer.visible:
				%CountdownTimer.hide_with_zoom()
			else:
				%CountdownTimer.show_with_zoom()

func _print_on_question_available(question, audiofile):
	playing_question = true
	var port = Global.config.get_value("printer", "port").to_int()
	var ok := await Printer.open(Global.config.get_value("printer", "ip"), port)
	if not ok:
		push_error("Could not connect to printer")
		return 
	
	Printer.print_receipt(
		Global.config.get_value("printer", "header"), 
		Global.config.get_value("printer", "subheader"), 
		question
	)
	
	Printer.close()
	if !playing_replay:
		QuestionApi.next_question()
	playing_question = false
	playing_replay = false

func _on_websocket_server_question(command: String) -> void:
	print_debug("Got question event: %s" %[command])
	if !playing_question:
		match command:
			"clear_cache":
				QuestionApi.clear_cache()
			"next":
				QuestionApi.current_question(_on_question_fetched, _on_question_failed)
			"replay":
				playing_replay = true
				QuestionApi.replay_question(_on_question_fetched, _on_question_failed)
			"print":
				QuestionApi.current_question(_print_on_question_available, _on_question_failed)
			"print_previous":
				playing_replay = true
				QuestionApi.replay_question(_print_on_question_available, _on_question_failed)


func _on_websocket_server_client_connected(peer_id: int) -> void:
	print("Client Connected: %d" % [peer_id])


func _on_websocket_server_client_disconnected(peer_id: int) -> void:
	print("Client Disconnected: %d" % [peer_id])

signal timer(command: String)
signal question(command: String)

func _handle_event(event, action):
	if event == "keyUp":
		print("Recieved %s with %s" % [event, action])
		
	match action.to_lower():
		"next":  # backwards compat
			question.emit("next")
		"replay":  # backwards compat
			question.emit("next")
		"questions.next":
			question.emit("next")
		"questions.replay":
			question.emit("replay")	
		"questions.print":
			question.emit("print")	
		"questions.print_prev":
			question.emit("print_prev")
		"questions.clear_cache":
			question.emit("clear_cache")
		"clear_cache":
			question.emit("clear_cache")
		"timer.start":
			timer.emit('start')
		"timer.stop":
			timer.emit('stop')
		"timer.reset":
			timer.emit('reset')
		"timer.toggle":
			timer.emit('toggle')
		"timer.complete":
			timer.emit('complete')	

func _on_websocket_server_message_received(peer_id: int, message: String) -> void:
	print_debug(message)
	
	var json = JSON.parse_string(message)
	_handle_event(json["event"], json["payload"]["settings"]["id"])
	
func _on_port_ws_port_changed() -> void:
	stop_ws()
	start_ws()
