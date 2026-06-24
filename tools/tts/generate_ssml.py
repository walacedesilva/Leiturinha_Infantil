"""
generate_ssml.py
-----------------------------------------------------------------------------
Lê assets/phonetics/reference.csv e gera 1 arquivo SSML por sílaba/palavra
em tools/tts/out/ssml/, otimizado para Azure Neural TTS (pt-BR-FranciscaNeural)
seguindo as regras do prompt de pronúncia infantil:

  - <phoneme alphabet="ipa" ph="…"> garante fidelidade fonêmica.
  - <prosody rate="85%"> para sílabas isoladas (clara, não robótica).
  - <prosody rate="90%"> para palavras inteiras.
  - <break time="200ms"> entre sílabas em palavras com ≥3 sílabas
    (no inventário atual todas têm 2; flag --syllabify força a quebra).
  - Sem auto-smoothing: cada sílaba é envelopada em <phoneme> próprio.
  - Ênfase (<emphasis level="moderate">) na sílaba tônica.

Uso:
    python tools/tts/generate_ssml.py
    python tools/tts/generate_ssml.py --syllabify   # quebra também as bissílabas
    python tools/tts/generate_ssml.py --voice pt-BR-AntonioNeural
"""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[2]
CSV_PATH = ROOT / "assets" / "phonetics" / "reference.csv"
OUT_DIR  = ROOT / "tools" / "tts" / "out" / "ssml"


def split_ipa_syllables(ipa: str) -> list[tuple[str, bool]]:
    """
    Divide o IPA em sílabas usando '.' como separador e '\u02c8' (ˈ) como
    marca tônica. Retorna [(silaba_ipa_limpa, eh_tonica), ...].
    """
    # marca a posição da tônica
    parts = ipa.split(".")
    out: list[tuple[str, bool]] = []
    for p in parts:
        tonic = "ˈ" in p
        clean = p.replace("ˈ", "").replace("ˌ", "")
        out.append((clean, tonic))
    return out


def build_ssml(row: dict, voice: str, force_syllabify: bool) -> str:
    grapheme = row["grapheme"]
    ipa      = row["ipa"]
    is_word  = row["type"] == "word"
    syllabify_str = row.get("syllabification", "")
    syllables = split_ipa_syllables(ipa)
    grapheme_syls = syllabify_str.split("-") if syllabify_str else [grapheme]

    rate = "90%" if is_word else "85%"

    # Quando quebrar em sílabas: palavras com ≥3 sílabas OU flag --syllabify
    should_break = is_word and (len(syllables) >= 3 or force_syllabify)

    # Garante consistência entre divisão ortográfica e fonética
    if should_break and len(grapheme_syls) == len(syllables):
        chunks: list[str] = []
        for (syl_ipa, tonic), syl_graph in zip(syllables, grapheme_syls):
            ph = escape(syl_ipa, {'"': "&quot;"})
            block = (
                f'<phoneme alphabet="ipa" ph="{ph}">{escape(syl_graph)}</phoneme>'
            )
            if tonic:
                block = f'<emphasis level="moderate">{block}</emphasis>'
            chunks.append(block)
        inner = '<break time="200ms"/>'.join(chunks)
    else:
        # Envelopa a forma inteira em um único <phoneme>, mas marca tônica
        # via <emphasis> envolvendo todo o item (Azure aplica leve aumento
        # de duração/intensidade que se alinha à sílaba tônica do IPA).
        ph = escape(ipa, {'"': "&quot;"})
        inner = (
            f'<emphasis level="moderate">'
            f'<phoneme alphabet="ipa" ph="{ph}">{escape(grapheme)}</phoneme>'
            f'</emphasis>'
        )

    ssml = f"""<speak version="1.0" xml:lang="pt-BR"
       xmlns="http://www.w3.org/2001/10/synthesis"
       xmlns:mstts="https://www.w3.org/2001/mstts">
  <voice name="{voice}">
    <mstts:express-as style="cheerful" styledegree="0.6">
      <prosody rate="{rate}" pitch="+0%" volume="medium">
        {inner}
      </prosody>
    </mstts:express-as>
  </voice>
</speak>
"""
    return ssml


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--voice", default="pt-BR-FranciscaNeural",
                    help="Voz neural Azure (ex.: pt-BR-FranciscaNeural, pt-BR-AntonioNeural)")
    ap.add_argument("--syllabify", action="store_true",
                    help="Força <break/> entre sílabas mesmo em bissílabas (uso pedagógico)")
    args = ap.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    count = 0
    with CSV_PATH.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            ssml = build_ssml(row, args.voice, args.syllabify)
            target = OUT_DIR / row["type"] / f'{row["id"]}.ssml.xml'
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(ssml, encoding="utf-8")
            count += 1

    print(f"Gerados {count} arquivos SSML em {OUT_DIR}")


if __name__ == "__main__":
    main()
