"""
elevenlabs_synthesize.py
-----------------------------------------------------------------------------
Sintetiza o banco fonético usando ElevenLabs com o perfil de voz infantil
definido em assets/voice/child_voice_profiles.json.

Requer:
    pip install elevenlabs
    setx ELEVENLABS_API_KEY "<sua-key>"     # PowerShell

Observações:
  - voice_id padrão é placeholder (`child_pt_br_female_01`). Substitua pela
    ID real do seu Voice Lab (clone/preset) antes de rodar em produção.
  - Roda sequencialmente com pequeno sleep para respeitar rate-limit.

Uso:
    python tools/tts/elevenlabs_synthesize.py --profile pt_br_girl_6y --phase 1
    python tools/tts/elevenlabs_synthesize.py --dry-run
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BANK_PATH  = ROOT / "assets" / "phonetics" / "phonetic_bank_v1.0_pt-BR_pedagogical.json"
VOICE_PATH = ROOT / "assets" / "voice" / "child_voice_profiles.json"
OUT_DIR    = ROOT / "assets" / "audio" / "child_voice"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--profile", default="pt_br_girl_6y")
    ap.add_argument("--phase", type=int, default=None)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    bank   = json.loads(BANK_PATH.read_text(encoding="utf-8"))
    voices = json.loads(VOICE_PATH.read_text(encoding="utf-8"))
    profile = voices["child_voice_profiles"][args.profile]
    el = profile["platform_mapping"]["elevenlabs"]

    api_key = os.environ.get("ELEVENLABS_API_KEY")
    if not args.dry_run and not api_key:
        print("ERRO: defina ELEVENLABS_API_KEY", file=sys.stderr)
        return 2

    if not args.dry_run:
        try:
            from elevenlabs.client import ElevenLabs
            from elevenlabs import VoiceSettings
        except ImportError:
            print("ERRO: pip install elevenlabs", file=sys.stderr)
            return 2
        client = ElevenLabs(api_key=api_key)
        vs = VoiceSettings(
            stability=el["settings"]["stability"],
            similarity_boost=el["settings"]["similarity_boost"],
            style=el["settings"]["style"],
            use_speaker_boost=el["settings"]["use_speaker_boost"],
        )

    out_root = OUT_DIR / args.profile / "elevenlabs"
    out_root.mkdir(parents=True, exist_ok=True)

    items = bank["phonetic_reference_bank"]["syllables"]
    total, ok, fail = 0, 0, 0
    for it in items:
        if args.phase is not None and it.get("phase") != args.phase:
            continue
        total += 1
        # Usa grafema + dica fonética inline para guiar a pronúncia
        text = f"{it['orthographic']}"
        target = out_root / f"phase{it.get('phase', 0)}" / f"{it['id']}.mp3"
        target.parent.mkdir(parents=True, exist_ok=True)

        if args.dry_run:
            print(f"[dry-run] {it['id']:>22}  -> {target.relative_to(ROOT)}")
            continue

        try:
            audio = client.text_to_speech.convert(
                voice_id=el["voice_id"],
                model_id=el["model_id"],
                text=text,
                voice_settings=vs,
                optimize_streaming_latency=el.get("optimize_streaming_latency", 2),
            )
            with target.open("wb") as f:
                for chunk in audio:
                    f.write(chunk)
            ok += 1
            print(f"  OK  {target.relative_to(ROOT)}")
            time.sleep(0.25)  # cortês com rate-limit
        except Exception as e:
            fail += 1
            print(f"  ERR {it['id']}: {e}", file=sys.stderr)

    print(f"\nTotal: {total} | OK: {ok} | Falhas: {fail}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
