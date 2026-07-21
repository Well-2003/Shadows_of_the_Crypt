extends Node
## Class responsible for managing game Audio.
##
## Will handle playing, stopping and pausing of various audio streams such as
## ambience sounds, soundtrack music, narration and sound effects. As well as
## audio effects.


#region Properties
## The time it takes to fade out audio when stopping.
const FADE_TIME: float = 4.0
## The size of the sound effects player pool.
const SFX_POOL_SIZE: int = 8

var sfx_players: Array[AudioStreamPlayer] = []
var available_sfx_players: Array[AudioStreamPlayer] = []
var _active_tweens: Dictionary = {}
var _active_soundtrack_player: AudioStreamPlayer

@onready var ambience: AudioStreamPlayer = $Ambience
@onready var soundtrack_0: AudioStreamPlayer = $Soundtrack0
@onready var soundtrack_1: AudioStreamPlayer = $Soundtrack1
#endregion


func _ready() -> void:
	_active_soundtrack_player = soundtrack_0

	# Initialize SFX player pool
	for i: int in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = get_node("SFX%d" % i)
		sfx_players.append(player)
		player.finished.connect(func(): _on_sfx_finished(player))
	
	available_sfx_players = sfx_players.duplicate(true)


#region Helpers
## Kill any active tween for the given player.
func _kill_active_tween(player: AudioStreamPlayer) -> void:
	if _active_tweens.has(player):
		var tween: Tween = _active_tweens[player]
		if tween.is_valid(): tween.kill()
		_active_tweens.erase(player)


## Sets the volume of the player using linear scale (0.0 to 1.0) correctly mapping to dB.
func _set_volume_linear(value: float, player: AudioStreamPlayer) -> void:
	player.volume_db = linear_to_db(max(value, 0.0001))


## Smoothly stops the given audio player by fading out its volume.
func _smooth_stop_audio_player(player: AudioStreamPlayer, duration: float = FADE_TIME) -> void:
	_kill_active_tween(player)

	var tween: Tween = create_tween()
	_active_tweens[player] = tween
	
	# Fade out using linear volume interpolation
	var start_val: float = db_to_linear(player.volume_db)
	tween.tween_method(_set_volume_linear.bind(player), start_val, 0.0, duration)
	tween.tween_callback(player.stop)
	tween.tween_property(player, "volume_db", 0.0, 0) # Reset to full volume for next use
	tween.finished.connect(func(): _active_tweens.erase(player))


## Sets the audio volume for the specified bus.
## [param bus] is the name of the audio bus, and [param volume] is linear volume value (0-100).
func set_audio_volume(bus: StringName, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus)
	if bus_index < 0: return

	var db_volue: float = volume_linear_to_db(volume)
	AudioServer.set_bus_volume_db(bus_index, db_volue)


## Converts linear volume (0-100) to logarithmic decibel scale
## [param volume]: Linear volume value (0-100), returns volume in decibels (dB).
static func volume_linear_to_db(volume: float) -> float:
	var normalized: float = volume / 100.0
	return linear_to_db(normalized)
#endregion


## Plays a sound effect from the [param audio_stream].
func play_sfx(audio_stream: AudioStream, is_ui: bool = false) -> void:
	if not audio_stream: return
	if available_sfx_players.is_empty(): return

	var player: AudioStreamPlayer = available_sfx_players.pop_back()
	player.stream = audio_stream

	if is_ui: player.bus = "UI"
	else: player.bus = "SFX"

	player.play()


## Picks a random [AudioStream] from [param audio_streams] and plays it as a sound effect.
func play_random_sfx(audio_streams: Array[AudioStream], is_ui: bool = false) -> void:
	var stream: AudioStream = RNG.pick_random(audio_streams)
	play_sfx(stream, is_ui)


#region Ambience
## Plays ambience audio from the [param audio_stream].
func play_environment(audio_stream: AudioStream) -> void:
	if (
		not audio_stream
		or ambience.playing
		and ambience.stream == audio_stream
		and not _active_tweens.has(ambience)
	):
		return

	_kill_active_tween(ambience)
	ambience.volume_db = 0.0

	ambience.stream = audio_stream
	ambience.play()


## Picks a random [AudioStream] from [param audio_streams] and plays it as ambience.
func play_random_environment(audio_streams: Array[AudioStream]) -> void:
	var stream: AudioStream = RNG.pick_random(audio_streams)
	play_environment(stream)


## Stops the currently playing ambience audio.
func stop_environment(force: bool = false) -> void:
	if not ambience.stream: return
	
	if force: 
		_kill_active_tween(ambience)
		ambience.stop()
		ambience.volume_db = 0.0
		return
	
	_smooth_stop_audio_player(ambience)
#endregion


#region Soundtrack
## Plays soundtrack audio from the [param audio_stream]. [br]
## If [param cross_fade] is true, it attempts to synchronize the playback position
## with the currently playing track, useful for dynamic music layers.
## [param duration] is the time it takes for the cross-fade to complete.
## If [param duration] is not specified (negative), it defaults to 2.0s for cross-fades and FADE_TIME for normal fades.
func play_soundtrack(audio_stream: AudioStream, cross_fade: bool = false, duration: float = -1.0) -> void:
	if not audio_stream: return

	# Set default duration if not provided
	if duration < 0:
		duration = 2.0 if cross_fade else FADE_TIME
	
	# If the requested stream is already playing on the active player, do nothing
	if (
		_active_soundtrack_player.playing
		and _active_soundtrack_player.stream == audio_stream
		and not _active_tweens.has(_active_soundtrack_player)
	):
		return

	var old_player: AudioStreamPlayer = _active_soundtrack_player
	var new_player: AudioStreamPlayer = soundtrack_1 if old_player == soundtrack_0 else soundtrack_0
	
	_active_soundtrack_player = new_player

	# Prepare the new player
	_kill_active_tween(new_player)
	new_player.stream = audio_stream
	new_player.volume_db = -80.0 # Start silent for fade-in
	
	# Sync playback position if we are cross-fading and have an active reference
	var start_position: float = 0.0
	if cross_fade and old_player.playing and not _active_tweens.has(old_player):
		start_position = old_player.get_playback_position()
		
		# Handle potential length differences (looping safety)
		var new_length: float = audio_stream.get_length()
		if new_length > 0 and start_position >= new_length:
			start_position = fmod(start_position, new_length)

	new_player.play(start_position)
	
	# Tween new player volume UP using linear interpolation
	var fade_in_tween: Tween = create_tween()
	_active_tweens[new_player] = fade_in_tween
	fade_in_tween.tween_method(_set_volume_linear.bind(new_player), 0.0, 1.0, duration)
	fade_in_tween.finished.connect(func(): _active_tweens.erase(new_player))
	
	# Fade OUT the old active player
	if old_player.playing:
		_smooth_stop_audio_player(old_player, duration)


## Picks a random [AudioStream] from [param audio_streams] and plays it as a soundtrack.
func play_random_soundtrack(audio_streams: Array[AudioStream], cross_fade: bool = false, duration: float = -1.0) -> void:
	var stream: AudioStream = RNG.pick_random(audio_streams)
	play_soundtrack(stream, cross_fade, duration)


## Stops the currently playing soundtrack.
func stop_soundtrack(force: bool = false) -> void:
	var players: Array[AudioStreamPlayer] = [soundtrack_0, soundtrack_1]
	
	for player: AudioStreamPlayer in players:
		if not player.playing: continue
		
		if force:
			player.stop()
			_kill_active_tween(player)
			player.volume_db = 0.0
		else:
			_smooth_stop_audio_player(player)
#endregion


## Called when an SFX player finishes playing to return it to the available pool.
func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	available_sfx_players.append(player)
