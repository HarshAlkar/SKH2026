from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .views import AshaRegisterView, AshaProfileView, LoginView

urlpatterns = [
    path('register/', AshaRegisterView.as_view(), name='asha-register'),
    path('login/', LoginView.as_view(), name='asha-login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('profile/', AshaProfileView.as_view(), name='asha-profile'),
]
