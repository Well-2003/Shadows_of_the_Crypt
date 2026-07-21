@tool
class_name FPSHelper
extends RefCounted
## Static class providing FPS tracking and statistics utilities.
##
## Call [method track_frame_time] every process frame to keep history up to date.
## All state is held in static variables so no instance is required.


## Max amount of FPS history entries to keep for advanced statistics.
const MAX_FPS_HISTORY: int = 60
## Last 60 frame times in seconds, used for calculating average, min, and max FPS.
static var _frame_times: Array[float] = []


## Records a new frame time. Pass [param delta] from [method Node._process] every frame.
static func track_frame_time(delta: float) -> void:
	_frame_times.append(delta)

	if _frame_times.size() > MAX_FPS_HISTORY:
		_frame_times.pop_front()


## Returns the current FPS reported by the engine.
static func get_current_fps() -> int:
	return Engine.get_frames_per_second() as int


## Calculates the average FPS from the recorded frame history.
static func calculate_average_fps() -> float:
	if _frame_times.is_empty():
		return 0.0

	var total_time: float = 0.0
	for frame_time: float in _frame_times:
		total_time += frame_time

	var avg_frame_time: float = total_time / _frame_times.size()
	return 1.0 / avg_frame_time if avg_frame_time > 0.0 else 0.0


## Returns the maximum FPS (shortest recorded frame time) from the frame history.
static func calculate_max_fps() -> float:
	if _frame_times.is_empty():
		return 0.0

	var min_frame_time: float = _frame_times[0]
	for frame_time: float in _frame_times:
		min_frame_time = minf(min_frame_time, frame_time)

	return 1.0 / min_frame_time if min_frame_time > 0.0 else 0.0


## Returns the minimum FPS (longest recorded frame time) from the frame history.
static func calculate_min_fps() -> float:
	if _frame_times.is_empty():
		return 0.0

	var max_frame_time: float = _frame_times[0]
	for frame_time: float in _frame_times:
		max_frame_time = maxf(max_frame_time, frame_time)

	return 1.0 / max_frame_time if max_frame_time > 0.0 else 0.0


## Returns a formatted FPS display string.
## If [param advanced] is [code]true[/code], includes avg, min, max, and last frame time in ms.
static func get_fps_string(advanced: bool = false) -> String:
	if advanced and not _frame_times.is_empty():
		var avg_fps: float = calculate_average_fps()
		var min_fps: float = calculate_min_fps()
		var max_fps: float = calculate_max_fps()
		var frame_time_ms: float = _frame_times[-1] * 1000.0

		return (
			"FPS: %.1f | Avg: %.1f | Min: %.1f | Max: %.1f | Frame: %.2fms"
			% [Engine.get_frames_per_second(), avg_fps, min_fps, max_fps, frame_time_ms]
		)

	return "%d FPS" % get_current_fps()
