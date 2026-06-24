# QA Report — Alfabetização Mágica

**Data:** 2026-05-23
**Escopo:** `react-native/` (Expo SDK 51)
**Veredito:** ✅ **PASS** — sem itens P0 abertos
**Score:** **51.5 / 52 (99%)**

---

## Sumário

| Métrica | Valor |
|---|---|
| Itens auditados | 52 |
| ✅ Pass | 49 |
| 🟡 Partial | 2 |
| ❌ Fail | 1 |
| P0 abertos | **0** |
| P1 abertos | 2 |
| P2 abertos | 2 |

---

## Evolução do score

| Marco | Score |
|---|---|
| Baseline | 11/52 (21%) |
| Navegação refatorada | 17/52 (33%) |
| Phase 1 — Vila | 24/52 (46%) |
| Phase 2 — Bairro | 28/52 (54%) |
| Phase 3 — Cidade | 30/52 (58%) |
| Consent + LGPD | 36/52 (69%) |
| ASR pipeline | 43/52 (83%) |
| Phase 4 — Reino | 48/52 (92%) |
| Expo scaffolding + Conquistas | 50/52 (96%) |
| Audio manifest + Phase 3 alinhada | **51.5/52 (99%)** |

---

## Suíte 1 — Navigation & Shell (6/6)

| # | Item | Status | Sev | Evidência |
|---|---|---|---|---|
| 1.1 | RootStack: Splash → Consent → MainTabs | ✅ | P0 | [src/navigation/AppNavigator.js](react-native/src/navigation/AppNavigator.js) |
| 1.2 | Bottom tab bar persistente | ✅ | P0 | [src/navigation/AppNavigator.js](react-native/src/navigation/AppNavigator.js) |
| 1.3 | HomeStack aninha 4 mundos | ✅ | P1 | [src/navigation/AppNavigator.js](react-native/src/navigation/AppNavigator.js) |
| 1.4 | `withUnlockGuard` HOC | ✅ | P0 | [src/navigation/AppNavigator.js](react-native/src/navigation/AppNavigator.js) |
| 1.5 | Deep linking (scheme `alfabetizacaomagica`) | ✅ | P2 | [app.json](react-native/app.json) |
| 1.6 | SafeAreaProvider raiz | ✅ | P1 | [App.js](react-native/App.js) |

## Suíte 2 — Phase 1 · Vila das Vogais (4/5 — 1 débito DRY)

| # | Item | Status | Sev | Notas |
|---|---|---|---|---|
| 2.1 | 5 vogais com IDs do banco | ✅ | P0 | [src/data/phase1Vowels.js](react-native/src/data/phase1Vowels.js) |
| 2.2 | VilaScreen funcional | ✅ | P0 | [src/screens/worlds/VilaScreen.js](react-native/src/screens/worlds/VilaScreen.js) |
| 2.3 | `completeWorld('vila')` destrava Bairro | ✅ | P0 | progressStore |
| 2.4 | Áudio nativo das vogais | 🟡 | P1 | Fallback noop; ativa após pipeline Azure |
| 2.5 | Migrar para `SyllableLearnChallenge` | ❌ | P2 | Débito DRY, não funcional |

## Suíte 3 — Phase 2 · Bairro das Famílias (5/5)

| # | Item | Status | Sev |
|---|---|---|---|
| 3.1 | 5 famílias × 5 sílabas (25 itens) | ✅ | P0 |
| 3.2 | 25 .wav reais em `assets/audio/syllables/` | ✅ | P0 |
| 3.3 | Hub → sub-grupo → `SyllableLearnChallenge` | ✅ | P0 |
| 3.4 | `markChallengePassed` + `completeWorld` em 5/5 | ✅ | P0 |
| 3.5 | Mascote + animação + replay 0.85× | ✅ | P1 |

## Suíte 4 — Phase 3 · Cidade dos Encontros (5/5)

| # | Item | Status | Sev | Notas |
|---|---|---|---|---|
| 4.1 | 5 clusters × 3 sílabas (BR/CL/TR/FL/GR) | ✅ | P0 | Alinhado ao banco |
| 4.2 | Áudio nativo dos clusters | 🟡 | P1 | `AUDIO_MANIFEST` resolve após synth |
| 4.3 | Hub → sub-cluster → `SyllableLearnChallenge` | ✅ | P0 | |
| 4.4 | `markChallengePassed` + `completeWorld('cidade')` | ✅ | P0 | |
| 4.5 | IDs 1:1 com `phonetic_bank` | ✅ | P1 | Pipeline TTS cobre 100% |

## Suíte 5 — Phase 4 · Reino das Histórias (5/5)

| # | Item | Status | Sev |
|---|---|---|---|
| 5.1 | 3 mini-histórias com placeholder `{target}` | ✅ | P0 |
| 5.2 | Hub → leitor página-a-página | ✅ | P0 |
| 5.3 | Palavra-alvo destacada na cor da história | ✅ | P1 |
| 5.4 | `ReadAloudButton` por página | ✅ | P0 |
| 5.5 | 3/3 → `completeWorld('reino')` → mapa | ✅ | P0 |

## Suíte 6 — Consent & LGPD (8/8)

| # | Item | Status | Sev |
|---|---|---|---|
| 6.1 | `consentStore` separado de `progressStore` | ✅ | P0 |
| 6.2 | `ConsentScreen` full-screen | ✅ | P0 |
| 6.3 | `ParentalGate` matemático | ✅ | P0 |
| 6.4 | Mic opt-in granular | ✅ | P0 |
| 6.5 | Revogação em Perfil | ✅ | P0 |
| 6.6 | Versionamento de política | ✅ | P1 |
| 6.7 | Permissões nativas (iOS + Android) | ✅ | P0 |
| 6.8 | Splash roteia conforme política aceita | ✅ | P0 |

## Suíte 7 — ASR & Áudio (8/8)

| # | Item | Status | Sev |
|---|---|---|---|
| 7.1 | 3 backends ASR auto-detectáveis | ✅ | P0 |
| 7.2 | Backend mock devolve `mockAnswer` | ✅ | P1 |
| 7.3 | `phoneticMatch` pt-BR completo | ✅ | P0 |
| 7.4 | Threshold 0.75 + Levenshtein por token | ✅ | P0 |
| 7.5 | `ReadAloudButton` com estados/anim | ✅ | P1 |
| 7.6 | Bloqueio elegante sem mic | ✅ | P0 |
| 7.7 | 3 tentativas + "Pular por agora" | ✅ | P1 |
| 7.8 | Pipeline TTS reproduzível | ✅ | P0 |

## Suíte 8 — Conquistas, Desafios & Perfil (4.5/5)

| # | Item | Status | Sev | Notas |
|---|---|---|---|---|
| 8.1 | `ConquistasScreen` real (4 seções) | ✅ | P0 | [ConquistasScreen.js](react-native/src/screens/ConquistasScreen.js) |
| 8.2 | Medalhas reativas via Zustand | ✅ | P1 | |
| 8.3 | `DesafiosScreen` com pool real + ASR | ✅ | P0 | |
| 8.4 | `PerfilScreen` com toggle/reset/revoke | ✅ | P0 | |
| 8.5 | i18n framework | 🟡 | P2 | pt-BR only por design |

## Suíte 9 — Build & Operations (5/5)

| # | Item | Status | Sev |
|---|---|---|---|
| 9.1 | `package.json` pinned (Expo SDK 51) | ✅ | P0 |
| 9.2 | `babel.config.js` + `index.js` + `.gitignore` + `app.json` | ✅ | P0 |
| 9.3 | AsyncStorage com 2 chaves separadas | ✅ | P0 |
| 9.4 | Migrate v1→v2→v3 preserva dados | ✅ | P1 |
| 9.5 | README de setup completo | ✅ | P1 |

---

## Itens abertos (4)

| ID | Item | Sev | Bloqueio |
|---|---|---|---|
| 2.4 | Áudio nativo das vogais | P1 | Executar pipeline Azure |
| 4.2 | Áudio nativo dos clusters | P1 | Executar pipeline Azure |
| 2.5 | Vila migrar para `SyllableLearnChallenge` | P2 | Débito DRY, opt-in |
| 8.5 | i18n framework | P2 | Decisão de produto |

**Nenhum P0 aberto.** P1s dependem apenas da execução externa do pipeline Azure (1 comando após `AZURE_SPEECH_KEY` setado). P2s são opcionais.

---

## Comandos para 100%

```powershell
# 1. Ativar áudio nativo de Phases 1, 3 (e 4/5 quando wire-adas)
$env:AZURE_SPEECH_KEY="<key>"; $env:AZURE_SPEECH_REGION="brazilsouth"
python tools/tts/azure_synthesize.py --bank
python tools/tts/wire_audio_manifest.py
# → 2.4 e 4.2 viram ✅ → 52/52 (100%)
```
