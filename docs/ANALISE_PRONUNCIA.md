# Análise Profunda — Pronúncia de Sílabas e Palavras (Leiturinha)

**Objetivo:** falar sílabas e palavras de forma **correta**, com **entonação** e **emoção** apropriadas para crianças de 4–7 anos em alfabetização.

**Data:** 24/06/2026 · Escopo: `lib/services/audio_manager.dart`, `assets/audio/*`, `assets/phonetic_reference_bank.json`, `lib/services/speech_validator.dart` e os ~62 pontos de chamada de áudio no app.

---

## 1. Como a pronúncia funciona hoje

Toda a fala do app vem do **TTS do Android** (`flutter_tts`), em tempo real:

- `playSyllable(s)` → `playSyllableInstant` → `_tts.speak(s.toUpperCase())`
- `playWord(w)` → `_tts.speak(w.toUpperCase())`
- `playWordSlow(w)` → rate 0.25, depois restaura via `setCompletionHandler`
- `speakSentence(frase, isChild)` → pitch 1.30 (criança) ou 1.0 (adulto)

Voz configurada uma vez (`applyChildVoice`): prefere vozes `pt-br-x-ptd/pte`, **pitch fixo 1.30** (para simular voz infantil ~280–320 Hz), **rate 0.45**, volume cheio.

Os efeitos sonoros (acerto, erro, pop, balões) usam WAVs reais via `audioplayers` — esses funcionam bem.

---

## 2. Problemas encontrados (priorizados)

### 🔴 P1 — `toUpperCase()` faz o TTS soletrar letras
Os chamadores já passam minúsculas (`playSyllable(syl.toLowerCase())`, `playWord(word.toLowerCase())`), mas o `AudioManager` **reconverte para MAIÚSCULAS** antes de falar (`_tts.speak(syllable.toUpperCase())`).

Muitos engines TTS Android interpretam texto todo em caixa-alta como **sigla** e leem **letra por letra** ("CASA" → "Cê-Á-Esse-Á") ou mudam a prosódia. É a causa nº 1 de pronúncia errada. **Correção trivial e de alto impacto:** remover o `toUpperCase()` e falar em caixa natural (minúsculas).

### 🔴 P2 — Os áudios pré-gravados são placeholders **mudos**
Existem `assets/audio/syllables/` (76 arquivos) e `assets/audio/words/` (88 arquivos), mas:
- Todos os WAV de sílaba têm **exatamente 2444 bytes**, 8 kHz, 8-bit, 0,300 s, **RMS = 128 (silêncio puro)**.
- Palavras idem (0,3 s, silêncio); `bola.wav` está **corrompido** (não começa com cabeçalho RIFF).
- **Nenhum código os utiliza** — o `AudioManager` só chama TTS.

Ou seja: a infraestrutura de "áudio gravado" existe no projeto, mas o conteúdo nunca foi gravado. Esse é o caminho para **pronúncia correta + entonação + emoção de verdade** (ver §3, Fase 2).

### 🟠 P3 — Banco fonético rico, 100% sem uso
`assets/phonetic_reference_bank.json` traz, por sílaba, **IPA**, SAMPA, traços articulatórios e até `ssml` com `<phoneme alphabet="ipa">`. Nada disso é lido pelo app. Sem isso, sílabas isoladas no TTS sofrem:
- **Epêntese**: "be" sai como "bê" (nome da letra) em vez de /b/+/e/ limpo.
- **Leitura por nome de letra** em sílabas curtas.

### 🟠 P4 — Pitch fixo 1.30 → efeito "chipmunk" e cansativo
Elevar o pitch em +30% sobre uma voz feminina deixa o som metálico/infantilizado artificial. Para alfabetização, a clareza do fonema importa mais que "soar como criança". Pitch alto fixo **piora a inteligibilidade** das vogais.

### 🟠 P5 — Sem entonação por contexto (zero "emoção")
Tudo é dito com a mesma prosódia. Não há diferença entre:
- **sílaba** (deve ser clara e levemente alongada),
- **palavra** (natural, fluida),
- **pergunta** ("Que som é esse?" — entonação ascendente),
- **elogio** ("Muito bem!!" — animada, mais rápida e brilhante),
- **incentivo** ("Quase lá, tenta de novo" — calma e acolhedora).

### 🟡 P6 — Pronúncia de sílaba isolada é intrinsecamente frágil no TTS
TTS é treinado em palavras/frases. Sílabas soltas ("fa", "xa", "lho") caem em casos de borda. Mesmo sem o bug do P1, a qualidade varia muito por aparelho/engine. **A única forma realmente confiável é áudio pré-gravado** (humano ou TTS neural de alta qualidade).

### 🟡 P7 — Restauração de velocidade frágil
`playWordSlow` usa `setCompletionHandler` para voltar o rate a 0.45, mas esse handler é **global** e fica registrado para todas as falas seguintes — efeitos colaterais e condições de corrida. Melhor restaurar o estado de forma explícita/escopada por chamada.

### 🟡 P8 — `dispose()` é singleton, mas chamado por telas
`AudioManager` é singleton; se alguma tela chamar `dispose()`, derruba o TTS para o app inteiro. Vale revisar (fora do escopo de pronúncia, mas relevante para estabilidade do áudio).

---

## 3. Plano de melhoria (em fases)

### Fase 1 — Correções de código (rápidas, alto impacto, sem novos assets)
1. **Remover `toUpperCase()`** em sílabas e palavras → falar em caixa natural. *(resolve P1)*
2. **Prosódia por contexto** — perfis de fala:
   - `syllable`: rate 0.40, pitch 1.15, leve pausa final.
   - `word`: rate 0.50, pitch 1.10.
   - `wordSlow`: rate 0.30, pitch 1.10.
   - `question`: rate 0.50, pitch 1.20 (final ascendente via pontuação "?").
   - `praise`: rate 0.62, pitch 1.30 (animada).
   - `encourage`: rate 0.48, pitch 1.12 (calma).
   *(ataca P4 e P5)*
3. **Baixar o pitch padrão** de 1.30 → ~1.10–1.15 (mais inteligível; ainda "fofo"). *(P4)*
4. **Restaurar rate/pitch de forma escopada** (salvar/aplicar/retornar por chamada, sem handler global). *(P7)*
5. **SSML/`<phoneme>` quando suportado** — tentar usar o IPA do banco fonético para sílabas; se o engine não suportar, cair no texto natural. *(P3 — ganho parcial; SSML no Android é dependente do engine, então é "melhor esforço")*
6. **Arquitetura "áudio-primeiro com fallback"** — `playSyllable`/`playWord` tentam tocar `assets/audio/.../<chave>.wav`; se não existir/for inválido, usam TTS. Já deixa o app pronto para a Fase 2 sem mexer nos 62 chamadores.

> A Fase 1 melhora muito a **correção** e introduz **entonação/emoção** via prosódia, mas o teto de qualidade ainda é o do TTS do aparelho.

### Fase 2 — Áudio real pré-gravado (recomendado para qualidade final)
Substituir os placeholders mudos por gravações de verdade, com **entonação e emoção** consistentes:

- **Opção A (melhor custo/qualidade): TTS neural offline na geração.** Rodar um modelo neural pt-BR de alta qualidade (ex.: Coqui/XTTS, Piper, ou um TTS de nuvem premium em build-time) para gerar **todas as sílabas e palavras** (e as falas de elogio/incentivo) como WAV/OGG, conferir manualmente e versionar em `assets/audio/`. Resultado: pronúncia correta e estável em **qualquer** aparelho, sem depender do TTS local.
- **Opção B (máxima emoção): locutor(a) humano(a).** Um(a) profissional grava sílabas, palavras e bordões com a emoção certa. É o padrão-ouro para apps infantis, porém mais caro/lento.
- Em ambos os casos: manter o TTS como **fallback** para conteúdo novo ainda não gravado.
- Especificação técnica sugerida: **mono, 22.05 kHz, 16-bit (ou OGG ~64–96 kbps)**, normalizado a ~ -16 LUFS, com 80–120 ms de silêncio nas bordas. (Os placeholders atuais são 8 kHz/8-bit — baixo demais.)

### Fase 3 — Camada de emoção/expressividade
- **Variantes de elogio/incentivo** (3–5 versões de "Muito bem!", "Isso!", "Quase!") sorteadas para não ficar repetitivo.
- **Ritmo pedagógico**: sílaba → pausa curta → palavra → reforço. Encadear áudios com pequenas pausas naturais.
- **Marcação prosódica** nas frases (ênfase na sílaba-alvo).

---

## 4. Impacto esperado

| Item | Hoje | Após Fase 1 | Após Fase 2 |
|---|---|---|---|
| Palavra lida corretamente | ⚠️ risco de soletrar | ✅ correta | ✅ correta e natural |
| Sílaba isolada | ⚠️ instável | 🟡 melhor | ✅ estável |
| Entonação/emoção | ❌ nenhuma | 🟡 por contexto | ✅ rica |
| Consistência entre aparelhos | ❌ depende do TTS | ❌ ainda depende | ✅ independente |

---

## 5. Recomendação

Começar pela **Fase 1** já — é de baixo risco, centralizada no `AudioManager` (não exige tocar nos 62 chamadores) e corrige o problema mais grave (P1) imediatamente, além de introduzir entonação por contexto. Em paralelo, planejar a **Fase 2** (gerar o áudio real), que é o que de fato entrega "pronúncia correta com entonação e emoção" de forma definitiva.

> Observação: posso implementar a Fase 1 agora (refatorar o `AudioManager` com perfis de prosódia + remoção do `toUpperCase()` + arquitetura áudio-primeiro) e, se quiser, montar um **script de geração de áudio** para a Fase 2.
