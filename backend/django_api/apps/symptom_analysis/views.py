from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from .models import VoiceSymptomInput, SymptomAnalysis
from .i18n import localize_analysis
from apps.alerts.notify import notify_village_care_team
from django.conf import settings
import sys

MAX_SKIN_IMAGE_BYTES = 3 * 1024 * 1024

HUMAN_DISCLAIMER = (
    'AI-assisted screening only. This result is not a medical diagnosis. '
    'Please consult a qualified healthcare professional.'
)


def _ensure_project_root():
    project_root = str(settings.BASE_DIR.parent.parent)
    if project_root not in sys.path:
        sys.path.append(project_root)
    return project_root


def _record_human_screening(
    user,
    symptoms_text,
    predicted_disease,
    severity,
    confidence,
    result,
    input_type='symptoms',
    client_id=None,
):
    try:
        from apps.one_health.models import ScreeningEvent
        ScreeningEvent.objects.create(
            domain='HUMAN',
            user=user,
            input_type=input_type,
            input_text=symptoms_text,
            possible_condition=predicted_disease,
            severity_level=severity,
            confidence=float(confidence or 0),
            advice=(result.get('advice') if isinstance(result, dict) else '') or '',
            result_json=result if isinstance(result, dict) else {},
            client_id=client_id or None,
        )
    except Exception:
        pass

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

    def post(self, request):
        user = request.user
        recognized_text = request.data.get('recognized_text', '')
        symptoms_text = request.data.get('symptoms', request.data.get('symptoms_text', recognized_text))
        language = request.data.get('language', 'en')
        
        # 1. Store Voice Input if provided
        if recognized_text:
            VoiceSymptomInput.objects.create(
                user=user,
                recognized_text=recognized_text
            )
        
        # 2. Convert text to symptom list (supporting Hindi/Unicode)
        import re
        # Support Unicode words for Hindi
        words = re.findall(r'[\w\u0900-\u097F]+', symptoms_text.lower())
        
        # Translate Hindi words to English for the AI engine
        symptoms_list = []
        for word in words:
            if word in self.HINDI_MAPPING:
                symptoms_list.append(self.HINDI_MAPPING[word])
            else:
                symptoms_list.append(word)
        
        # 3. AI Prediction
        _ensure_project_root() 
        try:
            from ai_engine.predict import predict_symptoms
            analysis_result = predict_symptoms(symptoms_list)
        except Exception as e:
            return Response({"error": f"AI Engine error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        predicted_disease = analysis_result.get('disease', 'Unknown')
        severity = analysis_result.get('severity', 'Low')
        confidence = analysis_result.get('confidence', 0)
        top_predictions = analysis_result.get('top_predictions') or [
            {'disease': predicted_disease, 'confidence': confidence, 'severity': severity}
        ]

        # 4. Store Analysis Result
        analysis = SymptomAnalysis.objects.create(
            user=user,
            symptoms_text=symptoms_text,
            predicted_disease=predicted_disease,
            severity_level=severity
        )

        _record_human_screening(user, symptoms_text, predicted_disease, severity, confidence, analysis_result)

        # 5. Alert village ASHA + doctor for High/Critical screening results
        alert_sent = False
        if severity in ['High', 'Critical']:
            _, alert_sent = notify_village_care_team(user, predicted_disease, severity)

        localized = localize_analysis(analysis_result, language=language, alert_sent=alert_sent)
        disclaimer = localized.get("disclaimer") or HUMAN_DISCLAIMER

        return Response({
            "analysis_id": analysis.id,
            "disease": predicted_disease,
            "disease_display": localized["disease_display"],
            "possible_condition": localized["disease_display"],
            "severity": severity,
            "severity_display": localized["severity_display"],
            "confidence": confidence,
            "top_predictions": localized["top_predictions"],
            "alert_sent": alert_sent,
            "advice": localized["advice"],
            "disclaimer": disclaimer,
            "language": localized["language"],
            "domain": "HUMAN",
        }, status=status.HTTP_200_OK)


class SkinAnalysisView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def post(self, request):
        uploaded = request.FILES.get("image") or request.FILES.get("file")
        if uploaded is None:
            return Response(
                {"error": "Upload a skin photo as form field 'image'."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if uploaded.size and uploaded.size > MAX_SKIN_IMAGE_BYTES:
            return Response(
                {"error": "Image is too large. Maximum size is 3 MB."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        content_type = (uploaded.content_type or "").lower()
        if content_type and not content_type.startswith("image/"):
            return Response(
                {"error": "File must be an image (jpeg, png, or webp)."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        _ensure_project_root()
        try:
            from ai_engine.skin.predict import SkinModelNotTrained, predict_skin

            uploaded.seek(0)
            analysis_result = predict_skin(uploaded)
        except SkinModelNotTrained as exc:
            return Response({"error": str(exc)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        except Exception as exc:
            return Response(
                {"error": f"Skin CNN error: {exc}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        predicted_disease = analysis_result.get("disease", "Unknown")
        severity = analysis_result.get("severity", "Low")
        confidence = analysis_result.get("confidence", 0)

        analysis = SymptomAnalysis.objects.create(
            user=request.user,
            symptoms_text="skin_image",
            predicted_disease=predicted_disease,
            severity_level=severity,
        )

        client_id = request.data.get("client_id")
        _record_human_screening(
            request.user,
            "skin_image",
            predicted_disease,
            severity,
            confidence,
            analysis_result,
            input_type="image",
            client_id=client_id,
        )

        alert_sent = False
        if severity in ["High", "Critical"]:
            _, alert_sent = notify_village_care_team(
                request.user, predicted_disease, severity
            )

        language = request.data.get("language", "en")
        localized = localize_analysis(analysis_result, language=language, alert_sent=alert_sent)
        disclaimer = localized.get("disclaimer") or (
            "AI-assisted skin screening only. Screening confidence is not a confirmed diagnosis. "
            "Professional evaluation is recommended."
        )

        return Response(
            {
                "analysis_id": analysis.id,
                "disease": predicted_disease,
                "disease_display": localized["disease_display"],
                "possible_condition": localized["disease_display"],
                "code": analysis_result.get("code"),
                "severity": severity,
                "severity_display": localized["severity_display"],
                "confidence": confidence,
                "top_predictions": localized["top_predictions"],
                "alert_sent": alert_sent,
                "source": analysis_result.get("source") or "skin_cnn",
                "advice": localized["advice"],
                "disclaimer": disclaimer,
                "message": analysis_result.get("message")
                or (
                    f"AI-assisted skin screening suggests possible elevated risk for "
                    f"{localized['disease_display']}. Screening confidence is not a confirmed diagnosis."
                ),
                "language": localized["language"],
                "domain": "HUMAN",
            },
            status=status.HTTP_200_OK,
        )
