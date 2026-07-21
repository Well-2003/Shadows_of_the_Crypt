@tool
class_name Tools
extends RefCounted
## Class containing various static utility functions used throughout the game.
## 
## This class provides a collection of static methods for common tasks, that can be easily accessed from anywhere in the project.


## Static utility function for loading JSON files. 
## [param file_path] is Path to the JSON file, and
## it returns Variant Parsed JSON data. Will return null if fails.
static func load_json_file(file_path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Could not load JSON file: ", file_path)
		return {}
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result: int = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing JSON file: ", file_path)
		return {}
	
	return json.data


## Static utility function for saving data to a JSON file.
## [param file_path] is the path to the JSON file.
## [param data] is the dictionary to save.
static func save_json_file(file_path: String, data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open file for writing: ", file_path)
		return
	
	var json_string: String = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()


## Frees all children of a node. The [param node] is the parent whose children will be freed.
static func free_children(node: Node) -> void:
	for child: Node in node.get_children():
		child.queue_free()


## Recursively deletes a directory and all its contents.
## The [param path] is the directory to delete, and this returns 
## True if successful, false otherwise.
static func delete_dir_recursive(path: String) -> bool:
	if not DirAccess.dir_exists_absolute(path):
		push_warning("Directory not found: ", path)
		return false
	
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		push_error("Could not open directory: ", path)
		return false
	
	var error: Error = dir.list_dir_begin()
	if error != OK:
		push_error("Could not list directory: ", path)
		return false
	
	var success: bool = true
	var file_name: String = dir.get_next()
	while file_name != "":
		# Skip special directories
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue
		
		var full_path: String = path.path_join(file_name)
		
		if dir.current_is_dir():
			# Recursively delete subdirectory
			if not delete_dir_recursive(full_path):
				success = false
				push_error("Failed to delete subdirectory: ", full_path)
		else:
			# Delete file
			if dir.remove(full_path) != OK:
				success = false
				push_error("Failed to delete file: ", full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Remove the directory itself
	if dir.remove(path) != OK:
		push_error("Failed to delete directory: ", path)
		return false
	
	return success


#region Atlas Helpers
## Counts the total number of frames in a texture atlas.
## [param atlas] is the texture atlas to count frames for, and
## it returns the total frame count calculated from the horizontal and vertical frame dimensions.
static func atlas_count_frames(atlas: Texture2D) -> int:
	var hframes: float = float(atlas.atlas.get_width()) / atlas.region.size.x
	var vframes: float = float(atlas.atlas.get_height()) / atlas.region.size.y
	var result: int = int(hframes * vframes)
	return result


## Gets the position for a specific frame in a texture atlas.
## [param atlas] is the texture atlas to get the frame position from.
## [param frame] is the frame index to locate. Will be clamped to valid range.
## Returns a Vector2 with the frame's position in atlas coordinates.
static func atlas_get_frame_rect(atlas: Texture2D, frame: int) -> Vector2:
	var total_frames: int = atlas_count_frames(atlas)

	if frame >= total_frames:
		frame = total_frames - 1
	
	var hframes: int = int(atlas.atlas.get_width() / atlas.region.size.x)
	var _vframes: int = int(atlas.atlas.get_height() / atlas.region.size.y)
	var x: int = frame % hframes
	var y: int = float(frame) / float(hframes) as int
	return Vector2(x * atlas.region.size.x, y * atlas.region.size.y)
#endregion
