extends Node

class_name QuestionApiClass

var audio_file = "user://question_audio_file.mp3"
var questions: QuestionApiClient

signal stats_updated(current: String, count: String)
signal audio_fetched(audio_file: String)
signal question_fetched(question: Dictionary, audio_file: String)

func setup(manager):
	questions = QuestionApiClient.new(manager)

	
func is_enabled() -> bool:
	return Global.config.get_value("api", "enabled", false)


func current_question(callback: Callable, failure: Callable):
	if is_enabled():
		if !questions.current_question(callback):
			failure.call()


func replay_question(callback: Callable, failure: Callable):
	if is_enabled():
		if !questions.replay_question(callback):
			failure.call()


func next_question():
	if is_enabled():
		questions.next(fetch_stats)


func clear_cache():
	questions.clear_cache()


func _handle_failure(_result):
	push_error("Failed to perform client request")


func fetch_stats():
	if is_enabled():
		questions.stats(_signal_stats_update)


func _signal_stats_update(stats):
	stats_updated.emit(stats["current"], stats["count"])

######################################

class QuestionApiClient:
	var http: HTTPManager
	var cache_path = "user://questions_cache"
	var current_stats: Dictionary
	var last_question: Dictionary
	
	func _init(manager):
		http = manager
		http.timeout = 10.0
		
	### STATS Stuff ###
	
	func stats(callback: Callable):
		return _request(
			api_url()
		).on_success(
			_handle_stats.bind(callback)
		).on_failure(
			_handle_failure
		).fetch()
		
	func _handle_stats(result, callback: Callable):
		current_stats = result.fetch()
		
		if current_stats.has("question"):
			# Precache the question audio for the next question
			_fetch_audio(current_stats["question"])
		
		callback.call(current_stats)		
		
	func _handle_failure(result):
		push_error("Request failed: [%s] %s" % [result.response_code, result.fetch()])
		
	###################

	func play_question(stats, callback: Callable) -> bool:
		if stats.has("question"):
			_fetch_audio(stats["question"], callback)
			return true 
		
		return false

	### Return information for the last question ###
	func current_question(callback: Callable) -> bool:
		return play_question(current_stats, callback)
		
	### Return information for the last question ###
	func replay_question(callback: Callable) -> bool:
		if last_question:
			_fetch_audio(last_question, callback)
			return true
			
		return false


	func _fetch_audio(question, success = null):
		question["filename"] = "%s/question_%s.mp3" % [cache_path, question["id"]]
		
		if FileAccess.file_exists(question["filename"]):
			print("found cached audio")
			if success:
				_handle_audio_success.call({}, question, success)
		else:
			print("fetching audio")
			var job = _request(question["play"]).on_failure(
				_handle_audio_failure.bind(question["filename"])
			)
			if success:
				job.on_success(
					_handle_audio_success.bind(question, success)
				)
			
			job.download(question["filename"])
	
	func _handle_audio_failure(_result, filename):
		if FileAccess.file_exists(filename):
			var d = DirAccess.open(cache_path)
			d.remove(filename)
		
	func _handle_audio_success(_result, question, callback: Callable):
		last_question = question
		callback.call(question["question"], question["filename"])
	
	### Update queue to the next question ###
	func next(callback: Callable):
		_request(api_url("next")).on_success(_handle_next_update.bind(callback)).fetch()
		
	func _handle_next_update(_result, callback: Callable):
		callback.call()
		
	### Build a request ###
	
	func clear_cache():
		var d = DirAccess.open(cache_path)
		for file in DirAccess.get_files_at(cache_path):
			d.remove(file)
	
	func api_url(endpoint: String = "") -> String:
		var uri = [
			Global.config.get_value("api", "url")
		]
		if endpoint.length() > 0:
			uri.append(endpoint)
				
		return "/".join(uri) + ".json"
	
	func _request(uri):
		return http.job(uri).add_header(
			"Authorization", "Bearer %s" % Global.config.get_value("api", "key")
		)
