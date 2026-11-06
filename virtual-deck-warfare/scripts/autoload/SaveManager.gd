extends Node

# ==========================================
# КОНСТАНТЫ
# ==========================================
const SAVE_DIR = "user://saves/"
const MAX_MANUAL_SLOTS = 6
const AUTO_SLOT = 0  # Слот 0 = автосохранение, 1-6 = ручные слоты

# ==========================================
# СИГНАЛЫ (для UI)
# ==========================================
signal save_created(slot_id: int)
signal save_deleted(slot_id: int)

# ==========================================
# СОСТОЯНИЕ
# ==========================================
var current_slot: int = -1   # -1 = новая игра, не загружена из слота
var play_time: float = 0.0   # Время в секундах с начала игровой сессии

# ==========================================
# ИНИЦИАЛИЗАЦИЯ
# ==========================================
func _ready():
	ensure_save_directory()
	
	# Тикающий таймер для подсчёта игрового времени (1 тик = 1 секунда)
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_playtime_tick)
	add_child(timer)

func _on_playtime_tick():
	# Прибавляем секунду только если игра запущена
	if current_slot >= 0:
		play_time += 1.0

# ==========================================
# ФАЙЛОВАЯ СИСТЕМА
# ==========================================
func ensure_save_directory():
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func get_slot_path(slot_id: int) -> String:
	if slot_id == AUTO_SLOT:
		return SAVE_DIR + "autosave.json"
	return SAVE_DIR + "slot_%d.json" % slot_id

func save_to_slot(slot_id: int, data: Dictionary) -> bool:
	ensure_save_directory()
	var path = get_slot_path(slot_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("[SaveManager] Не удалось открыть файл для записи: " + path)
		return false
	
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[SaveManager] Сохранено в слот ", slot_id)
	save_created.emit(slot_id)
	return true

func load_from_slot(slot_id: int) -> Dictionary:
	var path = get_slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	if data is Dictionary:
		return data
	return {}

func get_slot_metadata(slot_id: int) -> Dictionary:
	var data = load_from_slot(slot_id)
	if data.is_empty():
		return {}
	return data.get("metadata", {})

func has_save(slot_id: int) -> bool:
	return FileAccess.file_exists(get_slot_path(slot_id))

func delete_slot(slot_id: int) -> bool:
	var path = get_slot_path(slot_id)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[SaveManager] Удалён слот ", slot_id)
		save_deleted.emit(slot_id)
		return true
	return false

# ==========================================
# УТИЛИТЫ
# ==========================================
# Превращает секунды в "2ч 15м" или "45м"
func format_playtime(seconds: float) -> String:
	var total_sec = int(seconds)
	# ИСПРАВЛЕНО: используем 3600.0 и 60.0, чтобы Godot не ругался на Integer division
	var hours = int(total_sec / 3600.0)
	var minutes = int((total_sec % 3600) / 60.0)
	if hours > 0:
		return "%dч %02dм" % [hours, minutes]
	return "%dм" % minutes

# Получить красивую дату сохранения
func get_current_date_string() -> String:
	var d = Time.get_datetime_dict_from_system()
	return "%02d.%02d.%d %02d:%02d" % [d.day, d.month, d.year, d.hour, d.minute]
