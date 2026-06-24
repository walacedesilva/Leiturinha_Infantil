"""
google_synthesize.py
-----------------------------------------------------------------------------
Sintetiza o banco fonético usando Google Cloud TTS com o perfil infantil.

Requer:
    pip install google-cloud-texttospeech
    setx GOOGLE_APPLICATION_CREDENTIALS "C:\\path\\to\\service-account.json"

Uso:
    python tools/tts/google_synthesize.py --profile pt_br_girl_6y --phase 2
"""

from __future__ import annotations

import argparse
import json
import os
import sys
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
    g = profile["platform_mapping"]["google"]

    if not args.dry_run:
        if not os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
            print("ERRO: defina GOOGLE_APPLICATION_CREDENTIALS", file=sys.stderr)
            return 2
        try:
            from google.cloud import texttospeech as tts
        except ImportError:
            print("ERRO: pip install google-cloud-texttospeech", file=sys.stderr)
            return 2
        client = tts.TextToSpeechClient()
        voice = tts.VoiceSelectionParams(
            language_code="pt-BR",
            name=g["voice_name"],
            ssml_gender=tts.SsmlVoiceGender[g["ssml_gender"]],
        )
        cfg = g["config_overrides"]
        audio_cfg = tts.AudioConfig(
            audio_encoding=tts.AudioEncoding[cfg["audioEncoding"]],
            sample_rate_hertz=cfg["sampleRateHertz"],
            speaking_rate=cfg["speakingRate"],
            pitch=cfg["pitch"],
            volume_gain_db=cfg["volumeGainDb"],
            effects_profile_id=cfg["effectsProfileId"],
        )

    out_root = OUT_DIR / args.profile / "google"
    out_root.mkdir(parents=True, exist_ok=True)

    items = bank["phonetic_reference_bank"]["syllables"]
    total, ok, fail = 0, 0, 0
    for it in items:
        if args.phase is not None and it.get("phase") != args.phase:
            continue
        total += 1
        # Google aceita SSML completo via input.ssml
        ssml = f'<speak>{it["tts_ssml"]}</speak>'
        target = out_root / f"phase{it.get('phase', 0)}" / f"{it['id']}.wav"
        target.parent.mkdir(parents=True, exist_ok=True)

        if args.dry_run:
            print(f"[dry-run] {it['id']:>22}  -> {target.relative_to(ROOT)}")
            continue

        try:
            response = client.synthesize_speech(
                input=tts.SynthesisInput(ssml=ssml),
                voice=voice, audio_config=audio_cfg,
            )
            target.write_bytes(response.audio_content)
            ok += 1
            print(f"  OK  {target.relative_to(ROOT)}")
        except Exception as e:
            fail += 1
            print(f"  ERR {it['id']}: {e}", file=sys.stderr)

    print(f"\nTotal: {total} | OK: {ok} | Falhas: {fail}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
