extends Node

# ==========================================
# ПОЛЯ ИГРОВОГО СОСТОЯНИЯ
# ==========================================
var money: int = 50000
var year: int = 1995
var game_started: bool = false

var owned_game_ids: Array[String] = []
var owned_card_ids: Array[String] = []
var owned_dlc_ids: Array[String] = []
var owned_component_ids: Array[String] = ["cpu-pentium-75", "ram-8mb-edo", "gpu-nvidia-nv1"]

var equipped_components: Dictionary = {
	"cpu": "cpu-pentium-75",
	"ram": "ram-8mb-edo",
	"gpu": "gpu-nvidia-nv1"
}

var settings: Dictionary = {
	"music_volume": 0.5,
	"sfx_volume": 0.5,
	"music_enabled": true,
	"sfx_enabled": true
}

# ПЕРСОНАЖ
var player_name: String = "Игрок"
var player_country: String = "Россия"
var player_currency: String = "RUB"
var game_mode: String = "campaign"

# ==========================================
# ИСТОРИЧЕСКИЕ КУРСЫ ВАЛЮТ (К 1 USD)
# ==========================================
const COUNTRY_RATES = {
	1995: {"USD": 1.0, "RUB": 4.56, "CNY": 8.35, "JPY": 94.06, "INR": 32.42},
	1996: {"USD": 1.0, "RUB": 5.12, "CNY": 8.31, "JPY": 108.78, "INR": 35.43},
	1997: {"USD": 1.0, "RUB": 5.78, "CNY": 8.28, "JPY": 120.99, "INR": 36.31},
	1998: {"USD": 1.0, "RUB": 9.70, "CNY": 8.27, "JPY": 130.90, "INR": 41.25},
	1999: {"USD": 1.0, "RUB": 24.61, "CNY": 8.27, "JPY": 113.90, "INR": 43.05},
	2000: {"USD": 1.0, "RUB": 28.12, "CNY": 8.27, "JPY": 107.83, "INR": 44.94},
	2001: {"USD": 1.0, "RUB": 29.16, "CNY": 8.27, "JPY": 121.52, "INR": 47.18},
	2002: {"USD": 1.0, "RUB": 31.34, "CNY": 8.27, "JPY": 125.38, "INR": 48.61},
	2003: {"USD": 1.0, "RUB": 30.69, "CNY": 8.27, "JPY": 115.93, "INR": 46.58},
	2004: {"USD": 1.0, "RUB": 28.81, "CNY": 8.27, "JPY": 108.19, "INR": 45.31},
	2005: {"USD": 1.0, "RUB": 28.28, "CNY": 8.19, "JPY": 110.22, "INR": 44.10}
}

# ==========================================
# СЕРИАЛИЗАЦИЯ
# ==========================================
func to_save_dict() -> Dictionary:
	return {
		"year": year,
		"money": money,
		"owned_game_ids": owned_game_ids,
		"owned_card_ids": owned_card_ids,
		"owned_dlc_ids": owned_dlc_ids,
		"owned_component_ids": owned_component_ids,
		"equipped_components": equipped_components,
		"settings": settings,
		"player_name": player_name,
		"player_country": player_country,
		"player_currency": player_currency,
		"game_mode": game_mode
	}

func load_from_dict(data: Dictionary):
	year = data.get("year", 1995)
	money = data.get("money", 50000)
	owned_game_ids.assign(data.get("owned_game_ids", []))
	owned_card_ids.assign(data.get("owned_card_ids", []))
	owned_dlc_ids.assign(data.get("owned_dlc_ids", []))
	owned_component_ids.assign(data.get("owned_component_ids", ["cpu-pentium-75", "ram-8mb-edo", "gpu-nvidia-nv1"]))
	equipped_components = data.get("equipped_components", equipped_components)
	settings = data.get("settings", settings)
	player_name = data.get("player_name", "Игрок")
	player_country = data.get("player_country", "Россия")
	player_currency = data.get("player_currency", "RUB")
	game_mode = data.get("game_mode", "campaign")
	game_started = true

# ==========================================
# СОХРАНЕНИЕ / ЗАГРУЗКА
# ==========================================
func save_game():
	if not game_started:
		return
	save_to_slot(SaveManager.AUTO_SLOT)

func save_to_slot(slot_id: int) -> bool:
	if not game_started:
		return false
	
	var data = {
		"version": 1,
		"metadata": {
			"character_name": player_name,
			"country": player_country,
			"currency": player_currency,
			"mode": game_mode,
			"year": year,
			"money": money,
			"playtime": SaveManager.play_time,
			"date": SaveManager.get_current_date_string()
		},
		"state": to_save_dict()
	}
	
	return SaveManager.save_to_slot(slot_id, data)

func load_from_slot(slot_id: int) -> bool:
	var data = SaveManager.load_from_slot(slot_id)
	if data.is_empty():
		return false
	
	var state = data.get("state", {})
	if state.is_empty():
		return false
	
	load_from_dict(state)
	SaveManager.current_slot = slot_id
	return true

# ==========================================
# СТАРТ НОВОЙ ИГРЫ
# ==========================================
func start_new_game(mode: String, p_name: String, p_country: String, p_currency: String, p_year: int, start_money_usd: int):
	game_mode = mode
	player_name = p_name
	player_country = p_country
	player_currency = p_currency
	year = p_year
	
	var rate = 1.0
	if COUNTRY_RATES.has(p_year):
		rate = COUNTRY_RATES[p_year].get(p_currency, 1.0)
	
	var starting_money = int(round(start_money_usd * rate))
	
	match mode:
		"free": money = starting_money
		"campaign": money = starting_money
		_: money = starting_money
	
	owned_game_ids.clear()
	owned_card_ids.clear()
	owned_dlc_ids.clear()
	owned_component_ids = ["cpu-pentium-75", "ram-8mb-edo", "gpu-nvidia-nv1"]
	equipped_components = {
		"cpu": "cpu-pentium-75",
		"ram": "ram-8mb-edo",
		"gpu": "gpu-nvidia-nv1"
	}
	
	game_started = true
	SaveManager.current_slot = -1
	SaveManager.play_time = 0.0
	SaveManager.delete_slot(SaveManager.AUTO_SLOT)
	save_game()
	print("[PlayerState] Новая игра запущена: ", mode, " | Год: ", year, " | Баланс: ", money)

# ==========================================
# ГЕЙМПЛЕЙ
# ==========================================
func add_money(amount: int):
	money += amount
	save_game()

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		save_game()
		return true
	return false

func buy_game(game_id: String, price: int, card_ids: Array) -> bool:
	if owned_game_ids.has(game_id): return false
	if spend_money(price):
		owned_game_ids.append(game_id)
		for cid in card_ids:
			if not owned_card_ids.has(cid): owned_card_ids.append(cid)
		save_game()
		return true
	return false

func buy_dlc(dlc_id: String, price: int, card_ids: Array) -> bool:
	if owned_dlc_ids.has(dlc_id): return false
	if spend_money(price):
		owned_dlc_ids.append(dlc_id)
		for cid in card_ids:
			if not owned_card_ids.has(cid): owned_card_ids.append(cid)
		save_game()
		return true
	return false

func buy_component(component_id: String, price: int, type: String) -> bool:
	if owned_component_ids.has(component_id): return false
	if spend_money(price):
		owned_component_ids.append(component_id)
		equipped_components[type] = component_id
		save_game()
		return true
	return false

func equip_component(component_id: String, type: String):
	if owned_component_ids.has(component_id):
		equipped_components[type] = component_id
		save_game()

func get_pc_stats() -> Dictionary:
	var stats = {"cpu": 0, "ram": 0, "gpu": 0}
	var cpu_id = equipped_components.get("cpu", "")
	var ram_id = equipped_components.get("ram", "")
	var gpu_id = equipped_components.get("gpu", "")
	
	var cpu_comp = GameData.get_component(cpu_id)
	if cpu_comp.has("stats"): stats.cpu = cpu_comp.stats.get("cpu", 0)
	
	var ram_comp = GameData.get_component(ram_id)
	if ram_comp.has("stats"): stats.ram = ram_comp.stats.get("ram", 0)
	
	var gpu_comp = GameData.get_component(gpu_id)
	if gpu_comp.has("stats"): stats.gpu = gpu_comp.stats.get("gpu", 0)
	
	return stats

func can_run_game(game_id: String) -> bool:
	var game = GameData.get_game(game_id)
	if game.is_empty(): return false
	var req = game.get("requirements", {})
	var stats = get_pc_stats()
	return (
		stats.cpu >= req.get("cpu", 0) and
		stats.ram >= req.get("ram", 0) and
		stats.gpu >= req.get("gpu", 0)
	)

# ==========================================
# ВАЛЮТА
# ==========================================
func get_currency_symbol() -> String:
	match player_currency:
		"USD": return "$"
		"EUR": return "€"
		"JPY": return "¥"
		"CNY": return "¥"
		"GBP": return "£"
		"INR": return "₹"
		_: return "₽"
