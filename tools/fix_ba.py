#!/usr/bin/env python3
"""
Regera sílabas que o edge-tts leu como LETRAS (ex.: "ba" virou "bê-á").
Sintetiza a forma acentuada (ex.: "bá") para forçar a leitura como sílaba /ba/,
salvando com o nome de arquivo original (ba.mp3).

Uso:  py tools/fix_ba.py
"""
import asyncio
import os
import sys

try:
    import edge_tts
except ImportError:
    print("Falta o edge-tts. Rode:  py -m pip install edge-tts")
    sys.exit(1)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SYL_DIR = os.path.join(ROOT, "assets", "audio", "syllables")

VOICE = "pt-BR-FranciscaNeural"
PITCH = "+8Hz"
SYL_RATE = "-20%"

# stem do arquivo  ->  texto falado que força a sílaba correta
FIXES = {
    "ba": "bá",
}


async def synth(text, out_path):
    comm = edge_tts.Communicate(text, VOICE, rate=SYL_RATE, pitch=PITCH)
    await comm.save(out_path)


async def main():
    print(f"Pasta: {SYL_DIR}")
    for stem, spoken in FIXES.items():
        out = os.path.join(SYL_DIR, stem + ".mp3")
        try:
            await synth(spoken, out)
            print(f"  {stem}.mp3  <- '{spoken}'  ok")
        except Exception as e:
            print(f"  {stem}.mp3  ERRO: {e}")
    print("Concluido. Rebuild do app para empacotar.")


if __name__ == "__main__":
    asyncio.run(main())
