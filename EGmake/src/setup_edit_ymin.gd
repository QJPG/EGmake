class_name SEditYMin extends Node

@export var num_edit : SpinBox

func _ready():
	SetupMain.editor_settings[SetupMain.ED_YMIN] = num_edit.value
	num_edit.value_changed.connect(func(v):
		SetupMain.editor_settings[SetupMain.ED_YMIN] = v)
