from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .ai_service import analyze_symptoms

class SymptomAnalysisView(APIView):
    def post(self, request):
        symptoms = request.data.get('symptoms', [])
        if not symptoms:
            return Response({"error": "No symptoms provided"}, status=status.HTTP_400_BAD_REQUEST)
        
        result = analyze_symptoms(symptoms)
        return Response(result)
