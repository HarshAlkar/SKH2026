"""Display strings for symptom screening. Engine labels stay English."""

DISEASE_HI = {
    "Possible viral illness": "संभावित वायरल बीमारी",
    "Undetermined": "अनिश्चित / सामान्य लक्षण",
    "Common Cold": "सामान्य सर्दी-जुकाम",
    "Bronchial Asthma": "दमा (अस्थमा)",
    "GERD": "एसिडिटी / GERD",
    "Migraine": "माइग्रेन",
    "Malaria": "मलेरिया",
    "Dengue": "डेंगू",
    "Typhoid": "टाइफाइड",
    "Pneumonia": "निमोनिया",
    "Tuberculosis": "तपेदिक",
    "Jaundice": "पीलिया",
    "Fungal infection": "फंगल संक्रमण",
    "Hypertension": "उच्च रक्तचाप",
    "Diabetes": "मधुमेह",
    "Heart attack": "हृदयघात",
    "AIDS": "एड्स",
}

DISEASE_MR = {
    "Possible viral illness": "संभाव्य व्हायरल आजार",
    "Undetermined": "अनिश्चित / सामान्य लक्षणे",
    "Common Cold": "सर्दी-झुक्या",
    "Bronchial Asthma": "दमा (अस्थमा)",
    "GERD": "अॅसिडिटी / GERD",
    "Migraine": "मायग्रेन",
    "Malaria": "मलेरिया",
    "Dengue": "डेंग्यू",
    "Typhoid": "टायफॉइड",
    "Pneumonia": "न्यूमोनिया",
    "Tuberculosis": "क्षयरोग",
    "Jaundice": "कावीळ",
    "Fungal infection": "बुरशीजन्य संसर्ग",
    "Hypertension": "उच्च रक्तदाब",
    "Diabetes": "मधुमेह",
    "Heart attack": "हृदयविकाराचा झटका",
    "AIDS": "एड्स",
}

SEVERITY_HI = {
    "Low": "कम",
    "Moderate": "मध्यम",
    "High": "उच्च",
    "Critical": "गंभीर",
}

SEVERITY_MR = {
    "Low": "कमी",
    "Moderate": "मध्यम",
    "High": "उच्च",
    "Critical": "गंभीर",
}

ADVICE_EN = {
    "default": "Maintain hydration and rest. Monitor symptoms carefully.",
    "alert": "Potentially serious condition detected. ASHA worker and doctor have been notified.",
    "undetermined": "These symptoms are common. Rest, drink fluids, and consult a doctor if they worsen.",
}

ADVICE_HI = {
    "default": "पर्याप्त पानी पिएँ और आराम करें। लक्षणों पर नज़र रखें।",
    "alert": "संभावित गंभीर स्थिति। आशा कार्यकर्ता और डॉक्टर को सूचित किया गया है।",
    "undetermined": "ये लक्षण आम हैं। आराम करें, तरल पदार्थ लें, और बिगड़ने पर डॉक्टर से मिलें।",
}

ADVICE_MR = {
    "default": "पुरेसे पाणी प्या आणि विश्रांती घ्या. लक्षणांकडे लक्ष द्या.",
    "alert": "संभाव्य गंभीर स्थिती. आशा कार्यकर्ता आणि डॉक्टरांना कळवले आहे.",
    "undetermined": "ही लक्षणे सामान्य आहेत. विश्रांती घ्या, द्रव प्या आणि बिघडल्यास डॉक्टरांना भेटा.",
}

DISCLAIMER_EN = (
    "Screening indicates elevated risk — consult a qualified healthcare professional. "
    "This is not a medical diagnosis."
)
DISCLAIMER_HI = (
    "स्क्रीनिंग से जोखिम का संकेत — योग्य स्वास्थ्य पेशेवर से सलाह लें। यह चिकित्सा निदान नहीं है।"
)
DISCLAIMER_MR = (
    "स्क्रीनिंगमुळे धोका दिसतो — पात्र आरोग्य तज्ज्ञांचा सल्ला घ्या. हे वैद्यकीय निदान नाही."
)

INDIC_SYNONYMS = {
    "बुखार": "fever",
    "ताप": "fever",
    "खांसी": "cough",
    "खोकला": "cough",
    "सिरदर्द": "headache",
    "डोकेदुखी": "headache",
    "उल्टी": "vomiting",
    "उलटी": "vomiting",
    "दर्द": "pain",
    "वेदना": "pain",
    "थकान": "fatigue",
    "थकवा": "fatigue",
    "खुजली": "itching",
    "खाज": "itching",
    "चकत्ते": "rash",
    "पुरळ": "rash",
    "छींक": "sneezing",
    "शिंका": "sneezing",
    "जुकाम": "cold",
    "सर्दी": "cold",
    "कफ": "cough",
    "सांस": "breath",
    "श्वास": "breath",
    "चक्कर": "dizziness",
    "दस्त": "diarrhoea",
    "जुलाब": "diarrhoea",
    "पीलिया": "jaundice",
    "कावीळ": "jaundice",
    "पसीना": "sweating",
    "घाम": "sweating",
    "कमजोरी": "weakness",
    "अशक्तपणा": "weakness",
    "मितली": "nausea",
    "मळमळ": "nausea",
}


def normalize_language(language="en"):
    lang = (language or "en").lower()
    if lang.startswith("mr"):
        return "mr"
    if lang.startswith("hi"):
        return "hi"
    return "en"


def map_indic_tokens(words):
    out = []
    for word in words:
        mapped = INDIC_SYNONYMS.get(word)
        out.append(mapped if mapped else word)
    return out


def localize_analysis(analysis, language="en", alert_sent=False):
    lang_out = normalize_language(language)
    hindi = lang_out == "hi"
    marathi = lang_out == "mr"
    disease = analysis.get("disease") or "Undetermined"
    severity = analysis.get("severity") or "Low"
    top = list(analysis.get("top_predictions") or [])

    disease_map = DISEASE_MR if marathi else (DISEASE_HI if hindi else {})
    severity_map = SEVERITY_MR if marathi else (SEVERITY_HI if hindi else {})
    advice_map = ADVICE_MR if marathi else (ADVICE_HI if hindi else ADVICE_EN)

    localized_top = []
    for row in top:
        name = str(row.get("disease") or "")
        item = dict(row)
        item["disease_display"] = disease_map.get(name, name)
        item["severity_display"] = severity_map.get(str(row.get("severity") or ""), str(row.get("severity") or ""))
        localized_top.append(item)

    if alert_sent:
        advice_key = "alert"
    elif disease in {"Undetermined", "Possible viral illness"}:
        advice_key = "undetermined"
    else:
        advice_key = "default"

    if marathi:
        disclaimer = DISCLAIMER_MR
    elif hindi:
        disclaimer = DISCLAIMER_HI
    else:
        disclaimer = DISCLAIMER_EN

    return {
        "disease_display": disease_map.get(disease, disease),
        "severity_display": severity_map.get(severity, severity),
        "advice": advice_map[advice_key],
        "disclaimer": disclaimer,
        "top_predictions": localized_top,
        "language": lang_out,
    }
