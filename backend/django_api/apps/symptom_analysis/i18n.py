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

SEVERITY_HI = {
    "Low": "कम",
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


def localize_analysis(analysis, language="en", alert_sent=False):
    lang = (language or "en").lower()
    hindi = lang.startswith("hi")
    marathi = lang.startswith("mr")
    disease = analysis.get("disease") or "Undetermined"
    severity = analysis.get("severity") or "Low"
    top = list(analysis.get("top_predictions") or [])

    localized_top = []
    for row in top:
        name = str(row.get("disease") or "")
        item = dict(row)
        item["disease_display"] = DISEASE_HI.get(name, name) if hindi else name
        item["severity_display"] = SEVERITY_HI.get(str(row.get("severity") or ""), str(row.get("severity") or "")) if hindi else row.get("severity")
        localized_top.append(item)

    if alert_sent:
        advice_key = "alert"
    elif disease in {"Undetermined", "Possible viral illness"}:
        advice_key = "undetermined"
    else:
        advice_key = "default"

    if marathi:
        disclaimer = DISCLAIMER_MR
        lang_out = "mr"
    elif hindi:
        disclaimer = DISCLAIMER_HI
        lang_out = "hi"
    else:
        disclaimer = DISCLAIMER_EN
        lang_out = "en"

    return {
        "disease_display": DISEASE_HI.get(disease, disease) if hindi else disease,
        "severity_display": SEVERITY_HI.get(severity, severity) if hindi else severity,
        "advice": (ADVICE_HI if hindi else ADVICE_EN)[advice_key],
        "disclaimer": disclaimer,
        "top_predictions": localized_top,
        "language": lang_out,
    }
