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

### Fases 1, 2 e 3 (Estrutura de 300 Inimigos por Fase)
Cada fase inicial organiza o aprendizado em **5 seções estruturadas de 40 teclas seguidas por par simétrico** + **100 teclas na sequência final de consolidação**:

1. **Fase 1 (Linha de Base - Ciano Elétrico)**:
   - Seção 1: Par `F - J` (40 teclas)
   - Seção 2: Par `G - H` (40 teclas)
   - Seção 3: Par `D - K` (40 teclas)
   - Seção 4: Par `S - L` (40 teclas)
   - Seção 5: Par `A - Ç` (40 teclas)
   - Seção 6: Sequência Final Mista da Linha de Base (100 teclas)

2. **Fase 2 (Linha Superior - Verde Esmeralda)**:
   - Seção 1: Par `R - U` (40 teclas)
   - Seção 2: Par `T - Y` (40 teclas)
   - Seção 3: Par `E - I` (40 teclas)
   - Seção 4: Par `W - O` (40 teclas)
   - Seção 5: Par `Q - P` (40 teclas)
   - Seção 6: Sequência Final Mista da Linha Superior (100 teclas)

3. **Fase 3 (Linha Inferior com Pontuação - Âmbar Solar)**:
   - Seção 1: Par `B - N` (40 teclas)
   - Seção 2: Par `V - M` (40 teclas)
   - Seção 3: Par `C - ,` (40 teclas)
   - Seção 4: Par `X - .` (40 teclas)
   - Seção 5: Par `Z - ;` (40 teclas)
   - Seção 6: Sequência Final Mista da Linha Inferior (100 teclas)

> 🔔 **Transição entre Seções**: Em cada troca de par, o jogo emite o alerta *"Novos inimigos foram encontrados!"* via rádio tático e áudio comemorativo, **resetando o ritmo** para que o jogador assimile as novas teclas com calma e consciência motora.

### Fase 4 (Cruzadores Pesados & Métrica de 150ms - Carmesim)
- **50 Cruzadores Espaciais** com escala ampliada (1.35x a 1.45x) e velocidade reduzida:
  - 1ª Metade: 25 Cruzadores de 2 caracteres (2-HP) a 24 px/s.
  - 2ª Metade: 25 Cruzadores de 3 caracteres (3-HP) a 19 px/s.
- **Métrica-Chave**: Cadência alvo estrita de **150ms** de intervalo médio entre teclas registrada nos KPIs.

### Fase 5 (Alcance Difícil - Púrpura Cósmica)
- 18 palavras longas com saltos complexos de teclado (ex: `PIXEL`, `EQUIPE`, `ZUMBIDO`, `PROJETO`, `COMPLEXO`) a 19 px/s.

### Fase 6+ (Horda Cósmica Mista - Dourado)
- Mistura procedural de todas as categorias anteriores com dificuldade incremental contínua.

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
