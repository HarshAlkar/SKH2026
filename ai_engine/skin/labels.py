HAM10000_CODES = [
    "akiec",
    "bcc",
    "bkl",
    "df",
    "nv",
    "mel",
    "vasc",
]

DISPLAY_NAMES = {
    "akiec": "Actinic keratoses",
    "bcc": "Basal cell carcinoma",
    "bkl": "Benign keratosis",
    "df": "Dermatofibroma",
    "nv": "Melanocytic nevus",
    "mel": "Melanoma",
    "vasc": "Vascular lesion",
}

# Screening-only rules. Not a clinical grading system.
SEVERITY_BY_CODE = {
    "akiec": "High",
    "bcc": "High",
    "bkl": "Low",
    "df": "Low",
    "nv": "Low",
    "mel": "Critical",
    "vasc": "Moderate",
}

INPUT_SIZE = 224


def display_name(code):
    return DISPLAY_NAMES.get(code, code)


def severity_for(code):
    return SEVERITY_BY_CODE.get(code, "Moderate")


def labels_payload():
    return {
        "classes": HAM10000_CODES,
        "display_names": DISPLAY_NAMES,
        "severity": SEVERITY_BY_CODE,
        "input_size": INPUT_SIZE,
        "normalize": "mobilenet_v2",
        "disclaimer": (
            "Screening suggestion only, not a medical diagnosis. "
            "HAM10000-style models are biased toward lighter skin tones."
        ),
    }
