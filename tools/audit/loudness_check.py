"""
loudness_check.py
-----------------------------------------------------------------------------
Verifica conformidade dos .wav gerados com a faixa de segurança do perfil
infantil:
  - Loudness integrado: -18 a -16 LUFS (ITU-R BS.1770)
  - Banda de frequência: <180 Hz e >9 kHz com baixa energia
  - True-peak < -1 dBTP (evita clipping em fones infantis)

Requer:
    pip install pyloudnorm soundfile numpy

Uso:
    python tools/audit/loudness_check.py assets/audio/syllables
    python tools/audit/loudness_check.py assets/audio/child_voice/pt_br_girl_6y/google
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
import soundfile as sf
import pyloudnorm as pyln

LUFS_MIN, LUFS_MAX = -18.0, -16.0
SAFE_LOW_HZ, SAFE_HIGH_HZ = 180.0, 9000.0
SAFE_BAND_RATIO_MAX = 0.10  # <=10% energia fora da banda
TRUE_PEAK_MAX_DBTP = -1.0


def band_ratios(y: np.ndarray, sr: int) -> tuple[float, float]:
    spec = np.abs(np.fft.rfft(y * np.hanning(len(y))))
    freqs = np.fft.rfftfreq(len(y), 1 / sr)
    total = float(np.sum(spec ** 2)) or 1.0
    low  = float(np.sum(spec[freqs < SAFE_LOW_HZ] ** 2)) / total
    high = float(np.sum(spec[freqs > SAFE_HIGH_HZ] ** 2)) / total
    return low, high


def true_peak_dbtp(y: np.ndarray) -> float:
    peak = float(np.max(np.abs(y))) or 1e-12
    return 20.0 * np.log10(peak)


def analyze(path: Path) -> dict:
    y, sr = sf.read(path, always_2d=False)
    if y.ndim > 1:
        y = y.mean(axis=1)
    meter = pyln.Meter(sr)
    lufs = float(meter.integrated_loudness(y))
    low, high = band_ratios(y, sr)
    tp = true_peak_dbtp(y)
    issues = []
    if not (LUFS_MIN <= lufs <= LUFS_MAX):
        issues.append(f"LUFS {lufs:+.1f} fora de [{LUFS_MIN},{LUFS_MAX}]")
    if low > SAFE_BAND_RATIO_MAX:
        issues.append(f"energia <{int(SAFE_LOW_HZ)}Hz: {low*100:.0f}%")
    if high > SAFE_BAND_RATIO_MAX:
        issues.append(f"energia >{int(SAFE_HIGH_HZ)}Hz: {high*100:.0f}%")
    if tp > TRUE_PEAK_MAX_DBTP:
        issues.append(f"true-peak {tp:+.1f} dBTP > {TRUE_PEAK_MAX_DBTP}")
    return {
        "file": str(path).replace("\\", "/"),
        "sample_rate": sr,
        "lufs": round(lufs, 2),
        "true_peak_dbtp": round(tp, 2),
        "low_band_ratio": round(low, 3),
        "high_band_ratio": round(high, 3),
        "ok": len(issues) == 0,
        "issues": issues,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("path", type=Path, help="Pasta com .wav (recursivo)")
    ap.add_argument("--json", action="store_true", help="Saída JSON")
    args = ap.parse_args()

    if not args.path.exists():
        print(f"ERRO: {args.path} não existe", file=sys.stderr)
        return 2

    files = sorted(args.path.rglob("*.wav"))
    reports = [analyze(p) for p in files]

    if args.json:
        print(json.dumps(reports, ensure_ascii=False, indent=2))
    else:
        ok = sum(1 for r in reports if r["ok"])
        print(f"\n{'FILE':<60} {'LUFS':>7} {'TP':>6}  STATUS")
        print("-" * 90)
        for r in reports:
            status = "OK" if r["ok"] else " | ".join(r["issues"])
            print(f"{Path(r['file']).name:<60} {r['lufs']:>7.2f} {r['true_peak_dbtp']:>6.2f}  {status}")
        print(f"\n{ok}/{len(reports)} dentro do perfil infantil seguro.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
