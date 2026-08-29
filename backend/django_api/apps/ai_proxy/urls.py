from django.urls import path

from .views import GeminiChatProxyView, GeminiStatusView

urlpatterns = [
    path('gemini-chat/', GeminiChatProxyView.as_view(), name='gemini_chat_proxy'),
    path('status/', GeminiStatusView.as_view(), name='gemini_status'),
]
