from rest_framework import serializers
from .models import SymptomAnalysis

class SymptomAnalysisSerializer(serializers.ModelSerializer):
    class Meta:
        model = SymptomAnalysis
        fields = ['id', 'user', 'symptoms_text', 'predicted_disease', 'severity_level', 'created_at']
