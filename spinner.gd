extends Node2D

@export var radius: int = 100
@export_range(1, 1000) var segments : int = 100
@export var width : int = 10
#@export var color : Color = Color.GREEN
@export var antialiasing : bool = false

var _point2 : Vector2

var colors = [
	Color(1.0, 0.0, 0.0, 1.0), 
	Color(0.5, 0.0, 0.0, 1.0), 
	Color(1.0, 1.0, 0.0, 1.0), 
	Color(0.5, 1.0, 0.0, 1.0), 
	Color(1.0, 0.0, 1.0, 1.0), 
	Color(0.5, 0.0, 1.0, 1.0), 
	Color(1.0, 1.0, 1.0, 1.0), 
	Color(0.5, 1.0, 1.0, 1.0), 
	Color(1.0, 0.5, 1.0, 1.0), 
	Color(0.5, 0.5, 1.0, 1.0), 
	Color(1.0, 0.5, 0.5, 1.0), 
	Color(0.5, 0.5, 0.5, 1.0), 
	Color(1.0, 1.0, 0.5, 1.0), 
	Color(0.5, 1.0, 0.5, 1.0), 
]

@export var rotation_speed : float = 1
var center: Vector2

func _ready():
	center = get_viewport_rect().size / 2.0
	print(center)
	#var tween = create_tween()
	#tween.tween_property(self, "rotation", PI, 5)
	#tween.tween_callback(queue_redraw)

func _process(delta):
	#var tween = create_tween()
	#tween.tween_property(self, "rotation", PI, 5)
	#tween.tween_callback(queue_redraw)
	pass 
	
func _draw():	
	draw_set_transform(center)
	var current = 0
	var step = 360.0 / segments
	
	for angle in range(step, 360, step):
		draw_circle_arc_poly(Vector2(0,0), radius, current, angle, colors.pick_random())
		current = angle
		
	draw_circle_arc_poly(Vector2(0,0), radius, current, 360, colors.pick_random())


func draw_circle_arc_poly(center, radius, angle_from, angle_to, color):
	var nb_points = 32
	var points_arc = PackedVector2Array()
	points_arc.push_back(center)
	var colors = PackedColorArray([color])

	for i in range(nb_points + 1):
		var angle_point = deg_to_rad(angle_from + i * (angle_to - angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
		
	draw_polygon(points_arc, colors)
