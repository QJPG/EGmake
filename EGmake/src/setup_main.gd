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
const ED_YMIN = "Y-min"
const ED_DISPCOORDS = "Display Coords"

signal selecteds_list_changed
signal session_historic_registered(h)

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

class Historic:
	const TSELECTOR = 0
	const TENTADDED = 1
	const TENTREMV = 2
	
	var message : String = ""
	var type : int = -1
	var value = null

var editor_settings = {
	ED_GRID_SIZE : 16,
	ED_EDITMODE : E_VWMODES.EDIT_VERTEX,
	ED_TRANSFORM : E_TRANS.NOTHING,
	ED_YMIN : 0.0,
	ED_DISPCOORDS : false
}
var map : MapData = MapData.new()
var selecteds : Array[Selectors]
var session_historic : Array[Historic]

func get_edit_mode_enabled(mode : E_VWMODES) -> bool:
	return editor_settings[ED_EDITMODE] == mode

func add_selector(sel : Selectors) -> void:
	for slt in selecteds:
		if slt.entity_id == sel.entity_id and slt.vertices == sel.vertices and slt.mod == sel.mod:
			selecteds.erase(slt)
			selecteds_list_changed.emit()
			return
	
	selecteds.append(sel)
	
	var h = Historic.new()
	h.type = Historic.TSELECTOR
	h.message = "Selector created"
	h.value = sel
	
	add_historic(h)
	
	selecteds_list_changed.emit()

func clear_selecteds() -> void:
	selecteds.clear()
	selecteds_list_changed.emit()

func select_sector(entity : int) -> void:
	var e : BaseEntity = map.get_entity(entity)
	
	if not e:
		return
	
	var vertices = WireframeViewer.get_sector_vertices(e.id)
	
	if not vertices.size() > 0:
		return
	
	for v in vertices:
		var s = Selectors.new()
		s.mod = Selectors.SELT_VERTEX
		s.entity_id = e.id
		s.vertices.append(v[0])
		
		add_selector(s)
		
		var h = Historic.new()
		h.type = Historic.TSELECTOR
		h.message = "Sector Vertex Selected(%s)" % v[0]
		h.value = s
		
		add_historic(h)

func add_historic(h : Historic) -> void:
	if session_historic.size() > 10:
		session_historic.pop_front()
	
	session_historic.push_back(h)
	session_historic_registered.emit(h)

func _ready():
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	map.start()
