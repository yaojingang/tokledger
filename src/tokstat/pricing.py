from __future__ import annotations

import re
from dataclasses import dataclass


@dataclass(frozen=True)
class ModelPrice:
    input_per_million: float
    cached_input_per_million: float | None
    output_per_million: float


_PAREN_SUFFIX_RE = re.compile(r"\s*(\([^)]*\))\s*$")
_CLAUDE_PREFIX_RE = re.compile(r"^claude\s+(sonnet|opus|haiku)\s+([0-9.]+)(.*)$", re.IGNORECASE)
_CLAUDE_SUFFIX_RE = re.compile(r"^claude\s+([0-9.]+)\s+(sonnet|opus|haiku)(.*)$", re.IGNORECASE)
_GPT_RE = re.compile(r"^gpt[- ]?([0-9.]+)(?:[- ]?(mini|nano|codex))?(.*)$", re.IGNORECASE)


PRICE_BOOK: dict[str, ModelPrice] = {
    "GPT-5.4": ModelPrice(2.50, 0.25, 15.00),
    "GPT-5.4 Mini": ModelPrice(0.75, 0.075, 4.50),
    "GPT-5.4 Nano": ModelPrice(0.20, 0.02, 1.25),
    "GPT-5.2": ModelPrice(1.75, 0.175, 14.00),
    "GPT-5.2 Codex": ModelPrice(1.75, 0.175, 14.00),
    "GPT-5": ModelPrice(1.25, 0.125, 10.00),
    "GPT-5 Codex": ModelPrice(1.25, 0.125, 10.00),
    "GPT-5 Mini": ModelPrice(0.25, 0.025, 2.00),
    "GPT-5 Nano": ModelPrice(0.05, 0.005, 0.40),
    "GPT-4.1": ModelPrice(2.00, 0.50, 8.00),
    "GPT-4.1 Mini": ModelPrice(0.40, 0.10, 1.60),
    "GPT-4.1 Nano": ModelPrice(0.10, 0.025, 0.40),
    "Claude Sonnet 4.6": ModelPrice(3.00, 0.30, 15.00),
    "Claude Sonnet 4.5": ModelPrice(3.00, 0.30, 15.00),
    "Claude Haiku 4.5": ModelPrice(1.00, 0.10, 5.00),
    "Claude Opus 4.6": ModelPrice(5.00, 0.50, 25.00),
    "Claude Opus 4.5": ModelPrice(5.00, 0.50, 25.00),
    "Claude Sonnet 4": ModelPrice(3.00, 0.30, 15.00),
    "Claude Opus 4": ModelPrice(15.00, 1.50, 75.00),
}


def normalize_model_display(model: str | None, provider: str | None = None) -> str:
    model_value = (model or "").strip()
    provider_value = (provider or "").strip()
    if not model_value:
        if provider_value:
            return f"unknown (provider={provider_value})"
        return "unknown"

    suffix = ""
    suffix_match = _PAREN_SUFFIX_RE.search(model_value)
    if suffix_match:
        suffix = f" {suffix_match.group(1)}"
        model_value = model_value[: suffix_match.start()].strip()

    normalized = _normalize_claude(model_value)
    if normalized:
        return normalized + suffix

    normalized = _normalize_gpt(model_value)
    if normalized:
        return normalized + suffix

    return model.strip()


def estimate_cost_usd(
    *,
    model: str | None,
    provider: str | None,
    measurement_method: str | None,
    input_tokens: int | None,
    cached_input_tokens: int | None,
    output_tokens: int | None,
) -> float | None:
    if measurement_method != "exact":
        return None

    total_input = int(input_tokens or 0)
    cached_input = int(cached_input_tokens or 0)
    total_output = int(output_tokens or 0)
    if total_input <= 0 and total_output <= 0 and cached_input <= 0:
        return None

    normalized = normalize_model_display(model, provider)
    lookup_name = _strip_parenthetical_suffix(normalized)
    pricing = PRICE_BOOK.get(lookup_name)
    if pricing is None:
        return None

    cached_billable = min(cached_input, total_input)
    uncached_input = max(total_input - cached_billable, 0)
    cached_rate = pricing.cached_input_per_million
    if cached_rate is None:
        cached_rate = pricing.input_per_million

    estimate = (
        (uncached_input / 1_000_000) * pricing.input_per_million
        + (cached_billable / 1_000_000) * cached_rate
        + (total_output / 1_000_000) * pricing.output_per_million
    )
    return round(estimate, 8)


def _strip_parenthetical_suffix(value: str) -> str:
    return _PAREN_SUFFIX_RE.sub("", value).strip()


def _normalize_claude(model: str) -> str | None:
    match = _CLAUDE_PREFIX_RE.match(model)
    if not match:
        match = _CLAUDE_SUFFIX_RE.match(model)
        if not match:
            return None
        version = match.group(1)
        family = match.group(2)
        tail = match.group(3)
    else:
        family = match.group(1)
        version = match.group(2)
        tail = match.group(3)

    family_name = family.title()
    return f"Claude {family_name} {version}{tail}".strip()


def _normalize_gpt(model: str) -> str | None:
    normalized = model.replace("_", "-").strip()
    match = _GPT_RE.match(normalized)
    if not match:
        return None

    version = match.group(1)
    tier = match.group(2)
    tail = match.group(3)
    label = f"GPT-{version}"
    if tier:
        label += f" {tier.title()}"
    if tail:
        label += tail
    return label.strip()
