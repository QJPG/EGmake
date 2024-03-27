class_name DisplayCoordsToggler extends Node

@export var button : CheckButton

func _ready():
	SetupMain.editor_settings[SetupMain.ED_DISPCOORDS] = button.button_pressed
	
	button.toggled.connect(func(v):
		SetupMain.editor_settings[SetupMain.ED_DISPCOORDS] = v)
