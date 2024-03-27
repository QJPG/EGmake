extends SpinBox

enum Locations {
	X, Y, Z
}

@export var frameView : FrameViewer
@export var loc = Locations.X

func _ready():
	frameView.vertices_selected.connect(func():
		if frameView.selected_entity > -1 and frameView.selected_sector_vertexname.length() > 0:
			var v = ProjectMap.map.get_entity(frameView.selected_entity).get_keyvalue(frameView.selected_sector_vertexname) as Vector3
			match loc:
				Locations.X:
					value = v.x
				
				Locations.Y:
					value = v.y
				
				Locations.Z:
					value = v.z
		else:
			value = 0)
	
	value_changed.connect(func(v):
		
		var d = Vector2.ZERO
		
		match loc:
			Locations.X:
				d.x = v
			
			Locations.Y:
				d.y = v
			
			Locations.Z:
				d.y = v
		
		if frameView.selected_vertices.size() > 0:
			frameView.move_selecteds_vertex(d, true)
		else:
			frameView.move_selecteds_vertex(d, !true, true))
