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


func show_message(message: String):
	%Message.text = message


func update_queue_count():
	print("update queue count")
	QuestionApi.fetch_stats()	


func _on_play_question_clicked():
	if !playing_question:
		QuestionApi.current_question(_on_question_fetched, _on_question_failed)


func _on_replay_question_clicked():
	if !playing_question:
		playing_replay = true
		QuestionApi.replay_question(_on_question_fetched, _on_question_failed)


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
