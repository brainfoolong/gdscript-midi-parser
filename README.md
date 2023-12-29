# Godot GDScript 4+ Midi File Parser and Player

Parse your midi files directly with native GDScript 4+ with no other dependencies. The example also include a demo of how you can create a sound player based on the parsed midi data.

## Install
Clone/Download this repository into your project.

## Usage
```python
var parser = MidiFileParser.load_file("res://yourmidi.mid")
# parser.header contains midi header data
# parser.tracks contains all midi tracks

## iterate over tracks and events
for track in parser.tracks:
    for event in track.events:
        # do something with events here   
```
    
## Playback Demo

See `midi_file_player_example.gd` or load and play scene `demo/midi_demo`.

It will contain all required parts (timing, _process loop) to play notes at correct times.

The demo uses a very simple generic audio signal generator. Quality is not good but frequencies are correct. It will play "Beethoven - Fur Elise", which you will know for sure.