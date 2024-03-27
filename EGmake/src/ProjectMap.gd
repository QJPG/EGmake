extends Node

enum EditModes {
	ADD_SECTOR,
	EDIT_VERTICES,
	MOVE_VIEW,
}

var map_transform : Transform3D = Transform3D(Basis(), Vector3.ZERO)
var map_view_transform : Transform3D = Transform3D(Basis(), Vector3.ZERO)
var map : MapData = MapData.new()
var editor = {
	edit_mode = EditModes.ADD_SECTOR
}
