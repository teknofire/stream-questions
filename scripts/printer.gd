extends Node

# ----------------------------
# ESC/POS constants
# ----------------------------
const ESC: int = 0x1B
const GS:  int = 0x1D

# Command prefixes
const CMD_INIT:               Array = [ESC, 0x40]   # ESC @
const CMD_ALIGN:              Array = [ESC, 0x61]   # ESC a n
const CMD_BOLD:               Array = [ESC, 0x45]   # ESC E n
const CMD_TEXT_SIZE:          Array = [GS,  0x21]   # GS ! n
const CMD_LINE_FEED:          Array = [ESC, 0x64]   # ESC d n
const CMD_CUT:                Array = [GS,  0x56]   # GS V m [n]
const CMD_DRAWER_PULSE:       Array = [ESC, 0x70]   # ESC p m t1 t2
const CMD_SELECT_CODEPAGE:    Array = [ESC, 0x74]   # ESC t n

# Common params
enum Align { LEFT = 0, CENTER = 1, RIGHT = 2 }

# GS ! n text size flags
const SIZE_NORMAL      = 0x00  # 1x width, 1x height
const SIZE_DOUBLE_H    = 0x01  # 1x width, 2x height
const SIZE_DOUBLE_W    = 0x10  # 2x width, 1x height
const SIZE_DOUBLE_HW   = 0x11  # 2x width, 2x height

# Cut modes
const CUT_FULL:    int = 0x41
const CUT_PARTIAL: int = 0x42

# CRLF as const Array (convert when used)
const CRLF: Array = [0x0D, 0x0A]

# Codepages (printer-dependent)
const CP_CP437:   int = 0
const CP_CP850:   int = 2
const CP_WIN1252: int = 17
const DEFAULT_CODEPAGE: int = CP_WIN1252

# Paper width (chars) — adjust for your printer (42: 80mm, ~32: 58mm)
const PAPER_CHARS: int = 46

# ----------------------------
# TCP basics
# ----------------------------
var _tcp := StreamPeerTCP.new()
var _connected := false
var _host := ""
var _port := 9100
var _timeout_sec := 2.0

# --- Public API ---

func open(host: String, port: int = 9100, timeout_sec: float = 2.0) -> bool:
# Always start with a fresh socket
	if _tcp:
		_tcp.disconnect_from_host()
	_connected = false
	_tcp = StreamPeerTCP.new()

	# Resolve IPv4 address (some printers don't play with IPv6)
	var ip := host
	var err := _tcp.connect_to_host(ip, port)
	# In Godot 4, connect_to_host is non-blocking; ERR_BUSY means "connecting"
	if err != OK and err != ERR_BUSY:
		push_warning("TCP connect start failed: %s" % err)
		return false

	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		# Let the socket progress
		_tcp.poll()
		var status := _tcp.get_status()
		if status == StreamPeerTCP.STATUS_CONNECTED:
			# Optional: disable Nagle for small ESC/POS writes
			_tcp.set_no_delay(true)
			_connected = true
			_host = ip
			_port = port
			_timeout_sec = timeout_sec
			return true
		elif status == StreamPeerTCP.STATUS_ERROR:
			push_warning("TCP status error while connecting")
			break
		# Yield a frame to avoid blocking the main thread (do NOT use OS.delay_msec here)
		await get_tree().process_frame

	# Timeout or error
	_tcp.disconnect_from_host()
	_connected = false
	return false

func is_printer_connected() -> bool:
	return _connected and _tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED

func close():
	_tcp.disconnect_from_host()
	_connected = false

func send_bytes(data: PackedByteArray) -> bool:
	if not is_printer_connected():
		push_warning("Not connected; cannot send.")
		return false
	var err := _tcp.put_data(data)
	if err != OK:
		push_warning("put_data error: %s" % err)
		return false
	return true
	
	# ----------------------------
# ESC/POS helpers (const Arrays -> PackedByteArray at send)
# ----------------------------

func escpos_init() -> bool:
	return send_bytes(PackedByteArray(CMD_INIT))

func escpos_set_codepage(n: int = DEFAULT_CODEPAGE) -> bool:
	var payload: Array = CMD_SELECT_CODEPAGE + [n]
	return send_bytes(PackedByteArray(payload))

func escpos_align(where: int = Align.LEFT) -> bool:
	var payload: Array = CMD_ALIGN + [where]
	return send_bytes(PackedByteArray(payload))

func escpos_bold(enable: bool) -> bool:
	var payload: Array = CMD_BOLD + [1 if enable else 0]
	return send_bytes(PackedByteArray(payload))

func escpos_size(size_flag: int = SIZE_NORMAL) -> bool:
	var payload: Array = CMD_TEXT_SIZE + [size_flag]
	return send_bytes(PackedByteArray(payload))

func escpos_feed(n: int = 1) -> bool:
	n = max(1, n)
	var payload: Array = CMD_LINE_FEED + [n]
	return send_bytes(PackedByteArray(payload))

func escpos_cut() -> bool:
	# Some printers require trailing 0x00
	var payload: Array = CMD_CUT + [CUT_FULL, 0x00]
	return send_bytes(PackedByteArray(payload))

func escpos_partial_cut() -> bool:
	# Some printers require trailing 0x00
	var payload: Array = CMD_CUT + [CUT_PARTIAL, 0x00]
	return send_bytes(PackedByteArray(payload))

# Write text with newline using a simple Latin approximation.
func write_line(text: String, add_crlf: bool = true, codepage: int = DEFAULT_CODEPAGE) -> bool:
	escpos_set_codepage(codepage)
	var bytes := _latin_approx(text)
	if add_crlf:
		bytes.append_array(PackedByteArray(CRLF))
	return send_bytes(bytes)
	
# Crude ASCII/Latin-1-ish approximation: preserves ASCII; others -> '?'
func _latin_approx(s: String) -> PackedByteArray:
	var out := PackedByteArray()
	for ch in s:
		var code := ch.unicode_at(0)
		if code >= 0x20 and code <= 0x7E:
			out.append(code)
		elif code == 0x0A: # LF
			out.append(0x0A)
		elif code == 0x09: # TAB
			out.append(0x09)
		else:
			out.append(0x3F) # '?'
	return out

func escpos_wrap_and_print(text: String, width: int = PAPER_CHARS):
	var words := text.split(" ", false)
	var line := ""
	for w in words:
		if (line.length() + w.length() + 1) > width:
			write_line(line)
			line = w
		else:
			if line == "":
				line = w
			else:
				line += " " + w
	if line != "":
		write_line(line)

func print_receipt(header: String, subline: String, message: String):
	if not is_printer_connected(): return false
	
	escpos_init()
	escpos_align(Align.CENTER)
	escpos_bold(true)
	escpos_size(SIZE_DOUBLE_HW)
	write_line(header)
	escpos_size(SIZE_NORMAL)
	write_line(subline)
	escpos_bold(false)
	escpos_feed(1)
	
	escpos_align(Align.LEFT)
	write_line("-".repeat(PAPER_CHARS), true)
	
	escpos_feed(1)
	escpos_wrap_and_print(message)
	escpos_feed(4)
	escpos_partial_cut()
