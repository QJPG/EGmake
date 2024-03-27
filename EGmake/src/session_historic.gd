class_name SessionHistoric extends Node

@export var list : ItemList

func _ready():
	SetupMain.session_historic_registered.connect(func(h : SetupMain.Historic):
		if list.item_count > 5:
			list.remove_item(0)
		
		list.add_item("Session id(%s) : %s" % [h.type, h.message]))
