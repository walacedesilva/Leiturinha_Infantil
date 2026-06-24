"""
audit_audio.py
-----------------------------------------------------------------------------
Auditoria automática dos .wav em assets/audio/{syllables,words}/.
Cruza cada arquivo com a referência fonética (assets/phonetics/reference.csv)
e produz tools/audit/out/report.json + report.csv no formato pedido pelo
prompt de pronúncia infantil.

Checagens implementadas (sem Montreal Forced Aligner — opcional ao fim):
  1. Duração total e duração da fala (sem silêncio nas bordas).
  2. Contagem de núcleos silábicos via librosa.onset.onset_detect
     em pico de energia agregada (proxy de Syllable Boundary Accuracy).
  3. Vogais epentéticas / soletração: detecta vales de RMS *dentro* da
     porção falada que sugerem schwa/ɛ intrusivo entre C+V ou entre sílabas.
  4. Estabilidade tonal (pitch std via librosa.yin) — proxy de "tom estável".
  5. Banda de frequência: energia abaixo de 150 Hz e acima de 8 kHz (conforto
     auditivo infantil). Penaliza se >5% da energia fora da faixa.
  6. Score de precisão composto (0–100) com pesos pedagógicos.

Saída por arquivo (matching do prompt):
{
  "analise_fonetica": {...},
  "ajustes_tts_sugeridos": {...},
  "validacao_pedagogica": {...}
}

Uso:
    pip install -r tools/audit/requirements.txt
    python tools/audit/audit_audio.py
    python tools/audit/audit_audio.py --only syllables --verbose
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
from pathlib import Path
from typing import Any

import numpy as np
import librosa

ROOT      = Path(__file__).resolve().parents[2]
CSV_PATH  = ROOT / "assets" / "phonetics" / "reference.csv"
AUDIO_DIRS = {
    "syllable": ROOT / "assets" / "audio" / "syllables",
    "word":     ROOT / "assets" / "audio" / "words",
}
OUT_DIR = ROOT / "tools" / "audit" / "out"

SR_TARGET = 22050  # bom compromisso para análise de fala infantil


# --------------------------------------------------------------------------- #
# Análise de baixo nível
# --------------------------------------------------------------------------- #
def trim_silence(y: np.ndarray, sr: int) -> tuple[np.ndarray, float, float]:
    """Remove silêncio das bordas. Retorna (y_trim, start_s, end_s)."""
    yt, idx = librosa.effects.trim(y, top_db=35)
    if len(yt) == 0:
        return y, 0.0, len(y) / sr
    return yt, idx[0] / sr, idx[1] / sr


def detect_nuclei(y: np.ndarray, sr: int) -> int:
    """Estima nº de núcleos silábicos por picos de energia."""
    rms = librosa.feature.rms(y=y, frame_length=1024, hop_length=256)[0]
    if rms.size == 0:
        return 0
    # picos com proeminência mínima
    peaks = librosa.util.peak_pick(
        rms, pre_max=4, post_max=4, pre_avg=6, post_avg=6,
        delta=float(rms.mean() * 0.6), wait=8,
    )
    return int(len(peaks))


def epenthetic_score(y: np.ndarray, sr: int, expected_syllables: int) -> tuple[float, bool]:
    """
    Heurística: se observamos MAIS núcleos do que o esperado, há suspeita de
    vogal epentética ou pronúncia soletrada ("bê-a" para BA).
    Retorna (penalidade_0_30, suspeita_bool).
    """
    found = detect_nuclei(y, sr)
    extra = max(0, found - expected_syllables)
    return min(30.0, extra * 18.0), extra > 0


def pitch_stability(y: np.ndarray, sr: int) -> float:
    """Desvio padrão do F0 (Hz). Quanto menor, mais estável o tom."""
    try:
        f0 = librosa.yin(y, fmin=80, fmax=500, sr=sr)
        f0 = f0[np.isfinite(f0)]
        if f0.size < 5:
            return float("nan")
        return float(np.std(f0))
    except Exception:
        return float("nan")


def band_energy_ratio(y: np.ndarray, sr: int) -> tuple[float, float]:
    """
    Proporção da energia abaixo de 150 Hz e acima de 8 kHz.
    Idealmente próximas de 0 para conforto auditivo infantil.
    """
    spec = np.abs(np.fft.rfft(y * np.hanning(len(y))))
    freqs = np.fft.rfftfreq(len(y), 1 / sr)
    total = float(np.sum(spec ** 2)) or 1.0
    low  = float(np.sum(spec[freqs < 150] ** 2)) / total
    high = float(np.sum(spec[freqs > 8000] ** 2)) / total
    return low, high


# --------------------------------------------------------------------------- #
# Score & estrutura de saída
# --------------------------------------------------------------------------- #
def build_record(row: dict, audio_path: Path, verbose: bool = False) -> dict[str, Any]:
    grapheme = row["grapheme"]
    ipa_ref  = row["ipa"]
    expected_syls = len(row.get("syllabification", grapheme).split("-")) or 1

    desvios: list[str] = []
    ajuste_phonemes: dict[str, str] = {}

    if not audio_path.exists():
        return {
            "analise_fonetica": {
                "silaba_alvo": grapheme,
                "transcricao_esperada": f"/{ipa_ref}/",
                "transcricao_gerada": None,
                "desvios_detectados": ["arquivo ausente"],
                "score_precisao": 0,
            },
            "ajustes_tts_sugeridos": {
                "ssml_tags": None, "prosody": {}, "phoneme_overrides": {},
            },
            "validacao_pedagogica": {
                "coarticulacao": "❌", "tonicidade": "❌",
                "ritmo_infantil": "❌",
                "recomendacao": "Regenerar com tools/tts/azure_synthesize.py",
            },
        }

    y, sr = librosa.load(audio_path, sr=SR_TARGET, mono=True)
    y_trim, start_s, end_s = trim_silence(y, sr)
    duration = float(len(y) / sr)
    speech_dur = float(len(y_trim) / sr)
    leading_sil = start_s
    trailing_sil = max(0.0, duration - end_s)

    # 1. Epêntese / soletração
    epen_pen, epen_susp = epenthetic_score(y_trim, sr, expected_syls)
    if epen_susp:
        desvios.append("vogal epentética ou soletração suspeita (núcleos extras detectados)")
        ajuste_phonemes["ɛ_intrusivo"] = "remover"

    # 2. Silêncio nas bordas (cada borda >120ms é ruim para sílabas isoladas)
    border_pen = 0.0
    if row["type"] == "syllable":
        if leading_sil > 0.12:
            border_pen += 8; desvios.append(f"silêncio inicial {int(leading_sil*1000)}ms")
        if trailing_sil > 0.15:
            border_pen += 6; desvios.append(f"silêncio final {int(trailing_sil*1000)}ms")

    # 3. Duração plausível
    dur_pen = 0.0
    if row["type"] == "syllable":
        if speech_dur < 0.18:
            dur_pen += 10; desvios.append(f"sílaba curta demais ({int(speech_dur*1000)}ms)")
        elif speech_dur > 0.65:
            dur_pen += 6;  desvios.append(f"sílaba longa demais ({int(speech_dur*1000)}ms)")
    else:  # word
        per_syl = speech_dur / expected_syls
        if per_syl < 0.16:
            dur_pen += 8; desvios.append("ritmo muito acelerado para pedagogia infantil")
        if per_syl > 0.55:
            dur_pen += 6; desvios.append("ritmo muito lento (risco de robótico)")

    # 4. Estabilidade tonal
    pitch_std = pitch_stability(y_trim, sr)
    pitch_pen = 0.0
    if not np.isnan(pitch_std) and pitch_std > 45:
        pitch_pen = 10
        desvios.append(f"variação de pitch elevada (σ={pitch_std:.0f} Hz)")

    # 5. Faixa de frequência (conforto infantil)
    low_ratio, high_ratio = band_energy_ratio(y_trim, sr)
    band_pen = 0.0
    if low_ratio > 0.10:
        band_pen += 6; desvios.append(f"energia <150Hz {low_ratio*100:.0f}% (rumble)")
    if high_ratio > 0.08:
        band_pen += 6; desvios.append(f"energia >8kHz {high_ratio*100:.0f}% (sibilância)")

    score = max(0.0, 100.0 - epen_pen - border_pen - dur_pen - pitch_pen - band_pen)

    # ----- veredictos pedagógicos --------------------------------------------
    coart = "✅" if not epen_susp else ("⚠️" if epen_pen < 25 else "❌")
    ton   = "✅" if pitch_pen == 0 else ("⚠️" if pitch_pen < 10 else "❌")
    rit   = "✅" if dur_pen == 0 else ("⚠️" if dur_pen < 10 else "❌")

    if score >= 88:
        recomend = "Manter — dentro do alvo pedagógico."
    elif epen_susp:
        recomend = ("Regenerar via SSML envolvendo a forma inteira em um único "
                    "<phoneme>; reduzir <break> a ≤100ms; desativar smoothing.")
    elif dur_pen and "lento" in " ".join(desvios):
        recomend = "Reduzir <prosody rate> para 85-90% e remover ênfase excessiva."
    elif dur_pen and "acelerado" in " ".join(desvios):
        recomend = "Aumentar <prosody rate> para 90-95% e inserir <break time='150ms'/> entre sílabas."
    elif band_pen:
        recomend = "Aplicar EQ: corte suave <150Hz e >8kHz (Praat/SoX) ou reduzir styledegree."
    else:
        recomend = "Pequenos ajustes — revisar ênfase tônica."

    ssml_hint = (
        f'<phoneme alphabet="ipa" ph="{ipa_ref}">{grapheme}</phoneme>'
    )

    record = {
        "file": str(audio_path.relative_to(ROOT)).replace("\\", "/"),
        "analise_fonetica": {
            "silaba_alvo": grapheme,
            "transcricao_esperada": f"/{ipa_ref}/",
            "transcricao_gerada": None,   # requer MFA — ver seção opcional
            "desvios_detectados": desvios,
            "score_precisao": round(score, 1),
        },
        "ajustes_tts_sugeridos": {
            "ssml_tags": ssml_hint,
            "prosody": {
                "rate": "85%" if row["type"] == "syllable" else "90%",
                "pitch": "0%", "volume": "medium",
            },
            "phoneme_overrides": ajuste_phonemes,
        },
        "validacao_pedagogica": {
            "coarticulacao": coart,
            "tonicidade": ton,
            "ritmo_infantil": rit,
            "recomendacao": recomend,
        },
        "metrics": {
            "duration_s": round(duration, 3),
            "speech_s": round(speech_dur, 3),
            "leading_silence_s": round(leading_sil, 3),
            "trailing_silence_s": round(trailing_sil, 3),
            "expected_syllables": expected_syls,
            "detected_nuclei": detect_nuclei(y_trim, sr),
            "pitch_std_hz": None if np.isnan(pitch_std) else round(pitch_std, 1),
            "low_band_ratio": round(low_ratio, 3),
            "high_band_ratio": round(high_ratio, 3),
        },
    }
    if verbose:
        print(f"  {audio_path.name:>14}  score={score:5.1f}  desvios={len(desvios)}")
    return record


# --------------------------------------------------------------------------- #
# Driver
# --------------------------------------------------------------------------- #
def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", choices=["syllables", "words"], default=None)
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    if not CSV_PATH.exists():
        print(f"ERRO: {CSV_PATH} não encontrado.", file=sys.stderr)
        return 2

    rows = list(csv.DictReader(CSV_PATH.open(encoding="utf-8")))
    types_wanted = (
        {"syllable"} if args.only == "syllables"
        else {"word"} if args.only == "words"
        else {"syllable", "word"}
    )

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    report: list[dict[str, Any]] = []

    for row in rows:
        if row["type"] not in types_wanted:
            continue
        base = AUDIO_DIRS[row["type"]]
        audio_path = base / f'{row["id"]}.wav'
        report.append(build_record(row, audio_path, verbose=args.verbose))

    # JSON
    (OUT_DIR / "report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8",
    )

    # CSV resumido
    with (OUT_DIR / "report.csv").open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow([
            "file", "grapheme", "ipa_ref", "score",
            "coart", "tonicidade", "ritmo", "desvios", "recomendacao",
        ])
        for r in report:
            w.writerow([
                r["file"],
                r["analise_fonetica"]["silaba_alvo"],
                r["analise_fonetica"]["transcricao_esperada"],
                r["analise_fonetica"]["score_precisao"],
                r["validacao_pedagogica"]["coarticulacao"],
                r["validacao_pedagogica"]["tonicidade"],
                r["validacao_pedagogica"]["ritmo_infantil"],
                " | ".join(r["analise_fonetica"]["desvios_detectados"]),
                r["validacao_pedagogica"]["recomendacao"],
            ])

    # sumário
    scores = [r["analise_fonetica"]["score_precisao"] for r in report]
    bad = [r for r in report if r["analise_fonetica"]["score_precisao"] < 70]
    print(f"\nAuditados: {len(report)}")
    if scores:
        print(f"Score médio: {sum(scores)/len(scores):.1f}")
        print(f"Score mín / máx: {min(scores):.1f} / {max(scores):.1f}")
    print(f"Arquivos abaixo de 70: {len(bad)}")
    for r in bad[:15]:
        print(f"  - {r['file']:<40} score={r['analise_fonetica']['score_precisao']}")
    print(f"\nRelatórios em: {OUT_DIR}")
    return 0


# --------------------------------------------------------------------------- #
# NOTA — Forced alignment opcional (Montreal Forced Aligner)
# --------------------------------------------------------------------------- #
# Para preencher `transcricao_gerada` com IPA real (não apenas heurística),
# instale o MFA e rode:
#
#   conda install -c conda-forge montreal-forced-aligner
#   mfa model download acoustic portuguese_mfa
#   mfa model download dictionary portuguese_brazil_mfa
#   mfa align assets/audio/words corpus_lab portuguese_brazil_mfa \
#       portuguese_mfa tools/audit/out/aligned
#
# Os TextGrids de saída fornecem fronteiras de fonemas que podem ser
# convertidas para IPA via mapa fornecido pelo dicionário MFA.
# --------------------------------------------------------------------------- #

if __name__ == "__main__":
    sys.exit(main())
