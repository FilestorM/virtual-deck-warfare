extends Node2D

var cards: Array = []
var time: float = 0.0
var title_group: Node2D
var neon_glows: Array = []
var menu_buttons: Array = []

# Переменные для всплывающей подсказки
var tooltip_panel: Panel
var tooltip_label: Label
var tooltip_timer: Timer
var tooltip_tween: Tween
var pending_tooltip_text: String = ""
var pending_tooltip_btn: Button = null

const COLUMN_POSITIONS = [120.0, 320.0, 520.0, 720.0, 920.0, 1120.0]
var last_card_in_column: Array = [null, null, null, null, null, null]
const SPAWN_DISTANCE = 250.0

const COLORS = [
	Color(0.85, 0.85, 0.85),
	Color(0.0, 0.8, 1.0),
	Color(0.7, 0.1, 1.0),
	Color(1.0, 0.6, 0.0)
]

const SCENE_PLAY = "res://scenes/MyGames.tscn"
const SCENE_COLLECTION = "res://scenes/Collection.tscn"
const SCENE_SETTINGS = "res://scenes/Settings.tscn"

func _ready():
	print("[DEBUG] _ready() запущен")
	create_beautiful_background()
	create_vignette()
	create_neon_title()
	create_main_menu_ui()
	create_version_label()
	
	for i in range(COLUMN_POSITIONS.size()):
		spawn_card(randf_range(-300, 300), COLUMN_POSITIONS[i], i)

func _process(delta):
	time += delta
	animate_title()
	
	# --- АНИМАЦИЯ КНОПОК ---
	for btn in menu_buttons:
		if not is_instance_valid(btn): continue
		
		var target_scale = 1.0
		var target_mod = Color(1.0, 1.0, 1.0)
		
		if btn.is_pressed():
			target_scale = 0.95
			target_mod = Color(0.7, 0.7, 0.7)
		elif btn.is_hovered():
			target_scale = 1.08
			target_mod = Color(1.2, 1.2, 1.2)
			
		btn.scale = btn.scale.lerp(Vector2(target_scale, target_scale), delta * 15.0)
		btn.modulate = btn.modulate.lerp(target_mod, delta * 15.0)
	
	# Движение карт
	for card in cards:
		var speed = card.get_meta("fall_speed")
		card.position.y += speed * delta
		
		var phase = card.get_meta("phase")
		var sway_speed = card.get_meta("sway_speed")
		var sway_amp_x = card.get_meta("sway_amp_x")
		var sway_amp_rot = card.get_meta("sway_amp_rot")
		var current_time = time * sway_speed + phase
		
		card.position.x = card.get_meta("base_x") + sin(current_time) * sway_amp_x
		card.rotation = card.get_meta("base_rot") + cos(current_time) * sway_amp_rot
		
		if card.position.y > 850:
			var col_idx = card.get_meta("column_index")
			if last_card_in_column[col_idx] == card:
				last_card_in_column[col_idx] = null
			card.queue_free()
			cards.erase(card)
	
	for i in range(COLUMN_POSITIONS.size()):
		var last_card = last_card_in_column[i]
		if last_card == null or last_card.position.y > SPAWN_DISTANCE:
			if cards.size() < 15:
				spawn_card(-200, COLUMN_POSITIONS[i], i)

# ==========================================
# 1. ФОН И ВИНЬЕТКА
# ==========================================
func create_beautiful_background():
	var bg = TextureRect.new()
	bg.size = Vector2(1280, 720)
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
	vignette.size = Vector2(1280, 720)
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
# 2. НЕОНОВЫЙ ЗАГОЛОВОК (ТОЛЬКО ОБВОДКА)
# ==========================================
func create_neon_title():
	title_group = Node2D.new()
	title_group.position = Vector2(640, 160)
	title_group.z_index = 100
	add_child(title_group)
	
	# Верхняя строка: VIRTUAL DECK (Розово-фиолетовый неон)
	_create_neon_line("VIRTUAL DECK", -50, 80, Color(1.0, 0.1, 0.6))
	
	# Нижняя строка: WARFARE (Сине-голубой неон)
	_create_neon_line("WARFARE", 40, 90, Color(0.1, 0.6, 1.0))

# Вспомогательная функция для создания одной неоновой строки с 3 слоями
func _create_neon_line(text: String, y_pos: float, font_size: int, color: Color):
	var line_group = Node2D.new()
	line_group.position.y = y_pos
	title_group.add_child(line_group)
	
	# Слой 1: Внешнее широкое свечение (Bloom)
	var outer = Label.new()
	outer.text = text
	outer.add_theme_font_size_override("font_size", font_size)
	outer.add_theme_color_override("font_color", Color(0, 0, 0, 0)) # Прозрачный центр
	outer.add_theme_constant_override("outline_size", 45) # Широкое свечение
	outer.add_theme_color_override("font_outline_color", Color(color.r, color.g, color.b, 0.3))
	outer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.size = Vector2(1200, 100)
	outer.position = Vector2(-600, -50)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_group.add_child(outer)
	
	# Слой 2: Среднее свечение (Насыщенный цвет)
	var mid = Label.new()
	mid.text = text
	mid.add_theme_font_size_override("font_size", font_size)
	mid.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	mid.add_theme_constant_override("outline_size", 20)
	mid.add_theme_color_override("font_outline_color", Color(color.r, color.g, color.b, 0.8))
	mid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.size = Vector2(1200, 100)
	mid.position = Vector2(-600, -50)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_group.add_child(mid)
	
	# Сохраняем для анимации пульсации
	neon_glows.append(outer)
	neon_glows.append(mid)
	
	# Слой 3: Основа (Сама трубка - только обводка, внутри прозрачно)
	var core = Label.new()
	core.text = text
	core.add_theme_font_size_override("font_size", font_size)
	core.add_theme_color_override("font_color", Color(0, 0, 0, 0)) # Прозрачный центр
	core.add_theme_constant_override("outline_size", 6) # Толщина неоновой трубки
	core.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9)) # Яркая белая обводка
	core.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	core.size = Vector2(1200, 100)
	core.position = Vector2(-600, -50)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_group.add_child(core)

func animate_title():
	# Плавное парение всего заголовка
	var float_y = sin(time * 1.5) * 5.0
	title_group.position.y = 160 + float_y
	
	# Легкое покачивание
	title_group.rotation = sin(time * 1.0) * 0.01
	
	# Пульсация свечения (реалистичный неон)
	for i in range(neon_glows.size()):
		var lbl = neon_glows[i]
		var base_color = lbl.get_theme_color("font_outline_color")
		
		# Четные - внешний слой, нечетные - средний
		var is_outer = (i % 2 == 0)
		var speed = 3.0 if is_outer else 2.0
		var offset = i * 1.5
		
		var base_alpha = 0.3 if is_outer else 0.8
		var fluctuation = 0.15 if is_outer else 0.2
		
		var new_alpha = base_alpha + sin(time * speed + offset) * fluctuation
		new_alpha = clamp(new_alpha, 0.0, 1.0)
		
		lbl.add_theme_color_override("font_outline_color", Color(base_color.r, base_color.g, base_color.b, new_alpha))

# ==========================================
# 3. МЕНЮ
# ==========================================
func create_main_menu_ui():
	print("[DEBUG] Создание UI меню...")
	create_tooltip()
	
	var start_y = 320.0
	var spacing = 70.0
	
	create_menu_button("НОВАЯ ИГРА", Vector2(490, start_y), "Начать новое прохождение", _on_new_game_pressed)
	create_menu_button("ЗАГРУЗИТЬ", Vector2(490, start_y + spacing * 1), "Продолжить сохраненную игру", _on_load_pressed)
	create_menu_button("БАЗА ЗНАНИЙ", Vector2(490, start_y + spacing * 2), "Просмотр коллекции карт и правил", _on_knowledge_base_pressed)
	create_menu_button("НАСТРОЙКИ", Vector2(490, start_y + spacing * 3), "Звук, графика и управление", _on_settings_pressed)
	create_menu_button("ВЫХОД", Vector2(490, start_y + spacing * 4), "Завершить игру", _on_exit_pressed)
	
	print("[DEBUG] Все кнопки созданы")

func create_tooltip():
	tooltip_panel = Panel.new()
	tooltip_panel.z_index = 400
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 0.6, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 8
	tooltip_panel.add_theme_stylebox_override("panel", style)
	
	tooltip_label = Label.new()
	tooltip_label.add_theme_font_size_override("font_size", 16)
	tooltip_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tooltip_panel.add_child(tooltip_label)
	
	add_child(tooltip_panel)
	
	tooltip_timer = Timer.new()
	tooltip_timer.one_shot = true
	tooltip_timer.wait_time = 0.3
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
	add_child(tooltip_timer)

func create_menu_button(text: String, pos: Vector2, tooltip_text: String, callback: Callable):
	var btn = Button.new()
	btn.text = text
	btn.size = Vector2(300, 60)
	btn.position = pos
	btn.pivot_offset = Vector2(150, 30)
	
	btn.mouse_filter = Control.MOUSE_FILTER_STOP 
	btn.z_index = 300 
	
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 0.6, 1.0)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0.0, 0.4, 1.0, 0.3)
	style.shadow_size = 8
	btn.add_theme_stylebox_override("normal", style)
	
	var hover_style = style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.1, 0.15, 0.25, 0.9)
	hover_style.border_color = Color(0.4, 0.9, 1.0)
	hover_style.shadow_size = 12
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.02, 0.02, 0.05, 0.9)
	pressed_style.border_color = Color(0.2, 0.5, 1.0)
	pressed_style.shadow_size = 4
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.pressed.connect(func():
		if Engine.has_singleton("AudioManager"):
			Engine.get_singleton("AudioManager").play_click()
		callback.call()
	)
	
	btn.mouse_entered.connect(func():
		pending_tooltip_text = tooltip_text
		pending_tooltip_btn = btn
		tooltip_timer.start()
	)
	
	btn.mouse_exited.connect(func():
		tooltip_timer.stop()
		_hide_tooltip()
	)
	
	add_child(btn)
	menu_buttons.append(btn)

func _on_tooltip_timer_timeout():
	if pending_tooltip_btn:
		_show_tooltip(pending_tooltip_text, pending_tooltip_btn)

func _show_tooltip(text: String, btn: Button):
	tooltip_label.text = text
	var font = tooltip_label.get_theme_font("font")
	var font_size = tooltip_label.get_theme_font_size("font_size")
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	var panel_width = text_size.x + 32
	var panel_height = text_size.y + 16
	tooltip_panel.size = Vector2(panel_width, panel_height)
	tooltip_label.size = Vector2(panel_width, panel_height)
	tooltip_label.position = Vector2(0, 0)
	
	var target_x = btn.position.x + (btn.size.x - panel_width) / 2.0
	var target_y = btn.position.y + btn.size.y + 12
	
	tooltip_panel.position = Vector2(target_x, target_y + 10)
	tooltip_panel.modulate.a = 0
	tooltip_panel.visible = true
	
	if tooltip_tween: tooltip_tween.kill()
	tooltip_tween = create_tween().set_parallel(true)
	tooltip_tween.tween_property(tooltip_panel, "modulate:a", 1.0, 0.15)
	tooltip_tween.tween_property(tooltip_panel, "position:y", target_y, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _hide_tooltip():
	if tooltip_tween: tooltip_tween.kill()
	tooltip_tween = create_tween()
	tooltip_tween.tween_property(tooltip_panel, "modulate:a", 0.0, 0.1)
	tooltip_tween.tween_callback(func(): tooltip_panel.visible = false)

# ==========================================
# 4. ВЕРСИЯ
# ==========================================
func create_version_label():
	var version_lbl = Label.new()
	version_lbl.text = "Версия: 1.0.0 (Build 2026)"
	version_lbl.add_theme_font_size_override("font_size", 16)
	version_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	version_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_lbl.size = Vector2(400, 30)
	version_lbl.position = Vector2(440, 680)
	version_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	version_lbl.z_index = 300
	add_child(version_lbl)

# ==========================================
# 5. НАВИГАЦИЯ
# ==========================================
func _on_new_game_pressed():
	get_tree().change_scene_to_file("res://scenes/NewGameSetup.tscn")

func _on_load_pressed():
	get_tree().change_scene_to_file("res://scenes/LoadGameScreen.tscn")
	
func _on_knowledge_base_pressed():
	get_tree().change_scene_to_file(SCENE_COLLECTION)

func _on_settings_pressed():
	get_tree().change_scene_to_file(SCENE_SETTINGS)

func _on_exit_pressed():
	get_tree().quit()

# ==========================================
# 6. СПАВН КАРТ
# ==========================================
func spawn_card(start_y: float, fixed_x: float, col_idx: int):
	var rarity = randi() % 4
	var card = create_beautiful_card(rarity)
	
	card.position = Vector2(fixed_x, start_y)
	
	var depth = randf_range(0.6, 1.2)
	card.scale = Vector2(depth, depth)
	card.modulate.a = 0.75 + (depth - 0.6) * 0.4
	card.z_index = int(depth * 50)
	
	card.set_meta("base_x", fixed_x)
	card.set_meta("column_index", col_idx)
	card.set_meta("fall_speed", randf_range(35.0, 65.0) * depth)
	card.set_meta("sway_speed", randf_range(1.0, 2.5))
	card.set_meta("sway_amp_x", randf_range(15.0, 35.0) * depth)
	card.set_meta("sway_amp_rot", randf_range(0.05, 0.15))
	card.set_meta("phase", randf_range(0.0, TAU))
	
	var initial_rot = randf_range(-5.0, 5.0)
	card.rotation_degrees = initial_rot
	card.set_meta("base_rot", card.rotation)
	
	add_child(card)
	cards.append(card)
	last_card_in_column[col_idx] = card

# ==========================================
# 7. ДИЗАЙН КАРТЫ
# ==========================================
func create_beautiful_card(rarity: int) -> Control:
	var card = Control.new()
	card.custom_minimum_size = Vector2(100, 140)
	card.size = Vector2(100, 140)
	card.pivot_offset = Vector2(50, 70)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	var glow_color = COLORS[rarity]
	
	var shadow = Panel.new()
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow_style = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.7)
	shadow_style.corner_radius_top_left = 6
	shadow_style.corner_radius_top_right = 6
	shadow_style.corner_radius_bottom_left = 6
	shadow_style.corner_radius_bottom_right = 6
	shadow.add_theme_stylebox_override("panel", shadow_style)
	shadow.size = Vector2(100, 140)
	shadow.position = Vector2(5, 5)
	card.add_child(shadow)

	var glow = Panel.new()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_style = StyleBoxFlat.new()
	glow_style.bg_color = Color(glow_color.r, glow_color.g, glow_color.b, 0.25)
	glow_style.corner_radius_top_left = 6
	glow_style.corner_radius_top_right = 6
	glow_style.corner_radius_bottom_left = 6
	glow_style.corner_radius_bottom_right = 6
	glow_style.expand_margin_left = 3
	glow_style.expand_margin_right = 3
	glow_style.expand_margin_top = 3
	glow_style.expand_margin_bottom = 3
	glow.add_theme_stylebox_override("panel", glow_style)
	glow.size = Vector2(100, 140)
	card.add_child(glow)

	var panel = Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = glow_color
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style)
	panel.size = Vector2(100, 140)
	card.add_child(panel)
	
	var art_bg = ColorRect.new()
	art_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_bg.color = Color(0.03, 0.03, 0.06)
	art_bg.size = Vector2(84, 60)
	art_bg.position = Vector2(8, 8)
	panel.add_child(art_bg)
	
	var art_glow = ColorRect.new()
	art_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_glow.color = Color(glow_color.r, glow_color.g, glow_color.b, 0.15)
	art_glow.size = Vector2(84, 30)
	art_glow.position = Vector2(0, 30)
	art_bg.add_child(art_glow)
	
	var icon_type = randi() % 4
	var icon_center = Vector2(42, 30)
	create_art_icon(art_bg, icon_center, icon_type, glow_color)
	
	var text_bg = Panel.new()
	text_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text_style = StyleBoxFlat.new()
	text_style.bg_color = Color(0.12, 0.12, 0.15)
	text_bg.add_theme_stylebox_override("panel", text_style)
	text_bg.size = Vector2(84, 56)
	text_bg.position = Vector2(8, 76)
	panel.add_child(text_bg)
	
	var title = Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = "ИМЯ КАРТЫ"
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	title.add_theme_font_size_override("font_size", 8)
	title.position = Vector2(4, 4)
	text_bg.add_child(title)
	
	var desc = Label.new()
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc.text = "Свойство: ..."
	desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	desc.add_theme_font_size_override("font_size", 6)
	desc.position = Vector2(4, 18)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size = Vector2(76, 34)
	text_bg.add_child(desc)
	
	var mana_bg = Panel.new()
	mana_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mana_style = StyleBoxFlat.new()
	mana_style.bg_color = Color(0.0, 0.4, 1.0)
	mana_style.border_width_left = 1
	mana_style.border_width_right = 1
	mana_style.border_width_top = 1
	mana_style.border_width_bottom = 1
	mana_style.border_color = Color(0.5, 0.8, 1.0)
	mana_style.corner_radius_top_left = 10
	mana_style.corner_radius_top_right = 10
	mana_style.corner_radius_bottom_left = 10
	mana_style.corner_radius_bottom_right = 10
	mana_bg.add_theme_stylebox_override("panel", mana_style)
	mana_bg.size = Vector2(20, 20)
	mana_bg.position = Vector2(80, -8)
	card.add_child(mana_bg)
	
	var mana_lbl = Label.new()
	mana_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mana_lbl.text = str(randi_range(1, 10))
	mana_lbl.add_theme_color_override("font_color", Color.WHITE)
	mana_lbl.add_theme_font_size_override("font_size", 10)
	mana_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mana_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mana_lbl.size = Vector2(20, 20)
	mana_bg.add_child(mana_lbl)
	
	var stats_container = Control.new()
	stats_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_container.size = Vector2(84, 16)
	stats_container.position = Vector2(8, 116)
	panel.add_child(stats_container)
	
	var atk_bg = Panel.new()
	atk_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var atk_style = StyleBoxFlat.new()
	atk_style.bg_color = Color(0.8, 0.1, 0.1)
	atk_style.corner_radius_top_left = 3
	atk_style.corner_radius_bottom_right = 3
	atk_bg.add_theme_stylebox_override("panel", atk_style)
	atk_bg.size = Vector2(16, 16)
	atk_bg.position = Vector2(0, 0)
	stats_container.add_child(atk_bg)
	
	var atk_lbl = Label.new()
	atk_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	atk_lbl.text = str(randi_range(1, 9))
	atk_lbl.add_theme_color_override("font_color", Color.WHITE)
	atk_lbl.add_theme_font_size_override("font_size", 8)
	atk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atk_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	atk_lbl.size = Vector2(16, 16)
	atk_bg.add_child(atk_lbl)
	
	var hp_bg = Panel.new()
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hp_style = StyleBoxFlat.new()
	hp_style.bg_color = Color(0.1, 0.7, 0.1)
	hp_style.corner_radius_top_right = 3
	hp_style.corner_radius_bottom_left = 3
	hp_bg.add_theme_stylebox_override("panel", hp_style)
	hp_bg.size = Vector2(16, 16)
	hp_bg.position = Vector2(68, 0)
	stats_container.add_child(hp_bg)
	
	var hp_lbl = Label.new()
	hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_lbl.text = str(randi_range(1, 9))
	hp_lbl.add_theme_color_override("font_color", Color.WHITE)
	hp_lbl.add_theme_font_size_override("font_size", 8)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_lbl.size = Vector2(16, 16)
	hp_bg.add_child(hp_lbl)
	
	return card

func create_art_icon(parent: Control, center: Vector2, icon_type: int, color: Color):
	match icon_type:
		0:
			var blade = Polygon2D.new()
			blade.polygon = PackedVector2Array([
				center + Vector2(0, -18),
				center + Vector2(4, -5),
				center + Vector2(4, 10),
				center + Vector2(-4, 10),
				center + Vector2(-4, -5)
			])
			blade.color = Color(0.9, 0.9, 0.95)
			parent.add_child(blade)
			var handle = ColorRect.new()
			handle.color = Color(0.5, 0.3, 0.1)
			handle.size = Vector2(6, 8)
			handle.position = center + Vector2(-3, 10)
			parent.add_child(handle)
		1:
			var shield = Polygon2D.new()
			shield.polygon = PackedVector2Array([
				center + Vector2(0, -18),
				center + Vector2(16, -10),
				center + Vector2(16, 6),
				center + Vector2(0, 20),
				center + Vector2(-16, 6),
				center + Vector2(-16, -10)
			])
			shield.color = color
			parent.add_child(shield)
			var inner = Polygon2D.new()
			inner.polygon = PackedVector2Array([
				center + Vector2(0, -12),
				center + Vector2(10, -6),
				center + Vector2(10, 3),
				center + Vector2(0, 13),
				center + Vector2(-10, 3),
				center + Vector2(-10, -6)
			])
			inner.color = Color(0.1, 0.1, 0.15)
			parent.add_child(inner)
		2:
			var bolt = Polygon2D.new()
			bolt.polygon = PackedVector2Array([
				center + Vector2(-6, -20),
				center + Vector2(8, -8),
				center + Vector2(2, -8),
				center + Vector2(10, 20),
				center + Vector2(-10, 4),
				center + Vector2(-2, 4)
			])
			bolt.color = Color(1.0, 0.9, 0.3)
			parent.add_child(bolt)
		3:
			var crystal = Polygon2D.new()
			crystal.polygon = PackedVector2Array([
				center + Vector2(0, -20),
				center + Vector2(12, 0),
				center + Vector2(0, 20),
				center + Vector2(-12, 0)
			])
			crystal.color = color
			parent.add_child(crystal)
			var crystal_shine = Polygon2D.new()
			crystal_shine.polygon = PackedVector2Array([
				center + Vector2(-2, -12),
				center + Vector2(4, -4),
				center + Vector2(-2, 4),
				center + Vector2(-6, -4)
			])
			crystal_shine.color = Color(1, 1, 1, 0.4)
			parent.add_child(crystal_shine)
