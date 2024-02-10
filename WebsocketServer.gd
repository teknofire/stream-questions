extends Node

# The port we will listen to.
@export var PORT = 9000
var tcp_server := TCPServer.new()
var socket := WebSocketPeer.new()

signal next
signal replay
signal clear_cache

func log_message(message):
	var json = JSON.new()
	var err = json.parse(message)
	if err != OK:
		push_error("Unable to decode message from websocket")
	else:	
		var data = json.data
		if data.event == "keyUp":
			_handle_button_press(data.payload.settings.id, data.event)


func _handle_button_press(id, event):
	if event == "keyUp":
		print("Recieved %s with %s" % [event, id])
		match id:
			"next":
				next.emit()
			"replay":
				replay.emit()
			"clear_cache":
				clear_cache.emit()


func _ready():
	if tcp_server.listen(PORT) != OK:
		log_message("Unable to start server.")
		set_process(false)


func _process(_delta):
	while tcp_server.is_connection_available():
		var conn: StreamPeerTCP = tcp_server.take_connection()
		assert(conn != null)
		socket.accept_stream(conn)

	socket.poll()

	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			log_message(socket.get_packet().get_string_from_ascii())


func _exit_tree():
	socket.close()
	tcp_server.stop()


func _on_button_pong_pressed():
	socket.send_text("Pong")

