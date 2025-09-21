extends Object

class_name Duration

var duration: int = 0

func _init(d: int):
	duration = d
	
func hours() -> int:
	return duration / 3600

func minutes() -> int:
	return (duration % 3600) / 60
	
func seconds() -> int:
	return duration % 60

func update(hours:int, minutes: int) -> void:
	print(hours, ":", minutes)
	duration = (hours * 3600) + (minutes * 60)
