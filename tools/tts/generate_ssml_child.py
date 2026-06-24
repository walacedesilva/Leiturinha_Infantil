"""
generate_ssml_child.py
-----------------------------------------------------------------------------
Cruza:
  - assets/phonetics/phonetic_bank_v1.0_pt-BR_pedagogical.json  (o que falar)
  - assets/voice/child_voice_profiles.json                       (como falar)

Produz SSML Azure Neural TTS já com o perfil de VOZ INFANTIL aplicado
(pitch +15% Francisca / +12% Antonio, cheerful styledegree 1.1-1.2,
small-speaker-compensation, prosody.rate por tipo, ênfase tônica
preservada do banco fonético).

Uso:
    python tools/tts/generate_ssml_child.py
    python tools/tts/generate_ssml_child.py --profile pt_br_boy_6y
    python tools/tts/generate_ssml_child.py --profile pt_br_girl_6y --phase 3
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BANK_PATH   = ROOT / "assets" / "phonetics" / "phonetic_bank_v1.0_pt-BR_pedagogical.json"
VOICE_PATH  = ROOT / "assets" / "voice" / "child_voice_profiles.json"
OUT_BASE    = ROOT / "tools" / "tts" / "out" / "ssml_child"


TEMPLATE = """<speak version="1.0" xml:lang="pt-BR"
       xmlns="http://www.w3.org/2001/10/synthesis"
       xmlns:mstts="https://www.w3.org/2001/mstts">
  <voice name="{voice}">
    <mstts:express-as style="{style}" styledegree="{styledegree}">
      <prosody rate="{rate}" pitch="{pitch}" volume="{volume}">
        {inner}
      </prosody>
    </mstts:express-as>
    <mstts:effect type="{effect}"/>
  </voice>
</speak>
"""


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--profile", default="pt_br_girl_6y",
                    choices=["pt_br_girl_6y", "pt_br_boy_6y"])
    ap.add_argument("--phase", type=int, default=None, help="Filtra fase 1..5")
    args = ap.parse_args()

    bank   = json.loads(BANK_PATH.read_text(encoding="utf-8"))
    voices = json.loads(VOICE_PATH.read_text(encoding="utf-8"))
    profile = voices["child_voice_profiles"][args.profile]
    az = profile["platform_mapping"]["azure"]

    items = bank["phonetic_reference_bank"]["syllables"]
    out_dir = OUT_BASE / args.profile
    out_dir.mkdir(parents=True, exist_ok=True)

    count = 0
    for it in items:
        if args.phase is not None and it.get("phase") != args.phase:
            continue
        is_word = str(it["category"]).startswith("word_")
        # rate vem do perfil; ajusta levemente para sílaba isolada (mais lenta)
        rate = az["prosody"]["rate"]
        if not is_word:
            # 90% -> 85% para sílabas (mais didático)
            try:
                rate = f"{max(80, int(rate.rstrip('%')) - 5)}%"
            except ValueError:
                pass

        ssml = TEMPLATE.format(
            voice=az["voice_name"],
            style=az["style"],
            styledegree=az["style_degree"],
            rate=rate,
            pitch=az["prosody"]["pitch"],
            volume=az["prosody"]["volume"],
            effect=az["post_effect"],
            inner=it["tts_ssml"],
        )

        target = out_dir / f'phase{it.get("phase", 0)}' / f'{it["id"]}.ssml.xml'
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(ssml, encoding="utf-8")
        count += 1

    print(f"[{args.profile}] {count} SSMLs em {out_dir}")
    print(f"  voz: {az['voice_name']}  style: {az['style']} ({az['style_degree']})  "
          f"pitch: {az['prosody']['pitch']}  rate base: {az['prosody']['rate']}")


if __name__ == "__main__":
    main()
