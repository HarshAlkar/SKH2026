from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .models import VoiceSymptomInput, SymptomAnalysis
from django.conf import settings
import sys
import os

class SymptomAnalysisView(APIView):
    permission_classes = [IsAuthenticated]

    HINDI_MAPPING = {
        'बुखार': 'fever',
        'खांसी': 'cough',
        'सिरदर्द': 'headache',
        'उल्टी': 'vomiting',
        'दर्द': 'pain',
        'थकान': 'fatigue',
        'बदन': 'body',
        'खुजली': 'itching',
        'चकत्ते': 'rash',
        'छींक': 'sneezing',
        'जुकाम': 'cold',
        'कफ': 'cough',
        'सांस': 'breath',
        'चक्कर': 'dizziness',
        'घबराहट': 'anxiety',
        'कब्ज': 'constipation',
        'दस्त': 'diarrhoea',
        'पीलिया': 'jaundice',
        'पसीना': 'sweating',
        'कमजोरी': 'weakness',
    }

    MARATHI_MAPPING = {

        'ताप': 'fever',
        'खोकला': 'cough',
        'डोकेदुखी': 'headache',
        'उलट्या': 'vomiting',
        'वेदना': 'pain',
        'थकावट': 'fatigue',
        'हगवण': 'diarrhoea',
        'कंबर': 'back',
        'छातीत': 'chest',
        'श्वास': 'breath',
        'चक्कर': 'dizziness',
        'घबराट': 'anxiety',
        'बद्धकोष्ठता': 'constipation',
        'काविळ': 'jaundice',
        'घाम': 'sweating',
        'कमकुवतपणा': 'weakness',
    }

    def post(self, request):
        user = request.user
        recognized_text = request.data.get('recognized_text', '')
        symptoms_text = request.data.get('symptoms', request.data.get('symptoms_text', recognized_text))
        
        # 1. Store Voice Input if provided
        if recognized_text:
            VoiceSymptomInput.objects.create(
                user=user,
                recognized_text=recognized_text
            )
        
        # 2. Convert text to symptom list (supporting Hindi/Marathi/Unicode)
        import re
        # Support Unicode words for Hindi and Marathi
        words = re.findall(r'[\w\u0900-\u097F]+', symptoms_text.lower())
        
        # Translate Hindi/Marathi words to English for the AI engine
        symptoms_list = []
        for word in words:
            if word in self.HINDI_MAPPING:
                symptoms_list.append(self.HINDI_MAPPING[word])
            elif word in self.MARATHI_MAPPING:
                symptoms_list.append(self.MARATHI_MAPPING[word])
            else:
                symptoms_list.append(word)

        
        # 3. AI Prediction
        # Add project root (hs053) to sys.path
        project_root = str(settings.BASE_DIR.parent.parent)
        if project_root not in sys.path:
            sys.path.append(project_root)
            
        try:
            from ai_engine.predict import predict_symptoms
            analysis_result = predict_symptoms(symptoms_list)
        except Exception as e:
            return Response({"error": f"AI Engine error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        predicted_disease = analysis_result.get('disease', 'Unknown')
        severity = analysis_result.get('severity', 'Low')
        
        # 4. Store Analysis Result
        analysis = SymptomAnalysis.objects.create(
            user=user,
            symptoms_text=symptoms_text,
            predicted_disease=predicted_disease,
            severity_level=severity
        )
        
        return Response({
            "analysis_id": analysis.id,
            "disease": predicted_disease,
            "severity": severity,
        }, status=status.HTTP_200_OK)
