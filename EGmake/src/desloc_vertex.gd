class_name VertexDeslocXYZ extends Node

enum DSLC {
	X, Y, Z
}

@export var dx : SpinBox
@export var dy : SpinBox
@export var dz : SpinBox

var pivot : Vector3

func vchanged(dl : DSLC, nv : float) -> void:
	var original = pivot
	match dl:
		DSLC.X:
			pivot.x = nv
		
		DSLC.Y:
			pivot.y = nv
		
		DSLC.Z:
			pivot.z = nv
	
	for selt in SetupMain.selecteds:
		var e : BaseEntity = SetupMain.map.get_entity(selt.entity_id)
		
		if not e:
			continue
		
		for vname in selt.vertices:
			var v = e.get_keyvalue(vname) as Vector3
			var rel = (pivot - original)
			
			e.set_keyvalue(vname, v + rel)
	
	#get all vertices selected
	#recalculated with new value
	return

func _ready():
	dx.value_changed.connect(func(v):
		vchanged(DSLC.X, v))
	
	dy.value_changed.connect(func(v):
		vchanged(DSLC.Y, v))
	
	dz.value_changed.connect(func(v):
		vchanged(DSLC.Z, v))
	
	SetupMain.selecteds_list_changed.connect(func():
		var desl : Vector3
		
		for selt in SetupMain.selecteds:
			var e : BaseEntity = SetupMain.map.get_entity(selt.entity_id)
			
			if not e:
				continue
			
			for vname in selt.vertices:
				var v = e.get_keyvalue(vname) as Vector3
				desl = v - pivot
		
		pivot = desl
		
		dx.call_deferred("set_value_no_signal", pivot.x)
		dy.call_deferred("set_value_no_signal", pivot.y)
		dz.call_deferred("set_value_no_signal", pivot.z))
