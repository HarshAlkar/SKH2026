from django.urls import path

from .views import (
    AdminGeminiReportView,
    DetectLanguageView,
    GeminiChatProxyView,
    GeminiReportAnalysisView,
    GeminiStatusView,
)

urlpatterns = [
    path('gemini-chat/', GeminiChatProxyView.as_view(), name='gemini_chat_proxy'),
    path('status/', GeminiStatusView.as_view(), name='gemini_status'),
    path('report-analysis/', GeminiReportAnalysisView.as_view(), name='gemini_report_analysis'),
    path('admin-report/', AdminGeminiReportView.as_view(), name='gemini_admin_report'),
    path('detect-language/', DetectLanguageView.as_view(), name='detect_language'),
]
