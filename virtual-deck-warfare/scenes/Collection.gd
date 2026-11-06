extends Control

var content_vbox: VBoxContainer
var tab_buttons: Dictionary = {}
var active_tab: String = "games"

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	create_beautiful_background()
	create_vignette()
	create_main_panel()
	_show_category("games")

# ==========================================
# 1. ЕДИНЫЙ ФОН
# ==========================================
func create_beautiful_background():
	var bg = TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -100
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var gradient = Gradient.new()
	gradient.offsets = [0.0, 0.45, 1.0]
	gradient.colors = [Color(0.03, 0.03, 0.07), Color(0.08, 0.25, 0.5), Color(0.02, 0.02, 0.04)]
	
	var gt = GradientTexture2D.new()
	gt.gradient = gradient
	gt.fill_from = Vector2(0.5, 0)
	gt.fill_to = Vector2(0.5, 1)
	bg.texture = gt
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)
	
	var grid_lines = Node2D.new()
	grid_lines.z_index = -99
	add_child(grid_lines)
	
	for i in range(0, 1280, 80):
		var l = Line2D.new(); l.add_point(Vector2(i, 0)); l.add_point(Vector2(i, 720))
		l.width = 1.0; l.default_color = Color(0.0, 0.2, 0.4, 0.1); grid_lines.add_child(l)
	for i in range(0, 720, 80):
		var l = Line2D.new(); l.add_point(Vector2(0, i)); l.add_point(Vector2(1280, i))
		l.width = 1.0; l.default_color = Color(0.0, 0.2, 0.4, 0.1); grid_lines.add_child(l)
	
	var particles = CPUParticles2D.new()
	particles.z_index = -98
	particles.amount = 120
	particles.lifetime = 5.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(640, 360)
	particles.position = Vector2(640, 360)
	particles.gravity = Vector2(0, -10)
	particles.initial_velocity_min = 5
	particles.initial_velocity_max = 20
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.5
	
	var pg = Gradient.new()
	pg.set_color(0, Color(0.3, 0.7, 1.0, 0.8)); pg.set_color(1, Color(0.7, 0.2, 1.0, 0.0))
	var pgt = GradientTexture2D.new(); pgt.gradient = pg; particles.color_ramp = pgt
	add_child(particles)

func create_vignette():
	var vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.z_index = 50
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform float intensity : hint_range(0.0, 0.5) = 0.25;
	uniform float smoothness : hint_range(0.5, 2.0) = 1.2;
	void fragment() {
		vec2 uv = UV - 0.5;
		float dist = length(uv) * 1.5;
		float vignette = smoothstep(smoothness * 0.7, smoothness, dist);
		COLOR = vec4(0.0, 0.0, 0.02, vignette * intensity);
	}
	"""
	var sm = ShaderMaterial.new(); sm.shader = shader; vignette.material = sm
	add_child(vignette)

# ==========================================
# 2. ПАНЕЛЬ
# ==========================================
func create_main_panel():
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 40; panel.offset_top = 30; panel.offset_right = -40; panel.offset_bottom = -30
	
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.02, 0.04, 0.08, 0.85)
	ps.border_width_left = 2; ps.border_width_right = 2; ps.border_width_top = 2; ps.border_width_bottom = 2
	ps.border_color = Color(0.0, 0.5, 1.0, 0.7)
	ps.corner_radius_top_left = 15; ps.corner_radius_top_right = 15; ps.corner_radius_bottom_left = 15; ps.corner_radius_bottom_right = 15
	ps.shadow_color = Color(0.0, 0.3, 0.8, 0.3); ps.shadow_size = 25
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40); margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30); margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)
	
	var h_header = HBoxContainer.new()
	h_header.custom_minimum_size = Vector2(0, 60)
	main_vbox.add_child(h_header)
	
	var back_btn = Button.new()
	back_btn.text = "НАЗАД"
	back_btn.custom_minimum_size = Vector2(140, 45)
	back_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	
	var bstyle = StyleBoxFlat.new()
	bstyle.bg_color = Color(0.05, 0.05, 0.1, 0.8)
	bstyle.border_width_left = 2; bstyle.border_width_right = 2; bstyle.border_width_top = 2; bstyle.border_width_bottom = 2
	bstyle.border_color = Color(0.0, 0.5, 1.0)
	bstyle.corner_radius_top_left = 8; bstyle.corner_radius_top_right = 8; bstyle.corner_radius_bottom_left = 8; bstyle.corner_radius_bottom_right = 8
	back_btn.add_theme_stylebox_override("normal", bstyle)
	
	var b_hover = bstyle.duplicate() as StyleBoxFlat
	b_hover.bg_color = Color(0.1, 0.15, 0.25, 0.9); b_hover.border_color = Color(0.4, 0.9, 1.0)
	back_btn.add_theme_stylebox_override("hover", b_hover)
	
	back_btn.pressed.connect(func():
		if Engine.has_singleton("AudioManager"): Engine.get_singleton("AudioManager").play_click()
		get_tree().change_scene_to_file("res://scenes/MainMenu2D.tscn")
	)
	h_header.add_child(back_btn)
	
	var spacer_l = Control.new(); spacer_l.custom_minimum_size = Vector2(140, 0); h_header.add_child(spacer_l)
	
	var title = Label.new()
	title.text = "БАЗА ЗНАНИЙ"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 1.0))
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color(0.3, 0.1, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_header.add_child(title)
	
	var spacer_r = Control.new(); spacer_r.custom_minimum_size = Vector2(140, 0); h_header.add_child(spacer_r)
	
	var h_content = HBoxContainer.new()
	h_content.add_theme_constant_override("separation", 30)
	h_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(h_content)
	
	var left_menu = VBoxContainer.new()
	left_menu.custom_minimum_size = Vector2(250, 0)
	left_menu.add_theme_constant_override("separation", 15)
	h_content.add_child(left_menu)
	
	var tabs_data = {"games": "ИГРЫ", "cards": "КАРТЫ", "components": "ЖЕЛЕЗО", "mechanics": "МЕХАНИКИ"}
	for id in tabs_data:
		var btn = Button.new()
		btn.text = tabs_data[id]
		btn.custom_minimum_size = Vector2(250, 50)
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
		
		var s = StyleBoxFlat.new()
		s.bg_color = Color(0.05, 0.05, 0.1, 0.8)
		s.border_width_left = 2; s.border_width_right = 2; s.border_width_top = 2; s.border_width_bottom = 2
		s.border_color = Color(0.0, 0.5, 1.0)
		s.corner_radius_top_left = 8; s.corner_radius_top_right = 8; s.corner_radius_bottom_left = 8; s.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", s)
		var hs = s.duplicate() as StyleBoxFlat
		hs.bg_color = Color(0.1, 0.15, 0.25, 0.9); hs.border_color = Color(0.4, 0.9, 1.0)
		btn.add_theme_stylebox_override("hover", hs)
		
		btn.pressed.connect(_show_category.bind(id))
		left_menu.add_child(btn)
		tab_buttons[id] = btn
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	h_content.add_child(scroll)
	
	content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(content_vbox)

func _show_category(category: String):
	active_tab = category
	for id in tab_buttons:
		var btn = tab_buttons[id]
		var s = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		if id == category:
			s.border_color = Color(1.0, 0.3, 1.0); s.bg_color = Color(0.15, 0.05, 0.15, 0.9)
		else:
			s.border_color = Color(0.0, 0.5, 1.0); s.bg_color = Color(0.05, 0.05, 0.1, 0.8)
		btn.add_theme_stylebox_override("normal", s)
	for child in content_vbox.get_children(): child.queue_free()
	match category:
		"games": _load_games()
		"cards": _load_cards()
		"components": _load_components()
		"mechanics": _load_mechanics()

func _create_entry(title: String, description: String, details: String = "") -> Panel:
	var entry = Panel.new()
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.02, 0.04, 0.08, 0.8)
	s.border_width_left = 4; s.border_color = Color(0.2, 0.6, 1.0)
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6; s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	entry.add_theme_stylebox_override("panel", s)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20); margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15); margin.add_theme_constant_override("margin_bottom", 15)
	entry.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.add_theme_font_size_override("font_size", 22); lbl_title.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	vbox.add_child(lbl_title)
	
	var lbl_desc = Label.new()
	lbl_desc.text = description; lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_font_size_override("font_size", 14); lbl_desc.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(lbl_desc)
	
	if details != "":
		var div = ColorRect.new(); div.color = Color(0.0, 0.5, 1.0, 0.2); div.custom_minimum_size = Vector2(0, 1)
		vbox.add_child(div)
		var lbl_det = Label.new()
		lbl_det.text = details; lbl_det.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_det.add_theme_font_size_override("font_size", 13); lbl_det.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
		vbox.add_child(lbl_det)
	return entry

func _load_games():
	for g in GameData.games:
		var title = g.get("title", "Неизвестно") + " (" + str(g.get("year", "")) + ")"
		var desc = g.get("description", "")
		var req = g.get("requirements", {})
		var details = "Жанр: %s\nТребования: CPU %s, RAM %sMB, GPU %sMB\nМеханика: %s" % [g.get("genre", ""), req.get("cpu", 0), req.get("ram", 0), req.get("gpu", 0), g.get("uniqueMechanic", "")]
		content_vbox.add_child(_create_entry(title, desc, details))

func _load_cards():
	for c in GameData.cards:
		var title = c.get("name", "Неизвестно") + " [" + c.get("rarity", "").to_upper() + "]"
		var desc = "Тип: %s | Цена: %s" % [c.get("type", ""), c.get("cost", 0)]
		var ability = "Свойство: " + c.get("ability", "Нет")
		content_vbox.add_child(_create_entry(title, desc, ability))

func _load_components():
	for c in GameData.pc_components:
		var title = c.get("name", "Неизвестно")
		var desc = "Тип: %s | Год: %s | Цена: %s $" % [c.get("type", "").to_upper(), c.get("year", ""), c.get("price", 0)]
		var stats = c.get("stats", {})
		var stat_str = ""
		for k in stats: stat_str += "%s: %s  " % [k.to_upper(), stats[k]]
		content_vbox.add_child(_create_entry(title, desc, stat_str))

func _load_mechanics():
	content_vbox.add_child(_create_entry("Экономика и Валюты", "В игре представлены исторические курсы валют (1995-2005). Ваш стартовый капитал пересчитывается по курсу выбранной страны.", "Цены на карты и игры фиксированы в USD, но списываются в вашей локальной валюте."))
	content_vbox.add_child(_create_entry("Сборка ПК и Требования", "Чтобы играть в игры, ваш компьютер должен соответствовать их системным требованиям (CPU, RAM, GPU).", "Если игра тормозит, обновите комплектующие в магазине."))
	content_vbox.add_child(_create_entry("Режимы игры", "Свободная игра: неограниченный капитал, нет миссий.\nКампания: историческое прохождение, выполнение заданий.", "В режиме кампании вам придется выживать на стартовый капитал."))
