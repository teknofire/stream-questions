extends ScrollContainer

func _ready() -> void:
	get_v_scroll_bar().connect("changed", _on_scroll_container_resized)

func _on_scroll_container_resized() -> void:
	scroll_vertical = get_v_scroll_bar().max_value
