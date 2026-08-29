/// Shared One Health screening safety copy (never present AI as a diagnosis).
class ScreeningDisclaimer {
  ScreeningDisclaimer._();

  static const String enHuman =
      'AI-assisted screening only. This is not a medical or veterinary '
      'diagnosis. Please consult a qualified healthcare professional.';

  static const String enAnimal =
      'AI-assisted screening only. This is not a medical or veterinary '
      'diagnosis. Livestock screening is decision support only — consult a qualified veterinarian.';

  static const String hiHuman =
      'स्क्रीनिंग से जोखिम का संकेत — योग्य स्वास्थ्य पेशेवर से सलाह लें। यह चिकित्सा निदान नहीं है।';

  static const String hiAnimal =
      'स्क्रीनिंग से जोखिम का संकेत — योग्य पशुचिकित्सक से सलाह लें। यह पशु चिकित्सा निदान नहीं है।';

  static const String mrHuman =
      'स्क्रीनिंगमुळे धोका दिसतो — पात्र आरोग्य तज्ज्ञांचा सल्ला घ्या. हे वैद्यकीय निदान नाही.';

  static const String mrAnimal =
      'स्क्रीनिंगमुळे धोका दिसतो — पात्र पशुवैद्यांचा सल्ला घ्या. हे पशुवैद्यकीय निदान नाही.';

  static String text({
    required String language,
    required bool isAnimal,
  }) {
    final lang = language.toLowerCase();
    if (lang.startsWith('mr')) {
      return isAnimal ? mrAnimal : mrHuman;
    }
    if (lang.startsWith('hi')) {
      return isAnimal ? hiAnimal : hiHuman;
    }
    return isAnimal ? enAnimal : enHuman;
  }

  static String possibleConditionLabel(String language) {
    final lang = language.toLowerCase();
    if (lang.startsWith('mr')) return 'संभाव्य स्थिती (स्क्रीनिंग)';
    if (lang.startsWith('hi')) return 'संभावित स्थिति (स्क्रीनिंग)';
    return 'Possible condition (screening)';
  }
}
