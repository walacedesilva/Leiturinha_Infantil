# Changelog — Revisão e correção (Fases 1–4)

**Data:** 23/06/2026
**Escopo:** correção de bugs de progressão, remoção de código morto, robustez de erros/logs e limpeza de repositório.

---

## Fase 1 — Bloqueio sequencial de fases reativado (crítico)

Antes, 6 telas de mapa tinham o bloqueio de fases desativado para teste (`// TODO: restaurar lock`), deixando todo o conteúdo liberado e quebrando a progressão pedagógica. Além disso, o Bairro das Sílabas nem lia o progresso real.

- **Novo:** `lib/features/reading_game/domain/lock_policy.dart` — política central de bloqueio com flag única `kUnlockAll` (para testes), predicado `isLevelUnlocked` e `DistrictCompletion` (conclusão de distritos).
- **`praca_central_screen.dart`** — mapa de distritos agora abre em sequência: cada distrito exige o anterior concluído (vogais → sílabas → famílias → palavras → construção → circo); distritos avançados liberam ao concluir o circo. Removido helper morto `_isVogaisComplete`.
- **`vila_das_vogais` / `parque_das_familias` / `castelo_das_palavras` / `distrito_da_construcao`** — regra sequencial: uma fase só abre quando a anterior é concluída.
- **`bairro_das_familias_screen.dart`** — **bug corrigido:** a tela tinha estado/progresso fixos (hardcoded) e ignorava o `ProgressService`; agora lê o progresso real e aplica o bloqueio sequencial.
- **Novo teste:** `test/lock_policy_test.dart` — cobre o predicado de desbloqueio, o cenário sequencial (1ª fase abre, demais travadas; concluir 1ª libera a 2ª) e a conclusão de distritos.

## Fase 2 — Telas órfãs resolvidas (0 telas inacessíveis)

O app tinha 9 telas inacessíveis (54 → 48 telas, todas alcançáveis agora).

**Removidas (6 telas-legado, com versões vivas equivalentes):**
`menu_screen`, `game_screen`, `profile_screen`, `perfil_screen`, `acessorios_screen`, `weekly_report_screen`. Eliminadas as duplicatas de perfil (mantida a aba `AvatarPersonalizacaoScreen`) e de relatório (mantida `DashboardRelatorioScreen`).

**Reconectadas (3 telas com mockup pronto):**
Nova seção **"🎮 Minijogos"** na aba Desafios (`desafios_screen.dart`) com pontos de entrada para `CorridaSilabasScreen` e `DesafioDePronunciaScreen` (que leva à `FeedbackRecompensasScreen`).

**Imports mortos limpos:** `profile_screen` em `ilha_das_palavras`; `perfil_screen` e `praca_central` em `nav_shell`; `praca_central` em `desafios`. Comentário de fluxo desatualizado corrigido em `syllable_selector_screen`.

## Fase 3 — Erros silenciosos e logs

- **`main.dart`** — em builds de produção (`kReleaseMode`), toda a saída de `debugPrint` é silenciada com uma única linha (todas as ~80 chamadas eram `debugPrint`), sem alterar os call sites. Em desenvolvimento, os logs continuam.
- **`catch` silenciosos tratados:** `pdf_export_service` (fallback de fonte agora loga), `session_tracking_service._load` (erro de JSON corrompido agora loga e reinicia em vez de engolir), `audio_manager` (restauração de velocidade do TTS).
- **`dashboard_relatorio_screen`** — mensagem de falha de exportação de PDF trocada por uma amigável (sem expor a exceção crua); erro real enviado ao log.

## Fase 4 — Limpeza de repositório

- **Removido:** pasta aninhada duplicada `lib/features/reading_game/reading_game/` (`word_bank.dart` morto).
- **Mockups fora do bundle:** 15 imagens não usadas movidas de `assets/images/` para `design_mockups/` (na raiz, não empacotada). Apenas `logo.png` permanece em `assets/images/`.
- **`.gitignore`** — adicionado `.expo/` da raiz e `**/node_modules/` defensivo. (O subprojeto `react-native/` já tinha o próprio `.gitignore` excluindo `node_modules/`, `.expo/`, `android/`, `ios/`.)
- **Mantidos:** `react-native/` e protótipos web (`portal_estelar/`, `reino_das_historias/`) como parte do projeto; `packages/o3d` (código-fonte de pacote Flutter).

---

## Validação recomendada

Estas mudanças foram revisadas manualmente (não foi possível rodar Flutter no ambiente de análise). Antes de commitar, rode localmente:

```
cd C:\Users\walace\Desktop\Leiturinha
flutter pub get
flutter analyze
flutter test
```

## Sugestão de mensagem de commit

```
fix: reativa bloqueio sequencial, remove telas órfãs e limpa repo

- Fase 1: restaura lock sequencial em 6 telas de mapa via LockPolicy
  central; corrige Bairro das Sílabas que ignorava o progresso real;
  adiciona test/lock_policy_test.dart
- Fase 2: remove 6 telas-legado e reconecta 3 telas (Minijogos na aba
  Desafios); 0 telas órfãs
- Fase 3: silencia debugPrint em release; trata catch silenciosos
- Fase 4: remove word_bank duplicado; tira mockups do bundle; ajusta .gitignore
```
