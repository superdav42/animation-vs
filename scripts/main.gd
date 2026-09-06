extends Control

const BackdropScript := preload("res://scripts/procedural_backdrop.gd")
const ArenaScript := preload("res://scripts/arena.gd")

var backdrop: Control
var screen: Control
var garage_category := "vehicles"
var toast: Label

func _ready() -> void:
	_build_shell()
	_show_home()

func _build_shell() -> void:
	backdrop = BackdropScript.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 44)
	screen.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var kicker := Label.new()
	kicker.text = "WILD TECH // ARENA 01"
	kicker.add_theme_font_size_override("font_size", 18)
	kicker.add_theme_color_override("font_color", Color("#61e2bb"))
	layout.add_child(kicker)
	var title := Label.new()
	title.text = "HENRY'S\nWILD RUN"
	title.add_theme_font_size_override("font_size", 66)
	title.add_theme_color_override("font_color", Color("#f5f0d7"))
	title.add_theme_color_override("font_shadow_color", Color(0.13, 0.8, 0.58, 0.28))
	title.add_theme_constant_override("shadow_offset_x", 5)
	title.add_theme_constant_override("shadow_offset_y", 6)
	layout.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Ride strange machines. Grow impossible vines.\nSurvive the living arena."
	subtitle.add_theme_font_size_override("font_size", 21)
	subtitle.add_theme_color_override("font_color", Color("#a9c2c1"))
	layout.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 44
	layout.add_child(spacer)
	var play := _menu_button("PLAY A ROUND", "60 seconds  •  earn parts", true)
	play.pressed.connect(_start_round)
	layout.add_child(play)
	var garage := _menu_button("GARAGE", "buy vehicles, weapons & powers")
	garage.pressed.connect(_show_garage)
	layout.add_child(garage)
	var mode_text := "CONTROL MODE:  %s" % ("MOBILE" if Progress.mobile_mode else "KEYBOARD")
	var mode := _menu_button(mode_text, "tap to switch")
	mode.pressed.connect(_toggle_mode)
	layout.add_child(mode)
	var loadout := _menu_button("LOADOUT", "equip your unlocked gear")
	loadout.pressed.connect(_show_loadout)
	layout.add_child(loadout)
	var help := _menu_button("HOW TO PLAY", "controls & ability guide")
	help.pressed.connect(_show_help)
	layout.add_child(help)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	footer.custom_minimum_size.y = 64
	layout.add_child(footer)
	var credits := Label.new()
	credits.text = "◆  %d PARTS" % Progress.credits
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
	var layout := _page_layout("THE GARAGE", "Spend parts earned in the arena.")
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	layout.add_child(tabs)
	for category in ["vehicles", "weapons", "abilities"]:
		var tab := Button.new()
		tab.text = category.to_upper()
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size.y = 58
		tab.add_theme_font_size_override("font_size", 17)
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
		action.text = "◆ %d" % data["cost"]
		action.pressed.connect(_buy_item.bind(category, item_id))
	row.add_child(action)
	return panel

func _show_loadout() -> void:
	_clear_screen()
	backdrop.show()
	var layout := _page_layout("LOADOUT", "Choose one ride, weapon, and power.")
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
		for item_id in Progress.unlocked[category]:
			content.add_child(_loadout_card(category, item_id))

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

func _show_help() -> void:
	_clear_screen()
	backdrop.show()
	var layout := _page_layout("HOW TO PLAY", "Survive for 60 seconds. Every defeated creature drops parts.")
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _box(Color(0.03, 0.1, 0.13, 0.94), Color("#2a725d"), 2, 24))
	layout.add_child(panel)
	var text := Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 22)
	text.add_theme_color_override("font_color", Color("#d5e3da"))
	text.text = "KEYBOARD MODE\nWASD / ARROWS   Move\nSPACE   Use weapon\nQ   Use equipped power\nSHIFT   Vehicle boost\nMOUSE   Aim and choose power targets\nESC   Leave the round\n\nMOBILE MODE\nUse the direction pad plus ATTACK, POWER, and BOOST. Vine Weaver and Phase Blink ask you to tap points in the arena.\n\nLIVING TERRAIN\nVines can begin on the ground or snap onto glowing tree branches. They grow across the arena, damage enemies, and slow survivors."
	panel.add_child(text)

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
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("#9eb8b5"))
	titles.add_child(subtitle)
	var wallet := Label.new()
	wallet.text = "◆ %d" % Progress.credits
	wallet.add_theme_font_size_override("font_size", 21)
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
	button.custom_minimum_size.y = 102 if primary else 82
	button.add_theme_font_size_override("font_size", 22 if primary else 19)
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

func _toggle_mode() -> void:
	Progress.toggle_mobile_mode()
	_show_home()

func _start_round() -> void:
	_clear_screen()
	backdrop.hide()
	var arena := ArenaScript.new()
	arena.round_finished.connect(_on_round_finished)
	screen.add_child(arena)

func _on_round_finished(summary: Dictionary) -> void:
	Progress.finish_round(summary["score"], summary["credits"])
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
	title.text = "ROUND CLEAR" if summary["survived"] else "RUN OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 55)
	title.add_theme_color_override("font_color", Color("#70e8b2") if summary["survived"] else Color("#ff7c82"))
	layout.add_child(title)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 330
	panel.add_theme_stylebox_override("panel", _box(Color(0.035, 0.12, 0.15, 0.96), Color("#3a7868"), 2, 25))
	layout.add_child(panel)
	var stats := Label.new()
	stats.text = "SCORE\n%06d\n\nENEMIES  %d     WAVE  %d\n\n◆  +%d PARTS" % [summary["score"], summary["kills"], summary["wave"], summary["credits"]]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 25)
	stats.add_theme_color_override("font_color", Color("#f2edd2"))
	panel.add_child(stats)
	var replay := _menu_button("PLAY AGAIN", "take the new loadout back in", true)
	replay.pressed.connect(_start_round)
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
