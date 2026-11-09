extends Node

# DifficultyManager - Gerenciador dinâmico de balanceamento de velocidade e quantidade por fase
# Suporta Desktop (persistência em JSON) e Web (somente leitura / reset ao reiniciar)

signal difficulty_updated()

const DEFAULT_CONFIG_PATH := "res://difficulty_balance.json"
const USER_CONFIG_PATH := "user://difficulty_balance.json"

var config_data: Dictionary = {}
var is_web: bool = false
var current_preset: String = "normal"

func _init() -> void:
	WordManager.difficulty_manager_ref = self
	is_web = OS.has_feature("web")
	load_config()

func _ready() -> void:
	is_web = OS.has_feature("web")
	if config_data.is_empty():
		load_config()

func load_config() -> void:
	# 1. Carrega o arquivo base padrão (res://difficulty_balance.json)
	var default_dict: Dictionary = _read_json_file(DEFAULT_CONFIG_PATH)
	if default_dict.is_empty():
		default_dict = _get_hardcoded_fallback()
	
	config_data = default_dict.duplicate(true)
	
	# 2. Se estiver no Desktop, verifica se o usuário possui alterações salvas em user://
	if not is_web:
		if FileAccess.file_exists(USER_CONFIG_PATH):
			var user_dict: Dictionary = _read_json_file(USER_CONFIG_PATH)
			if not user_dict.is_empty():
				_merge_config(config_data, user_dict)
				
	difficulty_updated.emit()

func save_config() -> bool:
	if is_web:
		# Na versão Web, as alterações permanecem apenas em memória durante a sessão
		difficulty_updated.emit()
		return true
		
	var json_str: String = JSON.stringify(config_data, "  ")
	
	# Grava em user:// para persistência das preferências do jogador
	var file := FileAccess.open(USER_CONFIG_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
	else:
		return false
		
	# Se executando no Editor Godot, atualiza também res://difficulty_balance.json para conveniência
	if OS.has_feature("editor"):
		var editor_file := FileAccess.open(DEFAULT_CONFIG_PATH, FileAccess.WRITE)
		if editor_file:
			editor_file.store_string(json_str)
			editor_file.close()
			
	difficulty_updated.emit()
	return true

func reset_to_defaults() -> void:
	if not is_web and FileAccess.file_exists(USER_CONFIG_PATH):
		DirAccess.remove_absolute(USER_CONFIG_PATH)
		
	var default_dict: Dictionary = _read_json_file(DEFAULT_CONFIG_PATH)
	if default_dict.is_empty():
		default_dict = _get_hardcoded_fallback()
		
	config_data = default_dict.duplicate(true)
	current_preset = "normal"
	difficulty_updated.emit()

# ----------------- CONSULTAS DE BALANCEAMENTO -----------------

func get_enemy_count(wave: int) -> int:
	var base_count: int = 40
	var wave_key: String = str(wave)
	var fases: Dictionary = config_data.get("fases", {})
	
	if fases.has(wave_key):
		base_count = int(fases[wave_key].get("quantidade_inimigos", 40))
	elif config_data.has("fases_superiores_padrao"):
		var def_upper: Dictionary = config_data["fases_superiores_padrao"]
		base_count = int(def_upper.get("quantidade_inimigos", 35)) + (wave - 22) * 7
	else:
		base_count = 35 + maxi(0, (wave - 22) * 7)
		
	var global_mult: float = float(config_data.get("modificadores_globais", {}).get("multiplicador_quantidade", 1.0))
	return maxi(4, int(round(base_count * global_mult)))

func get_fall_speed(wave: int) -> float:
	var base_spd: float = 32.0
	var wave_key: String = str(wave)
	var fases: Dictionary = config_data.get("fases", {})
	
	if fases.has(wave_key):
		base_spd = float(fases[wave_key].get("velocidade_queda", 32.0))
	elif config_data.has("fases_superiores_padrao"):
		var def_upper: Dictionary = config_data["fases_superiores_padrao"]
		base_spd = float(def_upper.get("velocidade_queda", 22.0))
	else:
		base_spd = 22.0
		
	var global_mult: float = float(config_data.get("modificadores_globais", {}).get("multiplicador_velocidade", 1.0))
	return maxf(8.0, base_spd * global_mult)

func get_spawn_interval(wave: int) -> float:
	var base_int: float = 1.25
	var wave_key: String = str(wave)
	var fases: Dictionary = config_data.get("fases", {})
	
	if fases.has(wave_key):
		base_int = float(fases[wave_key].get("intervalo_spawn", 1.25))
	elif config_data.has("fases_superiores_padrao"):
		var def_upper: Dictionary = config_data["fases_superiores_padrao"]
		base_int = float(def_upper.get("intervalo_spawn", 1.40))
	else:
		base_int = 1.40
		
	var global_mult: float = float(config_data.get("modificadores_globais", {}).get("multiplicador_spawn_intervalo", 1.0))
	return maxf(0.3, base_int * global_mult)

func get_wave_name(wave: int) -> String:
	var wave_key: String = str(wave)
	var fases: Dictionary = config_data.get("fases", {})
	if fases.has(wave_key):
		return str(fases[wave_key].get("nome", "Fase %d" % wave))
	return "Fase %d: Horda Mista Cósmica" % wave

# ----------------- AJUSTES E PRESETS -----------------

func apply_preset(preset_key: String) -> void:
	var presets: Dictionary = config_data.get("presets", {})
	if not presets.has(preset_key):
		return
		
	var p: Dictionary = presets[preset_key]
	var mods: Dictionary = config_data.get("modificadores_globais", {})
	mods["multiplicador_velocidade"] = float(p.get("multiplicador_velocidade", 1.0))
	mods["multiplicador_quantidade"] = float(p.get("multiplicador_quantidade", 1.0))
	mods["multiplicador_spawn_intervalo"] = float(p.get("multiplicador_spawn_intervalo", 1.0))
	config_data["modificadores_globais"] = mods
	current_preset = preset_key
	difficulty_updated.emit()

func set_global_multipliers(speed_mult: float, count_mult: float, spawn_mult: float) -> void:
	var mods: Dictionary = config_data.get("modificadores_globais", {})
	mods["multiplicador_velocidade"] = clampf(speed_mult, 0.4, 2.5)
	mods["multiplicador_quantidade"] = clampf(count_mult, 0.4, 3.0)
	mods["multiplicador_spawn_intervalo"] = clampf(spawn_mult, 0.4, 2.5)
	config_data["modificadores_globais"] = mods
	current_preset = "custom"
	difficulty_updated.emit()

func set_wave_balance(wave: int, count: int, speed: float, spawn_interval: float) -> void:
	var wave_key: String = str(wave)
	if not config_data.has("fases"):
		config_data["fases"] = {}
		
	if not config_data["fases"].has(wave_key):
		config_data["fases"][wave_key] = {"nome": "Fase %d" % wave}
		
	config_data["fases"][wave_key]["quantidade_inimigos"] = maxi(4, count)
	config_data["fases"][wave_key]["velocidade_queda"] = clampf(speed, 10.0, 100.0)
	config_data["fases"][wave_key]["intervalo_spawn"] = clampf(spawn_interval, 0.3, 4.0)
	difficulty_updated.emit()

# ----------------- UTILITÁRIOS INTERNOS -----------------

func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var content: String = file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error: Error = json.parse(content)
	if error == OK and json.data is Dictionary:
		return json.data as Dictionary
	return {}

func _merge_config(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		if target.has(key) and target[key] is Dictionary and source[key] is Dictionary:
			_merge_config(target[key], source[key])
		else:
			target[key] = source[key]

func _get_hardcoded_fallback() -> Dictionary:
	return {
		"modificadores_globais": {
			"multiplicador_velocidade": 1.0,
			"multiplicador_quantidade": 1.0,
			"multiplicador_spawn_intervalo": 1.0
		},
		"presets": {
			"facil": {"multiplicador_velocidade": 0.8, "multiplicador_quantidade": 0.75, "multiplicador_spawn_intervalo": 1.3},
			"normal": {"multiplicador_velocidade": 1.0, "multiplicador_quantidade": 1.0, "multiplicador_spawn_intervalo": 1.0},
			"dificil": {"multiplicador_velocidade": 1.25, "multiplicador_quantidade": 1.25, "multiplicador_spawn_intervalo": 0.8}
		},
		"fases": {},
		"fases_superiores_padrao": {
			"quantidade_inimigos": 35,
			"velocidade_queda": 22.0,
			"intervalo_spawn": 1.40
		}
	}
