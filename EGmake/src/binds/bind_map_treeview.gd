extends Tree

var root : TreeItem
var items : Array[TreeItem]

func _ready():
	root = create_item(null)
	
	for e in ProjectMap.map.entities:
		var item = create_item(root)
		item.set_text(0, "%s:%s" % [e.classname, e.id])
		item.set_meta("_id_", e.id)
		
		items.append(item)
	
	ProjectMap.map.entity_list_updated.connect(func(is_removed, id):
		if not is_removed:
			var item = create_item(root)
			item.set_text(0, "%s:%s" % [ProjectMap.map.get_entity(id).classname, id])
			item.set_meta("_id_", id)
			
			items.append(item)
		else:
			for item in items:
				if item.get("_id_") == id:
					items.erase(item)
					break)
