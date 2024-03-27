class_name BtSetVModEdit extends Button

@export var mode : SetupMain.E_VWMODES


func _ready():
	toggle_mode = true
	button_group = preload("res://button_group_editmodes.tres")
	button_pressed = SetupMain.editor_settings[SetupMain.ED_EDITMODE] == mode
	
	pressed.connect(func():
		SetupMain.editor_settings[SetupMain.ED_EDITMODE] = mode)
