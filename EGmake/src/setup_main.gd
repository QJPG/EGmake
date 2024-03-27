extends Node

enum E_VWMODES {
	MOVEVIEW,
	ADDSECTOR,
	EDIT_VERTEX,
	EDIT_LINE,
	EDIT_FACE,
}
enum E_TRANS {
	NOTHING,
	TRANSLATE,
	SCALE,
	ROTATE
}

const ED_GRID_SIZE = "Grid Size"
const ED_EDITMODE = "View Mode"
const ED_TRANSFORM = "Transform"

signal selecteds_list_changed

class Selectors:
	const SELT_EDGE = 0
	const SELT_VERTEX = 1
	const SELF_FACE = 2
	
	var mod : int
	var entity_id : int
	var vertices : Array[String]
	
	func is_valid() -> bool:
		match mod:
			Selectors.SELT_EDGE, Selectors.SELF_FACE:
				return vertices.size() > 0 and vertices.size() % 2 == 0
			
			Selectors.SELT_VERTEX:
				return vertices.size() > 0
		
		return false

var editor_settings = {
	ED_GRID_SIZE : 16,
	ED_EDITMODE : E_VWMODES.MOVEVIEW,
	ED_TRANSFORM : E_TRANS.NOTHING,
}
var map : MapData = MapData.new()
var selecteds : Array[Selectors]

func get_edit_mode_enabled(mode : E_VWMODES) -> bool:
	return editor_settings[ED_EDITMODE] == mode

func add_selector(sel : Selectors) -> void:
	for slt in selecteds:
		if slt.entity_id == sel.entity_id and slt.vertices == sel.vertices and slt.mod == sel.mod:
			selecteds.erase(slt)
			selecteds_list_changed.emit()
			return
	
	selecteds.append(sel)
	selecteds_list_changed.emit()

func clear_selecteds() -> void:
	selecteds.clear()
	selecteds_list_changed.emit()

func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)
