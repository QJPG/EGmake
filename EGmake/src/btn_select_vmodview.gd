class_name BtSetWFViewMod extends OptionButton

@export var wireframeviewer : WireframeViewer

const OPTIONS = {
	"Top": WireframeViewer.VMOD_VIEW.VMOD_VTOP,
	"Bottom": WireframeViewer.VMOD_VIEW.VMOD_VBOTTOM,
	"Left": WireframeViewer.VMOD_VIEW.VMOD_VLEFT,
	"Right": WireframeViewer.VMOD_VIEW.VMOD_VRIGHT,
	"Front": WireframeViewer.VMOD_VIEW.VMOD_VFRONT,
	"Back": WireframeViewer.VMOD_VIEW.VMOD_VBACK,
	"Ortho": WireframeViewer.VMOD_VIEW.VMOD_VORTHO,
}

func _init():
	for optname in OPTIONS.keys():
		add_item(optname)

func _ready():
	select(wireframeviewer.default_vmod_view)
	
	item_selected.connect(func(idx):
		wireframeviewer.default_vmod_view = OPTIONS[OPTIONS.keys()[idx]])
