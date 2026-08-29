"""Unit-style NLP extraction checks (no Flutter)."""

from __future__ import annotations

# Mirror of Dart phrase map for offline verification of expected tokens.
PHRASE_MAP = {
    "high fever": "high_fever",
    "fever": "fever",
    "headache": "headache",
    "vomiting": "vomiting",
    "throwing up": "vomiting",
    "stomach pain": "abdominal_pain",
    "belly pain": "abdominal_pain",
    "pain in my belly": "abdominal_pain",
    "feel very tired": "fatigue",
    "very tired": "fatigue",
    "cough": "cough",
}

NEG = ("no", "not", "without", "don't", "dont")


def extract(text: str) -> list[str]:
    t = " ".join(text.lower().split())
    found = set()
    suppressed = set()
    for phrase, token in sorted(PHRASE_MAP.items(), key=lambda x: -len(x[0])):
        idx = 0
        while True:
            i = t.find(phrase, idx)
            if i < 0:
                break
            window = t[max(0, i - 28) : i]
            if any(n in window.split() for n in NEG) or any(
                window.endswith(f"{n} ") or window.endswith(n) for n in NEG
            ):
                # simple: if negation word appears in prior 28 chars
                if any(f" {n} " in f" {window} " or window.startswith(f"{n} ") for n in NEG):
                    suppressed.add(token)
                else:
                    found.add(token)
            else:
                found.add(token)
            idx = i + len(phrase)
    found -= suppressed
    return sorted(found)


TESTS = [
    ("I have high fever, headache and vomiting.", ["headache", "high_fever", "vomiting"]),
    ("I have stomach pain and feel very tired.", ["abdominal_pain", "fatigue"]),
    ("I have fever but no cough.", ["fever"]),  # not cough
    ("Throwing up, headache and pain in my belly.", ["abdominal_pain", "headache", "vomiting"]),
    ("My body feels strange.", []),
]


def main():
    ok = True
    for text, expected in TESTS:
        got = extract(text)
        # For test 3, ensure cough not present
        if "no cough" in text.lower():
            assert "cough" not in got, got
        passed = set(got) >= set(expected) if expected else got == []
        # strange → empty
        if expected == []:
            passed = got == []
        print(f"{'PASS' if passed else 'FAIL'}: {text!r}")
        print(f"  expected~{expected} got={got}")
        ok = ok and passed
    raise SystemExit(0 if ok else 1)


if __name__ == "__main__":
    main()
