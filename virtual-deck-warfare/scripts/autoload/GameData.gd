extends Node

# Данные, которые загрузятся из JSON
var games: Array = []
var cards: Array = []
var dlcs: Array = []
var pc_components: Array = []

func _ready():
	print("[GameData] Загрузка данных...")
	games = _load_json("res://data/games.json")
	cards = _load_json("res://data/cards.json")
	dlcs = _load_json("res://data/dlcs.json")
	pc_components = _load_json("res://data/pc_components.json")
	
	print("[GameData] Загружено: игр=%d, карт=%d, DLC=%d, комплектующих=%d" % [
		games.size(), cards.size(), dlcs.size(), pc_components.size()
	])

# Функция для чтения JSON-файла
func _load_json(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("[GameData] Файл не найден: " + path)
		return []
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[GameData] Не удалось открыть: " + path)
		return []
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.parse_string(content)
	if json is Array:
		return json
	else:
		push_error("[GameData] Ошибка парсинга JSON: " + path)
		return []

# Удобные функции для поиска
func get_game(id: String) -> Dictionary:
	for g in games:
		if g.get("id") == id:
			return g
	return {}

func get_card(id: String) -> Dictionary:
	for c in cards:
		if c.get("id") == id:
			return c
	return {}

func get_dlc(id: String) -> Dictionary:
	for d in dlcs:
		if d.get("id") == id:
			return d
	return {}

func get_component(id: String) -> Dictionary:
	for c in pc_components:
		if c.get("id") == id:
			return c
	return {}
