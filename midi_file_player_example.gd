"""
Midi File Player Demo
See comments bellow, when to start/stop a note
@author BrainFooLong
@url https://github.com/brainfoolong/gdscript-midi-parser
""" 

class_name MidiFilePlayerExample extends Node

signal event (eventData, trackData)
signal finished

var parser : MidiFileParser
var ms_per_tick = 60000 / (120 * 480)
var lastEventTime = 0
var currentEventIndex = 0
var playing = false

func play():
	lastEventTime = -1
	playing = true

func pause():
	playing = false

func stop():
	playing = false
	
# Called when the node enters the scene tree for the first time.
func _ready():
	parser = MidiFileParser.load_file("res://yourmidi.mid")
	play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !playing:
		return
	var all_finished = true
	for track in parser.tracks:
		var delta_ms = 0
		var player_process
		if "player_process" not in track.additional_data:
			track.additional_data.player_process = {"time" : Time.get_ticks_msec(), "event_index" : 0}
			player_process = track.additional_data.player_process
		else:
			player_process = track.additional_data.player_process
			delta_ms = Time.get_ticks_msec() - player_process.time		
			
		var delta_ticks = delta_ms / ms_per_tick
		while player_process.event_index < track.events.size():
			var event = track.events[player_process.event_index]
			if event.delta_ticks > delta_ticks:
				break
			player_process.event_index += 1
			player_process.time = Time.get_ticks_msec()
			delta_ms = 0
			delta_ticks = 0
			self.emit_signal("event", event, track)
			if event.event_type == MidiFileParser.Event.EventType.META && event.type == MidiFileParser.Meta.Type.SET_TEMPO:
				# tempo update
				ms_per_tick = 60000 / (event.bpm * parser.header.time_division)
			if event.event_type == event.EventType.MIDI && event.note_name != '':
				if event.velocity > 0:
					print("Play "+event.note_name+" with velocity "+str(event.velocity))
				else:
					print("Stop "+event.note_name)
				
				# here play some note
				# event.velocity <= 0 = note off
				# event.velocity > 0 = note on
				# see MidiFileParser.Midi for more information about the midi data
				pass
			
		if all_finished && player_process.event_index != track.events.size():
			all_finished = false
			
	if all_finished:		
		print("finished")
		self.emit_signal("finished")
		stop()
