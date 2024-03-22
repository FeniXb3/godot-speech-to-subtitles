extends Node

func prepare_track(animation : Animation, label : RichTextLabel, update_mode : Animation.UpdateMode) -> int:
	var track_index := animation.add_track(Animation.TYPE_VALUE)
	var nodePath = NodePath(label.owner.get_path_to(label))
	animation.value_track_set_update_mode(track_index, update_mode)
	animation.track_set_path(track_index, nodePath.get_concatenated_names() + ":text")
	
	return track_index

func add_segment_word_by_word_to_track(written : String, caption, animation : Animation, track_index : int, end_override := 0.0) -> String:
	var text := caption["text"] as String # The text being displayed.
	var start := caption["start"] as float # The starting keyframe in seconds.
	var end := caption["end"] as float if not end_override else end_override # The ending keyframe in seconds.
	var words := text.split(" ") # Get every word.
	var segment_duration := end - start
	var word_duration = segment_duration / words.size()
	var currentTime = start
	for word in words:
		currentTime += word_duration
		written += word + " "
		animation.track_insert_key(track_index, currentTime, written)
		
	return written

func generate_animation_WORDS(data : Dictionary, caption_fields):
	var animation := Animation.new()
	var track_index := prepare_track(animation, data["Label"], Animation.UPDATE_DISCRETE)
	var last_field = caption_fields.pop_back()
	var written := ""
	for caption in caption_fields:
		written = add_segment_word_by_word_to_track(written, caption, animation, track_index)
	
	var duration : float = data.get("Duration", last_field["end"]) 
	written = add_segment_word_by_word_to_track(written, last_field, animation, track_index, duration)
	
	animation.length = duration
	
	if "AnimationPlayer" in data and "Name" in data: # Adds the named animation to the provded animation player.
		data["AnimationPlayer"].get_animation_library("").add_animation(data["Name"], animation)
		return true
	else: # Returns the animation.
		return animation

func generate_animation_LETTERS(data, caption_fields):
	var animation = Animation.new()
	var track_index = prepare_track(animation, data["Label"], Animation.UPDATE_CONTINUOUS)
	var last_field = caption_fields.pop_back()
	var full_script = ""
	var text := ""
	for caption in caption_fields:
		text = caption["text"] # The text being displayed.
		var start = caption["start"] # The starting keyframe in seconds.
		var end = caption["end"] # The ending keyframe in seconds.
		animation.track_insert_key(track_index, start, full_script)
		full_script += text + " "
		animation.track_insert_key(track_index, end, full_script)
	
	text = last_field["text"]

	animation.track_insert_key(track_index, last_field["start"], full_script)
	full_script += last_field["text"]
	
	var duration
	
	if "Duration" in data: # Check whether a custom duration was provided.
		duration = data["Duration"]
	else:
		duration = last_field["end"]
	
	animation.track_insert_key(track_index, duration, full_script)
	
	animation.length = duration
	
	var animPlayer
	
	if "AnimationPlayer" in data and "Name" in data: # Adds the named animation to the provded animation player.
		animPlayer = data["AnimationPlayer"]
		animPlayer.get_animation_library("").add_animation(data["Name"], animation)
		return true
	else: # Returns the animation.
		return animation
	

func create(data: Dictionary): # Creates and returns a label animation with the captions provided.
	
	var caption_fields = []
	var messy_values = []
	
	var raw_file
	
	if data["TextPath"].begins_with("res://") or data["TextPath"].begins_with("user://") or data["TextPath"].begins_with("C:/"): # File.
		raw_file = FileAccess.open(data["TextPath"], FileAccess.READ)
		while not raw_file.eof_reached():
			var line = raw_file.get_line()
			if line.find("-->") != -1: # Check if the line is a timestamp.
				var timestamps = get_timestamp_values(line) # Returns an array containing the start and end of the following line in seconds.
				messy_values.append(timestamps[0])
				messy_values.append(timestamps[1])
			elif messy_values.size() == 2: # If we have 2 stamps then this line must be the transcribed text.
				var dict = {"text": line, "start": messy_values[0], "end": messy_values[1]} # The dictionary used for creating keyframes.
				caption_fields.append(dict)
				messy_values.clear() # Clear the array for the next transcription.
		raw_file.close()
	else: # String.
		var everyLine = data["TextPath"].split("\n")
		for line in everyLine:
			if line.find("-->") != -1: # Check if the line is a timestamp.
				var timestamps = get_timestamp_values(line) # Returns an array containing the start and end of the following line in seconds.
				messy_values.append(timestamps[0])
				messy_values.append(timestamps[1])
			elif messy_values.size() == 2: # If we have 2 stamps then this line must be the transcribed text.
				var dict = {"text": line, "start": messy_values[0], "end": messy_values[1]} # The dictionary used for creating keyframes.
				caption_fields.append(dict)
				messy_values.clear() # Clear the array for the next transcription.
	
	if "TimeOnly" in data and data["TimeOnly"]: # Returns caption fields without animating them.
		return caption_fields
	
	if "Style" in data: # The style of the animation.
		if data["Style"].to_lower() == "word":
			var outcome = generate_animation_WORDS(data, caption_fields)
			return outcome
		else:
			var outcome = generate_animation_LETTERS(data, caption_fields)
			return outcome
	else: # Uses LETTERS as default.
		var outcome = generate_animation_LETTERS(data, caption_fields)
		return outcome


func get_timestamp_values(raw_time_stamp): # Get start and end keyframe seconds.  (Fun fact: Chat-GPT wrote this function)
	# Get the timestamp values
	
	var stamps = raw_time_stamp.split(" --> ")
	
	var start_timestamp = stamps[0]
	var end_timestamp = stamps[1]

	# Split the timestamp into an array
	var start_arr = start_timestamp.split(":")
	var end_arr = end_timestamp.split(":")

	# Calculate the total number of seconds
	var start_seconds = float(start_arr[0]) * 3600 + float(start_arr[1]) * 60 + float(start_arr[2].split(",")[0]) + float(start_arr[2].split(",")[1]) / 1000.0
	var end_seconds = float(end_arr[0]) * 3600 + float(end_arr[1]) * 60 + float(end_arr[2].split(",")[0]) + float(end_arr[2].split(",")[1]) / 1000.0
	
	return [start_seconds, end_seconds]


func get_complete_template():
	var template = {"TextPath": "PATH TO .TXT FILE (REQUIRED)", # Required
	"Label": "LABEL OR RICHTEXTLABEL NODE (REQUIRED)", # Required
	"Name": "NEW ANIMATION NAME (OPTIONAL)", # Optional
	"AnimationPlayer": "ANIMATIONPLAYER NODE (OPTIONAL)", # Optional
	"Duration": "AUDIO LENGTH (OPTIONAL)", # Optional
	"Style": "WORD OR LETTER (OPTIONAL)", # Optional
	"TimeOnly": "TRUE OR FALSE (OPTIONAL)" # Optional
	}
	return template
	
func get_required_template():
	var template = {"TextPath": "PATH TO .TXT FILE (REQUIRED)", "LABEL": "LABEL OR RICHTEXTLABEL NODE (REQUIRED)"}
	return template
