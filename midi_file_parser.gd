"""
Midi File Parser
@author BrainFooLong
@url https://github.com/brainfoolong/gdscript-midi-parser
""" 

class_name MidiFileParser

# set to "1" to print parsing debug output
# set to a string file path where to store debug output instead of printing
static var debug_output : String = "0"

# order of key names for a midi note
static var key_order = ["A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"]

"""
Load and parse a file by path
"""
static func load_file(path: String) -> MidiFileParser:
	return load_packed_byte_array(FileAccess.get_file_as_bytes(path))

"""
Load and parse a file by packed byte array
"""
static func load_packed_byte_array(arr: PackedByteArray) -> MidiFileParser:
	var instance = MidiFileParser.new()
	instance.bytes = arr
	if debug_output != "0":
		var debug = ""
		while true:
			var status = instance.parse()
			if status == MIDI_PARSER_EOB:
				debug += "eob\n"
				break
			elif status == MIDI_PARSER_ERROR:
				debug += "error\n"
				break
			elif status == MIDI_PARSER_INIT:
				debug += "init\n"
				continue
			elif status == MIDI_PARSER_HEADER:
				var header = instance.header
				debug += "header\n"
				debug += "    size: "+str(header.size)+"\n"
				debug += "    format: "+str(header.format)+"\n"
				debug += "    tracks count: "+str(header.tracks)+"\n"
				debug += "    time division: "+str(header.time_division)+"\n"
				continue
			elif status == MIDI_PARSER_TRACK:
				var track = instance.current_track
				debug += "track\n"
				debug += "    length: "+str(track.size)+"\n"
				continue
			elif status == MIDI_PARSER_TRACK_MIDI:
				var track = instance.current_track
				var midi = instance.current_midi
				debug += "track-midi (event "+str(track.events.size() - 1)+")\n"
				debug += "    time: "+str(track.delta_ticks)+"\n"
				debug += "    status: "+str(midi.status)+"\n"
				debug += "    channel: "+str(midi.channel)+"\n"
				debug += "    param1: "+str(midi.param1)+"\n"
				debug += "    param2: "+str(midi.param2)+"\n"
				continue
			elif status == MIDI_PARSER_TRACK_META:
				var track = instance.current_track
				var meta = instance.current_meta
				debug += "track-meta (event "+str(track.events.size() - 1)+")\n"
				debug += "    time: "+str(track.delta_ticks)+"\n"
				debug += "    type: "+str(meta.type)+"\n"
				debug += "    length: "+str(meta.length)+"\n"
				continue
			elif status == MIDI_PARSER_TRACK_SYSEX:
				var track = instance.current_track
				debug += "track-sysex (event "+str(track.events.size() - 1)+")\n"
				debug += "    time: "+str(track.delta_ticks)+"\n"
				continue
			else:
				debug += "Unhandled state " + str(status) +"\n"
				break
		if debug_output == "1":
			print(debug)
		else:
			var file = FileAccess.open(debug_output, FileAccess.WRITE)
			file.store_string(debug)
	else:
		while true:
			var status = instance.parse()
			if status == MIDI_PARSER_EOB || status == MIDI_PARSER_ERROR:
				break
	return instance

const MIDI_PARSER_EOB         = -2
const MIDI_PARSER_ERROR       = -1
const MIDI_PARSER_INIT        = 0
const MIDI_PARSER_HEADER      = 1
const MIDI_PARSER_TRACK       = 2
const MIDI_PARSER_TRACK_MIDI  = 3
const MIDI_PARSER_TRACK_META  = 4
const MIDI_PARSER_TRACK_SYSEX = 5

class Header:
	enum Format {
		SINGLE_TRACK = 0,
		MULTIPLE_TRACKS = 1,
		MULTIPLE_SONGS  = 2
	}
	var size: int = 0
	var format: Format = 0
	var tracks: int = 0
	var time_division: int = 480
	
class Track:
	var size : int
	var events : Array[Event] = []
	var midi : Array[Midi] = []
	var meta : Array[Meta] = []
	var sysex : Array[Sysex] = []
	var additional_data = {}
	var delta_ticks : int # internal value, changes during parsing
	var absolute_ticks : int = 0 # internal value, changes during parsing
	var end_byte_index = 0 # internal value, changes during parsing

class Event:
	enum EventType {
		META = 1,
		SYSEX = 2,
		MIDI = 3
	}
	var delta_ticks : int = 0 # relative ticks delta from the last event to this
	var absolute_ticks : int = 0 # absolute ticks from the start of the track
	var event_type: EventType = 0
	var additional_data = {}

class Midi extends Event:
	enum Status {
		NOTE_OFF = 0x8,
		NOTE_ON = 0x9,
		NOTE_AT = 0xA, # after touch
		CC = 0xB, # control change
		PGM_CHANGE = 0xC,
		CHANNEL_AT = 0xD, # after touch
		PITCH_BEND = 0xE
	}
	var status: Status = 0
	var channel: int = 0
	var param1: int = 0
	var param2: int = 0
	var octave : int = -1 # note octave, example 5
	var key : String = '' # note key, example E
	var note_name  : String = '' # note name, example E5
	var frequency : float = 0.0 # note frequency in hz
	var	velocity : float = 0.0 # note velocity between 0 and 1
	
class Meta extends Event:
	enum Type {
		SEQ_NUM = 0x00,
		TEXT = 0x01,
		COPYRIGHT = 0x02,
		TRACK_NAME = 0x03,
		INSTRUMENT_NAME = 0x04,
		LYRICS = 0x05,
		MAKER = 0x06,
		CUE_POINT = 0x07,
		CHANNEL_PREFIX = 0x20,
		END_OF_TRACK = 0x2F,
		SET_TEMPO = 0x51,
		SMPTE_OFFSET = 0x54,
		TIME_SIGNATURE = 0x58,
		KEY_SIGNATURE = 0x59,
		SEQ_SPECIFIC = 0x7F
	}
	var type: Type = 0
	var length: int = 0
	var bytes : PackedByteArray
	var value : int = 0
	var bpm : float = 120 # set in case of a SET_TEMPO event
	var ms_per_tick = 60000 / (120 * 480) # set in case of a SET_TEMPO event
	
class Sysex extends Event:
	var length: int = 0
	var bytes : PackedByteArray
	var value : int

# the midi file as byte array
var bytes : PackedByteArray
# current internal byteindex
var byte_index = 0
# current internal parse state
var state = MIDI_PARSER_INIT

# the midi header
var header = Header.new()
# all midi tracks
var tracks : Array[Track] = []
# current processed track
var current_track : Track
# current processed track-meta
var current_meta : Meta
# current processed track-sysex
var current_sysex : Sysex
# current processed track-midi
var current_midi : Midi

# internal helper vars
var prev_midi_status = 0
var prev_midi_channel = 0

"""
Parse data
Recall as often as MIDI_PARSER_EOB or MIDI_PARSER_ERROR state is returned
"""
func parse() -> int:
	if get_bytes_rest() < 1:
		return MIDI_PARSER_EOB
	if state == MIDI_PARSER_INIT:
		return parse_header()
	if state == MIDI_PARSER_HEADER:
		return parse_track()
	if state == MIDI_PARSER_TRACK:
		# we reached the end of the track
		if current_track.end_byte_index <= byte_index:
			state = MIDI_PARSER_HEADER
			return parse()
		return parse_event()
	return MIDI_PARSER_ERROR

"""
Parse the midi header
"""
func parse_header() -> int:
	if get_bytes_rest() < 14:
		return MIDI_PARSER_EOB
		
	var file_header = str_from_buffer(4)
	if file_header != "MThd":
		return MIDI_PARSER_ERROR
		
	header.size = int_from_buffer(4)
	header.format = int_from_buffer(2)
	header.tracks = int_from_buffer(2)
	header.time_division = int_from_buffer(2)
	state = MIDI_PARSER_HEADER
	return MIDI_PARSER_HEADER

"""
Parse a new track
"""
func parse_track() -> int:
	if get_bytes_rest() < 8:
		return MIDI_PARSER_EOB
	byte_index += 4
	current_track = Track.new()
	current_track.size = int_from_buffer(4)
	current_track.end_byte_index = byte_index + current_track.size
	tracks.append(current_track)
	prev_midi_status = 0
	state = MIDI_PARSER_TRACK
	return MIDI_PARSER_TRACK
	
"""
Parse current track time
Returns success boolean flag
"""
func parse_track_time() -> bool:
	var nbytes = 0
	var cont = 1
	current_track.delta_ticks = 0
	while (cont):
		++nbytes
		if (get_bytes_rest() < nbytes || current_track.end_byte_index <= byte_index):
			return false

		var b = int_from_buffer(1)
		current_track.delta_ticks = (current_track.delta_ticks << 7) | (b & 0x7f)

		if (current_track.delta_ticks > 0x0fffffff || nbytes > 5):
			return false

		cont = b & 0x80;
	current_track.absolute_ticks += current_track.delta_ticks
	return true


"""
Parse a tracks event
"""
func parse_event() -> int:
	if !parse_track_time():
		return MIDI_PARSER_EOB
		
	# Make sure the parser has not consumed the entire file or track, else
	# bytes might access heap-memory after the allocated buffer.
	if get_bytes_rest() <= 0 || current_track.size <= 0:
		return MIDI_PARSER_ERROR
		
	var channel_type = bytes[byte_index]
	if channel_type < 0xf0:
		# Regular channel events	
		return parse_channel_event()
	else:
		#  Special event types
		prev_midi_status = 0
		if channel_type == 0xf0:
			return parse_sysex_event()
		elif channel_type == 0xff:
			return parse_meta_event()
	return MIDI_PARSER_ERROR

"""
Parse a tracks channel event
"""
func parse_channel_event() -> int:
	if get_bytes_rest() < 2:
		return MIDI_PARSER_EOB
		
	current_midi = Midi.new()
	current_midi.delta_ticks = current_track.delta_ticks
	current_midi.event_type = current_meta.EventType.MIDI
	current_track.midi.append(current_midi)
	current_track.events.append(current_midi)
	
	var channel_type = bytes[byte_index]
	var byte_index_start = byte_index
	if (channel_type & 0x80) == 0:
		if (prev_midi_status == 0):
			return MIDI_PARSER_EOB
			
		current_midi.status  = prev_midi_status
		var datalen = get_event_datalen(current_midi.status)
		if get_bytes_rest() < datalen:
			return MIDI_PARSER_EOB
			
		current_midi.channel = prev_midi_channel
		if datalen > 0:
			current_midi.param1  = int_from_buffer(1)
		if datalen > 1:
			current_midi.param2  = int_from_buffer(1)
		
		byte_index = byte_index_start + datalen
	else:
		#  Full event with its own status.
		current_midi.status = (channel_type >> 4) & 0xf
		var datalen = get_event_datalen(current_midi.status)
		if get_bytes_rest() < 1 + datalen:
			return MIDI_PARSER_EOB
		current_midi.channel = channel_type & 0xf
		byte_index += 1
		if datalen > 0:
			current_midi.param1  = int_from_buffer(1)
		if datalen > 1:
			current_midi.param2  = int_from_buffer(1)
		prev_midi_status = current_midi.status
		prev_midi_channel = current_midi.channel
		byte_index = byte_index_start + datalen + 1
	if current_midi.status == current_midi.Status.NOTE_ON || current_midi.status == current_midi.Status.NOTE_OFF || current_midi.status == current_midi.Status.NOTE_AT:
		var midiKey = current_midi.param1 - 21
		current_midi.octave = floor((current_midi.param1 - 12) / 12)
		current_midi.key = key_order[midiKey - (current_midi.octave * 12)]
		current_midi.note_name = current_midi.key + str(current_midi.octave)
		current_midi.velocity = 1.0 / 127.0 * current_midi.param2
		current_midi.frequency = 440.0 * (2 ** ((current_midi.param1 - 69) / 12.0))
	return MIDI_PARSER_TRACK_MIDI
	
"""
Parse a tracks sysex event
"""
func parse_sysex_event() -> int:
	if !(get_bytes_rest() == 0 || bytes[byte_index] == 0xff) || get_bytes_rest() < 2:
		return MIDI_PARSER_ERROR
	
	var byte_index_meta_start = byte_index
	byte_index += 1
	
	current_sysex = Sysex.new()
	current_track.sysex.append(current_sysex)
	current_track.events.append(current_sysex)
	current_sysex.delta_ticks = current_track.delta_ticks
	current_sysex.event_type = current_meta.EventType.SYSEX
	current_sysex.length = int_variable_from_buffer()
	
	# Length should never be negative or more than the remaining size
	if current_sysex.length < 0 || current_sysex.length > get_bytes_rest():
		return MIDI_PARSER_ERROR
		
	# Don't count the 0xF7 ending byte as data, if given:
	if bytes[byte_index + current_sysex.length - 1] == 0xF7:
		current_sysex.length -= 1
	
	current_sysex.bytes = bytes.slice(byte_index, byte_index + current_sysex.length)
	current_sysex.value = buffer_to_int(current_sysex.bytes)
	byte_index += current_meta.length
	return MIDI_PARSER_TRACK_SYSEX
	
"""
Parse a tracks meta event
"""
func parse_meta_event() -> int:
	var channel_type = bytes[byte_index]
	
	if !(get_bytes_rest() == 0 || channel_type == 0xff) || get_bytes_rest() < 2:
		return MIDI_PARSER_ERROR
	
	var byte_index_meta_start = byte_index
	byte_index += 1
	var meta_type = int_from_buffer(1)
	current_meta = Meta.new()
	current_track.meta.append(current_meta)
	current_track.events.append(current_meta) 
	current_meta.delta_ticks = current_track.delta_ticks
	current_meta.event_type = current_meta.EventType.META
	current_meta.type = meta_type
	current_meta.length = int_variable_from_buffer()
	# Length should never be negative or more than the remaining size
	if current_meta.length < 0 || current_meta.length > get_bytes_rest():
		return MIDI_PARSER_ERROR
		
	current_meta.bytes = bytes.slice(byte_index, byte_index + current_meta.length)
	current_meta.value = buffer_to_int(current_meta.bytes)
	if current_meta.type == current_meta.Type.SET_TEMPO:
		current_meta.bpm = 60000000 / current_meta.value
		current_meta.ms_per_tick = 60000 / (current_meta.bpm * header.time_division)
	byte_index += current_meta.length
	
	return MIDI_PARSER_TRACK_META



"""
Get data length for given midi status
"""
func get_event_datalen(status) -> int:
	if status == Midi.Status.PGM_CHANGE || status == Midi.Status.CHANNEL_AT:
		return 1
	return 2

"""
Get number of bytes left to process
"""
func get_bytes_rest()-> int:
	return bytes.size() - byte_index - 1

"""
Return an string from current bytes buffer
"""
func str_from_buffer(readBytes: int) -> String:
	var i = byte_index
	byte_index += readBytes
	return bytes.slice(i, readBytes).get_string_from_ascii()

"""
Return an integer from current bytes buffer with variable byte length
It stops on a byte containing the specific end control bits
"""
func int_variable_from_buffer() -> int:
	var value = 0
	while get_bytes_rest() > 0:
		var b = int_from_buffer(1)
		value = (value << 7) | (b & 0x7f)
		if !(b & 0x80):
			break
	
	return value
	
"""
Return an integer from current bytes buffer and advance the internal byte index
"""
func int_from_buffer(readBytes) -> int:
	var i = byte_index
	byte_index += readBytes
	return buffer_to_int(bytes.slice(i, byte_index))
	

"""
Return an integer from a byte array
"""
func buffer_to_int(byte_arr) -> int:
	var l = byte_arr.size()
	if l == 4:
		return (byte_arr[0] << 24) | (byte_arr[1] << 16) | (byte_arr[2] << 8) | byte_arr[3];
	elif l == 3:
		return (byte_arr[0] << 16) | (byte_arr[1] << 8) | byte_arr[2];
	elif l == 2:
		return (byte_arr[0] << 8) | byte_arr[1];
	elif l == 1:
		return byte_arr[0];
	return 0
