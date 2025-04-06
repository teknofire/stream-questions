extends Label

func update_counts(current, count):
	var newtext = "Queue: %0.0d/%0.0d" % [current, count]
	
	if text != newtext:
		text = newtext
		get_parent().animate()
