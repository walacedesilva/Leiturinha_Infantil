# Análise do App Leiturinha — Lacunas, Falhas e Telas sem Uso

**Data:** 23/06/2026 · **Escopo:** `lib/` (Flutter, 54 telas, ~66 mil linhas Dart)

O app é um jogo de alfabetização (sílabas, vogais, dígrafos, encontros, rimas, histórias e aventuras) com navegação por abas (`nav_shell`) a partir da `SplashScreen → LoginScreen → IlhaDasPalavras`. A análise cruzou cada classe de tela com suas instanciações e fez busca de alcançabilidade (BFS) a partir da tela inicial.

---

## 1. Telas sem uso (órfãs / inacessíveis)

Nove telas **nunca são alcançadas** durante o uso real do app. Formam dois grupos: uma geração antiga de UI já substituída, e features prototipadas que ficaram desconectadas. Representam código morto que infla o build e confunde a manutenção.

| Tela | Arquivo | Situação |
|------|---------|----------|
| `MenuScreen` | `menu_screen.dart` | Menu antigo de seleção de família silábica. Substituído pelo `nav_shell` (abas). Ninguém instancia. |
| `ProfileScreen` | `profile_screen.dart` | Perfil antigo. Só era aberto pelo `MenuScreen` (já órfão). |
| `PerfilScreen` | `perfil_screen.dart` | **Segunda** tela de perfil (duplicada). Importada pelo `nav_shell` mas **nunca usada** — as abas usam `AvatarPersonalizacaoScreen` + `SettingsScreen`. |
| `AcessoriosScreen` | `acessorios_screen.dart` | Só era aberta pela `PerfilScreen` (órfã). |
| `WeeklyReportScreen` | `weekly_report_screen.dart` | Relatório semanal. Só era aberto pelo `MenuScreen` (órfão). Existe `DashboardRelatorioScreen` como versão viva. |
| `GameScreen` | `game_screen.dart` | Tela de jogo antiga. Nenhuma referência. |
| `CorridaSilabasScreen` | `corrida_silabas_screen.dart` | Feature "corrida de sílabas". Importada por `ilha_das_palavras` mas **nunca instanciada**. |
| `DesafioDePronunciaScreen` | `desafio_pronuncia_screen.dart` | Desafio de pronúncia. Nenhuma referência viva. |
| `FeedbackRecompensasScreen` | `feedback_recompensas_screen.dart` | Só é aberta pela `DesafioDePronunciaScreen` (órfã). |

> Indício forte de que eram features planejadas: existem **mockups em `assets/images/`** com exatamente esses nomes — `CorridaSilabas.png`, `DesafioDePronuncia.png`, `FeedbackRecompensas.png`. Ou foram abandonadas, ou faltou ligá-las ao fluxo.

**Decisão necessária:** ou reconectar essas telas ao app, ou removê-las. Há duplicação clara de propósito: **dois perfis** (`PerfilScreen` + `ProfileScreen` + a aba viva `AvatarPersonalizacaoScreen`) e **dois relatórios** (`WeeklyReportScreen` + `DashboardRelatorioScreen`).

---

## 2. Falha crítica: progressão sequencial desativada

Em **6 telas de mapa** o bloqueio de fases está fixado em "tudo liberado" com comentário `// TODO: restaurar lock sequencial para produção`:

- `praca_central_screen.dart` (`_stateOf` retorna sempre `_DState.available`)
- `vila_das_vogais_screen.dart`
- `castelo_das_palavras_screen.dart`
- `distrito_da_construcao_screen.dart`
- `parque_das_familias_screen.dart`
- `bairro_das_familias_screen.dart` (3 cartões fixados em `active // TODO: locked em produção`)

**Impacto:** a criança consegue pular direto para conteúdo avançado (ex.: dígrafos antes das vogais), quebrando a lógica pedagógica de aprendizagem progressiva — provavelmente o diferencial do produto. É um estado de teste que vazou para o código principal. **Prioridade alta antes de publicar.**

---

## 3. Resíduos de código e estrutura

- **Arquivo duplicado morto:** `lib/features/reading_game/reading_game/data/word_bank.dart` (45 linhas) — pasta `reading_game/reading_game/` aninhada por engano; nenhum import aponta para ela. A versão real é `lib/features/reading_game/data/word_bank.dart` (431 linhas).
- **Imports mortos:** `ilha_das_palavras_screen.dart` importa `corrida_silabas_screen.dart` e `profile_screen.dart` sem usar; `nav_shell.dart` importa `perfil_screen.dart` sem usar. (O analyzer do Flutter sinalizaria esses.)
- **Projetos paralelos misturados na raiz:** existe um app **React Native completo** em `react-native/` (com `node_modules`, `App.js`, `app.json`) e protótipos web em `portal_estelar/` e `reino_das_historias/` (HTML/CSS/JS), além de `.expo/`. Convivendo com um projeto Flutter, isso confunde o repositório e o build. Avaliar se são legados a arquivar/remover.
- **Asset lixo:** `assets/images/Novo(a) Imagem de bitmap.bmp` e mockups soltos (`tela 1.png`…`tela 6.png`, `tela 1_v2.mp4`) versionados junto aos assets de produção.

---

## 4. Tratamento de erros e logs

- **`catch` silenciosos** que engolem exceções sem log nem fallback: `pdf_export_service.dart` (2x, na exportação de PDF — falha silenciosa para o usuário), `session_tracking_service.dart`, `audio_manager.dart`. Vale ao menos registrar o erro.
- **`print`/`debugPrint` em produção** espalhados (game_logic 11x, story_player 5x, audio_manager 9x, google_auth_service 20x, speech_validator 31x). Trocar por um logger com nível, ou remover, para não vazar dados em release.

---

## 5. Qualidade / cobertura

Pontos positivos: há testes para a lógica de negócio (`game_logic`, `gamification_service`, `progress_service`, `session_tracking`, `speech_validator`, `models`) com fakes de áudio e prefs. **Não há testes de widget/navegação** — exatamente a área onde as telas órfãs passaram despercebidas. Um teste de fumaça que percorre o grafo de navegação pegaria telas inacessíveis automaticamente.

---

## Resumo de prioridades

1. **Alta —** Reativar o bloqueio sequencial de fases (6 telas) antes de publicar.
2. **Alta —** Decidir o destino das 9 telas órfãs: reconectar ou apagar (e resolver as duplicatas de perfil e de relatório).
3. **Média —** Remover `word_bank.dart` duplicado, imports mortos e tratar os `catch` silenciosos (PDF).
4. **Média —** Limpar a raiz do repo (react-native, protótipos web, assets de mockup).
5. **Baixa —** Substituir `print`/`debugPrint` por logger; adicionar teste de navegação.
