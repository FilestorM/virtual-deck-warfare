extends Control

var music_slider: HSlider
var sfx_slider: HSlider
var music_check: CheckButton
var sfx_check: CheckButton
var reset_btn: Button
var reset_label: Label

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	create_beautiful_background()
	create_vignette()
	create_main_panel()

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
	panel.offset_left = 240; panel.offset_top = 80; panel.offset_right = -240; panel.offset_bottom = -80
	
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
	margin.add_theme_constant_override("margin_left", 50); margin.add_theme_constant_override("margin_right", 50)
	margin.add_theme_constant_override("margin_top", 40); margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 30)
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
	title.text = "НАСТРОЙКИ"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 1.0))
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color(0.3, 0.1, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_header.add_child(title)
	
	var spacer_r = Control.new(); spacer_r.custom_minimum_size = Vector2(140, 0); h_header.add_child(spacer_r)
	
	# --- АУДИО ---
	var audio_title = Label.new()
	audio_title.text = "АУДИО"
	audio_title.add_theme_font_size_override("font_size", 22)
	audio_title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	main_vbox.add_child(audio_title)
	
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 20)
	main_vbox.add_child(grid)
	
	create_label(grid, "Громкость музыки:")
	music_slider = HSlider.new()
	music_slider.min_value = 0.0; music_slider.max_value = 1.0; music_slider.step = 0.05
	music_slider.value = PlayerState.settings.get("music_volume", 0.5)
	music_slider.custom_minimum_size = Vector2(400, 30)
	style_slider(music_slider)
	music_slider.value_changed.connect(_on_music_volume_changed)
	grid.add_child(music_slider)
	
	create_label(grid, "Громкость эффектов:")
	sfx_slider = HSlider.new()
	sfx_slider.min_value = 0.0; sfx_slider.max_value = 1.0; sfx_slider.step = 0.05
	sfx_slider.value = PlayerState.settings.get("sfx_volume", 0.5)
	sfx_slider.custom_minimum_size = Vector2(400, 30)
	style_slider(sfx_slider)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	grid.add_child(sfx_slider)
	
	create_label(grid, "Включить музыку:")
	music_check = CheckButton.new()
	music_check.button_pressed = PlayerState.settings.get("music_enabled", true)
	music_check.toggled.connect(_on_music_toggled)
	grid.add_child(music_check)
	
	create_label(grid, "Включить эффекты:")
	sfx_check = CheckButton.new()
	sfx_check.button_pressed = PlayerState.settings.get("sfx_enabled", true)
	sfx_check.toggled.connect(_on_sfx_toggled)
	grid.add_child(sfx_check)
	
	# --- ДАННЫЕ ---
	var data_title = Label.new()
	data_title.text = "УПРАВЛЕНИЕ ДАННЫМИ"
	data_title.add_theme_font_size_override("font_size", 22)
	data_title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	main_vbox.add_child(data_title)
	
	var h_data = HBoxContainer.new()
	h_data.add_theme_constant_override("separation", 20)
	main_vbox.add_child(h_data)
	
	reset_btn = Button.new()
	reset_btn.text = "СБРОСИТЬ ВСЕ СОХРАНЕНИЯ"
	reset_btn.custom_minimum_size = Vector2(350, 45)
	reset_btn.add_theme_font_size_override("font_size", 16)
	reset_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	
	var rs = StyleBoxFlat.new()
	rs.bg_color = Color(0.05, 0.05, 0.1, 0.8)
	rs.border_width_left = 2; rs.border_width_right = 2; rs.border_width_top = 2; rs.border_width_bottom = 2
	rs.border_color = Color(1.0, 0.2, 0.2)
	rs.corner_radius_top_left = 8; rs.corner_radius_top_right = 8; rs.corner_radius_bottom_left = 8; rs.corner_radius_bottom_right = 8
	reset_btn.add_theme_stylebox_override("normal", rs)
	
	var rh = rs.duplicate() as StyleBoxFlat
	rh.bg_color = Color(0.2, 0.05, 0.05, 0.9); rh.border_color = Color(1.0, 0.4, 0.4)
	reset_btn.add_theme_stylebox_override("hover", rh)
	
	reset_btn.pressed.connect(_on_reset_pressed)
	h_data.add_child(reset_btn)
	
	reset_label = Label.new()
	reset_label.text = ""
	reset_label.add_theme_font_size_override("font_size", 16)
	reset_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	reset_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h_data.add_child(reset_label)

func create_label(parent: Control, text: String):
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(200, 40)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(lbl)

func style_slider(slider: HSlider):
	var track = StyleBoxFlat.new()
	track.bg_color = Color(0.02, 0.04, 0.08)
	track.border_width_top = 2; track.border_width_bottom = 2; track.border_color = Color(0.0, 0.3, 0.6)
	track.corner_radius_top_left = 4; track.corner_radius_top_right = 4; track.corner_radius_bottom_left = 4; track.corner_radius_bottom_right = 4
	slider.add_theme_stylebox_override("slider", track)
	
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.0, 0.6, 1.0)
	fill.corner_radius_top_left = 4; fill.corner_radius_top_right = 4; fill.corner_radius_bottom_left = 4; fill.corner_radius_bottom_right = 4
	fill.shadow_color = Color(0.0, 0.6, 1.0, 0.5); fill.shadow_size = 4
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	
	var grabber = StyleBoxFlat.new()
	grabber.bg_color = Color.WHITE
	grabber.corner_radius_top_left = 12; grabber.corner_radius_top_right = 12; grabber.corner_radius_bottom_left = 12; grabber.corner_radius_bottom_right = 12
	grabber.border_width_left = 2; grabber.border_width_right = 2; grabber.border_width_top = 2; grabber.border_width_bottom = 2
	grabber.border_color = Color(1, 1, 1); grabber.shadow_color = Color(0.0, 0.8, 1.0, 0.8); grabber.shadow_size = 10
	slider.add_theme_stylebox_override("grabber", grabber)

func _on_music_volume_changed(val: float):
	PlayerState.settings["music_volume"] = val; _update_audio_manager()

func _on_sfx_volume_changed(val: float):
	PlayerState.settings["sfx_volume"] = val; _update_audio_manager()
	if Engine.has_singleton("AudioManager"): Engine.get_singleton("AudioManager").play_click()

func _on_music_toggled(toggled: bool):
	PlayerState.settings["music_enabled"] = toggled; _update_audio_manager()

func _on_sfx_toggled(toggled: bool):
	PlayerState.settings["sfx_enabled"] = toggled; _update_audio_manager()

func _update_audio_manager():
	if Engine.has_singleton("AudioManager"):
		Engine.get_singleton("AudioManager").update_settings(PlayerState.settings)

func _on_reset_pressed():
	for i in range(0, 7): SaveManager.delete_slot(i)
	PlayerState.game_started = false
	PlayerState.owned_game_ids.clear(); PlayerState.owned_card_ids.clear()
	PlayerState.owned_dlc_ids.clear(); PlayerState.owned_component_ids.clear()
	reset_label.text = "Все сохранения удалены!"
	reset_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	var tw = create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func(): reset_label.text = "")
