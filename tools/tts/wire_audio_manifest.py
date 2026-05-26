"""
wire_audio_manifest.py
-----------------------------------------------------------------------------
Varre os .wav já sintetizados (saída do azure_synthesize.py --bank) e
gera react-native/src/data/audioManifest.js com um require() por arquivo
existente.

Por que existe:
  - Metro (bundler do RN) resolve require() em build-time. Se referenciar
    um .wav inexistente, o bundle quebra.
  - Solução: este script só emite linhas para arquivos que existem AGORA
    no disco. Rode-o sempre que sintetizar áudio novo.

Saída do bank synth segue o padrão:
    assets/audio/bank/phase1/vogal_a.wav
    assets/audio/bank/phase3/encontro_bra.wav
    ...

Uso:
    python tools/tts/wire_audio_manifest.py
    python tools/tts/wire_audio_manifest.py --dry-run

Idempotente. Sobrescreve audioManifest.js inteiro.
-----------------------------------------------------------------------------
"""

from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BANK_AUDIO_ROOT = ROOT / "assets" / "audio" / "bank"
MANIFEST_PATH = ROOT / "react-native" / "src" / "data" / "audioManifest.js"

# Path relativo a partir de react-native/src/data/ para chegar em assets/audio/bank/
# react-native/src/data/audioManifest.js → ../../../../assets/audio/bank/
REL_PREFIX = "../../../../assets/audio/bank"

HEADER = """/**
 * audioManifest.js  — GERADO AUTOMATICAMENTE
 * Por tools/tts/wire_audio_manifest.py — não edite à mão.
 *
 * Mapeia id do banco fonético → asset .wav requerido.
 * Atualize rodando o script após cada azure_synthesize.py --bank.
 */

export const AUDIO_MANIFEST = {
"""

FOOTER = """};

export default AUDIO_MANIFEST;
"""


def collect_entries() -> list[tuple[str, str]]:
    """Retorna [(id, relative_require_path), ...] ordenado por id."""
    if not BANK_AUDIO_ROOT.exists():
        return []

    entries: list[tuple[str, str]] = []
    for wav in sorted(BANK_AUDIO_ROOT.rglob("*.wav")):
        item_id = wav.stem  # vogal_a, encontro_bra, ...
        # Path relativo no formato POSIX (forward slash) para Metro.
        rel_parent = wav.parent.relative_to(BANK_AUDIO_ROOT)  # phase1, phase3, ...
        rel = f"{REL_PREFIX}/{rel_parent.as_posix()}/{wav.name}"
        entries.append((item_id, rel))
    return entries


def render(entries: list[tuple[str, str]]) -> str:
    lines = []
    for item_id, rel in entries:
        # Sanitiza id como chave JS — todos seguem [a-z_0-9], então literal serve.
        lines.append(f"  {item_id!r}: require({rel!r}),")
    body = "\n".join(lines) if lines else "  // (nenhum .wav encontrado em assets/audio/bank/)"
    return HEADER + body + ("\n" if lines else "\n") + FOOTER


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    entries = collect_entries()
    content = render(entries)

    if args.dry_run:
        print(content)
        print(f"\n[dry-run] {len(entries)} entrada(s) — manifesto NÃO gravado.")
        return

    MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST_PATH.write_text(content, encoding="utf-8")
    print(f"Manifesto gravado: {MANIFEST_PATH}")
    print(f"Entradas: {len(entries)}")
    if entries:
        print("Exemplos:")
        for item_id, rel in entries[:5]:
            print(f"  {item_id} → {rel}")


if __name__ == "__main__":
    main()
