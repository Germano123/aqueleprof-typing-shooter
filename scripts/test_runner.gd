extends SceneTree

# TestRunner - Script automatizado para testar cadência de 150ms, spawn gamificado e KPIs

func _init() -> void:
	var snd_mgr = load("res://scripts/sound_manager.gd").new()
	snd_mgr.name = "SoundManager"
	root.add_child(snd_mgr)
	
	var score_mgr = load("res://scripts/score_manager.gd").new()
	score_mgr.name = "ScoreManager"
	root.add_child(score_mgr)

	print("--- INICIANDO TESTES DE CADÊNCIA ALVO DE 150MS, DDA, ONDAS PEDAGÓGICAS E GAME OVER ---")
	test_target_cadence_wave4()
	test_wave_colors_and_content()
	test_wave_1_2_3_ordered_pairs_and_sequence()
	test_section_transitions_and_flow_reset()
	test_ten_fixed_columns_finger_mapping()
	test_wave_3_lower_row_pairs()
	test_wave_4_heavy_cruisers()
	test_wave_5_long_words_pacing()
	test_wave_6_mixed_spawns()
	test_sound_manager()
	test_dynamic_difficulty_adjustment()
	test_game_over_enemy_stop()
	print("--- TODOS OS TESTES PASSARAM COM SUCESSO! ---")
	quit(0)

func test_target_cadence_wave4() -> void:
	print("[TEST] Meta de Cadência de 150ms para Fase 4+...")
	var tm := TypingMetrics.new()
	tm.start_session()
	
	# Fase 1 tem meta inicial
	tm.start_wave(1)
	assert(tm.get_target_cadence_ms() == 220.0, "Meta inicial Fase 1 = 220ms")
	
	# Fase 4 tem meta estrita de 150ms
	tm.start_wave(4)
	assert(tm.get_target_cadence_ms() == 150.0, "Meta Fase 4 deve ser exatamente 150ms")
	
	var kpis: Dictionary = tm.get_wave_kpis()
	assert(kpis["target_interval_ms"] == 150.0, "KPI da Fase 4 deve registrar meta de 150ms")
	print("  ✓ Meta de cadência de 150ms para Fase 4+ validada.")

func test_wave_colors_and_content() -> void:
	print("[TEST] Cores e Configurações por Fase...")
	var q1: Array[Dictionary] = WordManager.generate_wave_queue(1)
	assert(q1[0]["color"] == Color(0.25, 0.85, 1.0), "Fase 1 deve ser Ciano Elétrico")
	
	var q2: Array[Dictionary] = WordManager.generate_wave_queue(2)
	assert(q2[0]["color"] == Color(0.2, 0.95, 0.9), "Fase 2 deve ser Ciano Centro")
	
	var q19: Array[Dictionary] = WordManager.generate_wave_queue(19)
	assert(q19[0]["color"] == Color(1.0, 0.28, 0.38), "Fase 19 deve ser Carmesim Pesado")
	assert(q19[0]["scale"] == 1.35, "Fase 19 deve ter escala ampliada 1.35x")
	print("  ✓ Cores e escalas por fase validadas.")

func test_wave_1_2_3_ordered_pairs_and_sequence() -> void:
	print("[TEST] Progressão de Fases com Adição Gradual de Letras (Fases 1 a 6)...")
	
	# FASE 1: 40 inimigos com o par F e J
	var q1: Array[Dictionary] = WordManager.generate_wave_queue(1)
	assert(q1.size() == 40, "Fase 1 deve ter exatamente 40 inimigos")
	for item in q1:
		var w = item["word"]
		assert(w == "F" or w == "J", "Fase 1 deve conter apenas F e J")
		
	# FASE 2: 40 inimigos introduzindo G e H
	var q2: Array[Dictionary] = WordManager.generate_wave_queue(2)
	assert(q2.size() == 40, "Fase 2 deve ter exatamente 40 inimigos")
	var count_gh: int = 0
	for item in q2:
		var w = item["word"]
		if w == "G" or w == "H":
			count_gh += 1
	assert(count_gh >= 24, "Fase 2 deve focar na introdução dos novos inimigos G e H")
	
	# FASE 3: 40 inimigos introduzindo D e K
	var q3: Array[Dictionary] = WordManager.generate_wave_queue(3)
	assert(q3.size() == 40, "Fase 3 deve ter exatamente 40 inimigos")
	var count_dk: int = 0
	for item in q3:
		var w = item["word"]
		if w == "D" or w == "K":
			count_dk += 1
	assert(count_dk >= 24, "Fase 3 deve focar na introdução dos dedos médios D e K")
	
	# FASE 4: 40 inimigos introduzindo S e L
	var q4: Array[Dictionary] = WordManager.generate_wave_queue(4)
	assert(q4.size() == 40, "Fase 4 deve ter exatamente 40 inimigos")
	var count_sl: int = 0
	for item in q4:
		var w = item["word"]
		if w == "S" or w == "L":
			count_sl += 1
	assert(count_sl >= 24, "Fase 4 deve focar na introdução dos dedos anelares S e L")
	
	# FASE 5: 40 inimigos introduzindo A e Ç
	var q5: Array[Dictionary] = WordManager.generate_wave_queue(5)
	assert(q5.size() == 40, "Fase 5 deve ter exatamente 40 inimigos")
	var count_ac: int = 0
	for item in q5:
		var w = item["word"]
		if w == "A" or w == "Ç":
			count_ac += 1
	assert(count_ac >= 24, "Fase 5 deve focar na introdução dos dedos mínimos A e Ç")
	
	# FASE 6: 60 inimigos (Home Row Master - todas as 10 teclas)
	var q6: Array[Dictionary] = WordManager.generate_wave_queue(6)
	assert(q6.size() == 60, "Fase 6 deve ter 60 inimigos de consolidação da Linha de Base")
	
	print("  ✓ Progressão fase a fase com adição gradual de inimigos validada com sucesso.")

func test_section_transitions_and_flow_reset() -> void:
	print("[TEST] Transições de Ritmo e Reset de Fluxo...")
	var tm := TypingMetrics.new()
	tm.start_session()
	for i in range(25):
		tm.register_keystroke("F", true)
	assert(tm.current_perfect_streak == 25, "Streak acelerada")
	assert(tm.get_flow_state_name() == "ACELERADO", "Estado acelerado antes da troca")
	
	# Reset ao trocar de fase
	tm.reset_flow_rhythm()
	assert(tm.current_perfect_streak == 0, "Streak resetada para digitação consciente")
	assert(tm.get_flow_state_name() == "EQUILIBRADO", "Ritmo normalizado na troca de seção/fase")
	print("  ✓ Reset de fluxo validado com sucesso.")

func test_ten_fixed_columns_finger_mapping() -> void:
	print("[TEST] Sistema de 10 Colunas Fixas para Associação Dedo-a-Tecla...")
	# 1. 10 Colunas configuradas
	assert(WordManager.COLUMN_X_POSITIONS.size() == 10, "Devem existir exatamente 10 colunas fixas")
	assert(WordManager.COLUMN_FINGER_NAMES.size() == 10, "Devem existir 10 nomes de dedos correspondentes")
	
	# 2. Ordem crescente e limites dentro da arena de 820px
	for i in range(10):
		var x: float = WordManager.COLUMN_X_POSITIONS[i]
		assert(x > 50.0 and x < 770.0, "Coordenada X da coluna deve estar dentro da área de jogo com margens seguras")
		if i > 0:
			assert(WordManager.COLUMN_X_POSITIONS[i] > WordManager.COLUMN_X_POSITIONS[i - 1], "Colunas devem ser ordenadas da esquerda para a direita")
	
	# 3. Simetria central perfeita (410.0 é o centro da arena e nave)
	var mid_hands: float = (WordManager.COLUMN_X_POSITIONS[4] + WordManager.COLUMN_X_POSITIONS[5]) / 2.0
	assert(is_equal_approx(mid_hands, 410.0), "Ponto médio entre Mão Esquerda (Col 4) e Direita (Col 5) deve ser 410.0")
	
	# 4. Linha de Base (Home Row)
	assert(WordManager.get_column_for_key("A") == 0, "A deve mapear para Coluna 0 (Mindinho Esquerdo)")
	assert(WordManager.get_column_for_key("S") == 1, "S deve mapear para Coluna 1 (Anelar Esquerdo)")
	assert(WordManager.get_column_for_key("D") == 2, "D deve mapear para Coluna 2 (Médio Esquerdo)")
	assert(WordManager.get_column_for_key("F") == 3, "F deve mapear para Coluna 3 (Indicador Esquerdo Base)")
	assert(WordManager.get_column_for_key("G") == 4, "G deve mapear para Coluna 4 (Indicador Esquerdo Centro)")
	assert(WordManager.get_column_for_key("H") == 5, "H deve mapear para Coluna 5 (Indicador Direito Centro)")
	assert(WordManager.get_column_for_key("J") == 6, "J deve mapear para Coluna 6 (Indicador Direito Base)")
	assert(WordManager.get_column_for_key("K") == 7, "K deve mapear para Coluna 7 (Médio Direito)")
	assert(WordManager.get_column_for_key("L") == 8, "L deve mapear para Coluna 8 (Anelar Direito)")
	assert(WordManager.get_column_for_key("Ç") == 9, "Ç deve mapear para Coluna 9 (Mindinho Direito)")
	
	# 5. Linha Superior
	assert(WordManager.get_column_for_key("Q") == 0, "Q -> Col 0")
	assert(WordManager.get_column_for_key("W") == 1, "W -> Col 1")
	assert(WordManager.get_column_for_key("E") == 2, "E -> Col 2")
	assert(WordManager.get_column_for_key("R") == 3, "R -> Col 3")
	assert(WordManager.get_column_for_key("T") == 4, "T -> Col 4")
	assert(WordManager.get_column_for_key("Y") == 5, "Y -> Col 5")
	assert(WordManager.get_column_for_key("U") == 6, "U -> Col 6")
	assert(WordManager.get_column_for_key("I") == 7, "I -> Col 7")
	assert(WordManager.get_column_for_key("O") == 8, "O -> Col 8")
	assert(WordManager.get_column_for_key("P") == 9, "P -> Col 9")
	
	# 6. Linha Inferior com pontuação
	assert(WordManager.get_column_for_key("Z") == 0, "Z -> Col 0")
	assert(WordManager.get_column_for_key("X") == 1, "X -> Col 1")
	assert(WordManager.get_column_for_key("C") == 2, "C -> Col 2")
	assert(WordManager.get_column_for_key("V") == 3, "V -> Col 3")
	assert(WordManager.get_column_for_key("B") == 4, "B -> Col 4")
	assert(WordManager.get_column_for_key("N") == 5, "N -> Col 5")
	assert(WordManager.get_column_for_key("M") == 6, "M -> Col 6")
	assert(WordManager.get_column_for_key(",") == 7, ", -> Col 7")
	assert(WordManager.get_column_for_key(".") == 8, ". -> Col 8")
	assert(WordManager.get_column_for_key(";") == 9, "; -> Col 9")
	
	# 7. Palavras e Cruzadores Multi-HP: primeira letra determina a coluna
	assert(WordManager.get_x_for_key("FA") == WordManager.COLUMN_X_POSITIONS[3], "Palavra 'FA' deve descer na Coluna 3 (F)")
	assert(WordManager.get_x_for_key("SOL") == WordManager.COLUMN_X_POSITIONS[1], "Palavra 'SOL' deve descer na Coluna 1 (S)")
	assert(WordManager.get_x_for_key("LUA") == WordManager.COLUMN_X_POSITIONS[8], "Palavra 'LUA' deve descer na Coluna 8 (L)")
	
	# 8. Verificação nas filas de ondas geradas
	var q1: Array[Dictionary] = WordManager.generate_wave_queue(1)
	for item in q1:
		var expected_col: int = WordManager.get_column_for_key(item["word"])
		var expected_x: float = WordManager.COLUMN_X_POSITIONS[expected_col]
		assert(item["column_index"] == expected_col, "item column_index deve coincidir com tecla")
		assert(is_equal_approx(item["spawn_x"], expected_x), "item spawn_x deve coincidir com coluna fixa")
		
	print("  ✓ Mapeamento das 10 colunas fixas e associação dedo-tecla validada com sucesso.")

func test_wave_3_lower_row_pairs() -> void:
	print("[TEST] Linha Inferior com Pontuação (B-N, V-M, C-, X-., Z-; na Fase 18 Master)...")
	var q18: Array[Dictionary] = WordManager.generate_wave_queue(18)
	assert(q18.size() == 60, "Fase 18 deve ter 60 itens no Master da Linha Inferior")
	
	var found_b: bool = false
	var found_v: bool = false
	var found_comma: bool = false
	var found_dot: bool = false
	var found_semi: bool = false
	
	for item in q18:
		var w: String = item["word"]
		if w == "B": found_b = true
		if w == "V": found_v = true
		if w == ",": found_comma = true
		if w == ".": found_dot = true
		if w == ";": found_semi = true
		
	assert(found_b and found_v and found_comma and found_dot and found_semi, "Todos os pares da linha inferior devem estar presentes")
	print("  ✓ Pares da Linha Inferior da Fase 18 validados.")

func test_wave_4_heavy_cruisers() -> void:
	print("[TEST] Fases 19 e 20: Cruzadores Pesados (2-HP e 3-HP)...")
	var q19: Array[Dictionary] = WordManager.generate_wave_queue(19)
	assert(q19.size() == 25, "Fase 19 deve ter 25 cruzadores 2-HP")
	for i in range(25):
		var item = q19[i]
		var w: String = item["word"]
		assert(w.length() == 2, "Fase 19 deve ter cruzadores de 2 caracteres")
		assert(item["scale"] == 1.35, "Escala 1.35x para cruzadores 2-HP")
		assert(item.get("speed", -1.0) == 24.0, "Velocidade de 24.0 px/s para cruzadores 2-HP")
		assert(item["tag"] == "CRUZADOR 2-HP", "Tag CRUZADOR 2-HP")
		
	var q20: Array[Dictionary] = WordManager.generate_wave_queue(20)
	assert(q20.size() == 25, "Fase 20 deve ter 25 cruzadores 3-HP")
	for i in range(25):
		var item = q20[i]
		var w: String = item["word"]
		assert(w.length() == 3, "Fase 20 deve ter cruzadores de 3 caracteres")
		assert(item["scale"] == 1.45, "Escala 1.45x para cruzadores 3-HP")
		assert(item.get("speed", -1.0) == 19.0, "Velocidade de 19.0 px/s para cruzadores 3-HP")
		assert(item["tag"] == "CRUZADOR 3-HP", "Tag CRUZADOR 3-HP")
	print("  ✓ Cruzadores pesados 2-HP e 3-HP das Fases 19 e 20 validados.")

func test_wave_5_long_words_pacing() -> void:
	print("[TEST] Fase 21: Palavras Longas com Quantidade Reduzida e Movimento Cadenciado...")
	var q21: Array[Dictionary] = WordManager.generate_wave_queue(21)
	assert(q21.size() == 18, "Fase 21 deve ter 18 alvos spawnados (quantidade reduzida)")
	for item in q21:
		var w: String = item["word"]
		assert(w.length() >= 4, "Palavras da Fase 21 devem ter >= 4 letras")
		assert(item.get("speed", -1.0) == 19.0, "Velocidade da Fase 21 reduzida para 19.0 px/s")
	print("  ✓ Pacing e redução de quantidade da Fase 21 validados.")

func test_wave_6_mixed_spawns() -> void:
	print("[TEST] Fase 22+: Spawns Misturados com Todas as Opções Anteriores...")
	var q22: Array[Dictionary] = WordManager.generate_wave_queue(22)
	assert(q22.size() == 35, "Fase 22 deve ter 35 alvos distribuídos em 7 categorias")
	
	var found_base: bool = false
	var found_upper: bool = false
	var found_lower: bool = false
	var found_cruiser2: bool = false
	var found_cruiser3: bool = false
	var found_stretch: bool = false
	var found_advanced: bool = false
	
	for item in q22:
		var tag: String = item["tag"]
		var w: String = item["word"]
		if tag == "BASE":
			found_base = true
			assert(w.length() == 1, "Base tem 1 tecla")
		elif tag == "SUPERIOR":
			found_upper = true
			assert(w.length() == 1, "Superior tem 1 tecla")
		elif tag.contains("Inferior"):
			found_lower = true
			assert(w.length() == 1, "Inferior tem 1 caractere")
		elif tag == "CRUZADOR 2-HP":
			found_cruiser2 = true
			assert(w.length() == 2, "Cruzador 2-HP tem 2 letras")
			assert(item.get("speed", -1.0) == 24.0, "Velocidade cruzador 2-HP = 24.0 px/s")
		elif tag == "CRUZADOR 3-HP":
			found_cruiser3 = true
			assert(w.length() == 3, "Cruzador 3-HP tem 3 letras")
			assert(item.get("speed", -1.0) == 19.0, "Velocidade cruzador 3-HP = 19.0 px/s")
		elif tag == "ALCANCE":
			found_stretch = true
			assert(w.length() >= 4, "Palavra alcance tem >= 4 letras")
		elif tag == "AVANÇADA":
			found_advanced = true
			assert(w.length() >= 7, "Palavra avançada tem >= 7 letras")
			assert(item.get("speed", -1.0) == 16.0, "Velocidade avançada = 16.0 px/s")
			
	assert(found_base, "Fase 22 deve conter alvos da Linha de Base")
	assert(found_upper, "Fase 22 deve conter alvos da Linha Superior")
	assert(found_lower, "Fase 22 deve conter alvos da Linha Inferior com pontuação")
	assert(found_cruiser2, "Fase 22 deve conter Cruzadores 2-HP")
	assert(found_cruiser3, "Fase 22 deve conter Cruzadores 3-HP")
	assert(found_stretch, "Fase 22 deve conter palavras de Alcance Difícil")
	assert(found_advanced, "Fase 22 deve conter termos cósmicos Avançados")
	
	# Validar escalabilidade em ondas superiores (ex: Fase 23)
	var q23: Array[Dictionary] = WordManager.generate_wave_queue(23)
	assert(q23.size() == 42, "Fase 23 deve ter 42 alvos (6 por categoria)")
	print("  ✓ Spawns misturados da Fase 22+ validados com sucesso.")

func test_enemy_word_visual_customization() -> void:
	print("[TEST] EnemyWord com Coloração, Escala e Foco à Frente (Z-Index 50)...")
	var enemy_scene: PackedScene = load("res://scenes/enemy_word.tscn")
	assert(enemy_scene != null, "enemy_word.tscn deve existir")
	var enemy: EnemyWord = enemy_scene.instantiate() as EnemyWord
	root.add_child(enemy)
	enemy.setup("FA", 22.0, Vector2(250, 100), 600.0, "CRUZADOR 2-HP", Color(1.0, 0.28, 0.38), 1.35)
	assert(enemy.full_word == "FA", "Palavra de 2 caracteres")
	assert(enemy.scale == Vector2(1.35, 1.35), "Escala do inimigo aplicada")
	assert(enemy.z_index == 6, "Inimigo normal inicia com z_index = 6")
	
	# Testar foco no inimigo (deve ir para a frente com z_index = 50)
	enemy.set_targeted(true)
	assert(enemy.is_targeted == true, "Inimigo marcado como focado")
	assert(enemy.z_index == 50, "Inimigo focado deve ter z_index = 50 para renderizar à frente dos demais")
	assert(enemy.panel.modulate == Color(1.35, 1.35, 1.45, 1.0), "Painel focado com brilho aumentado")
	assert(enemy.label.text.contains("#ffe042"), "Letra ativa focada em amarelo solar destacado")
	assert(enemy.label.text.contains("#ffffff"), "Letras restantes em branco puro de alto contraste")
	
	# Testar desativação do foco
	enemy.set_targeted(false)
	assert(enemy.is_targeted == false, "Inimigo desfocado")
	assert(enemy.z_index == 6, "z_index deve retornar a 6")
	assert(enemy.panel.modulate == Color.WHITE, "Painel retorna à modulação padrão")
	
	assert(enemy.typed_index == 0, "HP inicial")
	enemy.on_correct_letter()
	assert(enemy.typed_index == 1, "HP intermediário")
	enemy.on_correct_letter()
	assert(enemy.is_completed(), "Cruzador destruído")
	enemy.queue_free()
	print("  ✓ EnemyWord com foco à frente (Z-Index 50) e estilização validado.")

func test_sound_manager() -> void:
	print("[TEST] SoundManager...")
	var snd_script = load("res://scripts/sound_manager.gd")
	var snd_mgr = snd_script.new()
	snd_mgr._ready()
	assert(snd_mgr.sfx_laser != null, "SFX Laser gerado")
	assert(snd_mgr.sfx_comms != null, "SFX Comms gerado")
	
	# Testar Player scene
	var player_scene: PackedScene = load("res://scenes/player.tscn")
	var player_inst: Node = player_scene.instantiate()
	assert(player_inst.get_node_or_null("Sprite2D") != null, "Player Sprite2D deve existir")
	assert(player_inst.get_node_or_null("StyleHUD/StyleBar") != null, "Player StyleBar deve existir")
	assert(player_inst.get_node_or_null("StyleHUD/RankLabel") != null, "Player RankLabel deve existir")
	player_inst.free()
	
	# Testar EnemyWord scene
	var enemy_scene: PackedScene = load("res://scenes/enemy_word.tscn")
	var enemy_inst: Node = enemy_scene.instantiate()
	assert(enemy_inst.get_node_or_null("Container/RichTextLabel") != null, "EnemyWord RichTextLabel deve existir")
	assert(enemy_inst.get_node_or_null("Container/HealthBar") != null, "EnemyWord HealthBar deve existir")
	enemy_inst.free()
	
	print("  ✓ Todos os nós das cenas validados com sucesso.")

func test_debug_mode_f1() -> void:
	print("[TEST] Modo Debug F1 (Avançar Próxima Onda)...")
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	assert(game_scene != null, "game.tscn deve existir")
	var game_inst = game_scene.instantiate()
	assert(game_inst.has_method("_debug_advance_next_wave"), "game.gd deve possuir o método _debug_advance_next_wave")
	assert(game_inst.has_method("_input"), "game.gd deve capturar entrada via _input")
	game_inst.free()
	print("  ✓ Modo Debug F1 validado com sucesso.")

func test_enemy_density_and_spawn_pacing() -> void:
	print("[TEST] Densidade de Inimigos (Mínimo de 4 alvos e fluxo contínuo sem trava)...")
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	assert(game_scene != null, "game.tscn deve existir")
	var game_inst = game_scene.instantiate()
	
	# Validar piso mínimo garantido de 4 alvos
	assert(game_inst.get("MIN_ON_SCREEN_ENEMIES") == 4, "MIN_ON_SCREEN_ENEMIES deve ser exatamente 4 (piso mínimo)")
	
	# Validar que a quantidade não é limitada a 4 (limite superior expandido para fluxo contínuo)
	assert(game_inst.get("MAX_ON_SCREEN_ENEMIES") >= 10, "MAX_ON_SCREEN_ENEMIES deve ser >= 10 para permitir fluxo contínuo sem travar em 4")
	assert(game_inst.has_method("_maintain_enemy_density"), "_maintain_enemy_density deve existir")
	assert(game_inst.has_method("_get_active_enemy_count"), "_get_active_enemy_count deve existir")
	assert(game_inst.has_method("_on_spawn_timer_timeout"), "_on_spawn_timer_timeout deve existir")
	
	game_inst.free()
	print("  ✓ Densidade mínima de 4 e fluxo contínuo validados com sucesso.")

func test_computer_flight_assistant() -> void:
	print("[TEST] Computador de Bordo (Mensagens situacionais e dicas táticas)...")
	var panel_scene: PackedScene = load("res://scenes/typing_panel.tscn")
	assert(panel_scene != null, "typing_panel.tscn deve existir")
	var panel_inst: Node = panel_scene.instantiate()
	assert(panel_inst.has_method("set_computer_message"), "TypingPanel deve ter método set_computer_message")
	
	# Testar envio de mensagem prioritária
	panel_inst.set_computer_message("Alerta! Próxima horda está a caminho.", true)
	var computer_card: PanelContainer = panel_inst.get_node_or_null("MarginContainer/VBoxContainer/ComputerCard")
	var msg_label: Label = panel_inst.get_node_or_null("MarginContainer/VBoxContainer/ComputerCard/Margin/VBox/ComputerMsgLabel")
	var status_label: Label = panel_inst.get_node_or_null("MarginContainer/VBoxContainer/ComputerCard/Margin/VBox/TopRow/ComputerStatusLabel")
	assert(computer_card != null, "ComputerCard deve existir")
	assert(msg_label != null, "ComputerMsgLabel deve existir")
	assert(status_label != null, "ComputerStatusLabel deve existir")
	
	# Validar espaço ampliado do monitor
	assert(computer_card.custom_minimum_size.y >= 120.0, "ComputerCard deve ter altura de monitor >= 120px")
	assert(msg_label.custom_minimum_size.y >= 60.0, "ComputerMsgLabel deve ter espaço vertical para exibição de texto >= 60px")
	
	# Validar efeito letra a letra (Typewriter)
	assert(panel_inst.is_typewriting == true, "Typewriter deve iniciar ativo após nova transmissão")
	assert(msg_label.visible_characters == 0, "visible_characters deve iniciar em 0 para transmissão letra a letra")
	assert(msg_label.text.contains("Alerta! Próxima horda está a caminho."), "Texto deve conter mensagem de alerta")
	assert(status_label.text == "[ALERTA PRIORITÁRIO]", "Status deve ser [ALERTA PRIORITÁRIO]")
	
	# Simular progressão de tempo do teletype
	panel_inst._process(0.15)
	assert(msg_label.visible_characters > 0, "visible_characters deve avançar com o tempo")
	
	# Simular alternância do cursor no monitor durante o teletype (validação do fix de formatação do % de sinal)
	panel_inst._process(0.5)
	var signal_label: Label = panel_inst.get_node_or_null("MarginContainer/VBoxContainer/ComputerCard/Margin/VBox/BottomRow/MonitorSignalLabel")
	assert(signal_label != null, "MonitorSignalLabel deve existir")
	assert(signal_label.text.contains("SINAL: 99%"), "MonitorSignalLabel deve atualizar status com porcentagem sem erro de formato")
	
	# Simular conclusão da transmissão
	panel_inst._process(3.0)
	assert(panel_inst.is_typewriting == false, "Typewriter deve finalizar após transmissão completa")
	assert(msg_label.visible_characters == -1, "visible_characters deve ser -1 ao finalizar")
	
	# Testar envio de nova mensagem com tempo de espera para leitura (Fila/Buffer)
	panel_inst.set_computer_message("Alternar entre os canhões ganha mais pontos.", false)
	assert(panel_inst.message_queue.size() == 1, "Nova mensagem deve aguardar na fila enquanto a anterior é lida")
	assert(msg_label.text.contains("Alerta! Próxima horda está a caminho."), "Mensagem anterior deve continuar visível para leitura")
	
	# Simular passagem do tempo de leitura (MIN_READ_TIME = 3.5s)
	panel_inst._process(4.0)
	assert(panel_inst.message_queue.is_empty(), "Fila deve ser processada e esvaziada após o tempo de leitura")
	assert(msg_label.text.contains("Alternar entre os canhões ganha mais pontos."), "Texto deve carregar a próxima mensagem da fila")
	assert(status_label.text == "[TRANSMISSÃO TÁTICA]", "Status deve atualizar para [TRANSMISSÃO TÁTICA]")
	
	panel_inst.free()
	
	# Validar constantes e mensagens do game.gd
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game_inst = game_scene.instantiate()
	assert(game_inst.get("COMPUTER_TIPS") != null, "game.gd deve ter COMPUTER_TIPS")
	var tips: Array = game_inst.get("COMPUTER_TIPS")
	assert(tips.has("Alerta! Próxima horda está a caminho."), "COMPUTER_TIPS deve conter alerta de horda")
	assert(tips.has("Inimigos mais fortes já estão na linha de frente."), "COMPUTER_TIPS deve conter alerta de inimigos mais fortes")
	assert(tips.has("Para disparos mais fortes você precisa manter seu ritmo constante."), "COMPUTER_TIPS deve conter dica de ritmo")
	assert(tips.has("Alternar entre os canhões ganha mais pontos."), "COMPUTER_TIPS deve conter dica de alternar canhões")
	assert(game_inst.has_method("_dispatch_computer_tip"), "_dispatch_computer_tip deve existir em game.gd")
	game_inst.free()
	
	print("  ✓ Computador de Bordo e mensagens situacionais validadas com sucesso.")

func test_dynamic_difficulty_adjustment() -> void:
	print("[TEST] Dificuldade Adaptativa (DDA) baseada no ritmo e sequência de digitação...")
	var tm := TypingMetrics.new()
	tm.start_session()
	
	# Estado inicial deve ser equilibrado (1x spawn, base cap 8)
	assert(tm.get_flow_spawn_multiplier() == 1.0, "Multiplicador inicial deve ser 1.0x")
	assert(tm.get_flow_state_name() == "EQUILIBRADO", "Estado inicial deve ser EQUILIBRADO")
	assert(tm.get_flow_spawn_batch_count() == 1, "Em estado equilibrado deve spawnar 1 inimigo por vez")
	assert(tm.get_flow_max_active_enemies(8) == 8, "Capacidade padrão mantida em 8")
	
	# Simular 10 acertos consecutivos (Streak 10)
	for i in range(10):
		tm.register_keystroke("A", true)
	assert(tm.current_perfect_streak == 10, "Streak deve ser 10")
	assert(tm.get_flow_spawn_multiplier() == 0.85, "Streak 10 deve acelerar spawn para 0.85x")
	assert(tm.get_flow_state_name() == "RITMO ELEVADO", "Estado deve ser RITMO ELEVADO")
	
	# Simular mais 10 acertos consecutivos (Streak 20)
	for i in range(10):
		tm.register_keystroke("S", true)
	assert(tm.current_perfect_streak == 20, "Streak deve ser 20")
	assert(tm.get_flow_spawn_multiplier() == 0.75, "Streak 20 deve acelerar spawn para 0.75x")
	assert(tm.get_flow_state_name() == "ACELERADO", "Estado deve ser ACELERADO")
	assert(tm.get_flow_spawn_batch_count() == 2, "Em estado acelerado deve spawnar 2 inimigos simultâneos")
	assert(tm.get_flow_max_active_enemies(8) == 10, "Capacidade máxima em tela expandida para 10")
	
	# Simular mais 20 acertos em ritmo alto para atingir Rank S/SS e Streak 40
	for i in range(20):
		tm.register_keystroke("D", true)
	assert(tm.current_perfect_streak >= 35, "Streak deve ser >= 35")
	assert(tm.style_points >= 75.0, "Pontos de estilo elevados")
	assert(tm.get_flow_spawn_multiplier() == 0.60, "Streak 35+ com rank alto deve ativar Frenesi a 0.60x")
	assert(tm.get_flow_state_name() == "FRENESI", "Estado deve ser FRENESI")
	assert(tm.get_flow_spawn_batch_count() == 3, "Em Frenesi deve spawnar enxame de 3 inimigos simultâneos")
	assert(tm.get_flow_max_active_enemies(8) == 12, "Capacidade máxima em tela expandida para 12")
	
	# Simular 1 erro de tecla
	var error_res = tm.register_keystroke("Z", false)
	assert(tm.current_perfect_streak == 0, "Streak zerada após erro")
	assert(tm.consecutive_errors == 1, "1 erro consecutivo registrado")
	assert(tm.get_flow_spawn_multiplier() == 1.30, "Erro deve desacelerar spawn para 1.30x (Modo Recuperação)")
	assert(tm.get_flow_state_name() == "RECUPERAÇÃO", "Estado deve ser RECUPERAÇÃO")
	assert(tm.get_flow_spawn_batch_count() == 1, "No modo recuperação deve spawnar estritamente 1 inimigo por vez")
	assert(tm.get_flow_max_active_enemies(8) == 6, "Capacidade máxima em tela reduzida para 6 para dar respiro")
	assert(error_res["flow_state"] == "RECUPERAÇÃO", "Dicionário de retorno deve incluir flow_state RECUPERAÇÃO")
	assert(error_res["flow_multiplier"] == 1.30, "Dicionário de retorno deve incluir flow_multiplier 1.30")
	
	# Simular início de recuperação com 3 acertos
	for i in range(3):
		tm.register_keystroke("F", true)
	assert(tm.consecutive_errors == 0, "Erros consecutivos zerados")
	assert(tm.get_flow_spawn_multiplier() == 1.0, "Multiplicador deve retornar a 1.0x na transição de recuperação")
	assert(tm.get_flow_state_name() == "EQUILIBRADO", "Estado retorna a EQUILIBRADO")
	assert(tm.get_flow_spawn_batch_count() == 1, "Quantidade volta a 1 no equilíbrio")
	
	print("  ✓ Dificuldade Adaptativa (DDA) com escalonamento de quantidade validada com sucesso.")

func test_game_over_enemy_stop() -> void:
	print("[TEST] Parada e congelamento dos inimigos no Game Over...")
	var enemy_scene: PackedScene = load("res://scenes/enemy_word.tscn")
	assert(enemy_scene != null, "enemy_word.tscn deve existir")
	var enemy: EnemyWord = enemy_scene.instantiate() as EnemyWord
	enemy.setup("TESTE", 50.0, Vector2(200, 100), 600.0)
	
	assert(enemy.is_active == true, "Inimigo deve iniciar ativo")
	var initial_pos: Vector2 = enemy.global_position
	
	# Chamar stop() como ocorre no game over
	enemy.stop()
	assert(enemy.is_active == false, "Inimigo deve estar inativo após stop()")
	
	# Chamar _process simulando passagem de 1 segundo de tempo
	enemy._process(1.0)
	assert(enemy.global_position == initial_pos, "Inimigo inativo não deve se mover após stop()")
	
	enemy.free()
	print("  ✓ Congelamento de inimigos no Game Over validado com sucesso.")



