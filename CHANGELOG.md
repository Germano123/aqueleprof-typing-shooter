# Changelog

Todas as alterações notáveis deste projeto serão documentadas neste arquivo.

O formato baseia-se em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/) e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

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
