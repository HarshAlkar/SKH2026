from django.urls import path
from .views import SymptomAnalysisView

urlpatterns = [
    path('analyze/', SymptomAnalysisView.as_view(), name='analyze-symptoms'),
]
