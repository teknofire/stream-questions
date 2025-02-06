extends PanelContainer

var dragging: bool = false
var offset: Vector2

const BWAAAM = preload("res://assets/Bwaaam.wav")

@onready var tween = get_tree().create_tween()

func _ready() -> void:
	global_position = Global.config.get_value("ui", "countdown_timer_position", Vector2(10,10))
	pivot_offset = size / 2

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if get_global_rect().has_point(event.position):
					dragging = true
					Global.dragging.emit()
					offset = event.position - global_position
			else:
				dragging = false
				Global.dropped.emit()
				Global.config.set_value("ui", "countdown_timer_position", global_position)
				Global.save_settings()
				
	elif event is InputEventMouseMotion and dragging:
		global_position = event.position - offset
		
var animating = false 
func animate() -> void:
	var angle = 15  # Degrees to rotate left and right
	var duration = 0.2  # Time for each rock movement
	
	if animating || %AudioStreamPlayer2D.is_playing(): 
		return 
		
	animating = true
	play_audio()
	
	for i in range(3):  # Loop 3 times
		# terminate any previous tweens
		tween.kill()
					
		tween = get_tree().create_tween()

		# Create rocking motion
		tween.tween_property(self, "rotation_degrees", angle, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "rotation_degrees", -angle, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		
	reset_animation()
	
func reset_animation():
	tween = get_tree().create_tween()	
	tween.tween_property(self, "rotation_degrees", 0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	animating = false
	

func play_audio():
	if !%AudioStreamPlayer2D.is_playing():
		print("BWWAAAMMM")
		%AudioStreamPlayer2D.stream = BWAAAM
		%AudioStreamPlayer2D.play()		


var stopping = false
func stop_animation():
	if stopping:
		return
	var volume_db = %AudioStreamPlayer2D.volume_db
	
	stopping = true
	if animating:
		print("stopping animation")
		tween.kill()
		reset_animation()
		
	# Fade out the active audio before stopping
	if %AudioStreamPlayer2D.is_playing():
		tween = get_tree().create_tween()
		tween.tween_property(%AudioStreamPlayer2D, "volume_db", -24, 1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT_IN)
		await tween.finished
		%AudioStreamPlayer2D.stop()
		%AudioStreamPlayer2D.volume_db = volume_db

	stopping = false
