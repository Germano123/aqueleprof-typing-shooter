# Changelog

Todas as alterações notáveis deste projeto serão documentadas neste arquivo.

O formato baseia-se em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/) e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

---

## [1.4.0] - 2026-11-09

### Adicionado
- **Sistema de Balanceamento e Dificuldade com Arquivo JSON**:
  - Criação do arquivo `difficulty_balance.json` na raiz do projeto contendo as regras de velocidade (`velocidade_queda`), quantidade de tropas (`quantidade_inimigos`) e intervalos de surgimento (`intervalo_spawn`) para todas as 22+ fases, além de multiplicadores globais e presets.
- **Gerenciador Global `DifficultyManager` (Autoload)**:
  - Carregamento e sincronização automática das regras de balanceamento.
  - **Suporte Multiplataforma Inteligente**:
    - **Desktop**: Salva customizações em `user://difficulty_balance.json` e atualiza o arquivo da raiz durante a execução pelo editor.
    - **Web**: Opera em modo somente-leitura/sessão (`is_web = true`), mantendo ajustes na memória da aba ativa e resetando aos valores originais ao recarregar o jogo.
  - Métodos utilitários de consulta (`get_enemy_count`, `get_fall_speed`, `get_spawn_interval`), aplicação de presets (`facil`, `normal`, `dificil`) e restauração para os padrões.
- **Tela de Configurações no Menu Principal (`MainMenu`)**:
  - Modal interativo com dropdown para seleção de fase individual ou multiplicador global.
  - Botões de presets rápidos (*Fácil 0.8x*, *Normal 1.0x*, *Difícil 1.25x*).
  - Sliders com exibição numérica em tempo real para velocidade, quantidade de inimigos e intervalo de spawn.
  - Indicador visual da plataforma em execução (Desktop com gravação local vs Web com reset automático).
- **Integração Dinâmica em `WordManager` e `Game`**:
  - A geração procedural de filas em `WordManager.generate_wave_queue` e o fluxo de combate em `Game._start_wave_sequence` adaptam-se instantaneamente às regras ativas de balanceamento mantendo as proporções pedagógicas de novos alvos e fixação.
- **Suíte de Testes Automatizada**:
  - Testes unitários em `scripts/test_runner.gd` cobrindo o ciclo de vida do `DifficultyManager`, leitura do JSON, presets, modificadores, reset e modo Web.

---

## [1.3.0] - 2026-11-09

### Adicionado
- **Arquitetura de Fases Modulares por Introdução de Teclas**:
  - Transformação de cada etapa de aprendizado em uma fase independente completa (~40 a 60 inimigos por onda, com duração ágil de ~1-2 min).
  - Loop de feedback positivo acelerado: telas de vitória e KPIs ao final de cada par introduzido, gerando sensação imediata de conquista e evolução.
  - **Fases 1 a 6 (Linha de Base)**:
    - Fase 1: Par `F - J` (40 inimigos)
    - Fase 2: Novos `G - H` (40 inimigos: 24 novos + 16 fixação)
    - Fase 3: Novos `D - K` (40 inimigos: 24 novos + 16 fixação)
    - Fase 4: Novos `S - L` (40 inimigos: 24 novos + 16 fixação)
    - Fase 5: Novos `A - Ç` (40 inimigos: 24 novos + 16 fixação)
    - Fase 6: Desafio Master Linha de Base (60 inimigos)
  - **Fases 7 a 12 (Linha Superior)**:
    - Fases individuais para `R - U`, `T - Y`, `E - I`, `W - O`, `Q - P`, culminando no Desafio Master Linha Superior (Fase 12).
  - **Fases 13 a 18 (Linha Inferior e Pontuação)**:
    - Fases individuais para `B - N`, `V - M`, `C - ,`, `X - .`, `Z - ;`, culminando no Desafio Master Linha Inferior (Fase 18).
  - **Fases 19 e 20 (Cruzadores Pesados)**:
    - Fase 19 com 25 Cruzadores 2-HP (24 px/s) e Fase 20 com 25 Cruzadores 3-HP (19 px/s).
  - **Fase 21 (Palavras Longas de Alcance Difícil)**:
    - 18 termos desafiadores em velocidade cadenciada (19 px/s).
  - **Fase 22+ (Horda Cósmica Mista Procedural)**:
    - Combinação de todas as classes com escalonamento infinito.
- **Configuração Visual e Computador de Bordo Personalizados**:
  - Paletas de cores exclusivas para as 22+ fases em `WordManager.WAVE_VISUAL_CONFIG`.
  - Mensagens situacionais no Computador de Bordo e banners de fase informando os pares específicos e instruções táticas para cada onda.

### Modificado
- `test_runner.gd` expandido para validar a nova malha de progressão de 22+ fases e a DDA contínua.

---

## [1.2.0] - 2026-11-09

### Adicionado
- **Sistema de 10 Colunas Fixas para Touch Typing**:
  - Arena subdividida em 10 pistas verticais correspondendo exatamente aos 10 dedos na digitação às cegas.
  - Coordenadas fixas $X \in [86.0, 158.0, 230.0, 302.0, 374.0, 446.0, 518.0, 590.0, 662.0, 734.0]$.
  - Divisor central luminoso no eixo $X = 410.0$ separando a Mão Esquerda (Colunas 0-4) e Direita (Colunas 5-9).
  - Nó `ColumnGuides` em `game.gd` renderizando linhas verticais sutis delimitando as colunas no cenário.
  - Alinhamento de descida estrito dos inimigos em linha reta pela coluna da sua tecla/primeira letra.
- **Fases Pedagógicas Reformuladas com 40 Teclas por Par**:
  - Fases 1, 2 e 3 ampliadas para 300 inimigos cada (5 seções de 40 teclas por par ordenado + 100 na sequência final).
  - Alerta de rádio e áudio *"Novos inimigos foram encontrados!"* a cada transição de seção.
  - Reset automático do ritmo e fluxo de combate ao trocar de seção para favorecer assimilação consciente das novas teclas.
- **Dificuldade Adaptativa (DDA - Dynamic Difficulty Adjustment)**:
  - Escalonamento da taxa de spawn e número de inimigos simultâneos (1 a 3) com base no ritmo e sequência perfeita do jogador.
  - Modo Recuperação imediato ao errar teclas: desaceleração (multiplicador 1.30x) e redução da densidade de inimigos para respiro tático.
- **Controle Estrito de Finalização no Game Over**:
  - Função `stop()` nos inimigos garantindo congelamento imediato da descida quando os escudos da nave chegam a zero.
- **Barra de Progresso da Onda**:
  - Medidor de 0% a 100% no canto inferior do painel de telemetria indicando o avanço na onda atual.
- **Cruzadores Pesados da Fase 4**:
  - 50 invasores carmesins com 2-HP (24 px/s) e 3-HP (19 px/s) com escala ampliada (1.35x a 1.45x).
  - Meta de cadência estrita de 150ms de intervalo médio entre teclas para a Fase 4+.
- **Suíte de Testes Unitários Completa**:
  - Testes cobrindo as 10 colunas, estrutura de 40 teclas por par, DDA, congelamento no Game Over e meta de 150ms.

---

## [1.1.0] - 2026-11-08

### Adicionado
- **Computador de Bordo Tático no Cockpit**:
  - Efeito teletype/typewriter com transmissão de mensagens situacionais prioritárias.
  - Fila de mensagens e dicas de gameplay para alternância de mãos e ritmo.
- **Coloração e Escala Temática por Fase**:
  - Fase 1 (Ciano Elétrico), Fase 2 (Verde Esmeralda), Fase 3 (Âmbar Solar), Fase 4 (Carmesim), Fase 5 (Púrpura Cósmica), Fase 6+ (Dourado Overdrive).
- **Inimigos com Barra de Vida Proporcional**:
  - ProgressBar integrada sobre os drones alienígenas indicando letras restantes.
- **Foco Visual Destacado**:
  - Inimigo alvo elevado para a frente com Z-index prioritário e retículo animado.

---

## [1.0.0] - 2026-11-07

### Adicionado
- Arquitetura de Split-Screen: Arena de combate (0 a 820px) e Painel de Telemetria (820 a 1280px).
- Teclado virtual interativo colorido por mãos com detecção de digitação em tempo real.
- Motor de telemetria `TypingMetrics` calculando CPM, WPM, precisão % e consistência de ritmo.
- Barra de Estilo (Rank SS a F) e ativação de partículas de Overdrive de plasma cósmico.
- Sistema de pontuação, combos e persistência de recorde em `ScoreManager`.
- Sintetizador procedural de áudio `SoundManager` com efeitos de laser, acertos, combos e rádio.
