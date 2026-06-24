#!/usr/bin/env python3
"""
Gera os áudios reais de sílabas e palavras com voz neural pt-BR (edge-tts),
substituindo os placeholders mudos em assets/audio/.

- Voz: pt-BR-FranciscaNeural (feminina, acolhedora). Troque em VOICE se quiser.
- Sílabas faladas mais devagar (clareza); palavras em ritmo natural.
- Cria <nome>.mp3 e remove o <nome>.wav antigo (placeholder).
- A lista vem dos próprios arquivos já existentes em assets/audio/.

Uso:  py tools/gen_audio.py            (gera tudo)
      py tools/gen_audio.py teste      (gera só "ba" e "casa" para testar)
"""
import asyncio
import glob
import os
import sys

try:
    import edge_tts
except ImportError:
    print("Falta o edge-tts. Rode:  py -m pip install edge-tts")
    sys.exit(1)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SYL_DIR = os.path.join(ROOT, "assets", "audio", "syllables")
WORD_DIR = os.path.join(ROOT, "assets", "audio", "words")

VOICE = "pt-BR-FranciscaNeural"
PITCH = "+8Hz"          # leve brilho, mais amigável p/ crianças
SYL_RATE = "-20%"       # sílaba bem articulada
WORD_RATE = "-5%"       # palavra natural


async def synth(text, out_path, rate):
    comm = edge_tts.Communicate(text, VOICE, rate=rate, pitch=PITCH)
    await comm.save(out_path)


def stems_in(dirpath):
    found = set()
    for ext in ("*.wav", "*.mp3"):
        for p in glob.glob(os.path.join(dirpath, ext)):
            found.add(os.path.splitext(os.path.basename(p))[0].lower())
    return sorted(found)


async def process(dirpath, rate, label, only=None):
    stems = stems_in(dirpath)
    if only:
        stems = [s for s in stems if s in only]
    print(f"\n== {label}: {len(stems)} itens ==")
    ok = 0
    for i, stem in enumerate(stems, 1):
        out = os.path.join(dirpath, stem + ".mp3")
        try:
            await synth(stem, out, rate)
            wav = os.path.join(dirpath, stem + ".wav")
            if os.path.exists(wav):
                os.remove(wav)
            ok += 1
            print(f"  [{i}/{len(stems)}] {stem}  ok")
        except Exception as e:
            print(f"  [{i}/{len(stems)}] {stem}  ERRO: {e}")
    print(f"  -> {ok}/{len(stems)} gerados")


async def main():
    test = len(sys.argv) > 1 and sys.argv[1] == "teste"
    if test:
        await process(SYL_DIR, SYL_RATE, "Silabas (teste)", only={"ba"})
        await process(WORD_DIR, WORD_RATE, "Palavras (teste)", only={"casa"})
    else:
        await process(SYL_DIR, SYL_RATE, "Silabas")
        await process(WORD_DIR, WORD_RATE, "Palavras")
    print("\nConcluido. Faca o rebuild do app para empacotar os .mp3.")


if __name__ == "__main__":
    asyncio.run(main())
