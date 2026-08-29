"""Shared risk bands and screening safety copy for One Health AI."""

HUMAN_DISCLAIMER = (
    "AI-assisted screening only. This result is not a medical diagnosis. "
    "Please consult a qualified healthcare professional."
)

ANIMAL_DISCLAIMER = (
    "Livestock screening indicates decision support only and is not a veterinary diagnosis. "
    "Consult a qualified veterinarian."
)

SKIN_DISCLAIMER = (
    "AI-assisted skin screening only. Screening confidence is not a confirmed diagnosis. "
    "Professional evaluation is recommended."
)

SEVERITY_ORDER = {"Low": 0, "Moderate": 1, "High": 2, "Critical": 3}

HUMAN_HIGH = [
    "Pneumonia",
    "Heart attack",
    "Jaundice",
    "Malaria",
    "Dengue",
    "Typhoid",
    "Tuberculosis",
    "hepatitis",
    "Hepatitis",
    "AIDS",
    "paralysis",
]
HUMAN_CRITICAL = ["Heart attack", "paralysis"]
HUMAN_MODERATE = [
    "Fungal infection",
    "Hypertension",
    "Diabetes",
    "Migraine",
    "Bronchial Asthma",
    "GERD",
    "Common Cold",
    "Possible viral illness",
]


def severity_for_human_disease(disease: str) -> str:
    lowered = (disease or "").lower()
    for name in HUMAN_CRITICAL:
        if name.lower() in lowered:
            return "Critical"
    for name in HUMAN_HIGH:
        if name.lower() in lowered:
            return "High"
    for name in HUMAN_MODERATE:
        if name.lower() in lowered:
            return "Moderate"
    return "Low"


def max_severity(*levels: str) -> str:
    best = "Low"
    for level in levels:
        if SEVERITY_ORDER.get(level, 0) > SEVERITY_ORDER.get(best, 0):
            best = level
    return best


def screening_wording(condition: str, domain: str = "HUMAN") -> str:
    label = condition or "an elevated-risk condition"
    if domain.upper() == "ANIMAL":
        return (
            f"Livestock screening indicates elevated risk for {label}. "
            "This result is decision support and not a veterinary diagnosis."
        )
    return (
        f"Screening result indicates elevated risk for {label}. "
        "This is not a diagnosis. Please consult a qualified healthcare professional."
    )
