from django.urls import path
from .views import SymptomAnalysisView, SkinAnalysisView

urlpatterns = [
    path('analyze/', SymptomAnalysisView.as_view(), name='analyze-symptoms'),
    path('analyze-skin/', SkinAnalysisView.as_view(), name='analyze-skin'),
]
