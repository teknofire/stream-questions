extends Label

func update_counts(current, count):
	var newtext = "Queue: %s/%s" % [current, count]
	
	if text != newtext:
		text = newtext
		get_parent().animate()
