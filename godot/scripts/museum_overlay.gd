extends Control
## MuseumOverlay: ACME Trophy Room & Evidence Hall of Recovered World Treasures

signal museum_closed

var active: bool = false
var selected_index: int = 0
var all_relics: Array[Dictionary] = []

@onready var title_label: Label = $TopBar/TitleLabel
@onready var summary_label: Label = $TopBar/SummaryLabel
@onready var relic_list: VBoxContainer = $Scroll/ItemList
@onready var hint_bar: Label = $BottomBar/HintBar

func _ready() -> void:
	visible = false

func open_museum() -> void:
	active = true
	visible = true
	selected_index = 0
	_populate_relics()
	SoundManager.play_confirm()

func _populate_relics() -> void:
	for child in relic_list.get_children():
		relic_list.remove_child(child)
		child.queue_free()

	all_relics = Database.TREASURES.duplicate()
	var recovered = GameManager.recovered_treasures
	var recovered_count := 0

	for r in all_relics:
		var is_recovered := false
		var thief_name := ""
		for rec in recovered:
			if rec is Dictionary and rec.get("name") == r["name"]:
				is_recovered = true
				thief_name = rec.get("thief", "SUSPECT")
				recovered_count += 1
				break

		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		vbox.theme_override_constants.separation = 3
		panel.add_child(vbox)

		var title_lbl = Label.new()
		title_lbl.add_theme_font_size_override("font_size", 12)
		
		var lore_lbl = RichTextLabel.new()
		lore_lbl.bbcode_enabled = true
		lore_lbl.fit_content = true
		lore_lbl.scroll_active = false
		lore_lbl.add_theme_font_size_override("normal_font_size", 11)

		if is_recovered:
			title_lbl.text = "★ %s (RECOVERED)" % r["name"]
			title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
			lore_lbl.text = "[color=#34d399]Recovered from %s![/color] [color=#38bdf8]Value: %s[/color]\n%s" % [thief_name, r.get("value", "$10,000,000"), r.get("lore", "Historic world relic.")]
		else:
			title_lbl.text = "🔒 %s (STOLEN / UNRECOVERED)" % r["name"]
			title_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
			var city_name = Database.CITIES.get(r["city"], {}).get("name", "UNKNOWN")
			lore_lbl.text = "[color=#f87171]Missing from %s.[/color] Apprehend the culprit to restore this relic to the ACME museum vault." % city_name

		vbox.add_child(title_lbl)
		vbox.add_child(lore_lbl)
		relic_list.add_child(panel)

	summary_label.text = "RECOVERED: %d / %d RELICS | RANK: %s" % [recovered_count, all_relics.size(), GameManager.current_rank["title"]]
	hint_bar.text = "UP/DOWN: BROWSE EXHIBITS | [B / ESC] RETURN"

func _input(event: InputEvent) -> void:
	if not active:
		return

	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_B or event.keycode == KEY_ESCAPE)):
		close_museum()
		get_viewport().set_input_as_handled()
		return

func close_museum() -> void:
	active = false
	visible = false
	SoundManager.play_cancel()
	museum_closed.emit()
