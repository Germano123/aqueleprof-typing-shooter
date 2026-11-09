class_name WordManager
extends RefCounted

# WordManager - Banco de palavras, pares de treino e dados de coloração/escala por fase

# Pares Simétricos da Linha de Base (Fase 1)
const PAIRS_HOME_ROW: Array[Dictionary] = [
	{"left": "F", "right": "J", "name": "Indicadores Base (F-J)"},
	{"left": "G", "right": "H", "name": "Indicadores Centro (G-H)"},
	{"left": "D", "right": "K", "name": "Médios (D-K)"},
	{"left": "S", "right": "L", "name": "Anelares (S-L)"},
	{"left": "A", "right": "Ç", "name": "Mínimos (A-Ç)"}
]

# Pares da Linha Superior (Fase 2)
const PAIRS_UPPER_ROW: Array[Dictionary] = [
	{"left": "R", "right": "U", "name": "Linha Superior (R-U)"},
	{"left": "T", "right": "Y", "name": "Linha Superior (T-Y)"},
	{"left": "E", "right": "I", "name": "Linha Superior (E-I)"},
	{"left": "W", "right": "O", "name": "Linha Superior (W-O)"},
	{"left": "Q", "right": "P", "name": "Linha Superior (Q-P)"}
]

# Pares da Linha Inferior (Fase 3: B-N, V-M, C-, X-. , Z-;)
const PAIRS_LOWER_ROW: Array[Dictionary] = [
	{"left": "B", "right": "N", "name": "Inferior (B-N)"},
	{"left": "V", "right": "M", "name": "Inferior (V-M)"},
	{"left": "C", "right": ",", "name": "Inferior (C-,)"},
	{"left": "X", "right": ".", "name": "Inferior (X-.)"},
	{"left": "Z", "right": ";", "name": "Inferior (Z-;)"}
]

# Inimigos Pesados de 2 Caracteres (Fase 4: Primeira metade - Cruzadores 2-HP)
const WORDS_HEAVY_2CHAR: Array[String] = [
	"FA", "JU", "DE", "KI", "SO", "LA", "AS", "ÇO",
	"CA", "BO", "VA", "MO", "PA", "TO", "RE", "TY",
	"WE", "OP", "GA", "HO", "BI", "NU", "MA", "VI"
]

# Inimigos Pesados de 3 Caracteres (Fase 4: Segunda metade - Cruzadores 3-HP)
const WORDS_HEAVY_3CHAR: Array[String] = [
	"SOL", "LUA", "MAR", "CEU", "RIO", "PAO", "GOL", "LUZ", "VOZ", "FIM",
	"SOM", "PAZ", "DOM", "MEL", "SAL", "REI", "ATO", "COR", "VER", "DAR",
	"LEI", "BEM", "MAL", "SIM", "NAO", "CHA", "CRU", "PRO", "VAI", "VEM"
]

# Palavras de Alcance Difícil (Fase 5)
const WORDS_DIFFICULT_STRETCH: Array[String] = [
	"PIXEL", "EQUIPE", "ZUMBIDO", "PROJETO", "COMPLEXO", "AXIOMA",
	"PSIQUE", "BRONZE", "ZEPLIM", "QUARTA", "POLAR", "OXIGENIO",
	"QUARK", "BLOCO", "EXAME", "BOXE", "FLUXO", "ZINCO", "PULSO"
]

# Termos Espaciais Avançados (Fase 6+)
const WORDS_ADVANCED_SPACE: Array[String] = [
	"ASTRONAVE", "GALAXIA", "NEBULOSA", "VELOCIDADE", "CONSTELACAO", "PROPULSOR",
	"HORIZONTE", "SUPERNOVA", "TELEMETRIA", "EXPEDICAO", "ATMOSFERA", "ANDROMEDA",
	"QUANTICA", "INTERSTELAR", "MAGNETISMO", "HIPERESPACO", "ASTROFISICA", "EXOPLANETA",
	"DESINTEGRADOR", "TRANSMISSAO", "SINGULARIDADE", "ANTIMATERIA", "ESTRATOSFERA"
]

# Configurações Visuais por Fase (Cor do Inimigo e Escala)
const WAVE_VISUAL_CONFIG: Dictionary = {
	1: {"color": Color(0.25, 0.85, 1.0), "scale": 1.0, "name": "Ciano Elétrico"},     # Fase 1: Ciano
	2: {"color": Color(0.25, 1.0, 0.45), "scale": 1.0, "name": "Verde Esmeralda"},    # Fase 2: Verde
	3: {"color": Color(1.0, 0.75, 0.15), "scale": 1.05, "name": "Âmbar Solar"},        # Fase 3: Âmbar/Dourado
	4: {"color": Color(1.0, 0.28, 0.38), "scale": 1.35, "name": "Carmesim Pesado"},   # Fase 4: Carmesim/Cruzador Pesado
	5: {"color": Color(0.85, 0.35, 1.0), "scale": 1.15, "name": "Púrpura Cósmica"},   # Fase 5: Púrpura
	6: {"color": Color(1.0, 0.9, 0.25), "scale": 1.25, "name": "Overdrive Dourado"}   # Fase 6+: Ouro
}

# 10 Colunas Fixas para Associação Dedo-a-Tecla (Digitação às Cegas - Touch Typing)
# Arena de jogo: X de 0.0 a 820.0 (Centro = 410.0, onde fica a nave)
# Margem lateral: 50px de cada lado -> Área útil: 720px (10 colunas de 72px)
# Cada coluna representa diretamente o dedo correspondente:
const COLUMN_X_POSITIONS: Array[float] = [
	86.0,  # Col 0: Mindinho Esquerdo (Q, A, Z, 1)
	158.0, # Col 1: Anelar Esquerdo (W, S, X, 2)
	230.0, # Col 2: Médio Esquerdo (E, D, C, 3)
	302.0, # Col 3: Indicador Esquerdo Base (R, F, V, 4)
	374.0, # Col 4: Indicador Esquerdo Centro (T, G, B, 5)
	446.0, # Col 5: Indicador Direito Centro (Y, H, N, 6)
	518.0, # Col 6: Indicador Direito Base (U, J, M, 7)
	590.0, # Col 7: Médio Direito (I, K, ,, 8)
	662.0, # Col 8: Anelar Direito (O, L, ., 9)
	734.0  # Col 9: Mindinho Direito (P, Ç, ;, 0)
]

const COLUMN_FINGER_NAMES: Array[String] = [
	"Mindinho Esquerdo",
	"Anelar Esquerdo",
	"Médio Esquerdo",
	"Indicador Esquerdo Base",
	"Indicador Esquerdo Centro",
	"Indicador Direito Centro",
	"Indicador Direito Base",
	"Médio Direito",
	"Anelar Direito",
	"Mindinho Direito"
]

const KEY_TO_COLUMN_INDEX: Dictionary = {
	# Coluna 0: Mindinho Esquerdo
	"Q": 0, "A": 0, "Z": 0, "1": 0, "!": 0,
	# Coluna 1: Anelar Esquerdo
	"W": 1, "S": 1, "X": 1, "2": 1, "@": 1,
	# Coluna 2: Médio Esquerdo
	"E": 2, "D": 2, "C": 2, "3": 2, "#": 2,
	# Coluna 3: Indicador Esquerdo Base
	"R": 3, "F": 3, "V": 3, "4": 3, "$": 3,
	# Coluna 4: Indicador Esquerdo Centro
	"T": 4, "G": 4, "B": 4, "5": 4, "%": 4,
	# Coluna 5: Indicador Direito Centro
	"Y": 5, "H": 5, "N": 5, "6": 5, "&": 5,
	# Coluna 6: Indicador Direito Base
	"U": 6, "J": 6, "M": 6, "7": 6, "*": 6,
	# Coluna 7: Médio Direito
	"I": 7, "K": 7, ",": 7, "8": 7, "<": 7,
	# Coluna 8: Anelar Direito
	"O": 8, "L": 8, ".": 8, "9": 8, ">": 8,
	# Coluna 9: Mindinho Direito
	"P": 9, "Ç": 9, ";": 9, "0": 9, ":": 9, "?": 9, "/": 9, "[": 9, "]": 9, "~": 9, "^": 9, "-": 9, "_": 9
}

const LEFT_HAND_X_MIN: float = 86.0
const LEFT_HAND_X_MAX: float = 374.0

const RIGHT_HAND_X_MIN: float = 446.0
const RIGHT_HAND_X_MAX: float = 734.0

static func get_column_for_key(k: String) -> int:
	var char_key: String = k.substr(0, 1).to_upper() if k.length() > 0 else ""
	if KEY_TO_COLUMN_INDEX.has(char_key):
		return KEY_TO_COLUMN_INDEX[char_key]
	return 3 if get_hand_for_key(char_key) == "E" else 6

static func get_x_for_column(col_idx: int) -> float:
	var idx: int = clampi(col_idx, 0, COLUMN_X_POSITIONS.size() - 1)
	return COLUMN_X_POSITIONS[idx]

static func get_x_for_key(k: String) -> float:
	return get_x_for_column(get_column_for_key(k))

static func get_finger_name_for_key(k: String) -> String:
	var col: int = get_column_for_key(k)
	return COLUMN_FINGER_NAMES[col]

static func get_hand_for_key(k: String) -> String:
	var left_keys: Array[String] = ["Q", "W", "E", "R", "T", "A", "S", "D", "F", "G", "Z", "X", "C", "V", "B", "1", "2", "3", "4", "5"]
	if left_keys.has(k.to_upper()):
		return "E"
	return "D"

static func get_visual_config_for_wave(wave: int) -> Dictionary:
	if WAVE_VISUAL_CONFIG.has(wave):
		return WAVE_VISUAL_CONFIG[wave]
	return WAVE_VISUAL_CONFIG[6]

static func generate_wave_queue(wave: int) -> Array[Dictionary]:
	var queue: Array[Dictionary] = []
	var cfg: Dictionary = get_visual_config_for_wave(wave)
	var tint_col: Color = cfg["color"]
	var scale_val: float = cfg["scale"]
	
	match wave:
		1:
			# FASE 1: 300 inimigos totais
			# Parte 1 (200 inimigos em 5 seções de 40 teclas): 40 teclas seguidas de cada par (F-J, G-H, D-K, S-L, A-Ç)
			for sec_idx in range(PAIRS_HOME_ROW.size()):
				var pair: Dictionary = PAIRS_HOME_ROW[sec_idx]
				var sec_id: int = sec_idx + 1
				for i in range(20):
					queue.append(_create_enemy_data(pair["left"], "E", pair["name"], tint_col, scale_val, -1.0, sec_id))
					queue.append(_create_enemy_data(pair["right"], "D", pair["name"], tint_col, scale_val, -1.0, sec_id))
			# Parte 2 (100 inimigos): Sequência final de todas as teclas da Linha de Base (Seção 6)
			for round_idx in range(10):
				for pair in PAIRS_HOME_ROW:
					queue.append(_create_enemy_data(pair["left"], "E", "LINHA DE BASE", tint_col, scale_val, -1.0, 6))
					queue.append(_create_enemy_data(pair["right"], "D", "LINHA DE BASE", tint_col, scale_val, -1.0, 6))
					
		2:
			# FASE 2: 300 inimigos totais
			# Parte 1 (200 inimigos em 5 seções de 40 teclas): 40 teclas seguidas de cada par da Linha Superior (R-U, T-Y, E-I, W-O, Q-P)
			for sec_idx in range(PAIRS_UPPER_ROW.size()):
				var pair: Dictionary = PAIRS_UPPER_ROW[sec_idx]
				var sec_id: int = sec_idx + 1
				for i in range(20):
					queue.append(_create_enemy_data(pair["left"], "E", pair["name"], tint_col, scale_val, -1.0, sec_id))
					queue.append(_create_enemy_data(pair["right"], "D", pair["name"], tint_col, scale_val, -1.0, sec_id))
			# Parte 2 (100 inimigos): Sequência final de todas as teclas da Linha Superior (Seção 6)
			for round_idx in range(10):
				for pair in PAIRS_UPPER_ROW:
					queue.append(_create_enemy_data(pair["left"], "E", "LINHA SUPERIOR", tint_col, scale_val, -1.0, 6))
					queue.append(_create_enemy_data(pair["right"], "D", "LINHA SUPERIOR", tint_col, scale_val, -1.0, 6))
					
		3:
			# FASE 3: 300 inimigos totais
			# Parte 1 (200 inimigos em 5 seções de 40 teclas): 40 teclas seguidas de cada par da Linha Inferior (B-N, V-M, C-, X-., Z-;)
			for sec_idx in range(PAIRS_LOWER_ROW.size()):
				var pair: Dictionary = PAIRS_LOWER_ROW[sec_idx]
				var sec_id: int = sec_idx + 1
				for i in range(20):
					queue.append(_create_enemy_data(pair["left"], "E", pair["name"], tint_col, scale_val, -1.0, sec_id))
					queue.append(_create_enemy_data(pair["right"], "D", pair["name"], tint_col, scale_val, -1.0, sec_id))
			# Parte 2 (100 inimigos): Sequência final de todas as teclas da Linha Inferior (Seção 6)
			for round_idx in range(10):
				for pair in PAIRS_LOWER_ROW:
					queue.append(_create_enemy_data(pair["left"], "E", "LINHA INFERIOR", tint_col, scale_val, -1.0, 6))
					queue.append(_create_enemy_data(pair["right"], "D", "LINHA INFERIOR", tint_col, scale_val, -1.0, 6))
					
		4:
			# FASE 4: 50 Cruzadores Pesados (Carmesim)
			# 1ª metade: 25 Cruzadores de 2 caracteres (2-HP) a 24.0 px/s (mais lentos que fases 1-3)
			for i in range(25):
				var word: String = WORDS_HEAVY_2CHAR[i % WORDS_HEAVY_2CHAR.size()]
				var hand: String = get_hand_for_key(word.substr(0, 1))
				queue.append(_create_enemy_data(word, hand, "CRUZADOR 2-HP", tint_col, 1.35, 24.0))
				
			# 2ª metade: 25 Cruzadores de 3 caracteres (3-HP) ainda mais lentos a 19.0 px/s
			for i in range(25):
				var word: String = WORDS_HEAVY_3CHAR[i % WORDS_HEAVY_3CHAR.size()]
				var hand: String = get_hand_for_key(word.substr(0, 1))
				queue.append(_create_enemy_data(word, hand, "CRUZADOR 3-HP", tint_col, 1.45, 19.0))
				
		5:
			# FASE 5: 18 palavras de Alcance Difícil (Púrpura) - quantidade reduzida e mais lentos (19.0 px/s)
			for i in range(18):
				var word: String = WORDS_DIFFICULT_STRETCH[i % WORDS_DIFFICULT_STRETCH.size()]
				var hand: String = get_hand_for_key(word.substr(0, 1))
				queue.append(_create_enemy_data(word, hand, "ALCANCE", tint_col, scale_val, 19.0))
				
		_:
			# FASE 6+: Horda Mista Cósmica - Spawns misturados entre todas as opções anteriores
			# Combina:
			# 1) Teclas da Linha de Base (Fase 1 - Ciano, 1 letra, 32.0 px/s)
			# 2) Teclas da Linha Superior (Fase 2 - Verde, 1 letra, 35.0 px/s)
			# 3) Linha Inferior com Pontuação (Fase 3 - Âmbar, 1 char, 33.0 px/s)
			# 4) Cruzadores Pesados 2-HP (Fase 4 - Carmesim, 2 letras, 24.0 px/s)
			# 5) Cruzadores Pesados 3-HP (Fase 4 - Carmesim, 3 letras, 19.0 px/s)
			# 6) Palavras de Alcance Difícil (Fase 5 - Púrpura, 5-8 letras, 19.0 px/s)
			# 7) Termos Cósmicos Avançados (Fase 6 - Dourado, 8-14 letras, 16.0 px/s)
			var col_base: Color = WAVE_VISUAL_CONFIG[1]["color"]
			var col_upper: Color = WAVE_VISUAL_CONFIG[2]["color"]
			var col_lower: Color = WAVE_VISUAL_CONFIG[3]["color"]
			var col_cruiser: Color = WAVE_VISUAL_CONFIG[4]["color"]
			var col_stretch: Color = WAVE_VISUAL_CONFIG[5]["color"]
			var col_cosmic: Color = WAVE_VISUAL_CONFIG[6]["color"]
			
			var count_per_type: int = 5 + (wave - 6)
			
			# 1. Linha de Base
			for i in range(count_per_type):
				var p: Dictionary = PAIRS_HOME_ROW[i % PAIRS_HOME_ROW.size()]
				var key_char: String = p["left"] if i % 2 == 0 else p["right"]
				var h: String = "E" if i % 2 == 0 else "D"
				queue.append(_create_enemy_data(key_char, h, "BASE", col_base, 1.0, 32.0))
				
			# 2. Linha Superior
			for i in range(count_per_type):
				var p: Dictionary = PAIRS_UPPER_ROW[i % PAIRS_UPPER_ROW.size()]
				var key_char: String = p["left"] if i % 2 == 0 else p["right"]
				var h: String = "E" if i % 2 == 0 else "D"
				queue.append(_create_enemy_data(key_char, h, "SUPERIOR", col_upper, 1.0, 35.0))
				
			# 3. Linha Inferior (incluindo pontuação , . ;)
			for i in range(count_per_type):
				var p: Dictionary = PAIRS_LOWER_ROW[i % PAIRS_LOWER_ROW.size()]
				var key_char: String = p["left"] if i % 2 == 0 else p["right"]
				var h: String = "E" if i % 2 == 0 else "D"
				queue.append(_create_enemy_data(key_char, h, p["name"], col_lower, 1.05, 33.0))
				
			# 4. Cruzadores 2-HP
			for i in range(count_per_type):
				var word: String = WORDS_HEAVY_2CHAR[i % WORDS_HEAVY_2CHAR.size()]
				var h: String = get_hand_for_key(word.substr(0, 1))
				queue.append(_create_enemy_data(word, h, "CRUZADOR 2-HP", col_cruiser, 1.35, 24.0))
				
			# 5. Cruzadores 3-HP
			for i in range(count_per_type):
				var word: String = WORDS_HEAVY_3CHAR[i % WORDS_HEAVY_3CHAR.size()]
				var h: String = get_hand_for_key(word.substr(0, 1))
				queue.append(_create_enemy_data(word, h, "CRUZADOR 3-HP", col_cruiser, 1.45, 19.0))
				
			# 6. Palavras de Alcance Difícil
			for i in range(count_per_type):
				var word: String = WORDS_DIFFICULT_STRETCH[i % WORDS_DIFFICULT_STRETCH.size()]
				var h: String = get_hand_for_key(word.substr(0, 1))
				queue.append(_create_enemy_data(word, h, "ALCANCE", col_stretch, 1.15, 19.0))
				
			# 7. Palavras Cósmicas Avançadas
			for i in range(count_per_type):
				var word: String = WORDS_ADVANCED_SPACE[i % WORDS_ADVANCED_SPACE.size()]
				var h: String = get_hand_for_key(word.substr(0, 1))
				queue.append(_create_enemy_data(word, h, "AVANÇADA", col_cosmic, 1.25, 16.0))
				
			# Embaralhar para garantir spawns heterogêneos e misturados
			queue.shuffle()
				
	return queue

static func _create_enemy_data(word_str: String, hand: String, tag: String, col: Color, sc: float, spd: float = -1.0, sec_id: int = 1) -> Dictionary:
	var first_char: String = word_str.substr(0, 1).to_upper()
	var col_idx: int = get_column_for_key(first_char)
	var spawn_x: float = get_x_for_column(col_idx)
	var finger_name: String = get_finger_name_for_key(first_char)
	var data: Dictionary = {
		"word": word_str,
		"hand": hand,
		"tag": tag,
		"column_index": col_idx,
		"finger_name": finger_name,
		"spawn_x": spawn_x,
		"color": col,
		"scale": sc,
		"section_id": sec_id
	}
	if spd > 0.0:
		data["speed"] = spd
	return data

static func get_word_for_wave(wave: int = 1, _exclude_initials: Array[String] = []) -> Dictionary:
	var q: Array[Dictionary] = generate_wave_queue(wave)
	if q.size() > 0:
		return q[randi() % q.size()]
	return {"word": "F", "tag": "BASE", "hand": "E", "column_index": 3, "finger_name": "Indicador Esquerdo Base", "spawn_x": 302.0, "color": Color.WHITE, "scale": 1.0}

static func get_random_word(wave: int = 1, _exclude_initials: Array[String] = []) -> String:
	var res: Dictionary = get_word_for_wave(wave)
	return res["word"]
