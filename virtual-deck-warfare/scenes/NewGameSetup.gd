extends Control

var name_input: LineEdit
var country_select: OptionButton
var year_select: OptionButton
var currency_label: Label
var balance_value_label: Label
var balance_slider: HSlider
var slider_container: VBoxContainer

var selected_mode: String = "campaign"
var mode_buttons: Dictionary = {}
var mode_description_label: Label

var selected_avatar_id: String = "hacker"
var avatar_buttons: Dictionary = {}

var start_time: float = 0.0
var start_btn_node: Button

var country_data = [
	{"name": "Россия", "currency": "RUB", "symbol": "₽"},
	{"name": "Китай", "currency": "CNY", "symbol": "¥"},
	{"name": "США", "currency": "USD", "symbol": "$"},
	{"name": "Япония", "currency": "JPY", "symbol": "¥"},
	{"name": "Индия", "currency": "INR", "symbol": "₹"}
]

var historical_rates = {
	1995: {"RUB": 4.56, "CNY": 8.35, "JPY": 94.06, "INR": 32.42, "USD": 1.0},
	1996: {"RUB": 5.12, "CNY": 8.31, "JPY": 108.78, "INR": 35.43, "USD": 1.0},
	1997: {"RUB": 5.78, "CNY": 8.28, "JPY": 120.99, "INR": 36.31, "USD": 1.0},
	1998: {"RUB": 9.70, "CNY": 8.27, "JPY": 130.90, "INR": 41.25, "USD": 1.0},
	1999: {"RUB": 24.61, "CNY": 8.27, "JPY": 113.90, "INR": 43.05, "USD": 1.0},
	2000: {"RUB": 28.12, "CNY": 8.27, "JPY": 107.83, "INR": 44.94, "USD": 1.0},
	2001: {"RUB": 29.16, "CNY": 8.27, "JPY": 121.52, "INR": 47.18, "USD": 1.0},
	2002: {"RUB": 31.34, "CNY": 8.27, "JPY": 125.38, "INR": 48.61, "USD": 1.0},
	2003: {"RUB": 30.69, "CNY": 8.27, "JPY": 115.93, "INR": 46.58, "USD": 1.0},
	2004: {"RUB": 28.81, "CNY": 8.27, "JPY": 108.19, "INR": 45.31, "USD": 1.0},
	2005: {"RUB": 28.28, "CNY": 8.19, "JPY": 110.22, "INR": 44.10, "USD": 1.0}
}

var avatars = [
	{"id": "hacker", "color": Color(0.0, 0.8, 1.0), "type": 0},
	{"id": "rogue", "color": Color(1.0, 0.1, 0.7), "type": 1},
	{"id": "corp", "color": Color(0.7, 0.9, 0.3), "type": 2},
	{"id": "samurai", "color": Color(1.0, 0.6, 0.0), "type": 3}
]

var modes = {
	"free": {
		"name": "СВОБОДНАЯ ИГРА",
		"description": "Исследуйте игровую вселенную без ограничений. Настройте стартовый капитал по своему вкусу и стройте империю в удобном темпе. Сюжетные миссии отключены.",
		"color": Color(0.2, 0.8, 1.0)
	},
	"campaign": {
		"name": "КАМПАНИЯ",
		"description": "Пройдите путь от первых шагов в 90-х до вершин киберспорта. Выполняйте сюжетные миссии, зарабатывайте репутацию и развивайтесь вместе с историей.",
		"color": Color(0.7, 0.9, 0.3)
	}
}

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	create_beautiful_background()
	create_vignette()
	create_main_panel()

func _process(delta):
	start_time += delta
	if start_btn_node and is_instance_valid(start_btn_node):
		var pulse = 1.0 + sin(start_time * 3.0) * 0.02
		start_btn_node.scale = Vector2(pulse, pulse)

# ==========================================
# 1. ЕДИНЫЙ ФОН (Как в главном меню)
# ==========================================
func create_beautiful_background():
	var bg = TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -100
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var gradient = Gradient.new()
	gradient.offsets = [0.0, 0.45, 1.0]
	gradient.colors = [
		Color(0.03, 0.03, 0.07),
		Color(0.08, 0.25, 0.5),
		Color(0.02, 0.02, 0.04)
	]
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0.5, 0)
	gradient_texture.fill_to = Vector2(0.5, 1)
	
	bg.texture = gradient_texture
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)
	
	var grid_lines = Node2D.new()
	grid_lines.z_index = -99
	add_child(grid_lines)
	
	for i in range(0, 1280, 80):
		var line = Line2D.new()
		line.add_point(Vector2(i, 0))
		line.add_point(Vector2(i, 720))
		line.width = 1.0
		line.default_color = Color(0.0, 0.2, 0.4, 0.1)
		grid_lines.add_child(line)
		
	for i in range(0, 720, 80):
		var line = Line2D.new()
		line.add_point(Vector2(0, i))
		line.add_point(Vector2(1280, i))
		line.width = 1.0
		line.default_color = Color(0.0, 0.2, 0.4, 0.1)
		grid_lines.add_child(line)
	
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
	
	var p_gradient = Gradient.new()
	p_gradient.set_color(0, Color(0.3, 0.7, 1.0, 0.8))
	p_gradient.set_color(1, Color(0.7, 0.2, 1.0, 0.0))
	
	var p_grad_tex = GradientTexture2D.new()
	p_grad_tex.gradient = p_gradient
	particles.color_ramp = p_grad_tex
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
	
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = shader
	vignette.material = shader_mat
	add_child(vignette)

# ==========================================
# 2. ПАНЕЛЬ
# ==========================================
func create_main_panel():
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 40
	panel.offset_top = 30
	panel.offset_right = -40
	panel.offset_bottom = -30
	
	var pstyle = StyleBoxFlat.new()
	pstyle.bg_color = Color(0.02, 0.04, 0.08, 0.85)
	pstyle.border_width_left = 2
	pstyle.border_width_right = 2
	pstyle.border_width_top = 2
	pstyle.border_width_bottom = 2
	pstyle.border_color = Color(0.0, 0.5, 1.0, 0.7)
	pstyle.corner_radius_top_left = 15
	pstyle.corner_radius_top_right = 15
	pstyle.corner_radius_bottom_left = 15
	pstyle.corner_radius_bottom_right = 15
	pstyle.shadow_color = Color(0.0, 0.3, 0.8, 0.3)
	pstyle.shadow_size = 25
	panel.add_theme_stylebox_override("panel", pstyle)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)
	
	# Шапка
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
	
	var v_title = VBoxContainer.new()
	v_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_title.alignment = BoxContainer.ALIGNMENT_CENTER
	h_header.add_child(v_title)
	
	var title = Label.new()
	title.text = "НОВАЯ ИГРА"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 1.0))
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color(0.3, 0.1, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_title.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Настройте профиль, выберите эпоху и режим игры"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_title.add_child(subtitle)
	
	var spacer_r = Control.new(); spacer_r.custom_minimum_size = Vector2(140, 0); h_header.add_child(spacer_r)
	
	var div = ColorRect.new(); div.color = Color(0.0, 0.5, 1.0, 0.2); div.custom_minimum_size = Vector2(0, 1)
	main_vbox.add_child(div)
	
	# Аватары
	var h_avatar = HBoxContainer.new()
	h_avatar.alignment = BoxContainer.ALIGNMENT_CENTER
	h_avatar.add_theme_constant_override("separation", 30)
	main_vbox.add_child(h_avatar)
	
	for av in avatars:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(70, 70)
		btn.pivot_offset = Vector2(35, 35)
		
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = Color(0.02, 0.02, 0.05, 0.9)
		b_style.corner_radius_top_left = 10; b_style.corner_radius_top_right = 10; b_style.corner_radius_bottom_left = 10; b_style.corner_radius_bottom_right = 10
		btn.add_theme_stylebox_override("normal", b_style)
		
		create_avatar_icon(btn, av.type, av.color)
		
		btn.pressed.connect(_on_avatar_selected.bind(av.id, btn, av.color))
		h_avatar.add_child(btn)
		avatar_buttons[av.id] = btn
		
		if av.id == selected_avatar_id:
			btn.scale = Vector2(1.1, 1.1)
			btn.modulate = Color(1, 1, 1)
			_update_avatar_style(btn, av.color, true)
		else:
			btn.scale = Vector2(0.9, 0.9)
			btn.modulate = Color(0.5, 0.5, 0.5)
	
	# Середина
	var h_middle = HBoxContainer.new()
	h_middle.add_theme_constant_override("separation", 50)
	h_middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(h_middle)
	
	# Левая колонка
	var left_col = VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(480, 0)
	left_col.add_theme_constant_override("separation", 20)
	h_middle.add_child(left_col)
	
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	left_col.add_child(grid)
	
	create_grid_label(grid, "Имя:")
	name_input = LineEdit.new()
	name_input.custom_minimum_size = Vector2(300, 45)
	name_input.text = "Игрок"
	name_input.max_length = 20
	style_line_edit(name_input)
	grid.add_child(name_input)
	
	create_grid_label(grid, "Год:")
	year_select = OptionButton.new()
	year_select.custom_minimum_size = Vector2(300, 45)
	for y in range(1995, 2006):
		year_select.add_item(str(y))
	style_option_button(year_select)
	year_select.item_selected.connect(_on_year_changed)
	grid.add_child(year_select)
	
	create_grid_label(grid, "Страна:")
	country_select = OptionButton.new()
	country_select.custom_minimum_size = Vector2(300, 45)
	for c in country_data:
		country_select.add_item(c.name)
	style_option_button(country_select)
	country_select.item_selected.connect(_on_country_changed)
	grid.add_child(country_select)
	
	create_grid_label(grid, "Валюта:")
	currency_label = Label.new()
	currency_label.custom_minimum_size = Vector2(300, 30)
	currency_label.add_theme_font_size_override("font_size", 16)
	currency_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	currency_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grid.add_child(currency_label)
	
	# Баланс
	var balance_panel = Panel.new()
	var b_style = StyleBoxFlat.new()
	b_style.bg_color = Color(0.02, 0.06, 0.1, 0.8)
	b_style.border_width_left = 2; b_style.border_width_right = 2; b_style.border_width_top = 2; b_style.border_width_bottom = 2
	b_style.border_color = Color(0.2, 0.8, 1.0, 0.4)
	b_style.corner_radius_top_left = 8; b_style.corner_radius_top_right = 8; b_style.corner_radius_bottom_left = 8; b_style.corner_radius_bottom_right = 8
	balance_panel.add_theme_stylebox_override("panel", b_style)
	balance_panel.custom_minimum_size = Vector2(480, 65)
	left_col.add_child(balance_panel)
	
	var h_balance = HBoxContainer.new()
	h_balance.set_anchors_preset(Control.PRESET_FULL_RECT)
	h_balance.offset_left = 15; h_balance.offset_right = -15; h_balance.offset_top = 12; h_balance.offset_bottom = -12
	balance_panel.add_child(h_balance)
	
	var bal_title = Label.new()
	bal_title.text = "Стартовый баланс:"
	bal_title.add_theme_font_size_override("font_size", 16)
	bal_title.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	bal_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h_balance.add_child(bal_title)
	
	balance_value_label = Label.new()
	balance_value_label.text = "0 ₽"
	balance_value_label.add_theme_font_size_override("font_size", 24)
	balance_value_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
	balance_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	balance_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	balance_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_balance.add_child(balance_value_label)
	
	# Правая колонка
	var right_col = VBoxContainer.new()
	right_col.custom_minimum_size = Vector2(520, 0)
	right_col.add_theme_constant_override("separation", 15)
	h_middle.add_child(right_col)
	
	for mode_id in ["free", "campaign"]:
		var mode_data = modes[mode_id]
		var btn = Button.new()
		btn.text = mode_data.name
		btn.custom_minimum_size = Vector2(520, 60)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pivot_offset = Vector2(260, 30)
		
		var bs = StyleBoxFlat.new()
		bs.bg_color = Color(0.02, 0.03, 0.08, 0.9)
		bs.border_width_left = 2; bs.border_width_right = 2; bs.border_width_top = 2; bs.border_width_bottom = 2
		bs.border_color = mode_data.color.darkened(0.6)
		bs.corner_radius_top_left = 8; bs.corner_radius_top_right = 8; bs.corner_radius_bottom_left = 8; bs.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", bs)
		
		var hs = bs.duplicate() as StyleBoxFlat
		hs.bg_color = Color(0.08, 0.12, 0.2, 0.9); hs.border_color = mode_data.color
		hs.shadow_color = Color(mode_data.color.r, mode_data.color.g, mode_data.color.b, 0.3); hs.shadow_size = 10
		btn.add_theme_stylebox_override("hover", hs)
		
		btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		
		btn.pressed.connect(_on_mode_selected.bind(mode_id))
		right_col.add_child(btn)
		mode_buttons[mode_id] = btn
	
	var desc_panel = Panel.new()
	var d_style = StyleBoxFlat.new()
	d_style.bg_color = Color(0.02, 0.04, 0.08, 0.6)
	d_style.corner_radius_top_left = 8; d_style.corner_radius_top_right = 8; d_style.corner_radius_bottom_left = 8; d_style.corner_radius_bottom_right = 8
	d_style.border_width_left = 1; d_style.border_width_right = 1; d_style.border_width_top = 1; d_style.border_width_bottom = 1
	d_style.border_color = Color(0.2, 0.4, 0.7, 0.3)
	desc_panel.add_theme_stylebox_override("panel", d_style)
	desc_panel.custom_minimum_size = Vector2(520, 100) 
	desc_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_child(desc_panel)
	
	mode_description_label = Label.new()
	mode_description_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	mode_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mode_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mode_description_label.add_theme_font_size_override("font_size", 14)
	mode_description_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	mode_description_label.offset_left = 20; mode_description_label.offset_right = -20; mode_description_label.offset_top = 15; mode_description_label.offset_bottom = -15
	desc_panel.add_child(mode_description_label)
	
	# Низ
	var bottom_section = VBoxContainer.new()
	bottom_section.add_theme_constant_override("separation", 15)
	main_vbox.add_child(bottom_section)
	
	slider_container = VBoxContainer.new()
	slider_container.visible = false
	slider_container.add_theme_constant_override("separation", 5)
	slider_container.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_section.add_child(slider_container)
	
	var slider_title = Label.new()
	slider_title.text = "Настройка стартового капитала (в USD)"
	slider_title.add_theme_font_size_override("font_size", 14)
	slider_title.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	slider_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slider_container.add_child(slider_title)
	
	balance_slider = HSlider.new()
	balance_slider.min_value = 5000; balance_slider.max_value = 100000; balance_slider.step = 1000; balance_slider.value = 50000
	balance_slider.custom_minimum_size = Vector2(800, 24)
	balance_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var track_style = StyleBoxFlat.new()
	track_style.bg_color = Color(0.02, 0.04, 0.08)
	track_style.border_width_top = 2; track_style.border_width_bottom = 2; track_style.border_color = Color(0.0, 0.3, 0.6)
	track_style.corner_radius_top_left = 4; track_style.corner_radius_top_right = 4; track_style.corner_radius_bottom_left = 4; track_style.corner_radius_bottom_right = 4
	balance_slider.add_theme_stylebox_override("slider", track_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.0, 0.6, 1.0)
	fill_style.corner_radius_top_left = 4; fill_style.corner_radius_top_right = 4; fill_style.corner_radius_bottom_left = 4; fill_style.corner_radius_bottom_right = 4
	fill_style.shadow_color = Color(0.0, 0.6, 1.0, 0.5); fill_style.shadow_size = 4
	balance_slider.add_theme_stylebox_override("grabber_area", fill_style)
	balance_slider.add_theme_stylebox_override("grabber_area_highlight", fill_style)
	
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color.WHITE
	grabber_style.corner_radius_top_left = 12; grabber_style.corner_radius_top_right = 12; grabber_style.corner_radius_bottom_left = 12; grabber_style.corner_radius_bottom_right = 12
	grabber_style.border_width_left = 2; grabber_style.border_width_right = 2; grabber_style.border_width_top = 2; grabber_style.border_width_bottom = 2
	grabber_style.border_color = Color(1, 1, 1); grabber_style.shadow_color = Color(0.0, 0.8, 1.0, 0.8); grabber_style.shadow_size = 10
	balance_slider.add_theme_stylebox_override("grabber", grabber_style)
	
	balance_slider.value_changed.connect(_on_slider_changed)
	slider_container.add_child(balance_slider)
	
	var h_minmax = HBoxContainer.new()
	h_minmax.custom_minimum_size = Vector2(800, 20)
	h_minmax.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var min_lbl = Label.new(); min_lbl.text = "$5 000"; min_lbl.custom_minimum_size = Vector2(400, 20)
	min_lbl.add_theme_font_size_override("font_size", 12); min_lbl.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
	min_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT; h_minmax.add_child(min_lbl)
	
	var max_lbl = Label.new(); max_lbl.text = "$100 000"; max_lbl.custom_minimum_size = Vector2(400, 20)
	max_lbl.add_theme_font_size_override("font_size", 12); max_lbl.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
	max_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; h_minmax.add_child(max_lbl)
	
	slider_container.add_child(h_minmax)
	
	var h_start = HBoxContainer.new()
	h_start.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_section.add_child(h_start)
	
	start_btn_node = Button.new()
	start_btn_node.text = "НАЧАТЬ ИГРУ"
	start_btn_node.custom_minimum_size = Vector2(320, 60)
	start_btn_node.add_theme_font_size_override("font_size", 24)
	start_btn_node.add_theme_color_override("font_color", Color(1, 1, 1))
	start_btn_node.pivot_offset = Vector2(160, 30)
	
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.1, 0.5, 0.2, 0.9)
	s.border_width_left = 2; s.border_width_right = 2; s.border_width_top = 2; s.border_width_bottom = 2
	s.border_color = Color(0.4, 1.0, 0.5)
	s.corner_radius_top_left = 10; s.corner_radius_top_right = 10; s.corner_radius_bottom_left = 10; s.corner_radius_bottom_right = 10
	s.shadow_color = Color(0.2, 0.8, 0.3, 0.5); s.shadow_size = 15
	start_btn_node.add_theme_stylebox_override("normal", s)
	
	var h = s.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.2, 0.8, 0.3, 1.0); h.shadow_size = 25
	start_btn_node.add_theme_stylebox_override("hover", h)
	
	start_btn_node.pressed.connect(_on_start_pressed)
	h_start.add_child(start_btn_node)
	
	_on_year_changed(0)

func create_grid_label(parent: Control, text: String):
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(140, 45)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(lbl)

func create_avatar_icon(parent: Control, type: int, color: Color):
	var center_node = Node2D.new(); center_node.position = Vector2(35, 35); parent.add_child(center_node)
	var glow = Polygon2D.new(); glow.color = Color(color.r, color.g, color.b, 0.3)
	var icon = Polygon2D.new(); icon.color = color
	match type:
		0:
			glow.polygon = PackedVector2Array([Vector2(0, -24), Vector2(24, 0), Vector2(0, 24), Vector2(-24, 0)])
			icon.polygon = PackedVector2Array([Vector2(0, -15), Vector2(15, 0), Vector2(0, 15), Vector2(-15, 0)])
		1:
			glow.polygon = PackedVector2Array([Vector2(0, -24), Vector2(8, -8), Vector2(24, -8), Vector2(12, 5), Vector2(18, 24), Vector2(0, 12), Vector2(-18, 24), Vector2(-12, 5), Vector2(-24, -8), Vector2(-8, -8)])
			icon.polygon = PackedVector2Array([Vector2(0, -15), Vector2(5, -5), Vector2(15, -5), Vector2(7, 3), Vector2(10, 15), Vector2(0, 7), Vector2(-10, 15), Vector2(-7, 3), Vector2(-15, -5), Vector2(-5, -5)])
		2:
			glow.polygon = PackedVector2Array([Vector2(0, -24), Vector2(22, -12), Vector2(22, 12), Vector2(0, 24), Vector2(-22, 12), Vector2(-22, -12)])
			icon.polygon = PackedVector2Array([Vector2(0, -15), Vector2(13, -7), Vector2(13, 7), Vector2(0, 15), Vector2(-13, 7), Vector2(-13, -7)])
		3:
			glow.polygon = PackedVector2Array([Vector2(0, -24), Vector2(24, 20), Vector2(0, 10), Vector2(-24, 20)])
			icon.polygon = PackedVector2Array([Vector2(0, -15), Vector2(15, 12), Vector2(0, 6), Vector2(-15, 12)])
	center_node.add_child(glow); center_node.add_child(icon)

func style_line_edit(le: LineEdit):
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.02, 0.02, 0.05, 0.9)
	s.border_width_left = 2; s.border_width_right = 2; s.border_width_top = 2; s.border_width_bottom = 2
	s.border_color = Color(0.2, 0.4, 0.7)
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6; s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	s.content_margin_left = 12
	le.add_theme_stylebox_override("normal", s); le.add_theme_stylebox_override("focus", s)
	le.add_theme_font_size_override("font_size", 16); le.add_theme_color_override("font_color", Color(1, 1, 1))
	le.add_theme_color_override("caret_color", Color(0.5, 0.9, 1.0))

func style_option_button(ob: OptionButton):
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.02, 0.02, 0.05, 0.9)
	s.border_width_left = 2; s.border_width_right = 2; s.border_width_top = 2; s.border_width_bottom = 2
	s.border_color = Color(0.2, 0.4, 0.7)
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6; s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	s.content_margin_left = 12
	ob.add_theme_stylebox_override("normal", s); ob.add_theme_stylebox_override("hover", s); ob.add_theme_stylebox_override("pressed", s)
	ob.add_theme_font_size_override("font_size", 16); ob.add_theme_color_override("font_color", Color(1, 1, 1))

func _update_avatar_style(btn: Button, color: Color, is_selected: bool):
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.05, 0.9)
	style.corner_radius_top_left = 10; style.corner_radius_top_right = 10; style.corner_radius_bottom_left = 10; style.corner_radius_bottom_right = 10
	if is_selected:
		style.border_width_left = 2; style.border_width_right = 2; style.border_width_top = 2; style.border_width_bottom = 2
		style.border_color = color; style.shadow_color = Color(color.r, color.g, color.b, 0.5); style.shadow_size = 8
	btn.add_theme_stylebox_override("normal", style)

func _on_avatar_selected(id: String, _btn: Button, color: Color):
	selected_avatar_id = id
	if Engine.has_singleton("AudioManager"): Engine.get_singleton("AudioManager").play_click()
	for av_id in avatar_buttons:
		var b = avatar_buttons[av_id]
		if av_id == id:
			b.scale = Vector2(1.1, 1.1); b.modulate = Color(1, 1, 1); _update_avatar_style(b, color, true)
		else:
			b.scale = Vector2(0.9, 0.9); b.modulate = Color(0.5, 0.5, 0.5); _update_avatar_style(b, Color.WHITE, false)

func _on_year_changed(_index: int): _update_balance_info()
func _on_country_changed(_index: int): _update_balance_info()
func _on_slider_changed(_value: float): _update_balance_info()

func _on_mode_selected(mode_id: String):
	selected_mode = mode_id
	var mode_data = modes[mode_id]
	for id in mode_buttons:
		var btn = mode_buttons[id]
		var is_sel = (id == mode_id)
		var bs = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		if is_sel:
			bs.bg_color = Color(mode_data.color.r, mode_data.color.g, mode_data.color.b, 0.15)
			bs.border_color = mode_data.color
			bs.shadow_color = Color(mode_data.color.r, mode_data.color.g, mode_data.color.b, 0.4)
			bs.shadow_size = 12
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
		else:
			bs.bg_color = Color(0.02, 0.03, 0.08, 0.9)
			bs.border_color = modes[id].color.darkened(0.6)
			bs.shadow_size = 0
			btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		btn.add_theme_stylebox_override("normal", bs)
	mode_description_label.text = mode_data.description
	mode_description_label.add_theme_color_override("font_color", mode_data.color.lightened(0.3))
	slider_container.visible = (mode_id == "free")
	_update_balance_info()

func _update_balance_info():
	var year = 1995 + year_select.selected
	var c_idx = country_select.selected
	var c_data = country_data[c_idx]
	var currency = c_data.currency
	var sym = c_data.symbol
	currency_label.text = "%s %s" % [sym, currency]
	if selected_mode == "free":
		var usd_amount = balance_slider.value
		var rate = historical_rates[year][currency]
		var local_amount = int(round(usd_amount * rate))
		balance_value_label.text = "%s %s" % [_format_money(local_amount), sym]
		balance_value_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	else:
		var base_usd = 50000.0
		var rate = historical_rates[year][currency]
		var local_amount = int(round(base_usd * rate))
		balance_value_label.text = "%s %s" % [_format_money(local_amount), sym]
		balance_value_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	var tw = create_tween()
	balance_value_label.modulate = Color(1.5, 1.5, 1.5)
	tw.tween_property(balance_value_label, "modulate", Color(1, 1, 1), 0.3)

func _format_money(value: int) -> String:
	var s = str(value)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0: result = " " + result
	return result

func _on_start_pressed():
	var p_name = name_input.text.strip_edges()
	if p_name == "": p_name = "Игрок"
	var year = 1995 + year_select.selected
	var country = country_data[country_select.selected].name
	var currency_code = country_data[country_select.selected].currency
	var start_money_usd = 50000.0
	if selected_mode == "free": start_money_usd = balance_slider.value
	if Engine.has_singleton("AudioManager"): Engine.get_singleton("AudioManager").play_purchase()
	PlayerState.start_new_game(selected_mode, p_name, country, currency_code, year, int(start_money_usd))
	get_tree().change_scene_to_file("res://scenes/MyGames.tscn")
