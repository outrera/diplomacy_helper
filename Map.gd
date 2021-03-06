extends TextureRect

enum MOVES {MOVE, HOLD, SUPPORT, CONVOY, NONE, DISBAND}

onready var Piece = preload("res://Piece.tscn")
onready var info_panel = $CanvasLayer/Panel/Info
onready var select_menu = $CanvasLayer/OrderSelectMenu
var selected = null
var select_target = false
var new_pos = null


func _ready():
	pass

func add_unit(_position, _nation, _type):
	#for unit in CONSTANTS.STARTING_UNITS:
		var p = Piece.instance()
		p.position = _position
		p.nation = _nation
		p.type = _type
		$Pieces.add_child(p)
		p.connect("clicked", self, "_on_Piece_clicked")
		
func _unhandled_input(event):
	if event.is_action_pressed('ui_select'):
		# clear all orders
		for piece in $Pieces.get_children():
			piece.move = NONE
			selected = null
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT:
			if select_target:
				selected.target = get_global_mouse_position()
				select_target = false
				selected.active = false
				selected = null
		if event.button_index == BUTTON_MIDDLE:
				new_pos = get_global_mouse_position()
				$CanvasLayer/ClickMenu.rect_position = $CanvasLayer/ClickMenu.get_global_mouse_position()
				$CanvasLayer/ClickMenu.popup()

func _on_Piece_clicked(piece):
	if piece.active:
		if selected:
			selected.active = false
		selected = piece
		select_menu.rect_position = select_menu.get_global_mouse_position()
		select_menu.set_item_disabled(CONVOY, selected.type == selected.TYPES.ARMY)
		select_menu.popup()
	else:
		selected = null

func _on_OrderSelectMenu_id_pressed(ID):
	selected.move = ID
	selected.target = null
	match ID:
		NONE:
			selected.active = false
			selected = null
		HOLD:
			selected.active = false
			selected = null
		MOVE:
			select_target = true
		SUPPORT:
			select_target = true
		CONVOY:
			select_target = true
		DISBAND:
			selected.queue_free()
			selected = null

func _on_ClickMenu_new_unit_menu():
	$CanvasLayer/AddUnitWindow.popup_centered()
	$CanvasLayer/AddUnitWindow.focus_mode = FOCUS_ALL

func _on_AddUnitWindow_add_unit(_nation, _type):
	#printt("adding new:", _nation, _type)
	var p = Piece.instance()
	p.position = new_pos
	p.nation = _nation
	p.type = _type
	$Pieces.add_child(p)
	p.connect("clicked", self, "_on_Piece_clicked")

func save_state():
	var save_game = File.new()
	#if save_game.file_exists("user://savegame.save"):
	save_game.open("user://savegame.save", File.WRITE)	
	for unit in $Pieces.get_children():
		var d = {}
		d["data"] = "unit"
		d["posx"] = unit.position.x
		d["posy"] = unit.position.y
		d["nation"] = unit.nation
		d["type"] = unit.type
		#printt(d)
		save_game.store_line(to_json(d))
	# also regions
	for region in $Regions.get_children():
		var d = {}
		d["data"] = "region"
		d["region"] = region.name
		d["owner"] = region.control
		#printt(d)
		save_game.store_line(to_json(d))
	save_game.close()
	
func load_state():
	var save_game = File.new()
	if not save_game.file_exists("user://savegame.save"):
		print("No save found!")
		return
	# clear existing state
	for unit in $Pieces.get_children():
		unit.queue_free()
	yield(get_tree(), "idle_frame")
	print("empty", $Pieces.get_child_count())
	
	save_game.open("user://savegame.save", File.READ)
	var count = 0
	while not save_game.eof_reached():
		var line = parse_json(save_game.get_line())
		if line:
			if line["data"] == "region":
				get_node("Regions").get_node(line["region"]).control = int(line["owner"])
			if line["data"] == "unit":
				count += 1
				var pos = Vector2(line["posx"], line["posy"])
				add_unit(pos, int(line["nation"]), int(line["type"])) 
				printt("adding unit:", line["nation"], line["posx"], line["posy"])
	printt(count, $Pieces.get_child_count())
	
func _on_ClickMenu_update_regions():
	for region in $Regions.get_children():
		region.update()
	var score = {CONSTANTS.AUSTRIA: 0, CONSTANTS.ENGLAND: 0,
			 	CONSTANTS.FRANCE: 0, CONSTANTS.GERMANY: 0,
			 	CONSTANTS.ITALY: 0, CONSTANTS.RUSSIA: 0,
			 	CONSTANTS.TURKEY: 0}
	# count score
	for sup in CONSTANTS.SUPPLY_CENTERS:
		var val = $Regions.get_node(sup).control
		if val >= 0:
			score[val] += 1
	for n in score.keys():
		info_panel.get_node(str(n)).get_node("Num").text = str(score[n])