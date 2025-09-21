extends Control

@export var title: String = Global.config.get_value("timer", "title", "Default Timer")
@export var duration_left: int = Global.config.get_value("timer", "total_duration", 1800)
@export var total_duration: int = Global.config.get_value("timer", "total_duration", 1800)
@export var elapsed: float = 0
@export var active: bool = false

var completed = false
var zoom_duration = 0.3

@onready var tween = Tween

func _ready() -> void:		
	reset_timer()
	load_settings()
	
func load_settings() -> void:
	%AudioStreamPlayer2D.volume_db = Global.config.get_value("timer", "volume_db", %AudioStreamPlayer2D.volume_db)
	title = Global.config.get_value("timer", "title", "Default Timer")
	
	if !active:
		duration_left = Global.config.get_value("timer", "total_duration", 1800)
		
	total_duration = Global.config.get_value("timer", "total_duration", 1800)

func start_timer():
	completed = false
	active = true
	show_with_zoom()
	
func complete_timer():
	active = false
	completed = true
	
	show_with_zoom()
	%TimerDisplay.animate()
	
func stop_timer():
	active = false
	completed = false	
	
func reset_timer():
	completed = false
	duration_left = total_duration
	elapsed = 0

	stop_timer()	
	show_with_zoom()
	_update_display()	

func show_with_zoom() -> void:
	visible = true
	tween = get_tree().create_tween()
	tween.tween_property(%TimerDisplay, "scale", Vector2(1,1), zoom_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func hide_with_zoom():
	tween = get_tree().create_tween()
	tween.tween_property(%TimerDisplay, "scale", Vector2(0, 0), zoom_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(_on_zoom_out_finished)  # Hide after shrinking
		
func _on_zoom_out_finished():
	visible = false  # Fully hide after zooming out	

func hours() -> int:
	return duration_left / 3600

func minutes() -> int:
	return (duration_left % 3600) / 60
	
func seconds() -> int:
	return duration_left % 60

func total_hours() -> int:
	return total_duration / 3600

func total_minutes() -> int:
	return (total_duration % 3600) / 60
	
func total_seconds() -> int:
	return total_duration % 60

func _update_display():
	%Title.text = title		
	%ProgressBar.max_value = total_duration		
	%ProgressBar.value = duration_left
	
	%TimeLeft.text = "%d:%02d:%02d" % [hours(), minutes(), seconds()]

func _physics_process(delta: float) -> void:			
	if active:
		if duration_left > 0:
			elapsed += delta	
			if elapsed > 1:
				duration_left -= 1
				elapsed -= 1
		else:
			completed = true
		
	if completed:
		complete_timer()
	else:
		%TimerDisplay.stop_animation()
		
	_update_display()	

func get_volume() -> int:
	return %AudioStreamPlayer2D.volume_db
	
func set_volume(db: int) -> void:
	%AudioStreamPlayer2D.volume_db = db

func _update_title(new_text: String) -> void:
	title = new_text
	
func set_duration(hours:int, minutes: int) -> void:
	print(hours, ":", minutes)
	total_duration = (hours * 3600) + (minutes * 60)
	if !active:
		duration_left = total_duration

func _on_main_menu_timer_volume(volume) -> void:
	set_volume(volume)
