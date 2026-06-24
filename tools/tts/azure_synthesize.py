"""
azure_synthesize.py
-----------------------------------------------------------------------------
Sintetiza em lote SSMLs usando Azure Speech REST API.

Suporta TRÊS layouts de entrada (autodetectados):

  L1) tools/tts/out/ssml/{syllable,word}/*.ssml.xml
      → gerado por generate_ssml.py (CSV). Saída em assets/audio/{syllables,words}/.

  L2) tools/tts/out/ssml_bank/phase{1..5}/*.ssml.xml
      → gerado por generate_ssml_from_bank.py.
      Saída em assets/audio/bank/phase{N}/.

  L3) tools/tts/out/ssml_child/<profile>/phase{1..5}/*.ssml.xml
      → gerado por generate_ssml_child.py (perfil de voz infantil).
      Saída em assets/audio/child_voice/<profile>/azure/phase{N}/.

Variáveis de ambiente obrigatórias:
    AZURE_SPEECH_KEY     – chave de assinatura
    AZURE_SPEECH_REGION  – ex.: brazilsouth, eastus

Uso:
    python tools/tts/azure_synthesize.py                          # L1 padrão
    python tools/tts/azure_synthesize.py --bank                   # L2
    python tools/tts/azure_synthesize.py --profile pt_br_girl_6y  # L3
    python tools/tts/azure_synthesize.py --ssml-dir <dir> --out-dir <dir>
    python tools/tts/azure_synthesize.py --dry-run
"""

from __future__ import annotations

import argparse
import os
import sys
import time
from pathlib import Path
from urllib import request as urlrequest
from urllib.error import HTTPError, URLError

ROOT = Path(__file__).resolve().parents[2]

# Layouts pré-definidos: (ssml_dir, out_dir)
LEGACY_SSML_DIR = ROOT / "tools" / "tts" / "out" / "ssml"
LEGACY_OUT = {
    "syllable": ROOT / "assets" / "audio" / "syllables",
    "word":     ROOT / "assets" / "audio" / "words",
}

BANK_SSML_DIR = ROOT / "tools" / "tts" / "out" / "ssml_bank"
BANK_OUT_DIR  = ROOT / "assets" / "audio" / "bank"

CHILD_SSML_ROOT = ROOT / "tools" / "tts" / "out" / "ssml_child"
CHILD_OUT_ROOT  = ROOT / "assets" / "audio" / "child_voice"

AUDIO_FORMAT = "riff-24khz-16bit-mono-pcm"
USER_AGENT   = "Leiturinha-TTS/1.0"


def synth_one(key: str, region: str, ssml: str) -> bytes:
    url = f"https://{region}.tts.speech.microsoft.com/cognitiveservices/v1"
    req = urlrequest.Request(
        url,
        data=ssml.encode("utf-8"),
        method="POST",
        headers={
            "Ocp-Apim-Subscription-Key": key,
            "Content-Type": "application/ssml+xml",
            "X-Microsoft-OutputFormat": AUDIO_FORMAT,
            "User-Agent": USER_AGENT,
        },
    )
    with urlrequest.urlopen(req, timeout=30) as resp:
        return resp.read()


def resolve_jobs(args: argparse.Namespace) -> list[tuple[Path, Path]]:
    """Mapeia (ssml_path -> wav_path) conforme o layout escolhido."""
    jobs: list[tuple[Path, Path]] = []

    # 1) Override manual (--ssml-dir / --out-dir): preserva a árvore sob ssml_dir
    if args.ssml_dir:
        ssml_root = Path(args.ssml_dir).resolve()
        out_root  = Path(args.out_dir or (ssml_root / "wav")).resolve()
        for p in sorted(ssml_root.rglob("*.ssml.xml")):
            rel_parent = p.relative_to(ssml_root).parent
            wav = out_root / rel_parent / f"{p.name.replace('.ssml.xml', '')}.wav"
            jobs.append((p, wav))
        return jobs

    # 2) Layout child voice
    if args.profile:
        ssml_root = CHILD_SSML_ROOT / args.profile
        out_root  = CHILD_OUT_ROOT / args.profile / "azure"
        for p in sorted(ssml_root.rglob("*.ssml.xml")):
            rel_phase = p.parent.name  # phase1, phase2, ...
            wav = out_root / rel_phase / f"{p.name.replace('.ssml.xml', '')}.wav"
            jobs.append((p, wav))
        return jobs

    # 3) Layout bank
    if args.bank:
        for p in sorted(BANK_SSML_DIR.rglob("*.ssml.xml")):
            rel_phase = p.parent.name
            wav = BANK_OUT_DIR / rel_phase / f"{p.name.replace('.ssml.xml', '')}.wav"
            jobs.append((p, wav))
        return jobs

    # 4) Layout legacy (default): syllable/word
    folders: list[tuple[str, Path]] = []
    if args.only in (None, "syllables"):
        folders.append(("syllable", LEGACY_SSML_DIR / "syllable"))
    if args.only in (None, "words"):
        folders.append(("word",     LEGACY_SSML_DIR / "word"))
    for kind, folder in folders:
        if not folder.exists():
            continue
        out_dir = LEGACY_OUT[kind]
        for p in sorted(folder.glob("*.ssml.xml")):
            wav = out_dir / f"{p.name.replace('.ssml.xml', '')}.wav"
            jobs.append((p, wav))
    return jobs


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", choices=["syllables", "words"], default=None,
                    help="(Layout legacy) Restringe a sílabas ou palavras.")
    ap.add_argument("--bank", action="store_true",
                    help="Usa o layout do banco fonético v1.0 (tools/tts/out/ssml_bank/).")
    ap.add_argument("--profile", default=None,
                    help="Usa o layout de voz infantil (tools/tts/out/ssml_child/<profile>/).")
    ap.add_argument("--ssml-dir", default=None,
                    help="Diretório-raiz alternativo de SSMLs (recursivo).")
    ap.add_argument("--out-dir", default=None,
                    help="Diretório-raiz de saída para --ssml-dir (preserva subpastas).")
    ap.add_argument("--dry-run", action="store_true",
                    help="Lista o que seria sintetizado, sem chamar Azure.")
    args = ap.parse_args()

    key    = os.environ.get("AZURE_SPEECH_KEY")
    region = os.environ.get("AZURE_SPEECH_REGION")
    if not args.dry_run and (not key or not region):
        print("ERRO: defina AZURE_SPEECH_KEY e AZURE_SPEECH_REGION.", file=sys.stderr)
        return 2

    jobs = resolve_jobs(args)
    if not jobs:
        print("Nenhum SSML encontrado. Rode antes um dos generate_ssml*.py "
              "ou ajuste --ssml-dir.", file=sys.stderr)
        return 1

    total, ok, fail = 0, 0, 0
    for ssml_path, wav_path in jobs:
        total += 1
        if args.dry_run:
            print(f"[dry-run] {ssml_path.relative_to(ROOT)} -> {wav_path.relative_to(ROOT)}")
            continue
        wav_path.parent.mkdir(parents=True, exist_ok=True)
        try:
            ssml = ssml_path.read_text(encoding="utf-8")
            audio = synth_one(key, region, ssml)
            wav_path.write_bytes(audio)
            ok += 1
            print(f"  OK  {wav_path.relative_to(ROOT)} ({len(audio)//1024} KB)")
            time.sleep(0.06)  # cortês com rate-limit
        except HTTPError as e:
            fail += 1
            body = ""
            try:
                body = e.read().decode("utf-8", errors="ignore")
            except Exception:
                pass
            print(f"  ERR {ssml_path.name}: HTTP {e.code} {e.reason} {body[:200]}",
                  file=sys.stderr)
        except URLError as e:
            fail += 1
            print(f"  ERR {ssml_path.name}: {e}", file=sys.stderr)

    print(f"\nTotal: {total} | OK: {ok} | Falhas: {fail}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
