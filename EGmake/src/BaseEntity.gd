class_name BaseEntity extends Object

var classname : String
var keyvalues : Dictionary
var hint_description : String
var id : int

func set_keyvalue(keyname : String, value) -> void:
	keyvalues[keyname] = value

func get_keyvalue(keyname : String, default = null):
	return keyvalues[keyname] if keyvalues.has(keyname) else default
