# Godot GDScript 4+ Midi File Parser

Parse your midi files directly with native GDScript with no other dependencies.

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
    
## Example of how to implement a playback

See `midi_file_player_example.gd`