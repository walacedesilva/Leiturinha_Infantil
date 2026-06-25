# Plano de Implementação / Correção — Leiturinha

**Base:** `ANALISE_LEITURINHA.md` · **Data:** 23/06/2026

Plano em 4 fases, da mais crítica (bloqueia publicação) à de higiene. Cada item traz arquivo, ação concreta e como validar. Sugestão: uma branch por fase e rodar `flutter analyze` + `flutter test` ao final de cada uma.

---

## Fase 1 — Reativar a progressão sequencial (CRÍTICO, bloqueia release)

**Problema:** em 6 telas o estado de fase está fixado em "liberado" para teste. Precisa voltar à regra: uma fase só abre quando a anterior é concluída.

O `ProgressService` já dá o que precisamos — `getFamilyProgress(key, total).isCompleted`. O enum `_DState`/`_CardState` já tem o estado `locked`; só falta voltar a retorná-lo.

**Padrão de correção (aplicar em cada tela):** a fase `i` fica `available` se `i == 0` **ou** se a fase `i-1` está `isCompleted`; caso contrário `locked`. Quem já está completa vira `completed`.

| Arquivo | Função a corrigir | Ação |
|---------|-------------------|------|
| `praca_central_screen.dart` | `_stateOf` (linha ~155) | Substituir `return _DState.available;` pela regra sequencial sobre `_kDistricts`. |
| `vila_das_vogais_screen.dart` | `_computeLevels` (~134) | Adicionar branch `locked` quando a vogal anterior não está `isCompleted`. |
| `castelo_das_palavras_screen.dart` | bloco do `// TODO` (~176) | Idem, sobre as famílias do castelo. |
| `distrito_da_construcao_screen.dart` | (~145) | Idem. |
| `parque_das_familias_screen.dart` | (~163) | Idem. |
| `bairro_das_familias_screen.dart` | cartões (~91, 106, 121) | Trocar `state: _BCardState.active // TODO` por estado derivado do progresso. |

**Recomendação extra:** em vez de repetir a regra em 6 telas, criar um helper único, ex. `LockPolicy.stateForLevel(index, progress)` em `domain/`, e chamá-lo em todas. Reduz o risco de outra fase "vazar" liberada no futuro. Manter um único flag de debug central (`kUnlockAll = false`) para destravar tudo em desenvolvimento sem espalhar TODOs.

**Validação:** com progresso zerado, só a 1ª fase de cada mapa abre; concluir a 1ª destrava a 2ª. Adicionar teste de widget que verifica isso (ver Fase 4).

---

## Fase 2 — Resolver as 9 telas órfãs e duplicatas (ALTO)

Para cada tela, **decidir**: reconectar ao fluxo ou remover. Recomendação abaixo entre parênteses.

**Duplicatas a consolidar (decisão de produto):**

- **Perfil:** existem `PerfilScreen`, `ProfileScreen` e a aba viva `AvatarPersonalizacaoScreen`. → Escolher uma; remover as outras duas. (Recomendo manter `AvatarPersonalizacaoScreen`, que já está nas abas, e remover `PerfilScreen` + `ProfileScreen`.)
- **Relatório:** `WeeklyReportScreen` (órfã) vs. `DashboardRelatorioScreen` (viva). → Se o relatório semanal tem conteúdo único, integrá-lo como aba do dashboard; senão remover `WeeklyReportScreen`.

**Telas com mockup pronto (`assets/images/`) — decidir se entram no produto:**

- `CorridaSilabasScreen` (mockup `CorridaSilabas.png`)
- `DesafioDePronunciaScreen` (mockup `DesafioDePronuncia.png`) → abre `FeedbackRecompensasScreen`
- Se forem manter: adicionar ponto de entrada (ex. botão na `IlhaDasPalavras` ou em `DesafiosScreen`) e teste de navegação. Se não: remover as 3 telas juntas.

**Remoção segura (provável legado):** `MenuScreen`, `GameScreen`, `AcessoriosScreen` — sem equivalente vivo referenciando-as.

**Ao remover qualquer tela:** apagar o arquivo, remover imports que a referenciam e rodar `flutter analyze` (vai apontar imports mortos restantes). Imports mortos já conhecidos: `corrida_silabas_screen` e `profile_screen` em `ilha_das_palavras_screen.dart`; `perfil_screen` em `nav_shell.dart`.

**Validação:** `flutter analyze` sem warnings de import/elemento não usado; app compila e navega.

---

## Fase 3 — Robustez de erros e logs (MÉDIO)

- **`catch` silenciosos** em `pdf_export_service.dart` (2x), `session_tracking_service.dart`, `audio_manager.dart`: no mínimo logar o erro; na exportação de PDF, sinalizar falha ao usuário (snackbar) em vez de falhar mudo.
- **`print`/`debugPrint` em release:** centralizar num logger com nível (ex. pacote `logging`) e silenciar em release; foco em `speech_validator.dart` (31), `google_auth_service.dart` (20), `game_logic.dart` (11), `audio_manager.dart` (9), `story_player_screen.dart` (5). Não logar dados de conta/voz.

**Validação:** build release sem logs no console; falha forçada de PDF mostra mensagem ao usuário.

---

## Fase 4 — Higiene de repositório e testes (MÉDIO/BAIXO)

- **Remover arquivo morto** `lib/features/reading_game/reading_game/data/word_bank.dart` e a pasta aninhada `reading_game/reading_game/` (nenhum import aponta para ela).
- **Limpar a raiz:** avaliar arquivar/remover o projeto React Native (`react-native/`), os protótipos web (`portal_estelar/`, `reino_das_historias/`) e `.expo/`. Se forem histórico, mover para um repo/branch separado; não devem conviver com o build Flutter.
- **Limpar assets:** remover `assets/images/Novo(a) Imagem de bitmap.bmp` e mockups soltos (`tela 1.png`…`tela 6.png`, `tela 1_v2.mp4`) ou movê-los para uma pasta `design/` fora do bundle.
- **Teste de navegação (preventivo):** adicionar em `test/` um teste de fumaça que percorre o grafo a partir da `SplashScreen` e falha se alguma tela `*Screen` ficar inalcançável — pega regressões de telas órfãs automaticamente. Os testes de lógica já existem (`game_logic`, `progress_service`, etc.); falta a camada de widget/navegação.

**Validação:** `flutter analyze` limpo, `flutter test` verde, tamanho do build reduzido.

---

## Ordem sugerida e estimativa grosseira

1. **Fase 1** — 0,5–1 dia · libera o release.
2. **Fase 2** — 1–2 dias · depende de decisões de produto (perfil/relatório/features de corrida).
3. **Fase 3** — 0,5 dia.
4. **Fase 4** — 0,5–1 dia.

Recomendo fechar a Fase 1 primeiro e isoladamente, já que é a única que impacta diretamente a experiência pedagógica da criança.
