"""
validation_map.py
-----------------------------------------------------------------------------
Carrega o banco fonético v1.0 e produz um VALIDATION_MAP para uso em
pipelines ASR (Whisper, Google STT, Azure Speech-to-Text), com variantes
aceitas e padrões rejeitados por item do banco.

Uso direto:
    from validation_map import VALIDATION_MAP, is_acceptable
    ok, reason = is_acceptable("BRA", transcricao_asr_ipa="/bɛ.ɾa/")
    # ok=False, reason="match rejected_pattern '/bɛ.ɾa/'"
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Iterable

BANK_PATH = (
    Path(__file__).resolve().parents[1]
    / "assets" / "phonetics"
    / "phonetic_bank_v1.0_pt-BR_pedagogical.json"
)

# ---------------------------------------------------------------------------#
# Heurísticas de variantes aceitáveis derivadas das notas do banco
# ---------------------------------------------------------------------------#
_VARIANT_RULES: list[tuple[re.Pattern[str], list[str]]] = [
    # vogais reduzidas finais comuns em pt-BR (toleradas em fala natural)
    (re.compile(r"o$"), ["o", "u"]),
    (re.compile(r"e$"), ["e", "i"]),
    # R inicial forte: tap e fricativa uvular são variantes regionais válidas
    (re.compile(r"^ʁ"), ["ʁ", "h", "x"]),
]

# Padrões SEMPRE rejeitados (soletração / epêntese)
_REJECT_PATTERNS_GLOBAL = [
    r"ɛ\.",      # epêntese aberta entre consoante e vogal
    r"ə\.",      # schwa intrusivo
    r"\.[aeiouɛɔ]\.",  # sílaba CV "esticada" como V isolada (proxy de soletração)
]


def _expand_variants(expected_ipa: str) -> list[str]:
    bare = expected_ipa.strip("/")
    variants = {bare}
    for pattern, repls in _VARIANT_RULES:
        if pattern.search(bare):
            for r in repls:
                variants.add(pattern.sub(r, bare))
    return [f"/{v}/" for v in variants]


def _build_map(bank: dict) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for item in bank["phonetic_reference_bank"]["syllables"]:
        key = item["orthographic"]
        expected = item["ipa"]
        rejects = list(item.get("common_child_errors", []))
        # converte erros em padrões IPA quando vêm entre /…/
        rejected_patterns = [e for e in rejects if e.startswith("/")]
        confidence = 0.70 if item["category"] in ("consonant_cluster",) else 0.75
        out[key] = {
            "expected_ipa": expected,
            "accepted_variants": _expand_variants(expected),
            "rejected_patterns": rejected_patterns,
            "min_confidence": confidence,
            "category": item["category"],
            "phase": item.get("phase"),
        }
    return out


def _load() -> dict[str, dict]:
    with BANK_PATH.open(encoding="utf-8") as f:
        return _build_map(json.load(f))


VALIDATION_MAP: dict[str, dict] = _load()


def is_acceptable(item: str, transcricao_asr_ipa: str,
                  confidence: float | None = None) -> tuple[bool, str]:
    """Retorna (ok, motivo) para um grafema vs. transcrição ASR."""
    entry = VALIDATION_MAP.get(item.upper())
    if not entry:
        return False, f"item desconhecido: {item}"

    if confidence is not None and confidence < entry["min_confidence"]:
        return False, f"confiança {confidence:.2f} < mínimo {entry['min_confidence']:.2f}"

    norm = transcricao_asr_ipa.strip()

    for rej in entry["rejected_patterns"]:
        if rej.strip("/") in norm.strip("/"):
            return False, f"match rejected_pattern '{rej}'"

    for pat in _REJECT_PATTERNS_GLOBAL:
        if re.search(pat, norm.strip("/")):
            return False, f"viola padrão global '{pat}'"

    if norm in entry["accepted_variants"]:
        return True, "match exato em accepted_variants"

    return False, (
        f"não corresponde a nenhuma variante aceita "
        f"{entry['accepted_variants']}"
    )


if __name__ == "__main__":
    import pprint, sys
    pprint.pp({k: VALIDATION_MAP[k] for k in list(VALIDATION_MAP)[:5]},
              width=120)
    print(f"\nTotal de itens validáveis: {len(VALIDATION_MAP)}")
    # smoke test
    cases: Iterable[tuple[str, str]] = [
        ("BA",  "/ba/"),
        ("BA",  "/bɛ.a/"),
        ("BRA", "/bɾa/"),
        ("BRA", "/ba.ɾa/"),
        ("CHA", "/ʃa/"),
        ("CHA", "/tʃa/"),
    ]
    for g, asr in cases:
        ok, why = is_acceptable(g, asr)
        print(f"  {g:>4}  asr={asr:<10}  -> {'OK ' if ok else 'NO '} {why}")
