extends OptionButton

func _ready():
	add_item("Add Sector")
	add_item("Edit Vertices")
	add_item("Move View")
	
	item_selected.connect(func(idx):
		match idx:
			0:
				ProjectMap.editor.edit_mode = ProjectMap.EditModes.ADD_SECTOR
			
			1:
				ProjectMap.editor.edit_mode = ProjectMap.EditModes.EDIT_VERTICES
			
			2:
				ProjectMap.editor.edit_mode = ProjectMap.EditModes.MOVE_VIEW
		)
