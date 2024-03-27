class_name FrameViewer extends Panel

enum VIEW_ALIGNMENTS {
	TOPVIEW,
	LEFTVIEW,
	RIGHTVIEW,
	BOTTOMVIEW,
	FRONTVIEW,
	BACKVIEW
}

const DEFAULT_SECTOR_SIZEHEIGHT := 10

@export var view_pos = VIEW_ALIGNMENTS.TOPVIEW
@export var grid_size := 16
@export var y_level := 0.0

var clicking := false
var right_clicking := false
var selection_box : Selector = null
var selected_entity : int = -1
var selected_sector_vertexname : String = ""
var selected_vertices : Array[SelectedVertex] = []

signal vertices_selected

class SelectedVertex:
	var sector_entity_id : int
	var sector_vertex_name : String
	
	func _init(id : int, vertex : String):
		sector_entity_id = id
		sector_vertex_name = vertex

class Selector:
	var start : Vector2
	var end : Vector2
	
	func _init(_start : Vector2, _end : Vector2):
		start =_start
		end = _end
	
	func expand(at : Vector2) -> void:
		end += at
	
	func get_dimension() -> Vector2:
		return Vector2(end.x - start.x, end.y - start.y)

func _init():
	return

func select_entity(id) -> void:
	selected_entity = id
	selected_sector_vertexname = ""

func select_vertex_at(local_mouse : Vector2):
	for e in ProjectMap.map.entities:
		if e.classname == "sector_zone":
			var all = []
			
			var fa = e.get_keyvalue("Floor V0") as Vector3
			var fb = e.get_keyvalue("Floor V1") as Vector3
			var fc = e.get_keyvalue("Floor V2") as Vector3
			var fd = e.get_keyvalue("Floor V3") as Vector3
			
			var ca = e.get_keyvalue("Cell V0") as Vector3
			var cb = e.get_keyvalue("Cell V1") as Vector3
			var cc = e.get_keyvalue("Cell V2") as Vector3
			var cd = e.get_keyvalue("Cell V3") as Vector3
			
			all.append(["Floor V0", fa])
			all.append(["Floor V1", fb])
			all.append(["Floor V2", fc])
			all.append(["Floor V3", fd])
			
			all.append(["Cell V0", ca])
			all.append(["Cell V1", cb])
			all.append(["Cell V2", cc])
			all.append(["Cell V3", cd])
			
			for i in range(all.size()):
				var pos = ProjectMap.map_view_transform * all[i][1] as Vector3
				var pos2 : Vector2
				
				match view_pos:
					VIEW_ALIGNMENTS.TOPVIEW:
						pos2 = Vector2(pos.x, pos.z)
				
				if pos2.distance_to(local_mouse) < 10.0:
					select_entity(e.id)
					selected_sector_vertexname = all[i][0]
					vertices_selected.emit()
					return
	
	selected_vertices.clear()
	select_entity(-1)

func select_all_vertex_on_selection() -> void:
	select_entity(-1)
	
	selected_vertices.clear()
	
	if not selection_box:
		return
	
	for e in ProjectMap.map.entities:
		if not e.classname == "sector_zone":
			continue
		
		var all = []
			
		var fa = e.get_keyvalue("Floor V0") as Vector3
		var fb = e.get_keyvalue("Floor V1") as Vector3
		var fc = e.get_keyvalue("Floor V2") as Vector3
		var fd = e.get_keyvalue("Floor V3") as Vector3
		
		var ca = e.get_keyvalue("Cell V0") as Vector3
		var cb = e.get_keyvalue("Cell V1") as Vector3
		var cc = e.get_keyvalue("Cell V2") as Vector3
		var cd = e.get_keyvalue("Cell V3") as Vector3
		
		all.append(["Floor V0", fa])
		all.append(["Floor V1", fb])
		all.append(["Floor V2", fc])
		all.append(["Floor V3", fd])
		
		all.append(["Cell V0", ca])
		all.append(["Cell V1", cb])
		all.append(["Cell V2", cc])
		all.append(["Cell V3", cd])
		
		for i in range(all.size()):
			var pos = ProjectMap.map_view_transform * all[i][1] as Vector3
			var pos2 : Vector2
			
			match view_pos:
				VIEW_ALIGNMENTS.TOPVIEW:
					pos2 = Vector2(pos.x, pos.z)
			
			print(Rect2(selection_box.start, abs(selection_box.get_dimension())))
			
			if Rect2(selection_box.start, abs(selection_box.get_dimension())).has_point(pos2):
				selected_vertices.append(SelectedVertex.new(e.id, all[i][0]))
				continue
	
	vertices_selected.emit()

func move_selecteds_vertex(at : Vector2, increment = true, keep_nonzero_values = false) -> void:
	var e : BaseEntity
	var v : Vector3
	
	if selected_vertices.size() > 0:
		for s in selected_vertices:
			e = ProjectMap.map.get_entity(s.sector_entity_id)
			
			match view_pos:
				VIEW_ALIGNMENTS.TOPVIEW:
					v.x = at.x
					v.z = at.y
			
			if increment:
				v += e.get_keyvalue(s.sector_vertex_name) as Vector3
			
			e.set_keyvalue(s.sector_vertex_name, v)
			continue
		return
	
	if not selected_entity > -1:
		return
	
	if not selected_sector_vertexname.length() > 0:
		return
	
	e = ProjectMap.map.get_entity(selected_entity)
	
	match view_pos:
		VIEW_ALIGNMENTS.TOPVIEW:
			v.x = at.x
			v.z = at.y
	
	if increment:
		v += e.get_keyvalue(selected_sector_vertexname) as Vector3
	else:
		if keep_nonzero_values:
			v.x = v.x if v.x != 0.0 else e.get_keyvalue(selected_sector_vertexname).x
			v.y = v.y if v.y != 0.0 else e.get_keyvalue(selected_sector_vertexname).y
			v.z = v.z if v.z != 0.0 else e.get_keyvalue(selected_sector_vertexname).z
	
	e.set_keyvalue(selected_sector_vertexname, v)

func get_transformed_coords(relative = Vector2.ZERO) -> Vector2:
	var coords : Vector2 = relative
	var global : Vector3
	
	match view_pos:
		VIEW_ALIGNMENTS.TOPVIEW:
			global = ProjectMap.map_transform * ProjectMap.map_view_transform * Vector3(relative.x, 0, relative.y)
			coords.x = global.x
			coords.y = global.z
	
	return coords

func get_local_to_world(local : Vector2) -> Vector2:
	var coords : Vector2
	
	match view_pos:
		VIEW_ALIGNMENTS.TOPVIEW:
			coords = local - Vector2(
				ProjectMap.map_view_transform.origin.x,
				ProjectMap.map_view_transform.origin.z)
	
	return coords

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					clicking = true
					
					match ProjectMap.editor.edit_mode:
						ProjectMap.EditModes.EDIT_VERTICES:
							select_vertex_at(event.position)
				
				MOUSE_BUTTON_RIGHT:
					call_deferred("grab_click_focus")
					right_clicking = true
		else:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					clicking = false
				
				MOUSE_BUTTON_RIGHT:
					right_clicking = false
	
	if event is InputEventKey:
		if event.pressed:
			match ProjectMap.editor.edit_mode:
				ProjectMap.EditModes.EDIT_VERTICES:
					match event.keycode:
								KEY_LEFT:
									move_selecteds_vertex(Vector2.LEFT)
								
								KEY_RIGHT:
									move_selecteds_vertex(Vector2.RIGHT)
								
								KEY_UP:
									move_selecteds_vertex(Vector2.UP)
								
								KEY_DOWN:
									move_selecteds_vertex(Vector2.DOWN)
	
	if event is InputEventMouseMotion:
		match ProjectMap.editor.edit_mode:
			ProjectMap.EditModes.ADD_SECTOR:
				if clicking:
					var local = event.position
					
					if not selection_box:
						selection_box = Selector.new(
							local.snapped(Vector2.ONE * grid_size),
							local.snapped(Vector2.ONE * grid_size))
					
					selection_box.expand(event.relative.snapped(Vector2.ONE * grid_size))
				else:
					if selection_box is Selector:
						var s = get_local_to_world(selection_box.start)
						
						ProjectMap.map.create_sector(
							AABB(
								Vector3(s.x, y_level, s.y),
								Vector3(selection_box.get_dimension().x, DEFAULT_SECTOR_SIZEHEIGHT, selection_box.get_dimension().y)))
						selection_box = null
		
			ProjectMap.EditModes.EDIT_VERTICES:
				if right_clicking:
					var mouse_snapped = event.position.snapped(Vector2.ONE * grid_size)
					if not selection_box:
						selection_box = Selector.new(
							mouse_snapped,
							mouse_snapped)
					
					selection_box.expand(event.relative.snapped(Vector2.ONE * grid_size))
				else:
					if selection_box is Selector:
						select_all_vertex_on_selection()
						selection_box = null
				
				if clicking:
					move_selecteds_vertex(get_local_to_world(event.position).snapped(Vector2.ONE * grid_size), false)
			
			ProjectMap.EditModes.MOVE_VIEW:
				if clicking:
					match view_pos:
						VIEW_ALIGNMENTS.TOPVIEW:
							ProjectMap.map_view_transform.origin += Vector3(event.relative.x, 0, event.relative.y)

func draw_grid():
	var y = 0
	for x in range(size.x / grid_size):
		draw_line(Vector2(x * grid_size, 0), Vector2(x * grid_size, size.y), Color(1.0, 1.0, 1.0, 0.5))
		draw_line(Vector2(0, y * grid_size), Vector2(size.x, y * grid_size), Color(1.0, 1.0, 1.0, 0.2))
		y += 1
		y = clamp(y, 0, size.y / grid_size)

func draw_point(p : Vector3) -> void:
	var g = ProjectMap.map_view_transform * p
	
	var v2 : Vector2
	match view_pos:
		VIEW_ALIGNMENTS.TOPVIEW:
			v2 = Vector2(g.x, g.z)
	
	var col = Color.SKY_BLUE
	col.a = 0.5
	
	if selected_vertices.size() > 0:
		for s in selected_vertices:
			if ProjectMap.map.get_entity(s.sector_entity_id).get_keyvalue(s.sector_vertex_name) == p:
				col = Color.YELLOW_GREEN
	else:
		if selected_entity > -1:
			if selected_sector_vertexname.length() > 0:
				if ProjectMap.map.get_entity(selected_entity).get_keyvalue(selected_sector_vertexname) == p:
					col = Color.YELLOW
	
	draw_circle(v2, 2.0, col)

func draw_segment(p0 : Vector3, p1 : Vector3, color = Color.DIM_GRAY) -> void:
	var g0 = ProjectMap.map_view_transform * p0
	var g1 = ProjectMap.map_view_transform * p1
	
	var v2_a : Vector2
	var v2_b : Vector2
	match view_pos:
		VIEW_ALIGNMENTS.TOPVIEW:
			v2_a = Vector2(g0.x, g0.z)
			v2_b = Vector2(g1.x, g1.z)
	
	draw_line(v2_a, v2_b, color)

func draw_entities() -> void:
	for i in range(ProjectMap.map.entities.size()):
		var e = ProjectMap.map.entities[i] as BaseEntity
		
		if e.classname == "sector_zone":
			var fa = e.get_keyvalue("Floor V0") as Vector3
			var fb = e.get_keyvalue("Floor V1") as Vector3
			var fc = e.get_keyvalue("Floor V2") as Vector3
			var fd = e.get_keyvalue("Floor V3") as Vector3
			
			var ca = e.get_keyvalue("Cell V0") as Vector3
			var cb = e.get_keyvalue("Cell V1") as Vector3
			var cc = e.get_keyvalue("Cell V2") as Vector3
			var cd = e.get_keyvalue("Cell V3") as Vector3
			
			draw_segment(fa, fb)
			draw_segment(fb, fc)
			draw_segment(fc, fd)
			draw_segment(fd, fa)
			
			draw_segment(ca, cb, Color.GRAY)
			draw_segment(cb, cc, Color.GRAY)
			draw_segment(cc, cd, Color.GRAY)
			draw_segment(cd, ca, Color.GRAY)
			
			draw_point(fa)
			draw_point(fb)
			draw_point(fc)
			draw_point(fd)
			
			draw_point(ca)
			draw_point(cb)
			draw_point(cc)
			draw_point(cd)

func _draw():
	draw_grid()
	#draw_origins()
	
	#for i in range(ProjectMap.unlinked_points.size()):
	#	var p = ProjectMap.unlinked_points[i]
	#	var view_p : Vector2
	#	var p_world_pos = ProjectMap.map_transform * p.position
	#	
	#	match view_pos:
	#		VIEW_ALIGNMENTS.TOPVIEW:
	#			view_p = Vector2(p_world_pos.x, p_world_pos.z)
	#	
	#	var col = Color.SKY_BLUE
	#	
	#	if p_world_pos.y == y_level:
	#		draw_circle(view_p, 3.0, col)
	
	draw_entities()
	
	if selection_box is Selector:
		draw_rect(Rect2(
			selection_box.start,
			selection_box.get_dimension()), Color(0.3, 0.5, 0.8, 0.3))

func _process(delta):
	queue_redraw()
