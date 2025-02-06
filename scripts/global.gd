extends Node

var config: ConfigFile = ConfigFile.new()
var config_file = "user://questions.cfg"
var api_settings = ["enabled", "url", "key"]
var ws_settings = ["port"]

signal dragging
signal dropped

func _init():
	load_settings()


func save_settings():
	config.save(config_file)


func load_settings():
	var err = config.load(config_file)
	if err != OK:
		push_error("Unable to load config file: ", config_file)
