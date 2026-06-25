# Lista de sons para baixar — Leiturinha

Checklist prático. Formatos: SFX e clipes curtos `.mp3`/`.wav` (0,1–2 s); trilhas e ambientes `.mp3` em **loop perfeito**. Onde baixar (CC0/grátis): **Pixabay**, **Mixkit**, **Freesound** (filtre CC0), **OpenGameArt**.

> Dica: os 40 ambientes podem ir **achatados** em `assets/audio/ambient/` (só o nome do arquivo) — o código tem fallback automático para essa pasta, não precisa recriar as subpastas das histórias.

---

## 1. Efeitos base — SUBSTITUIR (hoje são bipes sintéticos) → `assets/audio/sfx/`

| # | Arquivo (manter nome) | Som | Busca sugerida |
|---|---|---|---|
| ☐ | `correct.wav` | acerto alegre, ~0,5 s | "success chime kids" |
| ☐ | `error.wav` | erro suave/gentil, ~0,4 s | "wrong soft gentle" |
| ☐ | `pop.wav` | toque de botão, ~0,15 s | "bubble pop ui" |
| ☐ | `balloons.wav` | celebração/confete, ~1–2 s | "celebration confetti win" |

## 2. Clipes de animais — ADICIONAR → `assets/audio/sfx/`

| # | Arquivo | Som | Busca sugerida |
|---|---|---|---|
| ☐ | `leao.mp3` | rugido curto | "lion roar short" |
| ☐ | `sapo.mp3` | coaxar | "frog croak" |

## 3. Recompensas (opcional, classe `AppSfxFiles`) → `assets/audio/sfx/`

| # | Arquivo | Som |
|---|---|---|
| ☐ | `sfx-success.mp3` | sucesso |
| ☐ | `sfx-achievement.mp3` | conquista/fanfarra curta |
| ☐ | `sfx-coin.mp3` | moeda |
| ☐ | `sfx-try-again.mp3` | tente de novo |
| ☐ | `sfx-recording-start.mp3` | início de gravação |

## 4. Trilha de fundo (loop) → `assets/audio/music/`

| # | Arquivo | Onde toca | Busca sugerida |
|---|---|---|---|
| ☐ | `menu.mp3` | tela de login/menu | "kids playful menu loop" |
| ☐ | `mapa.mp3` | hub/mapa principal | "cheerful adventure loop kids" |
| ☐ | `jogo.mp3` | (opcional) atividades | "calm neutral background loop" |

## 5. Ambientes das histórias (loop) → `assets/audio/ambient/` (40 arquivos)

**Safari**
- ☐ `act1_ambient_savana.mp3` — savana, pássaros
- ☐ `act2_ambient_mixed.mp3` — savana variada
- ☐ `act3_ambient_crossroads.mp3` — encruzilhada, tensão leve
- ☐ `act3b_savana_golden.mp3` — savana dourada
- ☐ `act3b_lago_crystal.mp3` — lago/água cristalina
- ☐ `act4_ambient_celebration.mp3` — festa suave

> ⚠️ Há `act4_ambient_celebration.mp3` em 3 histórias (Safari, Cozinha, Jardim). Se forem iguais, baixe 1 e copie; se quiser distintos, renomeie por história.

**Cozinha**
- ☐ `act1_ambient_kitchen.mp3` — cozinha aconchegante
- ☐ `act2_ambient_cooking.mp3` — cozinhando (panelas)
- ☐ `act3_ambient_choice.mp3` — momento de escolha
- ☐ `act3b_sweet_jingle.mp3` — jingle doce (3–5 s)
- ☐ `act3b_savory_jingle.mp3` — jingle salgado (3–5 s)
- ☐ `act4_ambient_celebration.mp3` — festa suave

**Planetas**
- ☐ `act1_ambient_launch.mp3` — lançamento de foguete
- ☐ `act2_ambient_space.mp3` — espaço/sci-fi
- ☐ `act3_ambient_orbit.mp3` — órbita
- ☐ `act3b_warp_speed.mp3` — whoosh/velocidade de dobra
- ☐ `act3b_scenic_wonders.mp3` — maravilhas cósmicas
- ☐ `act4_ambient_planet_surface.mp3` — superfície de planeta

**Teatro**
- ☐ `act1_ambient_backstage.mp3` — bastidores
- ☐ `act2_ambient_stage.mp3` — palco
- ☐ `act3_ambient_conflict.mp3` — conflito/tensão
- ☐ `act3b_dialogue_resolved.mp3` — alívio/resolução
- ☐ `act3b_silence_peace.mp3` — silêncio/paz
- ☐ `act4_ambient_spotlight.mp3` — holofote/aplauso

**Jardim**
- ☐ `act1_ambient_garden_morning.mp3` — jardim de manhã, pássaros
- ☐ `act2_ambient_garden_planting.mp3` — plantio
- ☐ `act3_ambient_twilight.mp3` — entardecer
- ☐ `act3b_day_garden.mp3` — jardim de dia
- ☐ `act3b_night_garden.mp3` — jardim de noite, grilos
- ☐ `act4_ambient_celebration.mp3` — festa suave

**Floresta Sussurrante**
- ☐ `act1_ambient.mp3` — floresta calma
- ☐ `act2_rain.mp3` — chuva
- ☐ `act3_rain_rhythm.mp3` — chuva ritmada
- ☐ `act4_thunder.mp3` — trovão
- ☐ `act5_rainbow.mp3` — pós-chuva/arco-íris

> ⚠️ Conflito de nomes: Floresta e "Heloísa" usam `act1_ambient.mp3`...`act5_ambient.mp3`/etc. Se baixar achatado em `audio/ambient/`, **renomeie** para evitar sobrescrever (ex.: `floresta_act1_ambient.mp3`, `heloisa_act1_ambient.mp3`) e ajuste os caminhos no `stories_pack_v1.json`. Ou mantenha as subpastas originais e registre-as no `pubspec.yaml`.

**Heloísa e o Amigo Trovão**
- ☐ `act1_ambient.mp3` — ambiente inicial
- ☐ `act2_ambient.mp3`
- ☐ `act3_ambient.mp3`
- ☐ `act4_ambient.mp3`
- ☐ `act5_ambient.mp3`

---

### Totais
- Efeitos base: **4** (substituir) · Animais: **2** · Recompensas: **5** (opcional)
- Trilha: **2–3** · Ambientes: **40**
- **Mínimo para tudo funcionar bem: ~48 arquivos** (sem os opcionais da seção 3).
