# Godot Speech To Subtitles

Godot Speech To Subtitles (GSS) works as a Godot Singleton and Transcription Guide that helps you generate and sync subtitles for when your in-game character speaks.

GSS creates an [Animation](https://docs.godotengine.org/en/stable/classes/class_animation.html) for the [Label](https://docs.godotengine.org/en/stable/classes/class_label.html) and [RichTextLabel](https://docs.godotengine.org/en/stable/classes/class_richtextlabel.html) nodes using a text files (.txt) which are formatted identically to a subrip files (.srt).

## Things I Recommend

- Godot Engine 4 (or above)
- Python 3.7+ and OpenAI (Optional for transcribing audio files)

## How To Use

Download or copy and paste the captions.gd file into your project.
Create a Singleton for this script.

![Screenshot_88](https://github.com/1Othello/godot-speech-to-subtitles/assets/132980114/750c3696-43f4-4830-a6c0-b4c63d6d5b9d)

(This allows you to use it inside of any script.)


### Easy Usage

```gdscript
var data = {"TextPath": "res://path_to_text_file.txt", "Label": label_or_richtextlabel_node} # Settings which will be passed as an argument.
var animation = Captions.generate_animation(data) # Returns an Animation which can be used by AnimationPlayer to start showing the subtitles.
```
See example below.

```gdscript
@onready var animation_player = %AnimationPlayer
@onready var subtitle : RichTextLabel = %Subtitle
@export var speech_player : AudioStreamPlayer

func _ready():
	var data = {
		"TextPath": "res://text_file_format_example.txt", 
		"Label": subtitle
	} # Settings which will be passed as an argument.
	var animation := Captions.generate_animation(data)
  	animation_player.get_animation_library("").add_animation("display_subtitles", animation)
	animation_player.play("display_subtitles")
	if speech_player:
		speech_player.play()

```


### Moderate Usage

In order to create your ideal subtitle animation you need to pass over a dictionary for the Captions.create() function to use.

Here are all the keys which the singleton will accept:

1. TextPath (String) (REQUIRED)
   - The path to the text file which is in subrip format. (Example: "res://my_long_speech.txt")
   - This can also be the text file in string format.
 
2. Label (Label or RichTextLabel) (REQUIRED)
   - A node representing a Label or RichTextLabel. (For displaying the subtitles.)

The rest are completely optional.

3. Name (String)
   - The name you want to give your animation. (Combine this with the AnimationPlayer key to have the animation automatically added to your AnimationPlayer node.)

4. AnimationPlayer (AnimationPlayer)
   - The AnimationPlayer node you want to create an animation inside of. (You must include the Name key for this to work.)

5. Duration (Float)
   - The length of the animation. If this isn't provided it will automatically be set to the last timestamp on the .txt file.
   - (I recommend having this setting be the length of your audio file.)

6. Style (String)
   - The style in which subtitles will appear on the screen. (This is set to "Letter" by default. Although can be changed to "Word")
   - "Letter" makes it so that the all characters appear one by one to create a typewriter effect.
   - "Word" makes it so that all words appears one by one instead of characters.
   - "Subtitles" makes it so that a segment is shown at the start time and hidden on the end time, like in video players.
  
7. Container (Node)
   - Node containing the label
   - It willbe made visible on start of the segment and hidden on the end of it
   - Best to use with "subtitles" style

Examples:
```gdscript
@onready var animation_player = %AnimationPlayer
@onready var subtitle : RichTextLabel = %Subtitle
@export var speech_player : AudioStreamPlayer

func _ready():
	var data = {
		"TextPath": "res://text_file_format_example.txt", 
		"Label": subtitle,
		"AnimationPlayer": animation_player, 
		"Name": "display_subtitles", 
		"Style": "word",
		"Duration": speech_player.stream.get_length()
	} # Settings which will be passed as an argument.
	Captions.generate_animation(data)
	animation_player.play("display_subtitles")
	if speech_player:
		speech_player.play()

```

```gdscript
@onready var animation_player = %AnimationPlayer
@onready var subtitle : RichTextLabel = %Subtitle
@onready var external_margin_container = %ExternalMarginContainer
@export var speech_player : AudioStreamPlayer

func _ready():
	var data = {
		"TextPath": r"1
00:00:01,440 --> 00:00:05,375
Senator, we're making
our final approach into Coruscant.

2
00:00:05,476 --> 00:00:07,501
Very good, Lieutenant.", 
		"Label": subtitle,
		"AnimationPlayer": animation_player, 
		"Name": "display_subtitles", 
		"Style": "subtitles",
		"Container": external_margin_container,
	}
	Captions.generate_animation(data)
	animation_player.play("display_subtitles")
	if speech_player:
		speech_player.play()

```

You can retrieve a template of the dictionary data needed directly from the singleton itself.

```gdscript
var template = Captions.get_required_template() # Returns a dictionary with only the required keys.
print(template)
# Output {"TextPath": "PATH TO .TXT FILE (REQUIRED)", "LABEL": "LABEL OR RICHTEXTLABEL NODE (REQUIRED)"}
```

Or

```gdscript
var template = Captions.get_complete_template() # Returns a dictionary with every key.
print(template)
# Output {"TextPath": "PATH TO .TXT FILE (REQUIRED)", # Required
#	"Label": "LABEL OR RICHTEXTLABEL NODE (REQUIRED)", # Required
#	"Name": "NEW ANIMATION NAME (OPTIONAL)", # Optional
#	"AnimationPlayer": "ANIMATIONPLAYER NODE (OPTIONAL)", # Optional
#	"Duration": "AUDIO LENGTH (OPTIONAL)", # Optional
#	"Style": "WORD OR LETTER (OPTIONAL)", # Optional
#	}
```


If you want to simply get parsed captions from the file or text input, call `read_and_parse` function:
```gdscript
var caption_fields := read_and_parse("res://text_file_format_example.txt")

```

## Creating an SRT file (Tutorial)

(If you already have an SRT file then please convert it into a .txt file and ignore this section.)

An SRT file (also known as a SubRip Subtitle) is a type of file which is commonly used when creating captions for films and videos.

These files are similar to .txt files except they are formatted in a way that allows a program to read and know what's being said by someone and at what time.

Below is an image of what the inside of a .srt file looks like.
![stgz](https://github.com/1Othello/godot-speech-to-subtitles/assets/132980114/f541d6b6-a7c1-4d8f-aa97-2a4282177cde)

As you will be converting this file type into a .txt file you can just create a text file and structure it like above. (This takes a good while so I don't recommend it.)

Alternatively there are websites such as happyscribe and go-transcribe that will create a SRT file from any audio containin speech. (They may charge for this service.)

(It doesn't matter how you get it done, just make sure you have a .txt file in the same format as a .srt file.)

The method I'm about to describe uses OpenAI is Whisper along with Python. (You will need an OpenAI API key for this. [See here](https://www.howtogeek.com/885918/how-to-get-an-openai-api-key/#:~:text=How%20to%20Get%20an%20OpenAI%20API%20Key%201,Secret%20Key%22%20to%20generate%20a%20new%20API%20key.)

After you have your OpenAI API key make sure you have the openai library installed. (You may also need to install pytorch and ffmpeg if you get an error.)
```bash
pip install openai
```

Upon having installed everything simply create a python file with the following contents. (Also make sure you know the path to the audio file you want to transcribe.)

```python
import openai
openai.api_key = "OPENAI_API_KEY" # Replace with your API key.
def get_captions():
    audio_file = open("PATH_TO_AUDIO_FILE", "rb") # Replace PATH_TO_AUDIO_FILE with your audio file containing your character's speech.
    transcript = openai.Audio.transcribe("whisper-1", audio_file, response_format="srt", language="en")
    with open('raw_captions.txt', 'w') as f:
        f.write(transcript)
get_captions()
```

Run this simple script having made sure you replaced "OPENAI_API_KEY" and "PATH_TO_AUDIO_FILE" with the value that applies to you.

You should find a .txt file called "raw_captions" in the folder you ran the script. This is the file you will need to import into godot in order to generate subtitles.

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
