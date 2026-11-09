# 🚀 Typing Shooter

Um jogo arcade 2D de combate espacial tático e treinador avançado de digitação às cegas (**Touch Typing**) desenvolvido na **Godot Engine 4.x**.

Repositório Oficial: [Germano123/aqueleprof-typing-shooter](https://github.com/Germano123/aqueleprof-typing-shooter)

---

## 🎮 Arquitetura de Tela Dividida (Split-Screen)

O jogo opera em resolução **1280x720**, dividido em dois módulos sinérgicos:

- **Arena de Combate Espacial (0 a 820px)**:
  - Nave do jogador posicionada no eixo central ($X = 410\text{px}$).
  - Invasores alienígenas descendentes em colunas estritas com barra de vida proporcional.
  - Disparos laser de plasma alternados por canhão, impacto com partículas e anéis de choque.
  - Barra de Estilo e Ritmo (Rank SS a F) com ativação de modo **Overdrive**.
  - Guias visuais verticais delimitando as colunas dos dedos e divisor central luminoso entre as mãos.

- **Painel de Telemetria e Cockpit Tático (820 a 1280px)**:
  - **Teclado Virtual Interativo**: Mapeamento cromático por mão e dedos em tempo real.
  - **Métricas de Precisão e Desempenho**: CPM (caracteres/min), WPM (palavras/min) e % de acerto.
  - **Equilíbrio de Mãos**: Comparativo contínuo de uso Mão Esquerda vs Mão Direita.
  - **Barra de Progresso da Onda**: Indicador de conclusão da fase de 0% a 100%.
  - **Computador de Bordo**: Transmissão teletype letra a letra com alertas situacionais prioritários.

---

## 🖐️ Sistema de 10 Colunas Fixas (Touch Typing)

Para reforçar a memória muscular espacial e a correspondência motora dedo-tecla, a arena é subdividida em **10 colunas fixas verticais** de **72px** com margens de segurança de **50px**. Os inimigos descem em linha reta exatamente na coluna correspondente ao dedo que deve pressionar a tecla:

| Coluna | Coordenada $X$ | Dedo Associado | Mão | Teclas Mapeadas |
| :---: | :---: | :--- | :---: | :--- |
| **0** | **86.0 px** | **Mindinho Esquerdo** | Esquerda | `Q`, `A`, `Z`, `1`, `!` |
| **1** | **158.0 px** | **Anelar Esquerdo** | Esquerda | `W`, `S`, `X`, `2`, `@` |
| **2** | **230.0 px** | **Médio Esquerdo** | Esquerda | `E`, `D`, `C`, `3`, `#` |
| **3** | **302.0 px** | **Indicador Esquerdo Base** | Esquerda | `R`, `F`, `V`, `4`, `$` |
| **4** | **374.0 px** | **Indicador Esquerdo Centro** | Esquerda | `T`, `G`, `B`, `5`, `%` |
| --- | **410.0 px** | *Divisor Central (Eixo da Nave)* | --- | *Separador Simétrico Esquerda / Direita* |
| **5** | **446.0 px** | **Indicador Direito Centro** | Direita | `Y`, `H`, `N`, `6`, `&` |
| **6** | **518.0 px** | **Indicador Direito Base** | Direita | `U`, `J`, `M`, `7`, `*` |
| **7** | **590.0 px** | **Médio Direito** | Direita | `I`, `K`, `,`, `8`, `<` |
| **8** | **662.0 px** | **Anelar Direito** | Direita | `O`, `L`, `.`, `9`, `>` |
| **9** | **734.0 px** | **Mindinho Direito** | Direita | `P`, `Ç`, `;`, `0`, `:`, `?`, `/`, `]`, `~`, `^`, `-` |

*Em palavras de múltiplos caracteres (Fase 4+), a primeira letra determina a coluna de descida, preparando o dedo para o disparo inicial.*

---

## 📚 Progressão Pedagógica das Fases

O jogo estrutura a curva de aprendizado em **fases modulares e focadas** (40 a 60 inimigos cada, durando ~1 a 2 minutos). Cada etapa de introdução de novas teclas e novos tipos de inimigos opera como uma **fase independente**, permitindo frequentes telas de vitória, fanfarras de conquista, exibição de métricas detalhadas (KPIs) e uma nítida sensação de avanço contínuo:

### 🏠 Bloco 1: Linha de Base (Home Row - Fases 1 a 6)
- **Fase 1: Indicadores Base (`F` - `J`)** (40 inimigos | Ciano Elétrico)
  - Assimilação dos pontos de repouso dos indicadores com as marcações táteis do teclado.
- **Fase 2: Novos Indicadores Centro (`G` - `H`)** (40 inimigos: 24 G/H + 16 F/J)
  - Deslocamento lateral dos indicadores e retorno imediato à base.
- **Fase 3: Novos Dedos Médios (`D` - `K`)** (40 inimigos: 24 D/K + 16 fixação)
  - Ativação dos dedos médios com reforço dos indicadores já aprendidos.
- **Fase 4: Novos Dedos Anelares (`S` - `L`)** (40 inimigos: 24 S/L + 16 fixação)
  - Desenvolvimento da independência motora dos dedos anelares.
- **Fase 5: Novos Dedos Mínimos (`A` - `Ç`)** (40 inimigos: 24 A/Ç + 16 fixação)
  - Domínio das extremidades da linha de base pelos dedos mínimos.
- **Fase 6: Desafio Master da Linha de Base** (60 inimigos | Ouro Ciano)
  - Teste integrativo com todos os pares da linha de base misturados em alta velocidade.

### ⬆️ Bloco 2: Linha Superior (Top Row - Fases 7 a 12)
- **Fase 7: Indicadores Superior (`R` - `U`)** (40 inimigos | Verde Esmeralda)
- **Fase 8: Novos Indicadores Centro Superior (`T` - `Y`)** (40 inimigos: 24 T/Y + 16 R/U)
- **Fase 9: Novos Médios Superior (`E` - `I`)** (40 inimigos: 24 E/I + 16 fixação)
- **Fase 10: Novos Anelares Superior (`W` - `O`)** (40 inimigos: 24 W/O + 16 fixação)
- **Fase 11: Novos Mínimos Superior (`Q` - `P`)** (40 inimigos: 24 Q/P + 16 fixação)
- **Fase 12: Desafio Master da Linha Superior** (60 inimigos | Ouro Esmeralda)

### ⬇️ Bloco 3: Linha Inferior & Pontuação (Bottom Row - Fases 13 a 18)
- **Fase 13: Indicadores Inferior (`B` - `N`)** (40 inimigos | Âmbar Solar)
- **Fase 14: Novos Indicadores Centro Inferior (`V` - `M`)** (40 inimigos: 24 V/M + 16 B/N)
- **Fase 15: Novos Médios & Vírgula (`C` - `,`)** (40 inimigos: 24 C/, + 16 fixação)
- **Fase 16: Novos Anelares & Ponto (`X` - `.`)** (40 inimigos: 24 X/. + 16 fixação)
- **Fase 17: Novos Mínimos & Ponto e Vírgula (`Z` - `;`)** (40 inimigos: 24 Z/; + 16 fixação)
- **Fase 18: Desafio Master da Linha Inferior** (60 inimigos | Ouro Âmbar)

### 🛡️ Bloco 4: Desafios Avançados & Cruzadores (Fases 19+)
- **Fase 19: Cruzadores Pesados 2-HP** (25 inimigos | Carmesim | 24 px/s):
  - Invasores reforçados exigindo 2 disparos consecutivos rápidos; ativação da meta de cadência de **150ms**.
- **Fase 20: Cruzadores Pesados 3-HP** (25 inimigos | Carmesim Escuro | 19 px/s):
  - Blindagem tripla testando sequências de 3 caracteres com alta precisão.
- **Fase 21: Alcance Difícil (Palavras Longas)** (18 inimigos | Púrpura Cósmica | 19 px/s):
  - Termos complexos com saltos pelo teclado (`PIXEL`, `EQUIPE`, `ZUMBIDO`, `PROJETO`, `COMPLEXO`).
- **Fase 22+: Horda Cósmica Mista Procedural** (Dourado Infinito):
  - Spawns combinados de todas as categorias anteriores com dificuldade incremental contínua.

---

## ⚡ Dificuldade Adaptativa (DDA - Dynamic Difficulty Adjustment)

O jogo monitora em tempo real a constância e velocidade do jogador:
- **Ritmo Elevado / Acelerado / Frenesi**: Sequências perfeitas aceleram o surgimento de inimigos e liberam ondas de 2 a 3 invasores simultâneos, desafiando jogadores ágeis.
- **Modo Recuperação**: Ao cometer um erro, a sequência é reiniciada, a cadência desacelera (multiplicador 1.30x) e a capacidade em tela é reduzida para respiro tático.

---

## 🛑 Finalização Estrita no Game Over

Ao esgotar os escudos, o estado de Game Over aciona a parada imediata e congelamento de movimentação de todos os inimigos em tela (`stop()`), garantindo que o jogo encerre a fase com clareza visual e sem impactos tardios.

---

## 📂 Estrutura do Projeto

```
typing-shooter/
├── project.godot               # Configurações do projeto e Autoloads
├── scenes/
│   ├── main_menu.tscn          # Menu principal e instruções
│   ├── game.tscn               # Arena de combate e split-screen
│   ├── player.tscn             # Nave espacial com HUD de Rank
│   ├── enemy_word.tscn         # Inimigo pod com barra de vida e tags
│   ├── typing_panel.tscn       # Painel de telemetria, gauges e teclado virtual
│   ├── projectile.tscn         # Projétil laser de plasma
│   ├── explosion.tscn          # Partículas e explosão vetorial
│   ├── floating_text.tscn      # Feedback flutuante de pontos e combo
│   └── hud.tscn                # HUD superior, banners e modal de KPIs
├── scripts/
│   ├── word_manager.gd         # Banco de palavras, 10 colunas e filas pedagógicas
│   ├── game.gd                 # Loop do jogo, guias de colunas e DDA
│   ├── typing_metrics.gd       # Motor de cadência, DDA, KPIs e telemetria
│   ├── typing_panel.gd         # Teclado virtual, teletype e medidores
│   ├── enemy_word.gd           # Comportamento, escala, cores e congelamento
│   ├── player.gd               # Controle da nave e disparo alternado
│   ├── sound_manager.gd        # Sintetizador procedural de áudio (Autoload)
│   ├── score_manager.gd        # Gestão de pontuação e recorde (Autoload)
│   ├── hud.gd                  # Interface, escudos e banners
│   ├── main_menu.gd            # Lógica de interface inicial
│   └── test_runner.gd          # Suíte completa de testes automatizados
└── assets/
    └── textures/               # Sprites vetoriais SVG
```

---

## 🧪 Testes Automatizados

Para executar os 11 testes unitários automatizados em modo headless com o console Godot:

```powershell
& "Godot_v4.7.1-stable_win64_console.exe" --headless --script res://scripts/test_runner.gd --path "."
```

---

## 🎮 Controles e Atalhos

- **Teclado Alfanumérico**: Digite as letras/caracteres exibidos nos inimigos.
- **F1**: Avançar imediatamente para a próxima onda (*Modo Debug*).
- **Esc**: Retornar ao Menu Principal.
