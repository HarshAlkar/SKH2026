"""Stable char n-gram hashing shared by train + on-device LID."""

from __future__ import annotations

DIM = 256
N_MIN = 2
N_MAX = 4

LABELS = ("en", "hi", "mr")

# Dataset language names → ISO codes
NAME_TO_CODE = {
    "english": "en",
    "hindi": "hi",
    "marathi": "mr",
}


def fnv1a(text: str) -> int:
    h = 2166136261
    for ch in text:
        h ^= ord(ch)
        h = (h * 16777619) & 0xFFFFFFFF
    return h


def vectorize(text: str, dim: int = DIM, n_min: int = N_MIN, n_max: int = N_MAX):
    import numpy as np

    vec = np.zeros(dim, dtype=np.float32)
    compact = "".join((text or "").lower().split())
    if not compact:
        return vec
    for n in range(n_min, n_max + 1):
        if len(compact) < n:
            continue
        for i in range(len(compact) - n + 1):
            gram = compact[i : i + n]
            vec[fnv1a(gram) % dim] += 1.0
    norm = float(vec.sum())
    if norm > 0:
        vec /= norm
    return vec
