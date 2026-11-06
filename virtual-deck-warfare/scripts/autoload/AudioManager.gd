extends Node

# ==========================================
# АУДИО-МЕНЕДЖЕР (ГЕНЕРАЦИЯ ЗВУКОВ БЕЗ ФАЙЛОВ)
# ==========================================

var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

var music_volume: float = 0.5
var sfx_volume: float = 0.5
var music_enabled: bool = true
var sfx_enabled: bool = true

func _ready():
	print("[AudioManager] Инициализация...")
	
	# Создаем плееры для звуков и музыки
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	# Загружаем настройки из PlayerState (если они уже есть)
	update_settings(PlayerState.settings)
	
	# Запускаем фоновую музыку
	play_music()

# ==========================================
# ГЕНЕРАТОР ЗВУКА (СИНТЕЗАТОР)
# ==========================================
# Эта функция создает аудио-поток прямо из математики (синусоида)
func _generate_tone(frequency: float, duration: float, volume: float = 0.5) -> AudioStreamWAV:
	var sample_rate = 44100
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2) # 16-bit = 2 байта на семпл
	
	for i in range(num_samples):
		var time = float(i) / sample_rate
		
		# Основной тон (синусоида)
		var val = sin(2.0 * PI * frequency * time)
		
		# Затухание (Envelope) для плавного затухания звука
		var envelope = 1.0 - (time / duration)
		val *= envelope * envelope # Квадратичное затухание звучит приятнее
		
		# Преобразуем в 16-bit PCM
		var int_val = int(clamp(val * volume, -1.0, 1.0) * 32767.0)
		
		# Записываем байты (Little Endian)
		data.encode_s16(i * 2, int_val)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

# ==========================================
# ПУБЛИЧНЫЕ МЕТОДЫ ДЛЯ ЗВУКОВ (SFX)
# ==========================================

func play_click():
	if not sfx_enabled: return
	sfx_player.stream = _generate_tone(1200.0, 0.05, sfx_volume) # Высокий "тик"
	sfx_player.play()

func play_purchase():
	if not sfx_enabled: return
	# Имитация "звона монет": три ноты подряд. 
	# Так как AudioStreamPlayer играет один поток, мы быстро генерируем аккорд
	var sample_rate = 44100
	var duration = 0.3
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var time = float(i) / sample_rate
		var envelope = 1.0 - (time / duration)
		
		# Три ноты (C, E, G) играют одновременно
		var val1 = sin(2.0 * PI * 523.25 * time)
		var val2 = sin(2.0 * PI * 659.25 * time)
		var val3 = sin(2.0 * PI * 783.99 * time)
		
		var val = (val1 + val2 + val3) / 3.0
		val *= envelope
		
		var int_val = int(clamp(val * sfx_volume, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_val)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	sfx_player.stream = stream
	sfx_player.play()

func play_error():
	if not sfx_enabled: return
	# Низкий, неприятный звук
	sfx_player.stream = _generate_tone(150.0, 0.3, sfx_volume)
	sfx_player.play()

# ==========================================
# МУЗЫКА (BGM)
# ==========================================

func play_music():
	if not music_enabled: return
	
	# Генерируем простой зацикленный трек (длиной 4 секунды)
	var sample_rate = 22050 # Немного ниже качество, чтобы сэкономить память
	var duration = 4.0
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	# Список нот (аккорд + мелодия)
	var chord = [261.63, 329.63, 392.00] # C, E, G
	var melody = [523.25, 587.33, 659.25, 783.99] # C, D, E, G
	
	for i in range(num_samples):
		var time = float(i) / sample_rate
		var val = 0.0
		
		# Аккорд (тихий фон)
		for freq in chord:
			val += sin(2.0 * PI * freq * time) * 0.2
			
		# Мелодия (играет четвертями)
		var beat = int(time * 2.0) % melody.size()
		var beat_time = fmod(time, 0.5)
		var envelope = 1.0 - (beat_time / 0.5)
		val += sin(2.0 * PI * melody[beat] * time) * envelope * 0.5
		
		# Затухание в самом конце трека для бесшовного лупа (последние 0.1 сек)
		if time > duration - 0.1:
			val *= (duration - time) / 0.1
			
		var int_val = int(clamp(val * music_volume * 0.3, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, int_val)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD # Зацикливаем
	stream.loop_begin = 0
	stream.loop_end = num_samples
	
	music_player.stream = stream
	music_player.play()

func stop_music():
	music_player.stop()

# ==========================================
# НАСТРОЙКИ
# ==========================================

func update_settings(new_settings: Dictionary):
	music_volume = new_settings.get("music_volume", 0.5)
	sfx_volume = new_settings.get("sfx_volume", 0.5)
	music_enabled = new_settings.get("music_enabled", true)
	sfx_enabled = new_settings.get("sfx_enabled", true)
	
	# ИСПРАВЛЕНО: добавлено .0 к -80, чтобы типы (float) совпадали
	music_player.volume_db = linear_to_db(music_volume) if music_enabled else -80.0
	sfx_player.volume_db = linear_to_db(sfx_volume) if sfx_enabled else -80.0
	
	# Если музыку выключили - останавливаем
	if not music_enabled:
		stop_music()
	elif music_player.stream == null or not music_player.playing:
		play_music()
