extends Tree

@export var viewframe1 : SubViewportContainer
@export var viewframe2 : SubViewportContainer

var root : TreeItem
var items : Array[TreeItem]
var last_focused_viewframe : SubViewportContainer = null

func add_entity_item(id : int) -> void:
	var item = create_item(root)
	item.set_text(0, "%s<%s>" % [SetupMain.map.get_entity(id).classname, id])
	item.set_meta("_id_", id)
	#item.add_button(0, null, 0, false, "Delete Entity?")
	
	items.append(item)

func _ready():
	viewframe1.focus_entered.connect(func(): last_focused_viewframe = viewframe1)
	viewframe2.focus_entered.connect(func(): last_focused_viewframe = viewframe2)
	
	root = create_item(null)
	
	for e in SetupMain.map.entities:
		add_entity_item(e.id)
	
	item_selected.connect(func():
		var item = get_selected()
		
		var e : BaseEntity = SetupMain.map.get_entity(item.get_meta("_id_"))
		if not e:
			return
		
		SetupMain.clear_selecteds()
		SetupMain.select_sector(e.id)
		
		if last_focused_viewframe:
			last_focused_viewframe.grab_focus())
	
	SetupMain.map.entity_list_updated.connect(func(is_removed, id):
		if not is_removed:
			add_entity_item(id)
		else:
			for item in items:
				if item.get("_id_") == id:
					items.erase(item)
					break)
