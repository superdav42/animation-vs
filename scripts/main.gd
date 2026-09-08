extends Control

const BackdropScript := preload("res://scripts/procedural_backdrop.gd")
const ArenaScript := preload("res://scripts/arena.gd")

var backdrop: Control
var screen: Control
var garage_category := "vehicles"
var toast: Label
var multiplayer_loadout := {"vehicles": "", "weapons": "", "abilities": ""}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_shell()
	_show_home()

func _build_shell() -> void:
	backdrop = BackdropScript.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen)

func _clear_screen() -> void:
	for child in screen.get_children():
		child.queue_free()
	toast = null

func _show_home() -> void:
	_clear_screen()
	backdrop.show()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_right", 54)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_bottom", 44)
	screen.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var kicker := Label.new()
	kicker.text = "SOLO OR LOCAL MULTIPLAYER  •  DRAW YOUR GEAR"
	kicker.add_theme_font_size_override("font_size", 18)
	kicker.add_theme_color_override("font_color", Color("#61e2bb"))
	layout.add_child(kicker)
	var title := Label.new()
	title.text = "ANIMATION\nVS"
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color("#f5f0d7"))
	title.add_theme_color_override("font_shadow_color", Color(0.13, 0.8, 0.58, 0.28))
	title.add_theme_constant_override("shadow_offset_x", 5)
	title.add_theme_constant_override("shadow_offset_y", 6)
	layout.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Your loadout sets the CPU's level.\nIts gear is always different from yours."
	subtitle.add_theme_font_size_override("font_size", 21)
	subtitle.add_theme_color_override("font_color", Color("#a9c2c1"))
	layout.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 16
	layout.add_child(spacer)
	var play := _menu_button("PLAY A ROUND", "fight a randomized CPU rival", true)
	play.pressed.connect(_start_round)
	layout.add_child(play)
	var multiplayer := _menu_button("MULTIPLAYER", "choose Player 2 gear, then fight face-to-face", true)
	multiplayer.pressed.connect(_show_multiplayer_setup)
	layout.add_child(multiplayer)
	var arena_data: Dictionary = GearCatalog.ARENAS[Progress.selected_arena]
	var arenas := _menu_button("CHOOSE ARENA:  %s" % arena_data["name"].to_upper(), "pick the background before the round")
	arenas.pressed.connect(_show_arenas)
	layout.add_child(arenas)
	var garage := _menu_button("GARAGE", "buy gear, powers & skins")
	garage.pressed.connect(_show_garage)
	layout.add_child(garage)
	var mode_text := "CONTROL MODE:  %s" % ("MOBILE" if Progress.mobile_mode else "KEYBOARD")
	var mode := _menu_button(mode_text, "tap to switch")
	mode.pressed.connect(_toggle_mode)
	layout.add_child(mode)
	var loadout := _menu_button("LOADOUT", "equip your unlocked gear")
	loadout.pressed.connect(_show_loadout)
	layout.add_child(loadout)
	var customize := _menu_button("CUSTOMIZE FIGHTER", "skin, colour & face design")
	customize.pressed.connect(_show_customize)
	layout.add_child(customize)
	var help := _menu_button("HOW TO PLAY", "controls & ability guide")
	help.pressed.connect(_show_help)
	layout.add_child(help)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	footer.custom_minimum_size.y = 64
	layout.add_child(footer)
	var credits := Label.new()
	credits.text = "PARTS  %d" % Progress.credits
	credits.add_theme_font_size_override("font_size", 22)
	credits.add_theme_color_override("font_color", Color("#ffd56b"))
	credits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	credits.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(credits)
	var best := Label.new()
	best.text = "BEST  %06d" % Progress.best_score
	best.add_theme_font_size_override("font_size", 18)
	best.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(best)

func _show_garage() -> void:
	_clear_screen()
	backdrop.show()
	var layout := _page_layout("THE GARAGE", "Spend earned parts on gear and skins.")
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	layout.add_child(tabs)
	for category in ["vehicles", "weapons", "abilities", "skins"]:
		var tab := Button.new()
		tab.text = category.to_upper()
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size.y = 58
		tab.add_theme_font_size_override("font_size", 14)
		if garage_category == category:
			tab.add_theme_color_override("font_color", Color("#71f0bd"))
		tab.pressed.connect(_set_garage_category.bind(category))
		tabs.add_child(tab)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	for item_id in GearCatalog.category_data(garage_category):
		list.add_child(_shop_card(garage_category, item_id))
	toast = Label.new()
	toast.custom_minimum_size.y = 38
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 18)
	toast.add_theme_color_override("font_color", Color("#ffd46d"))
	layout.add_child(toast)

func _shop_card(category: String, item_id: String) -> Control:
	var data := GearCatalog.item(category, item_id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 142
	panel.add_theme_stylebox_override("panel", _box(Color(0.035, 0.11, 0.14, 0.94), GearCatalog.tier_color(data["tier"]), 2, 20))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var icon := Label.new()
	icon.text = data["icon"]
	icon.custom_minimum_size.x = 106
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 15)
	icon.add_theme_color_override("font_color", GearCatalog.tier_color(data["tier"]))
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var name := Label.new()
	name.text = "%s  //  %s" % [data["name"], data["tier"].to_upper()]
	name.add_theme_font_size_override("font_size", 22)
	info.add_child(name)
	var description := Label.new()
	description.text = data["description"]
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", Color("#a9c2c1"))
	info.add_child(description)
	var action := Button.new()
	action.custom_minimum_size = Vector2(114, 62)
	action.add_theme_font_size_override("font_size", 17)
	if Progress.owns(category, item_id):
		action.text = "OWNED"
		action.disabled = true
	else:
		action.text = "%d PARTS" % data["cost"]
		action.pressed.connect(_buy_item.bind(category, item_id))
	row.add_child(action)
	return panel

func _show_loadout() -> void:
	_clear_screen()
	backdrop.show()
	var layout := _page_layout("LOADOUT", "Weapon required. Vehicle and ability optional.")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 20)
	scroll.add_child(content)
	for category in ["vehicles", "weapons", "abilities"]:
		var heading := Label.new()
		heading.text = category.to_upper()
		heading.add_theme_font_size_override("font_size", 20)
		heading.add_theme_color_override("font_color", Color("#5ee5b7"))
		content.add_child(heading)
		if category != "weapons":
			content.add_child(_empty_loadout_card(category))
		for item_id in Progress.unlocked[category]:
			content.add_child(_loadout_card(category, item_id))

func _show_multiplayer_setup() -> void:
	_ensure_multiplayer_loadout()
	_clear_screen()
	backdrop.show()
	var layout := _page_layout("PLAYER 2 GEAR", "Choose from gear purchased in the Garage. Vehicle and ability are optional.")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	for category in ["weapons", "vehicles", "abilities"]:
		var heading := _section_heading("PLAYER 2  //  %s" % category.to_upper())
		heading.add_theme_color_override("font_color", Color("#f07eac"))
		content.add_child(heading)
		if category != "weapons":
			content.add_child(_multiplayer_gear_button(category, ""))
		for item_id in Progress.unlocked[category]:
			content.add_child(_multiplayer_gear_button(category, item_id))
	var start := _menu_button("START FACE-TO-FACE MATCH", "Player 2 uses the upside-down top side", true)
	start.pressed.connect(_start_round.bind("multiplayer"))
	layout.add_child(start)

func _ensure_multiplayer_loadout() -> void:
	if not Progress.owns("weapons", multiplayer_loadout["weapons"]):
		multiplayer_loadout["weapons"] = Progress.unlocked["weapons"][0]
	for category in ["vehicles", "abilities"]:
		if not multiplayer_loadout[category].is_empty() and not Progress.owns(category, multiplayer_loadout[category]):
			multiplayer_loadout[category] = ""

func _multiplayer_gear_button(category: String, item_id: String) -> Button:
	var button := Button.new()
	var active: bool = multiplayer_loadout[category] == item_id
	if item_id.is_empty():
		var empty_label := "ON FOOT" if category == "vehicles" else "NO ABILITY"
		button.text = "%s  •  %s" % [empty_label, "SELECTED" if active else "TAP TO SELECT"]
		button.add_theme_stylebox_override("normal", _box(Color(0.08, 0.08, 0.13, 0.95), Color("#805a79"), 3 if active else 1, 16))
	else:
		var data := GearCatalog.item(category, item_id)
		button.text = "%s  //  %s  •  %s" % [data["name"], data["tier"].to_upper(), "SELECTED" if active else "TAP TO SELECT"]
		button.add_theme_stylebox_override("normal", _box(Color(0.12, 0.055, 0.11, 0.95), GearCatalog.tier_color(data["tier"]), 3 if active else 1, 16))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 66
	button.add_theme_font_size_override("font_size", 17)
	if not active:
		button.pressed.connect(_set_multiplayer_item.bind(category, item_id))
	return button

func _set_multiplayer_item(category: String, item_id: String) -> void:
	if category == "weapons" and not Progress.owns(category, item_id):
		return
	if category in ["vehicles", "abilities"] and not item_id.is_empty() and not Progress.owns(category, item_id):
		return
	multiplayer_loadout[category] = item_id
	_show_multiplayer_setup()

func _empty_loadout_card(category: String) -> Control:
	var active: bool = Progress.equipped[category].is_empty()
	var label := "ON FOOT" if category == "vehicles" else "NO ABILITY"
	var detail := "CPU ALSO GOES WITHOUT" if active else "TAP TO LEAVE SLOT EMPTY"
	var button := Button.new()
	button.text = "%s\nOPTIONAL  •  %s" % [label, detail]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 82
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", Color("#baffd9") if active else Color("#c6d0cc"))
	button.add_theme_stylebox_override("normal", _box(Color(0.035, 0.1, 0.13, 0.94), Color("#4e8276"), 2 if active else 1, 18))
	if not active:
		button.pressed.connect(_unequip_item.bind(category))
	return button

func _loadout_card(category: String, item_id: String) -> Control:
	var data := GearCatalog.item(category, item_id)
	var active: bool = Progress.equipped[category] == item_id
	var button := Button.new()
	button.text = "%s\n%s  •  %s" % [data["name"], data["tier"].to_upper(), "EQUIPPED" if active else "TAP TO EQUIP"]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 90
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("#baffd9") if active else Color("#e9efdf"))
	button.add_theme_stylebox_override("normal", _box(Color(0.04, 0.14, 0.17, 0.94), GearCatalog.tier_color(data["tier"]), 2 if active else 1, 18))
	if not active:
		button.pressed.connect(_equip_item.bind(category, item_id))
	return button

func _show_customize() -> void:
	_clear_screen()
	backdrop.show()
	var layout := _page_layout("CUSTOMIZE", "Style your stick fighter. Purchased skins appear here.")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)

	var current := Label.new()
	var skin_name: String = GearCatalog.item("skins", Progress.equipped["skins"])["name"]
	current.text = "CURRENT  //  %s  •  %s  •  %s" % [skin_name.to_upper(), Progress.player_color.to_upper(), GearCatalog.PLAYER_DESIGNS[Progress.player_design].to_upper()]
	current.add_theme_font_size_override("font_size", 18)
	current.add_theme_color_override("font_color", GearCatalog.PLAYER_COLORS[Progress.player_color])
	content.add_child(current)
	content.add_child(_section_heading("OWNED SKINS"))
	for skin_id in Progress.unlocked["skins"]:
		content.add_child(_custom_skin_card(skin_id))

	content.add_child(_section_heading("LINE COLOUR"))
	var color_grid := GridContainer.new()
	color_grid.columns = 2
	color_grid.add_theme_constant_override("h_separation", 10)
	color_grid.add_theme_constant_override("v_separation", 10)
	content.add_child(color_grid)
	for color_name in GearCatalog.PLAYER_COLORS:
		var color_button := Button.new()
		color_button.text = "%s%s" % ["✓  " if Progress.player_color == color_name else "", color_name.to_upper()]
		color_button.custom_minimum_size = Vector2(285, 64)
		color_button.add_theme_font_size_override("font_size", 17)
		var swatch: Color = GearCatalog.PLAYER_COLORS[color_name]
		color_button.add_theme_stylebox_override("normal", _box(Color(swatch, 0.22), swatch, 3 if Progress.player_color == color_name else 1, 15))
		color_button.pressed.connect(_set_player_color.bind(color_name))
		color_grid.add_child(color_button)

	content.add_child(_section_heading("FACE DESIGN"))
	for design_id in GearCatalog.PLAYER_DESIGNS:
		var design_button := Button.new()
		var active: bool = Progress.player_design == design_id
		design_button.text = "%s  %s" % ["✓" if active else "○", GearCatalog.PLAYER_DESIGNS[design_id].to_upper()]
		design_button.custom_minimum_size.y = 64
		design_button.add_theme_font_size_override("font_size", 18)
		design_button.pressed.connect(_set_player_design.bind(design_id))
		content.add_child(design_button)

func _section_heading(text: String) -> Label:
	var heading := Label.new()
	heading.text = text
	heading.custom_minimum_size.y = 42
	heading.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", Color("#69e8bc"))
	return heading

func _custom_skin_card(skin_id: String) -> Button:
	var data := GearCatalog.item("skins", skin_id)
	var active: bool = Progress.equipped["skins"] == skin_id
	var button := Button.new()
	button.text = "%s\n%s  •  %s" % [data["name"], data["tier"].to_upper(), "EQUIPPED" if active else "TAP TO WEAR"]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 84
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_stylebox_override("normal", _box(Color(0.04, 0.14, 0.17, 0.94), GearCatalog.tier_color(data["tier"]), 2 if active else 1, 18))
	if not active:
		button.pressed.connect(_equip_custom_skin.bind(skin_id))
	return button

func _show_help() -> void:
	_clear_screen()
	backdrop.show()
	var layout := _page_layout("HOW TO PLAY", "Beat the CPU before time expires, or finish with more health.")
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(Color(0.03, 0.1, 0.13, 0.94), Color("#2a725d"), 2, 24))
	layout.add_child(panel)
	var text := Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 22)
	text.add_theme_color_override("font_color", Color("#d5e3da"))
	text.text = "VS RULES\nThe CPU always draws visibly different gear at your equipment tiers. Every vehicle changes speed, armour, and boost. The Pocket Rocket and Gravity Wings support sustained flight. Teleports may move upward, but gravity pulls you back to your platform. A low-chance post-round reward replaces parts with a random gear unlock, with high tiers much rarer.\n\nKEYBOARD MODE\nA / D or LEFT / RIGHT   Move sideways\nW / UP   Jump; hold to fly when equipped\nSPACE   Use weapon\nQ   Use equipped power\nSHIFT   Vehicle boost or rocket thrust\nMOUSE   Aim and choose targets\nESC   Forfeit\n\nMOBILE MODE\nTouch and drag anywhere in the left movement zone. The large joystick appears under your thumb, then disappears on release. Use JUMP to leave the floor, or drag upward to fly when equipped. ATTACK, POWER, BOOST, or THRUST remain large on the right.\n\nMULTIPLAYER\nChoose Player 2's weapon and optional vehicle and ability from purchased gear. Player 1 fights from the bottom. Player 2 and their controls are upside down at the top; movement is inverted for the opposite viewing direction."
	panel.add_child(text)

func _show_arenas() -> void:
	_clear_screen()
	backdrop.show()
	var layout := _page_layout("CHOOSE ARENA", "Your selected background is used for solo and multiplayer rounds.")
	var list := VBoxContainer.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	layout.add_child(list)
	for arena_id in GearCatalog.ARENAS:
		var data: Dictionary = GearCatalog.ARENAS[arena_id]
		var active: bool = Progress.selected_arena == arena_id
		var button := Button.new()
		button.text = "%s\n%s  •  %s" % [data["name"].to_upper(), data["description"], "SELECTED" if active else "TAP TO SELECT"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 142
		button.add_theme_font_size_override("font_size", 19)
		button.add_theme_stylebox_override("normal", _box(Color(data["accent"], 0.13), data["accent"], 4 if active else 2, 20))
		if not active:
			button.pressed.connect(_select_arena.bind(arena_id))
		list.add_child(button)

func _select_arena(arena_id: String) -> void:
	Progress.select_arena(arena_id)
	_show_arenas()

func _page_layout(title_text: String, subtitle_text: String) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 38)
	margin.add_theme_constant_override("margin_bottom", 34)
	screen.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	layout.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#f4f0d8"))
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size.x = 0
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("#9eb8b5"))
	titles.add_child(subtitle)
	var wallet := Label.new()
	wallet.text = "PARTS  %d" % Progress.credits
	wallet.custom_minimum_size.x = 100
	wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wallet.add_theme_font_size_override("font_size", 18)
	wallet.add_theme_color_override("font_color", Color("#ffd56b"))
	wallet.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(wallet)
	var back := Button.new()
	back.text = "‹  HOME"
	back.custom_minimum_size.y = 54
	back.pressed.connect(_show_home)
	layout.add_child(back)
	return layout

func _menu_button(title: String, detail: String, primary := false) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [title, detail]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 80 if primary else 62
	button.add_theme_font_size_override("font_size", 19 if primary else 17)
	var fill := Color("#196d58") if primary else Color(0.035, 0.12, 0.15, 0.94)
	var border := Color("#82f3bb") if primary else Color("#275c53")
	button.add_theme_stylebox_override("normal", _box(fill, border, 2, 19))
	button.add_theme_stylebox_override("hover", _box(fill.lightened(0.08), Color("#9dffd0"), 2, 19))
	button.add_theme_stylebox_override("pressed", _box(fill.darkened(0.08), Color("#d5ffe4"), 3, 19))
	return button

func _set_garage_category(category: String) -> void:
	garage_category = category
	_show_garage()

func _buy_item(category: String, item_id: String) -> void:
	if Progress.purchase(category, item_id):
		_show_garage()
		toast.text = "UNLOCKED  //  %s" % GearCatalog.item(category, item_id)["name"]
	else:
		toast.text = "NOT ENOUGH PARTS — PLAY ANOTHER ROUND"

func _equip_item(category: String, item_id: String) -> void:
	Progress.equip(category, item_id)
	_show_loadout()

func _unequip_item(category: String) -> void:
	Progress.unequip(category)
	_show_loadout()

func _equip_custom_skin(skin_id: String) -> void:
	Progress.equip("skins", skin_id)
	_show_customize()

func _set_player_color(color_name: String) -> void:
	Progress.set_player_color(color_name)
	_show_customize()

func _set_player_design(design_id: String) -> void:
	Progress.set_player_design(design_id)
	_show_customize()

func _toggle_mode() -> void:
	Progress.toggle_mobile_mode()
	_show_home()

func _start_round(game_mode := "cpu") -> void:
	_clear_screen()
	backdrop.hide()
	var arena := ArenaScript.new()
	arena.game_mode = game_mode
	if game_mode == "multiplayer":
		_ensure_multiplayer_loadout()
		arena.player_two_loadout = multiplayer_loadout.duplicate(true)
	arena.round_finished.connect(_on_round_finished)
	screen.add_child(arena)

func _on_round_finished(summary: Dictionary) -> void:
	var reward: Dictionary = Progress.finish_round(summary["score"], summary["credits"])
	summary["credits"] = reward["credits"]
	summary["drop_category"] = reward["drop_category"]
	summary["drop_id"] = reward["drop_id"]
	summary["drop_data"] = reward["drop_data"]
	_show_results(summary)

func _show_results(summary: Dictionary) -> void:
	_clear_screen()
	backdrop.show()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 62)
	margin.add_theme_constant_override("margin_right", 62)
	margin.add_theme_constant_override("margin_top", 150)
	margin.add_theme_constant_override("margin_bottom", 100)
	screen.add_child(margin)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 24)
	margin.add_child(layout)
	var title := Label.new()
	title.text = summary["result"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 55)
	var result_color := Color("#70e8b2") if summary["won"] else (Color("#ffd56b") if summary["result"] == "DRAW" else Color("#ff7c82"))
	title.add_theme_color_override("font_color", result_color)
	layout.add_child(title)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 330
	panel.add_theme_stylebox_override("panel", _box(Color(0.035, 0.12, 0.15, 0.96), Color("#3a7868"), 2, 25))
	layout.add_child(panel)
	var stats := Label.new()
	var cpu_weapon: String = summary["cpu_loadout"]["weapon_data"]["name"]
	var opponent_label: String = summary.get("opponent_label", "CPU")
	var reward_text := "+%d PARTS" % summary["credits"]
	if not summary.get("drop_id", "").is_empty():
		var drop_data: Dictionary = summary["drop_data"]
		reward_text = "RARE GEAR DROP!\n%s  //  %s\nNO PARTS THIS ROUND" % [drop_data["name"].to_upper(), drop_data["tier"].to_upper()]
	stats.text = "SCORE\n%06d\n\nDAMAGE  %d     %s  %s\n\n%s" % [summary["score"], summary["damage"], opponent_label, cpu_weapon.to_upper(), reward_text]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 25)
	stats.add_theme_color_override("font_color", Color("#f2edd2"))
	panel.add_child(stats)
	var replay := _menu_button("PLAY AGAIN", "take the new loadout back in", true)
	replay.pressed.connect(_start_round.bind(summary.get("game_mode", "cpu")))
	layout.add_child(replay)
	var home := _menu_button("RETURN HOME", "garage, loadout & controls")
	home.pressed.connect(_show_home)
	layout.add_child(home)

func _box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 22
	box.content_margin_right = 22
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box
