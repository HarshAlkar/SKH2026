from django.urls import path

from .views import (
    TrustShieldDemoClaimsView,
    TrustShieldReportView,
    TrustShieldVerifyView,
)

urlpatterns = [
    path('verify/', TrustShieldVerifyView.as_view(), name='trustshield-verify'),
    path('report/', TrustShieldReportView.as_view(), name='trustshield-report'),
    path('demos/', TrustShieldDemoClaimsView.as_view(), name='trustshield-demos'),
]
