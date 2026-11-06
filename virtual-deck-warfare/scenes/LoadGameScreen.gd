extends Control

var slots_container: VBoxContainer

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	create_background()
	create_header()
	create_slots_container()
	refresh_slots()

func create_background():
	var bg = TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var gradient = Gradient.new()
	gradient.offsets = [0.0, 0.5, 1.0]
	gradient.colors = [Color(0.03, 0.03, 0.07), Color(0.06, 0.15, 0.3), Color(0.02, 0.02, 0.04)]
	
	var gt = GradientTexture2D.new()
	gt.gradient = gradient
	gt.fill_from = Vector2(0.5, 0)
	gt.fill_to = Vector2(0.5, 1)
	
	bg.texture = gt
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)

func create_header():
	var back_btn = Button.new()
	back_btn.text = "← НАЗАД"
	back_btn.position = Vector2(40, 40)
	back_btn.size = Vector2(160, 50)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.05, 0.05, 0.1, 0.8)
	bs.border_width_left = 2
	bs.border_width_right = 2
	bs.border_width_top = 2
	bs.border_width_bottom = 2
	bs.border_color = Color(0.0, 0.5, 1.0)
	bs.corner_radius_top_left = 8
	bs.corner_radius_top_right = 8
	bs.corner_radius_bottom_left = 8
	bs.corner_radius_bottom_right = 8
	back_btn.add_theme_stylebox_override("normal", bs)
	
	back_btn.pressed.connect(func():
		if Engine.has_singleton("AudioManager"):
			Engine.get_singleton("AudioManager").play_click()
		get_tree().change_scene_to_file("res://scenes/MainMenu2D.tscn")
	)
	add_child(back_btn)
	
	var title = Label.new()
	title.text = "ЗАГРУЗКА ИГРЫ"
	title.position = Vector2(0, 40)
	title.size = Vector2(1280, 60)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 1.0))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_outline_color", Color(0.3, 0.1, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Выберите сохранение для продолжения"
	subtitle.position = Vector2(0, 105)
	subtitle.size = Vector2(1280, 30)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)

func create_slots_container():
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(80, 170)
	scroll.size = Vector2(1120, 500)
	scroll.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(scroll)
	
	slots_container = VBoxContainer.new()
	slots_container.custom_minimum_size = Vector2(1120, 500)
	slots_container.add_theme_constant_override("separation", 20)
	scroll.add_child(slots_container)

func refresh_slots():
	for child in slots_container.get_children():
		child.queue_free()
	
	# Автосохранение сверху
	if SaveManager.has_save(SaveManager.AUTO_SLOT):
		var auto_row = HBoxContainer.new()
		auto_row.add_theme_constant_override("separation", 20)
		auto_row.add_child(create_slot_card(SaveManager.AUTO_SLOT, "АВТОСОХРАНЕНИЕ"))
		auto_row.add_child(create_empty_space())
		slots_container.add_child(auto_row)
	
	# Заголовок ручных сохранений
	var manual_title = Label.new()
	manual_title.text = "РУЧНЫЕ СОХРАНЕНИЯ (6 слотов)"
	manual_title.add_theme_font_size_override("font_size", 18)
	manual_title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	manual_title.custom_minimum_size = Vector2(1120, 30)
	slots_container.add_child(manual_title)
	
	# Сетка слотов 3х2
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	slots_container.add_child(grid)
	
	for slot_id in range(1, SaveManager.MAX_MANUAL_SLOTS + 1):
		grid.add_child(create_slot_card(slot_id, "СЛОТ " + str(slot_id)))

func create_empty_space() -> Control:
	var space = Control.new()
	space.custom_minimum_size = Vector2(740, 0)
	return space

func create_slot_card(slot_id: int, label_text: String) -> Panel:
	var has_save = SaveManager.has_save(slot_id)
	var meta = SaveManager.get_slot_metadata(slot_id) if has_save else {}
	
	var card = Panel.new()
	card.custom_minimum_size = Vector2(360, 160)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.15, 0.85) if has_save else Color(0.02, 0.03, 0.06, 0.6)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 0.6, 1.0) if has_save else Color(0.2, 0.2, 0.3)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 8
	card.add_theme_stylebox_override("panel", style)
	
	# Заголовок
	var title = Label.new()
	title.text = label_text
	title.position = Vector2(15, 10)
	title.size = Vector2(250, 25)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0) if has_save else Color(0.4, 0.4, 0.5))
	card.add_child(title)
	
	if has_save:
		# Имя
		var name_lbl = Label.new()
		name_lbl.text = meta.get("character_name", "Игрок")
		name_lbl.position = Vector2(15, 35)
		name_lbl.size = Vector2(280, 25)
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		card.add_child(name_lbl)
		
		# Режим + страна
		var mode_names = {"sandbox": "Песочница", "career": "Карьера", "hardcore": "Хардкор"}
		var mode_colors = {"sandbox": Color(0.2, 0.8, 1.0), "career": Color(0.7, 0.9, 0.3), "hardcore": Color(1.0, 0.3, 0.3)}
		var mode_lbl = Label.new()
		mode_lbl.text = mode_names.get(meta.get("mode", "career"), "Карьера") + " • " + meta.get("country", "—")
		mode_lbl.position = Vector2(15, 62)
		mode_lbl.size = Vector2(280, 20)
		mode_lbl.add_theme_font_size_override("font_size", 12)
		mode_lbl.add_theme_color_override("font_color", mode_colors.get(meta.get("mode", "career"), Color(0.7, 0.9, 0.3)))
		card.add_child(mode_lbl)
		
		# Год + деньги
		var stats_lbl = Label.new()
		stats_lbl.text = "Год: %d  •  %s" % [meta.get("year", 1995), _format_money_with_sym(meta.get("money", 0), meta.get("currency", "RUB"))]
		stats_lbl.position = Vector2(15, 85)
		stats_lbl.size = Vector2(330, 20)
		stats_lbl.add_theme_font_size_override("font_size", 12)
		stats_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		card.add_child(stats_lbl)
		
		# Playtime + дата
		var info_lbl = Label.new()
		info_lbl.text = "%s  •  %s" % [SaveManager.format_playtime(meta.get("playtime", 0.0)), meta.get("date", "")]
		info_lbl.position = Vector2(15, 110)
		info_lbl.size = Vector2(330, 20)
		info_lbl.add_theme_font_size_override("font_size", 11)
		info_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		card.add_child(info_lbl)
		
		# Кнопка Загрузить
		var load_btn = Button.new()
		load_btn.text = "ЗАГРУЗИТЬ"
		load_btn.position = Vector2(15, 130)
		load_btn.size = Vector2(250, 25)
		load_btn.add_theme_font_size_override("font_size", 12)
		load_btn.add_theme_color_override("font_color", Color(1, 1, 1))
		
		var ls = StyleBoxFlat.new()
		ls.bg_color = Color(0.2, 0.6, 0.9)
		ls.corner_radius_top_left = 4
		ls.corner_radius_top_right = 4
		ls.corner_radius_bottom_left = 4
		ls.corner_radius_bottom_right = 4
		load_btn.add_theme_stylebox_override("normal", ls)
		card.add_child(load_btn)
		
		load_btn.pressed.connect(func(): _load_slot(slot_id))
		
		# Кнопка удалить (X)
		var del_btn = Button.new()
		del_btn.text = "✕"
		del_btn.position = Vector2(315, 10)
		del_btn.size = Vector2(30, 25)
		del_btn.add_theme_font_size_override("font_size", 14)
		del_btn.add_theme_color_override("font_color", Color(1, 1, 1))
		
		var ds = StyleBoxFlat.new()
		ds.bg_color = Color(0.7, 0.1, 0.1)
		ds.corner_radius_top_left = 4
		ds.corner_radius_top_right = 4
		ds.corner_radius_bottom_left = 4
		ds.corner_radius_bottom_right = 4
		del_btn.add_theme_stylebox_override("normal", ds)
		del_btn.pressed.connect(func(): _delete_slot(slot_id))
		card.add_child(del_btn)
	else:
		# Пустой слот
		var empty_lbl = Label.new()
		empty_lbl.text = "Пусто"
		empty_lbl.position = Vector2(0, 70)
		empty_lbl.size = Vector2(360, 40)
		empty_lbl.add_theme_font_size_override("font_size", 18)
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(empty_lbl)
	
	return card

func _format_money_with_sym(value: int, currency: String) -> String:
	var sym = "₽"
	match currency:
		"USD": sym = "$"
		"EUR": sym = "€"
		"JPY": sym = "¥"
		"CNY": sym = "¥"
		"GBP": sym = "£"
	
	var s = str(value)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = " " + result
	return result + " " + sym

func _load_slot(slot_id: int):
	if Engine.has_singleton("AudioManager"):
		Engine.get_singleton("AudioManager").play_purchase()
	
	if PlayerState.load_from_slot(slot_id):
		get_tree().change_scene_to_file("res://scenes/MyGames.tscn")

func _delete_slot(slot_id: int):
	SaveManager.delete_slot(slot_id)
	refresh_slots()
