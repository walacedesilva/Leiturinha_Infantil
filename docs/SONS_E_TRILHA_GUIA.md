# Leiturinha — Varredura de Sons (não-palavras) + Guia de Trilha e Efeitos

> Gerado em 24/06/2026. Cobre tudo que **não é fala** (sílabas/palavras gravadas): efeitos sonoros, clipes de animais, áudios ambientes das histórias e trilha sonora de fundo.

---

## 1. Resumo da situação

| Categoria | Existe? | Qualidade atual | Tocado pelo código? | Ação |
|---|---|---|---|---|
| SFX base (4) | ✅ Sim | ❌ Placeholder sintético (beep 8-bit, 16 kHz) | ✅ Sim | **Substituir por sons reais** |
| Clipes de animais (2) | ❌ Não | — | ✅ Sim (`playClip`) — hoje fica em silêncio | **Baixar e adicionar** |
| `AppSfxFiles` (5) | ❌ Não | — | ❌ Não (só declarados) | Decidir: usar ou remover |
| Áudios ambientes das histórias (40) | ❌ Não | — | ❌ Não (campo lido, nunca tocado) | **Baixar + implementar** |
| Trilha sonora de fundo | ❌ Não | — | ❌ Não implementada (só slider de volume) | **Baixar + implementar** |

A pasta dos sons é `assets/audio/sfx/`. As palavras/sílabas (`assets/audio/words/`, `assets/audio/syllables/`) **não** entram aqui — são fala e já estão prontas.

---

## 2. SFX base — substituir os 4 placeholders

Hoje os 4 arquivos são bipes sintéticos (PCM 8-bit, mono, 16 kHz). Troque pelos reais **mantendo o mesmo nome e caminho** — o código já os usa via o enum `SFXType` → `playSFX()`.

| Arquivo (manter o nome) | Quando toca | Que som baixar |
|---|---|---|
| `assets/audio/sfx/correct.wav` | Acerto da criança | "ding"/chime curto e alegre, ~0,4–0,8 s |
| `assets/audio/sfx/error.wav` | Erro (suave, sem punir) | "bloop"/"boop" grave e gentil, ~0,4 s |
| `assets/audio/sfx/pop.wav` | Toque em botão/peça | "pop"/"bubble" curtíssimo, ~0,1–0,2 s |
| `assets/audio/sfx/balloons.wav` | Celebração/balões | confete/sininhos/aplauso curto, ~1–2 s |

Onde é disparado no código (já funciona): `playSFX(SFXType.correct/error/pop/balloons)` em quase todas as telas de jogo (`game_logic.dart`, `*_screen.dart`).

> Dica: pode trocar a extensão para `.mp3` (mais leve), mas então atualize as strings em `lib/services/audio_manager.dart` no método `playSFX` (linhas ~248–253).

---

## 3. Clipes de animais — adicionar (já referenciados)

O código (`story_player_screen.dart` linha 121 → `AudioManager().playClip(nome)`) toca `assets/audio/sfx/<nome>.mp3` para personagens `animal_<nome>`. Hoje **não existem** e ficam em silêncio (fallback seguro).

| Arquivo a criar | Personagem | Som |
|---|---|---|
| `assets/audio/sfx/leao.mp3` | Leão (história Safari) | rugido curto |
| `assets/audio/sfx/sapo.mp3` | Sapo (história Safari) | coaxar curto |

> Quando criar novas histórias com `animal_gato`, `animal_passaro` etc., basta adicionar `gato.mp3`, `passaro.mp3` nessa mesma pasta — nenhuma mudança de código necessária.

---

## 4. `AppSfxFiles` — 5 sons declarados, mas não usados

Em `lib/core/app_colors.dart` (linhas ~986–1000) existe a classe `AppSfxFiles` apontando para arquivos que **não existem e não são chamados em lugar nenhum**:

`sfx-success.mp3`, `sfx-achievement.mp3`, `sfx-coin.mp3`, `sfx-try-again.mp3`, `sfx-recording-start.mp3`

Duas opções: (a) **remover** a classe (código morto), ou (b) **usá-los** de fato (ex.: moeda ao ganhar recompensa, "achievement" ao concluir distrito). Se for usar, baixe-os e adicione em `assets/audio/sfx/`.

---

## 5. Áudios ambientes das histórias — 40 arquivos + implementação

O JSON `assets/stories/stories_pack_v1.json` referencia 40 trilhas de ambiente (campo `ambientAudio`), uma por ato/cena. **Nenhuma existe** e, além disso, o código **lê o campo mas nunca toca** (ver `StoryBackground.ambientAudio` em `story_models.dart` — só parsing). Então falta baixar **e** implementar (ver §7).

Lista completa por história (caminhos exatos do JSON):

**Safari** — `assets/stories/story_safari_v1/`: `act1_ambient_savana.mp3`, `act2_ambient_mixed.mp3`, `act3_ambient_crossroads.mp3`, `act3b_savana_golden.mp3`, `act3b_lago_crystal.mp3`, `act4_ambient_celebration.mp3`

**Cozinha** — `assets/stories/story_cozinha_v1/`: `act1_ambient_kitchen.mp3`, `act2_ambient_cooking.mp3`, `act3_ambient_choice.mp3`, `act3b_sweet_jingle.mp3`, `act3b_savory_jingle.mp3`, `act4_ambient_celebration.mp3`

**Planetas** — `assets/stories/story_planetas_v1/`: `act1_ambient_launch.mp3`, `act2_ambient_space.mp3`, `act3_ambient_orbit.mp3`, `act3b_warp_speed.mp3`, `act3b_scenic_wonders.mp3`, `act4_ambient_planet_surface.mp3`

**Teatro** — `assets/stories/story_teatro_v1/`: `act1_ambient_backstage.mp3`, `act2_ambient_stage.mp3`, `act3_ambient_conflict.mp3`, `act3b_dialogue_resolved.mp3`, `act3b_silence_peace.mp3`, `act4_ambient_spotlight.mp3`

**Jardim** — `assets/stories/story_jardim_v1/`: `act1_ambient_garden_morning.mp3`, `act2_ambient_garden_planting.mp3`, `act3_ambient_twilight.mp3`, `act3b_day_garden.mp3`, `act3b_night_garden.mp3`, `act4_ambient_celebration.mp3`

**Floresta Sussurrante** — `assets/stories/whispering_forest/`: `act1_ambient.mp3`, `act2_rain.mp3`, `act3_rain_rhythm.mp3`, `act4_thunder.mp3`, `act5_rainbow.mp3`

**Heloísa e o Amigo Trovão** — `assets/stories/heloisa_thunder_friend/`: `act1_ambient.mp3`, `act2_ambient.mp3`, `act3_ambient.mp3`, `act4_ambient.mp3`, `act5_ambient.mp3`

> ⚠️ **pubspec**: hoje o `pubspec.yaml` só registra `assets/stories/` (arquivos diretos). O Flutter **não inclui subpastas automaticamente** — cada subpasta acima precisa ser listada, OU mova os ambientes para `assets/audio/ambient/` e ajuste os caminhos no JSON (recomendado, mais limpo).

Sugestão de tipo de som por palavra-chave no nome: `savana/garden_morning` = ambiente natural com pássaros; `rain/thunder` = chuva/trovão; `space/launch/warp` = sci-fi/whoosh; `kitchen/cooking` = cozinha aconchegante; `stage/spotlight/backstage` = teatro; `celebration` = festa suave; `jingle` = melodia curta (3–5 s).

---

## 6. Onde baixar sons reais (grátis, uso comercial)

Priorize licença **CC0 / domínio público** (sem atribuição obrigatória):

- **Pixabay** (pixabay.com/sound-effects e /music) — CC0, ótimo para SFX e trilhas infantis.
- **Mixkit** (mixkit.co/free-sound-effects, /free-stock-music) — grátis para uso comercial.
- **Freesound** (freesound.org) — enorme; **filtre por licença CC0** (algumas exigem crédito).
- **OpenGameArt** (opengameart.org) — SFX e música de jogos, filtrar CC0.
- **Incompetech** (incompetech.com) — trilhas de Kevin MacLeod (CC-BY, exige crédito).
- **Zapsplat** (zapsplat.com) — grande acervo (conta grátis; checar termos de crédito).

**Termos de busca úteis:** correct → "success chime kids", error → "wrong soft buzzer gentle", pop → "bubble pop ui", balloons → "celebration confetti win", leão → "lion roar short", sapo → "frog croak", ambiente → "savanna ambience", "rain loop", "space ambience loop", "kids playful background music loop".

**Especificações recomendadas antes de colocar no app:**
- Formato **`.mp3`** (≈128 kbps) para tudo, exceto manter `.wav` nos 4 SFX base se não quiser mexer no código. 44,1 kHz, estéreo (SFX podem ser mono).
- **SFX:** curtos (0,1–2 s), normalizados (~ -3 dBFS), sem silêncio nas pontas.
- **Trilha/ambiente:** **loop perfeito** (sem clique na emenda), 30 s–2 min, volume mais baixo que a narração.
- Converter/normalizar com ffmpeg, ex.: `ffmpeg -i entrada.wav -ar 44100 -ac 2 -b:a 128k saida.mp3`

---

## 7. Implementar trilha sonora de fundo + ambiente

Hoje só existe o **slider** de volume ("Trilha Sonora 🎵" em `settings_screen.dart`) e os métodos `setMusicVolume`/`setMasterVolume` — mas **nada toca música**. Abaixo, como ligar de fato.

### 7.1 Estrutura de pastas
Crie `assets/audio/music/` (trilhas de tela: menu, mapa, jogo) e `assets/audio/ambient/` (ambientes de história). Registre no `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/audio/syllables/
    - assets/audio/words/
    - assets/audio/sfx/
    - assets/audio/music/      # NOVO
    - assets/audio/ambient/    # NOVO
```

### 7.2 Adicionar canais de música/ambiente no AudioManager
Em `lib/services/audio_manager.dart`, adicione os campos e métodos (a classe já importa `audioplayers` e já tem `_musicVolume`, `_masterVolume`):

```dart
  AudioPlayer? _musicPlayer;
  String? _currentMusic;
  AudioPlayer? _ambientPlayer;
  String? _currentAmbient;

  /// Trilha de tela em loop. Ex.: playMusic('menu'), playMusic('mapa').
  Future<void> playMusic(String name, {bool loop = true}) async {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return;
    if (_currentMusic == n && _musicPlayer != null) return; // já tocando
    await stopMusic();
    try {
      final p = AudioPlayer();
      _musicPlayer = p;
      _currentMusic = n;
      await p.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await p.setVolume(_musicVolume * _masterVolume);
      await p.play(AssetSource('audio/music/$n.mp3'));
    } catch (e) {
      debugPrint('[AudioManager] music $n: $e');
    }
  }

  Future<void> stopMusic() async {
    try { await _musicPlayer?.stop(); await _musicPlayer?.dispose(); } catch (_) {}
    _musicPlayer = null;
    _currentMusic = null;
  }

  /// Ambiente de história. Aceita 'audio/ambient/x.mp3' ou caminho completo do JSON.
  Future<void> playAmbient(String? assetPath, {bool loop = true}) async {
    if (assetPath == null || assetPath.trim().isEmpty) { await stopAmbient(); return; }
    var path = assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;
    if (_currentAmbient == path && _ambientPlayer != null) return;
    await stopAmbient();
    try {
      final p = AudioPlayer();
      _ambientPlayer = p;
      _currentAmbient = path;
      await p.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await p.setVolume(_musicVolume * _masterVolume * 0.7); // ambiente mais baixo
      await p.play(AssetSource(path));
    } catch (e) {
      debugPrint('[AudioManager] ambient $path: $e');
    }
  }

  Future<void> stopAmbient() async {
    try { await _ambientPlayer?.stop(); await _ambientPlayer?.dispose(); } catch (_) {}
    _ambientPlayer = null;
    _currentAmbient = null;
  }
```

Faça os sliders agirem **ao vivo** — atualize os setters existentes:

```dart
  void setMasterVolume(double val) {
    _masterVolume = val;
    _tts.setVolume(_narrationVolume * _masterVolume);
    _musicPlayer?.setVolume(_musicVolume * _masterVolume);
    _ambientPlayer?.setVolume(_musicVolume * _masterVolume * 0.7);
  }

  void setMusicVolume(double val) {
    _musicVolume = val;
    _musicPlayer?.setVolume(_musicVolume * _masterVolume);
    _ambientPlayer?.setVolume(_musicVolume * _masterVolume * 0.7);
  }
```

E no `dispose()` adicione `_musicPlayer?.dispose(); _ambientPlayer?.dispose();`.

### 7.3 Usar nas telas
- **Trilha por tela**: em `initState` da tela, `AudioManager().playMusic('menu');` (ou `'mapa'`, `'jogo_calmo'`). Como `playMusic` ignora se já é a mesma faixa, navegar entre telas que pedem a mesma trilha não corta a música.
- **Ambiente de história**: no `story_player_screen.dart`, quando o background muda de ato, chame `AudioManager().playAmbient(background.ambientAudio);` e `AudioManager().stopAmbient();` ao sair da história. (O campo `ambientAudio` já é parseado em `StoryBackground` — só falta esta chamada.)
- **Pausar ao sair do app**: em `WidgetsBindingObserver.didChangeAppLifecycleState`, chame `stopMusic()/stopAmbient()` em `paused` e retome em `resumed`.

### 7.4 Arquivos mínimos de trilha sugeridos
Comece com 3 faixas em loop em `assets/audio/music/`: `menu.mp3` (alegre, leve), `mapa.mp3` (aventura suave), `jogo.mp3` (neutra, baixa, não distrai a leitura). Depois adicione ambientes conforme a §5.

---

## 8. Checklist de execução

1. Baixar SFX reais (§2) e sobrescrever os 4 `.wav`.
2. Baixar `leao.mp3` e `sapo.mp3` → `assets/audio/sfx/` (§3).
3. Decidir sobre `AppSfxFiles` (§4): usar ou remover.
4. Criar `assets/audio/music/` e `assets/audio/ambient/`, registrar no `pubspec.yaml` (§7.1).
5. Baixar trilhas (menu/mapa/jogo) e os 40 ambientes (§5/§6).
6. Aplicar o código de `playMusic`/`playAmbient` e os setters ao vivo (§7.2).
7. Chamar `playMusic`/`playAmbient` nas telas e na história (§7.3).
8. `flutter pub get` → testar volume nos sliders → testar loop sem clique.
