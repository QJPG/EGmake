class_name MapData extends Resource

@export var map_name : String
@export var keyvalues : Dictionary

signal entity_list_updated(is_removed, entity_id)

var entities : Array[BaseEntity]

func _init():
	pass

func start() -> void:
	#create_sector(AABB(Vector3(16, 0, 16), Vector3(55, 10, 100)))
	return

func create_sector(dimension : AABB) -> BaseEntity:
	var e = BaseEntity.new()
	e.id = randi()
	e.classname = "sector_zone"
	e.hint_description = "Create a box room with custom properties."
	
	e.set_keyvalue("WallLeft", true)
	e.set_keyvalue("WallRight", true)
	e.set_keyvalue("WallFront", true)
	e.set_keyvalue("WallBack", true)
	e.set_keyvalue("FloorEnabled", true)
	e.set_keyvalue("CellEnable", true)
	e.set_keyvalue("Floor V0", dimension.position)
	e.set_keyvalue("Floor V1", dimension.position + dimension.size * Vector3(1, 0, 0))
	e.set_keyvalue("Floor V2", dimension.position + dimension.size * Vector3(1, 0, 1))
	e.set_keyvalue("Floor V3", dimension.position + dimension.size * Vector3(0, 0, 1))
	e.set_keyvalue("Cell V0", dimension.position + dimension.size * Vector3(0, 1, 0))
	e.set_keyvalue("Cell V1", dimension.position + dimension.size * Vector3(1, 1, 0))
	e.set_keyvalue("Cell V2", dimension.position + dimension.size * Vector3(1, 1, 1))
	e.set_keyvalue("Cell V3", dimension.position + dimension.size * Vector3(0, 1, 1))
	
	add_entity(e)
	
	entity_list_updated.emit(false, e.id)
	
	return e

func add_entity(e : BaseEntity) -> void:
	entities.append(e)
	
	var h = SetupMain.Historic.new()
	h.type = h.TENTADDED
	h.message = "Entity created"
	h.value = e
	
	SetupMain.add_historic(h)

func remove_entity(id : int) -> void:
	for i in range(entities.size()):
		if entities[i].id == id:
			entities.erase(entities[i])
			entity_list_updated.emit(true, id)
			
			var h = SetupMain.Historic.new()
			h.type = h.TENTREMV
			h.message = "Entity removed"
			h.value = entities[i]
			
			SetupMain.add_historic(h)
			return

func get_entity(id : int) -> BaseEntity:
	for i in range(entities.size()):
		if entities[i].id == id:
			return entities[i]
	
	return null
