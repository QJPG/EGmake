class_name WireframeViewer extends Node2D

enum VMOD_VIEW {
	VMOD_VTOP,
	VMOD_VBOTTOM,
	VMOD_VLEFT,
	VMOD_VRIGHT,
	VMOD_VFRONT,
	VMOD_VBACK,
	VMOD_VORTHO,
}

class SelectionBox:
	var start : Vector2
	var end : Vector2
	
	func _init(_start : Vector2, _end : Vector2):
		self.start = _start
		self.end = _end
	
	func dim() -> Vector2:
		return self.end - self.start

const GUI_FONT = preload("res://misc/rainyhearts.ttf")

@export var default_vmod_view : VMOD_VIEW
@export var camera_espectator : Camera2D
@export var viewport_frame : SubViewportContainer
@export var ortho_plane : Plane = Plane(Vector3(0, 1, 0).rotated(Vector3(1, 0, 0), deg_to_rad(-95)).rotated(Vector3(0, 1, 0), deg_to_rad(5)), 0)
@export var ortho_plane_rotation : Vector3 = Vector3(0, 0, 0) #deg

var b1_pressed := false
var b2_pressed := false
var has_focus := false
var shift_pressed := false
var selection : SelectionBox = null
var sector_selection = null
var ctrl_pressed := false

func set_orthoplane_rot(rot : Vector3) -> void:
	ortho_plane_rotation = rot
	
	ortho_plane.normal = ortho_plane.normal.rotated(Vector3(1, 0, 0), deg_to_rad(ortho_plane_rotation.x))
	ortho_plane.normal = ortho_plane.normal.rotated(Vector3(0, 1, 0), deg_to_rad(ortho_plane_rotation.y))
	ortho_plane.normal = ortho_plane.normal.rotated(Vector3(0, 0, 1), deg_to_rad(ortho_plane_rotation.z))

func move_camera(rel : Vector2) -> void:
	if not has_focus:
		return
	
	#if not SetupMain.get_edit_mode_enabled(SetupMain.E_VWMODES.MOVEVIEW):
	#	return
	
	camera_espectator.position -= rel

func zoom_camera(zoomdelta : float) -> void:
	if not has_focus:
		return
	
	var z = camera_espectator.zoom + Vector2.ONE * zoomdelta
	
	z = clamp(z, Vector2(0.1, 0.1), Vector2(10, 10))
	
	camera_espectator.zoom = z

func lock_cursor() -> void:
	if not has_focus:
		return
	
	if SetupMain.get_edit_mode_enabled(SetupMain.E_VWMODES.MOVEVIEW):
		if b1_pressed:
			if not Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			if not Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

static func get_sector_vertices(id : int) -> Array[Array]:
	var res : Array[Array]
	var e : BaseEntity = SetupMain.map.get_entity(id)
	
	if not e:
		return res
	
	if not e.classname == "sector_zone":
		return res
	
	var fa = e.get_keyvalue("Floor V0") as Vector3
	var fb = e.get_keyvalue("Floor V1") as Vector3
	var fc = e.get_keyvalue("Floor V2") as Vector3
	var fd = e.get_keyvalue("Floor V3") as Vector3
	
	var ca = e.get_keyvalue("Cell V0") as Vector3
	var cb = e.get_keyvalue("Cell V1") as Vector3
	var cc = e.get_keyvalue("Cell V2") as Vector3
	var cd = e.get_keyvalue("Cell V3") as Vector3
	
	res.append(["Floor V0", fa])
	res.append(["Floor V1", fb])
	res.append(["Floor V2", fc])
	res.append(["Floor V3", fd])
	
	res.append(["Cell V0", ca])
	res.append(["Cell V1", cb])
	res.append(["Cell V2", cc])
	res.append(["Cell V3", cd])
	
	return res

func select(at : Vector2) -> void:
	if not has_focus:
		return
	
	if not shift_pressed:
		SetupMain.clear_selecteds()
	
	var points = []
	var candidates = []
	var most_near = null
	var gmouse = get_2d_to_3d_view(get_global_mouse_position(), 9999, 9999, 9999)
	var mod : int
	
	for e in SetupMain.map.entities:
		if not e.classname == "sector_zone":
			continue
		
		match SetupMain.editor_settings[SetupMain.ED_EDITMODE]:
			SetupMain.E_VWMODES.EDIT_VERTEX:
				mod = SetupMain.Selectors.SELT_VERTEX
				
				var vertices : Array[Array]
				vertices = get_sector_vertices(e.id)
				
				if not vertices.size() > 0:
					return
				
				for i in range(vertices.size()):
					var v_name : String = vertices[i][0]
					var v_pos : Vector3 = vertices[i][1]
					var v2_pos : Vector2 = get_3d_to_2d_view(v_pos)
					
					if not is_vertex_displayed(v_pos):
						continue
					
					if (get_canvas_transform() * v2_pos).distance_to(at) < 30.0:
						points.append([e.id, [v_name], gmouse.distance_to(v_pos)])
			
			SetupMain.E_VWMODES.EDIT_LINE:
				mod = SetupMain.Selectors.SELT_EDGE
				
				var lines = []
				
				lines.append(["Floor V0", "Floor V1"])
				lines.append(["Floor V1", "Floor V2"])
				lines.append(["Floor V2", "Floor V3"])
				lines.append(["Floor V3", "Floor V0"])
				
				lines.append(["Cell V0", "Cell V1"])
				lines.append(["Cell V1", "Cell V2"])
				lines.append(["Cell V2", "Cell V3"])
				lines.append(["Cell V3", "Cell V0"])
				
				lines.append(["Floor V0", "Cell V0"])
				lines.append(["Floor V1", "Cell V1"])
				lines.append(["Floor V2", "Cell V2"])
				lines.append(["Floor V3", "Cell V3"])
				
				#most_near = []
				
				for i in range(lines.size()):
					var v0 = e.get_keyvalue(lines[i][0]) as Vector3
					var v1 = e.get_keyvalue(lines[i][1]) as Vector3
					
					if not (is_vertex_displayed(v0) and is_vertex_displayed(v1)):
						continue
					
					var v2_0 = get_canvas_transform() * get_3d_to_2d_view(v0)
					var v2_1 = get_canvas_transform() * get_3d_to_2d_view(v1)
					
					var x1 = v2_0.x
					var y1 = v2_0.y
					var x2 = v2_1.x
					var y2 = v2_1.y
					var x0 = at.x
					var y0 = at.y
					
					var eq = abs((x2 - x1) * (y1 - y0) - (x1 - x0) * (y2 - y1)) / sqrt(pow(x2 - x1, 2.0) + pow(y2 - y1, 2.0))
					#print(eq)
					
					if eq < 30.0:
						var middle = (v0 + v1) / 2
						var d = gmouse.distance_to(middle)
						points.append([e.id, [lines[i][0], lines[i][1]], d])
					
					#if not most_near:
					#	most_near = [i, eq]
					#else:
					#	if eq < most_near[1]:
					#		most_near = [i, eq]
					
				#if most_near:
				#	var s = SetupMain.Selectors.new()
				#	s.entity_id = e.id
				#	s.vertices.append(lines[most_near[0]][0])
				#	s.vertices.append(lines[most_near[0]][1])
				#	s.mod = SetupMain.Selectors.SELT_EDGE
				#	
				#	SetupMain.add_selector(s)
				#	
				#	most_near = []
	
	for i in range(points.size()):
		candidates.append([i])
		#print(points[i], " ", candidates[i], " ", gmouse)]
		
		if not most_near:
			most_near = points[i]
		else:
			if points[i][2] < most_near[2]:
				most_near = points[i]
	
	#for i in range(candidates.size()):
	#	if not most_near:
	#		most_near = candidates[i]
	#	else:
	#		if candidates[i][1] < most_near[1]:
	#			most_near = candidates[i]
	
	
	"""
	var near_point = (get_2d_to_3d_view(get_global_mouse_position()) * -1).distance_to(v_pos)
	print(v_pos, " ", get_2d_to_3d_view(get_global_mouse_position()), " ", near_point)
	
	if not most_near:
		most_near = [v_name, v_pos.distance_to(get_2d_to_3d_view(gmouse)), e.id]
		
	else:
		if most_near[1] > v_pos.distance_to(get_2d_to_3d_view(gmouse)):
			most_near = [v_name, v_pos.distance_to(get_2d_to_3d_view(gmouse)), e.id]
		else:
			pass
	"""
	
	if most_near:
		var s = SetupMain.Selectors.new()
		s.entity_id = most_near[0]
		s.vertices.append_array(most_near[1])
		s.mod = mod

		SetupMain.add_selector(s)

	return

func transform_selectors(movement : Vector2) -> void:
	if not has_focus:
		return
	
	for slt in SetupMain.selecteds:
		var e : BaseEntity = SetupMain.map.get_entity(slt.entity_id)
		
		if not e:
			continue
		
		for v_name in slt.vertices:
			var v : Vector3 = e.get_keyvalue(v_name)
			
			match SetupMain.editor_settings[SetupMain.ED_TRANSFORM]:
				SetupMain.E_TRANS.TRANSLATE:
					var grid_size = SetupMain.editor_settings[SetupMain.ED_GRID_SIZE]
					v += get_2d_to_3d_view(movement).snapped(Vector3.ONE * grid_size)
			
			e.set_keyvalue(v_name, v)

func _ready():
	viewport_frame.mouse_entered.connect(func():
		viewport_frame.grab_focus()
		
		if not viewport_frame.has_focus():
			return
		
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			has_focus = true)
	
	viewport_frame.mouse_exited.connect(func():
		if not viewport_frame.has_focus():
			return
		
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			has_focus = false)

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if has_focus:
				if SetupMain.editor_settings[SetupMain.ED_TRANSFORM] != SetupMain.E_TRANS.NOTHING:
					SetupMain.editor_settings[SetupMain.ED_TRANSFORM] = SetupMain.E_TRANS.NOTHING
					return
			
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					b1_pressed = true
					select(event.position)
				
				MOUSE_BUTTON_RIGHT:
					b2_pressed = true
				
				MOUSE_BUTTON_WHEEL_UP:
					zoom_camera(0.2)
				
				MOUSE_BUTTON_WHEEL_DOWN:
					zoom_camera(-0.2)
					
		else:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					b1_pressed = false
				
				MOUSE_BUTTON_RIGHT:
					b2_pressed = false
	
	if event is InputEventMouseMotion:
		if b2_pressed and ctrl_pressed:
			move_camera(event.relative)
		
		create_selection(get_global_mouse_position(), event.relative)
		create_sector_selection(get_global_mouse_position(), event.relative)
		transform_selectors(event.relative)
	
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_SHIFT:
					shift_pressed = true
				
				KEY_G:
					SetupMain.editor_settings[SetupMain.ED_TRANSFORM] = SetupMain.E_TRANS.TRANSLATE
				
				KEY_S:
					SetupMain.editor_settings[SetupMain.ED_TRANSFORM] = SetupMain.E_TRANS.SCALE
				
				KEY_R:
					SetupMain.editor_settings[SetupMain.ED_TRANSFORM] = SetupMain.E_TRANS.ROTATE
				
				KEY_CTRL:
					ctrl_pressed = true
		else:
			match event.keycode:
				KEY_SHIFT:
					shift_pressed = false
				
				KEY_CTRL:
					ctrl_pressed = false

func is_vertex_displayed(v : Vector3) -> bool:
	return v.y <= SetupMain.editor_settings[SetupMain.ED_YMIN]

func get_vertices_on_selection() -> void:
	if not selection:
		return
	
	for e in SetupMain.map.entities:
		if not e.classname == "sector_zone":
			continue
		
		var vertices = get_sector_vertices(e.id)
		
		match SetupMain.editor_settings[SetupMain.ED_EDITMODE]:
			SetupMain.E_VWMODES.EDIT_VERTEX:
				for vdata in vertices:
					if not is_vertex_displayed(vdata[1]):
						continue
					
					if Rect2(selection.start, selection.dim()).abs().has_point(get_3d_to_2d_view(vdata[1])):
						var s = SetupMain.Selectors.new()
						s.entity_id = e.id
						s.mod = SetupMain.Selectors.SELT_VERTEX
						s.vertices.append(vdata[0])
						
						SetupMain.add_selector(s)

func get_2d_coords_snapped(local : Vector2) -> Vector2:
	return local.snapped(Vector2.ONE * SetupMain.editor_settings[SetupMain.ED_GRID_SIZE])

func get_nearest_3d_point(point : Vector3, points : Array[Vector3], thers = 0.5) -> int:
	var most = null
	var most_idx = -1
	
	for i in range(points.size()):
		if not most:
			most = points[i]
			most_idx = i
		else:
			if points[i].distance_to(point) <= thers:
				most = points[i]
				most_idx = i
	
	return most_idx

func get_2d_to_3d_view(p : Vector2, x = 0, y = 0, z = 0) -> Vector3:
	var v : Vector3
	
	match default_vmod_view:
		VMOD_VIEW.VMOD_VTOP:
			v.x = p.x
			v.z = p.y
			v.y = 1 * y
		
		VMOD_VIEW.VMOD_VLEFT:
			v.z = p.x
			v.y = -p.y
			v.x = -1 * x
		
		VMOD_VIEW.VMOD_VRIGHT:
			v.z = -p.x
			v.y = -p.y
			v.x = 1 * x
		
		VMOD_VIEW.VMOD_VFRONT:
			v.x = p.x
			v.y = -p.y
			v.z = 1 * z
		
		VMOD_VIEW.VMOD_VBACK:
			v.x = -p.x
			v.y = -p.y
			v.z = -1 * z
		
		VMOD_VIEW.VMOD_VORTHO:
			v.x = p.x
			v.y = -p.y
			
			v = ortho_plane.project(v)

	return v

func create_sector_selection(start : Vector2, rel : Vector2) -> void:
	if not has_focus:
		return
	
	if not SetupMain.get_edit_mode_enabled(SetupMain.E_VWMODES.ADDSECTOR):
		return
	
	if b1_pressed:
		if not sector_selection:
			var at = get_2d_coords_snapped(start)
			sector_selection = AABB(get_2d_to_3d_view(at), get_2d_to_3d_view(at) + Vector3.ONE * 1)
		
		var dir = (get_2d_to_3d_view(get_2d_coords_snapped(start)) - sector_selection.end)
		
		if not (sector_selection.end + dir) - sector_selection.position == Vector3.ZERO:
			sector_selection.end += (get_2d_to_3d_view(get_2d_coords_snapped(start)) - sector_selection.end)
		
	else:
		#create sector
		if sector_selection is AABB:
			SetupMain.map.create_sector(sector_selection)
		sector_selection = null

func create_selection(start : Vector2, rel : Vector2) -> void:
	if not has_focus:
		return
	
	if SetupMain.get_edit_mode_enabled(SetupMain.E_VWMODES.EDIT_FACE) or \
		SetupMain.get_edit_mode_enabled(SetupMain.E_VWMODES.EDIT_LINE) or \
		SetupMain.get_edit_mode_enabled(SetupMain.E_VWMODES.EDIT_VERTEX):
			if b1_pressed and shift_pressed:
				var mouse = get_2d_coords_snapped(start)
				if not selection:
					selection = SelectionBox.new(mouse, mouse)
				
				selection.end += get_2d_coords_snapped(start - selection.end)
			else:
				get_vertices_on_selection()
				selection = null

func get_3d_to_2d_view(p : Vector3) -> Vector2:
	var v : Vector2
	
	match default_vmod_view:
		VMOD_VIEW.VMOD_VTOP:
			v.x = p.x
			v.y = p.z
		
		VMOD_VIEW.VMOD_VLEFT:
			v.x = p.z
			v.y = -p.y
		
		VMOD_VIEW.VMOD_VRIGHT:
			v.x = -p.z
			v.y = -p.y
		
		VMOD_VIEW.VMOD_VFRONT:
			v.x = p.x
			v.y = -p.y
		
		VMOD_VIEW.VMOD_VBACK:
			v.x = -p.x
			v.y = -p.y
		
		VMOD_VIEW.VMOD_VORTHO:
			var l = ortho_plane.project(p)
			v.x = l.x
			v.y = -l.y
	
	return v

func draw_grid():
	var y = 0
	var grid_size = SetupMain.editor_settings[SetupMain.ED_GRID_SIZE]
	for x in range(get_viewport().size.x / grid_size):
		draw_line(Vector2(x * grid_size, 0), Vector2(x * grid_size, get_viewport().size.y), Color(1.0, 1.0, 1.0, 0.5))
		draw_line(Vector2(0, y * grid_size), Vector2(get_viewport().size.x, y * grid_size), Color(1.0, 1.0, 1.0, 0.2))
		y += 1
		y = clamp(y, 0, get_viewport().size.y / grid_size)

func draw_point(p : Vector3) -> void:
	if not is_vertex_displayed(p):
		return
	
	var col = Color.SKY_BLUE
	col.a = 0.5
	
	for slt in SetupMain.selecteds:
		if not slt.mod == SetupMain.Selectors.SELT_VERTEX:
			continue
		
		var e : BaseEntity = SetupMain.map.get_entity(slt.entity_id)
		
		if not e:
			break
		
		if not e.classname == "sector_zone":
			continue
		
		for v_name in slt.vertices:
			if e.get_keyvalue(v_name) == p:
				col = Color.YELLOW
				break
	
	draw_circle(get_3d_to_2d_view(p), 2.0, col)
	if SetupMain.editor_settings[SetupMain.ED_DISPCOORDS]:
		draw_string(GUI_FONT, get_3d_to_2d_view(p), str(get_3d_to_2d_view(p)), HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)

func draw_segment(p0 : Vector3, p1 : Vector3, color = Color.DIM_GRAY) -> void:
	if not (is_vertex_displayed(p0) and is_vertex_displayed(p1)):
		return
	
	for slt in SetupMain.selecteds:
		if not slt.mod == SetupMain.Selectors.SELT_EDGE:
			continue
		
		var e : BaseEntity = SetupMain.map.get_entity(slt.entity_id)
		
		if not e:
			break
		
		if not e.classname == "sector_zone":
			continue
		
		for v_name_idx in range(0, slt.vertices.size(), 2):
			if e.get_keyvalue(slt.vertices[v_name_idx + 0]) == p0 and e.get_keyvalue(slt.vertices[v_name_idx + 1]) == p1 or \
			e.get_keyvalue(slt.vertices[v_name_idx + 0]) == p1 and e.get_keyvalue(slt.vertices[v_name_idx + 1]) == p0:
				color = Color.YELLOW
				break
	
	draw_line(get_3d_to_2d_view(p0), get_3d_to_2d_view(p1), color)

func draw_entities() -> void:
	for i in range(SetupMain.map.entities.size()):
		var e = SetupMain.map.entities[i] as BaseEntity
		
		if e.classname == "sector_zone":
			var fa = e.get_keyvalue("Floor V0") as Vector3
			var fb = e.get_keyvalue("Floor V1") as Vector3
			var fc = e.get_keyvalue("Floor V2") as Vector3
			var fd = e.get_keyvalue("Floor V3") as Vector3
			
			var ca = e.get_keyvalue("Cell V0") as Vector3
			var cb = e.get_keyvalue("Cell V1") as Vector3
			var cc = e.get_keyvalue("Cell V2") as Vector3
			var cd = e.get_keyvalue("Cell V3") as Vector3
			
			#draw floor topview
			draw_segment(fa, fb, Color.RED)
			draw_segment(fb, fc, Color.RED)
			draw_segment(fc, fd, Color.RED)
			draw_segment(fd, fa, Color.RED)
			
			#draw cell topview
			draw_segment(ca, cb, Color.BLUE)
			draw_segment(cb, cc, Color.BLUE)
			draw_segment(cc, cd, Color.BLUE)
			draw_segment(cd, ca, Color.BLUE)
			
			#draw floor and cell sideview
			draw_segment(fa, ca, Color.GREEN)
			draw_segment(fb, cb, Color.GREEN)
			draw_segment(fc, cc, Color.GREEN)
			draw_segment(fd, cd, Color.GREEN)
			
			#draw all vertices
			draw_point(fa)
			draw_point(fb)
			draw_point(fc)
			draw_point(fd)
			
			draw_point(ca)
			draw_point(cb)
			draw_point(cc)
			draw_point(cd)

func draw_selection() -> void:
	if selection is SelectionBox:
		draw_rect(Rect2(selection.start, selection.dim()), Color(0.5, 0.5, 0.5, 0.2))

func draw_sector_selection() -> void:
	#if sector_selection is SelectionBox:
	#	draw_string(GUI_FONT,
	#	sector_selection.end,
	#	"%s m x %s m" % [abs(sector_selection.dim().x), abs(sector_selection.dim().y)],HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	#	draw_rect(Rect2(sector_selection.start, sector_selection.dim()), Color(1.0, 0.0, 0.0, 1.0), false)
	
	if sector_selection is AABB:
		var f0 = sector_selection.position
		var f1 = sector_selection.position + sector_selection.size * Vector3(1, 0, 0)
		var f2 = sector_selection.position + sector_selection.size * Vector3(1, 0, 1)
		var f3 = sector_selection.position + sector_selection.size * Vector3(0, 0, 1)
		
		var c0 = sector_selection.position + sector_selection.size * Vector3(0, 1, 0)
		var c1 = sector_selection.position + sector_selection.size * Vector3(1, 1, 0)
		var c2 = sector_selection.position + sector_selection.size * Vector3(1, 1, 1)
		var c3 = sector_selection.position + sector_selection.size * Vector3(0, 1, 1)
		
		draw_segment(f0, f1, Color.RED)
		draw_segment(f1, f2, Color.RED)
		draw_segment(f2, f3, Color.RED)
		draw_segment(f3, f0, Color.RED)
		
		draw_segment(c0, c1, Color.RED)
		draw_segment(c1, c2, Color.RED)
		draw_segment(c2, c3, Color.RED)
		draw_segment(c3, c0, Color.RED)
		
		draw_segment(f0, c0, Color.RED)
		draw_segment(f1, c1, Color.RED)
		draw_segment(f2, c2, Color.RED)
		draw_segment(f3, c3, Color.RED)
		
		draw_string(GUI_FONT,
		get_3d_to_2d_view(f0),
		"%s m x %s m %s m" % [abs(sector_selection.size.x), abs(sector_selection.size.y), abs(sector_selection.size.z)],HORIZONTAL_ALIGNMENT_LEFT, -1, 16)

func _draw():
	draw_grid()
	draw_entities()
	draw_sector_selection()
	draw_selection()

func _process(delta):
	#lock_cursor()
	
	queue_redraw()
