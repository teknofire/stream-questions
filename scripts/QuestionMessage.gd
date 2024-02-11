extends Label

var drag = false
var offset = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


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
