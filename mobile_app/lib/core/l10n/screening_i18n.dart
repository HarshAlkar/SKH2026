/// Localized display strings for on-device screening (engine labels stay English).
class ScreeningI18n {
  ScreeningI18n._();

  static const diseaseHi = {
    'Possible viral illness': 'संभावित वायरल बीमारी',
    'Undetermined': 'अनिश्चित / सामान्य लक्षण',
    'Common Cold': 'सामान्य सर्दी-जुकाम',
    'Bronchial Asthma': 'दमा (अस्थमा)',
    'GERD': 'एसिडिटी / GERD',
    'Migraine': 'माइग्रेन',
    'Malaria': 'मलेरिया',
    'Dengue': 'डेंगू',
    'Typhoid': 'टाइफाइड',
    'Pneumonia': 'निमोनिया',
    'Tuberculosis': 'तपेदिक',
    'Jaundice': 'पीलिया',
    'Fungal infection': 'फंगल संक्रमण',
    'Hypertension': 'उच्च रक्तचाप',
    'Diabetes': 'मधुमेह',
    'Heart attack': 'हृदयघात',
    'AIDS': 'एड्स',
    'Insufficient input': 'अपर्याप्त लक्षण',
    'Not enough recognizable symptoms': 'पहचान योग्य लक्षण पर्याप्त नहीं',
    'Elevated-risk screening result': 'उच्च-जोखिम स्क्रीनिंग परिणाम',
  };

  static const diseaseMr = {
    'Possible viral illness': 'संभाव्य व्हायरल आजार',
    'Undetermined': 'अनिश्चित / सामान्य लक्षणे',
    'Common Cold': 'सर्दी-झुक्या',
    'Bronchial Asthma': 'दमा (अस्थमा)',
    'GERD': 'अॅसिडिटी / GERD',
    'Migraine': 'मायग्रेन',
    'Malaria': 'मलेरिया',
    'Dengue': 'डेंग्यू',
    'Typhoid': 'टायफॉइड',
    'Pneumonia': 'न्यूमोनिया',
    'Tuberculosis': 'क्षयरोग',
    'Jaundice': 'कावीळ',
    'Fungal infection': 'बुरशीजन्य संसर्ग',
    'Hypertension': 'उच्च रक्तदाब',
    'Diabetes': 'मधुमेह',
    'Heart attack': 'हृदयविकाराचा झटका',
    'AIDS': 'एड्स',
    'Insufficient input': 'अपुरी लक्षणे',
    'Not enough recognizable symptoms': 'ओळखता येणारी लक्षणे अपुरी',
    'Elevated-risk screening result': 'उच्च-धोका स्क्रीनिंग निकाल',
  };

  static const severityHi = {
    'Low': 'कम',
    'Moderate': 'मध्यम',
    'High': 'उच्च',
    'Critical': 'गंभीर',
    'Unknown': 'अज्ञात',
  };

  static const severityMr = {
    'Low': 'कमी',
    'Moderate': 'मध्यम',
    'High': 'उच्च',
    'Critical': 'गंभीर',
    'Unknown': 'अज्ञात',
  };

  static String disease(String name, String language) {
    final lang = language.toLowerCase();
    if (lang.startsWith('mr')) return diseaseMr[name] ?? diseaseHi[name] ?? name;
    if (lang.startsWith('hi')) return diseaseHi[name] ?? name;
    return name;
  }

  static String severity(String name, String language) {
    final lang = language.toLowerCase();
    if (lang.startsWith('mr')) return severityMr[name] ?? name;
    if (lang.startsWith('hi')) return severityHi[name] ?? name;
    return name;
  }

  static String advice({
    required String language,
    required bool alertSent,
    required String diseaseName,
  }) {
    final lang = language.toLowerCase();
    final undetermined = diseaseName == 'Undetermined' ||
        diseaseName == 'Possible viral illness';
    if (lang.startsWith('mr')) {
      if (alertSent) {
        return 'संभाव्य गंभीर स्थिती. आशा कार्यकर्ता आणि डॉक्टरांना कळवले आहे.';
      }
      if (undetermined) {
        return 'ही लक्षणे सामान्य आहेत. विश्रांती घ्या, द्रव प्या आणि बिघडल्यास डॉक्टरांना भेटा.';
      }
      return 'पुरेसे पाणी प्या आणि विश्रांती घ्या. लक्षणांकडे लक्ष द्या.';
    }
    if (lang.startsWith('hi')) {
      if (alertSent) {
        return 'संभावित गंभीर स्थिति। आशा कार्यकर्ता और डॉक्टर को सूचित किया गया है।';
      }
      if (undetermined) {
        return 'ये लक्षण आम हैं। आराम करें, तरल पदार्थ लें, और बिगड़ने पर डॉक्टर से मिलें।';
      }
      return 'पर्याप्त पानी पिएँ और आराम करें। लक्षणों पर नज़र रखें।';
    }
    if (alertSent) {
      return 'Potentially serious condition detected. ASHA worker and doctor have been notified.';
    }
    if (undetermined) {
      return 'These symptoms are common. Rest, drink fluids, and consult a doctor if they worsen.';
    }
    return 'Maintain hydration and rest. Monitor symptoms carefully.';
  }

  static String disclaimer(String language, {bool animal = false}) {
    final lang = language.toLowerCase();
    if (lang.startsWith('mr')) {
      return animal
          ? 'स्क्रीनिंगमुळे धोका दिसतो — पात्र पशुवैद्यांचा सल्ला घ्या. हे पशुवैद्यकीय निदान नाही.'
          : 'स्क्रीनिंगमुळे धोका दिसतो — पात्र आरोग्य तज्ज्ञांचा सल्ला घ्या. हे वैद्यकीय निदान नाही.';
    }
    if (lang.startsWith('hi')) {
      return animal
          ? 'स्क्रीनिंग से जोखिम का संकेत — योग्य पशुचिकित्सक से सलाह लें। यह पशु चिकित्सा निदान नहीं है।'
          : 'स्क्रीनिंग से जोखिम का संकेत — योग्य स्वास्थ्य पेशेवर से सलाह लें। यह चिकित्सा निदान नहीं है।';
    }
    return animal
        ? 'AI-assisted screening only. This is not a veterinary diagnosis. Consult a qualified veterinarian.'
        : 'AI-assisted screening only. This result is not a medical diagnosis. Please consult a qualified healthcare professional.';
  }

  /// Devanagari (HI+MR) → English screening tokens.
  static const indicSynonyms = {
    'बुखार': 'fever',
    'ताप': 'fever',
    'खांसी': 'cough',
    'खोकला': 'cough',
    'सिरदर्द': 'headache',
    'डोकेदुखी': 'headache',
    'उल्टी': 'vomiting',
    'उलटी': 'vomiting',
    'दर्द': 'pain',
    'वेदना': 'pain',
    'थकान': 'fatigue',
    'थकवा': 'fatigue',
    'खुजली': 'itching',
    'खाज': 'itching',
    'चकत्ते': 'rash',
    'पुरळ': 'rash',
    'छींक': 'sneezing',
    'शिंका': 'sneezing',
    'जुकाम': 'cold',
    'सर्दी': 'cold',
    'कफ': 'cough',
    'सांस': 'breath',
    'श्वास': 'breath',
    'चक्कर': 'dizziness',
    'चक्कर येणे': 'dizziness',
    'दस्त': 'diarrhoea',
    'जुलाब': 'diarrhoea',
    'पीलिया': 'jaundice',
    'कावीळ': 'jaundice',
    'पसीना': 'sweating',
    'घाम': 'sweating',
    'कमजोरी': 'weakness',
    'अशक्तपणा': 'weakness',
    'मितली': 'nausea',
    'मळमळ': 'nausea',
    'भूख': 'appetite',
    'भूक': 'appetite',
    'सीने': 'chest',
    'छाती': 'chest',
  };
}
