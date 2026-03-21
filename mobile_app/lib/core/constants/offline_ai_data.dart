class OfflineAIData {
  static const Map<String, Map<String, String>> responses = {
    'en': {
      'emergency': 'For emergencies, please call 108 immediately. Keep calm and ensure the patient is in a safe position.',
      'who': 'I am your Gramin Health Assistant, here to help you with health queries and doctor appointments.',
      'fever': 'If you have a fever, rest well, stay hydrated, and take paracetamol if prescribed. If symptoms persist, consult a doctor.',
      'abha': 'Your ABHA ID is your unique health identity. You can find it in your profile section.',
      'family': 'You can add your family members in the profile section to manage their health records as well.',
      'help': 'I can help with: \n1. Symptom checking\n2. Emergency info\n3. Profile management\n4. Consulting doctors',
      'default': 'I am sorry, I am currently in offline mode and don\'t have an answer for that. Please connect to the internet for more advanced help.'
    },
    'hi': {
      'emergency': 'आपातकालीन स्थिति में, कृपया तुरंत 108 पर कॉल करें। शांत रहें और सुनिश्चित करें कि रोगी सुरक्षित स्थिति में है।',
      'who': 'मैं आपका ग्रामीण स्वास्थ्य सहायक हूँ, यहाँ आपकी स्वास्थ्य संबंधी पूछताछ और डॉक्टर के अपॉइंटमेंट में मदद करने के लिए हूँ।',
      'fever': 'यदि आपको बुखार है, तो अच्छी तरह से आराम करें, हाइड्रेटेड रहें, और डॉक्टर की सलाह पर पैरासिटामोल लें। यदि लक्षण बने रहते हैं, तो डॉक्टर से परामर्श करें।',
      'abha': 'आपकी ABHA ID आपकी विशिष्ट स्वास्थ्य पहचान है। आप इसे अपने प्रोफ़ाइल अनुभाग में पा सकते हैं।',
      'family': 'आप अपने परिवार के सदस्यों को उनके स्वास्थ्य रिकॉर्ड का प्रबंधन करने के लिए प्रोफ़ाइल अनुभाग में जोड़ सकते हैं।',
      'help': 'मैं आपकी मदद कर सकता हूँ: \n1. लक्षण जाँच\n2. आपातकालीन जानकारी\n3. प्रोफ़ाइल प्रबंधन\n4. डॉक्टरों से परामर्श',
      'default': 'क्षमा करें, मैं वर्तमान में ऑफ़लाइन मोड में हूँ और मेरे पास इसका जवाब नहीं है। कृपया अधिक उन्नत मदद के लिए इंटरनेट से जुड़ें।'
    },
    'mr': {
      'emergency': 'आणीबाणीच्या परिस्थितीत, कृपया त्वरित 108 वर कॉल करा. शांत राहा आणि रुग्ण सुरक्षित स्थितीत असल्याची खात्री करा.',
      'who': 'मी तुमचा ग्रामीण आरोग्य सहाय्यक आहे, तुम्हाला आरोग्याच्या शंका आणि डॉक्टरांच्या भेटीसाठी मदत करण्यासाठी येथे आहे.',
      'fever': 'तुम्हाला ताप असल्यास, नीट विश्रांती घ्या, हायड्रेटेड राहा आणि डॉक्टरांनी लिहून दिल्यास पॅरासिटामॉल घ्या. लक्षणे कायम राहिल्यास डॉक्टरांचा सल्ला घ्या.',
      'abha': 'तुमची ABHA ID ही तुमची अद्वितीय आरोग्य ओळख आहे. तुम्ही ती तुमच्या प्रोफाइल विभागात शोधू शकता.',
      'family': 'तुम्ही तुमच्या कुटुंबातील सदस्यांच्या आरोग्य नोंदी व्यवस्थापित करण्यासाठी त्यांना प्रोफाइल विभागात जोडू शकता.',
      'help': 'मी मदत करू शकतो: \n1. लक्षणे तपासणे\n2. आणीबाणीची माहिती\n3. प्रोफाइल व्यवस्थापन\n4. डॉक्टरांचा सल्ला घेणे',
      'default': 'क्षमस्व, मी सध्या ऑफलाइन मोडमध्ये आहे आणि माझ्याकडे त्याचे उत्तर नाही. कृपया अधिक प्रगत मदतीसाठी इंटरनेटशी कनेक्ट व्हा.'
    }
  };

  static String getOfflineResponse(String input, String lang) {
    final query = input.toLowerCase();
    final data = responses[lang] ?? responses['en']!;

    if (query.contains('emergency') || query.contains('accident') || query.contains('मदत') || query.contains('आपातकालीन')) {
      return data['emergency']!;
    }
    if (query.contains('who') || query.contains('who are you') || query.contains('कोण') || query.contains('कौन')) {
      return data['who']!;
    }
    if (query.contains('fever') || query.contains('temp') || query.contains('ताप') || query.contains('बुखार')) {
      return data['fever']!;
    }
    if (query.contains('abha') || query.contains('id')) {
      return data['abha']!;
    }
    if (query.contains('family') || query.contains('कुटुंब') || query.contains('परिवार')) {
      return data['family']!;
    }
     if (query.contains('help') || query.contains('काय करू') || query.contains('क्या कर सकते')) {
      return data['help']!;
    }

    return data['default']!;
  }
}
