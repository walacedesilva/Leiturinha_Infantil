"""
generate_ssml_from_bank.py
-----------------------------------------------------------------------------
Gerador de SSML para Azure Neural TTS baseado em
assets/phonetics/phonetic_bank_v1.0_pt-BR_pedagogical.json.

Diferenças vs. generate_ssml.py (CSV):
  - Cobre TODAS as 5 fases pedagógicas (vogais, sílabas, encontros, dígrafos,
    palavras-chave): 70 itens.
  - Usa o campo `tts_ssml` pré-definido do banco como base,
    envolvendo-o em <voice> + <prosody> + estilo cheerful.
  - Organiza saída por fase: out/ssml/phaseN/<id>.ssml.xml

Uso:
    python tools/tts/generate_ssml_from_bank.py
    python tools/tts/generate_ssml_from_bank.py --voice pt-BR-AntonioNeural
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT      = Path(__file__).resolve().parents[2]
BANK_PATH = ROOT / "assets" / "phonetics" / "phonetic_bank_v1.0_pt-BR_pedagogical.json"
OUT_DIR   = ROOT / "tools" / "tts" / "out" / "ssml_bank"


WRAPPER = """<speak version="1.0" xml:lang="pt-BR"
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


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--voice", default="pt-BR-FranciscaNeural")
    args = ap.parse_args()

    bank = json.loads(BANK_PATH.read_text(encoding="utf-8"))
    items = bank["phonetic_reference_bank"]["syllables"]
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    count = 0
    for item in items:
        phase = item.get("phase", 0)
        is_word = str(item["category"]).startswith("word_")
        rate = "90%" if is_word else "85%"
        inner = item["tts_ssml"]
        ssml = WRAPPER.format(voice=args.voice, rate=rate, inner=inner)

        target = OUT_DIR / f"phase{phase}" / f'{item["id"]}.ssml.xml'
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(ssml, encoding="utf-8")
        count += 1

    print(f"Gerados {count} SSMLs (banco v{bank['phonetic_reference_bank']['version']}) em {OUT_DIR}")


if __name__ == "__main__":
    main()
