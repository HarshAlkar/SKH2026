"""
URL configuration for config project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse

def api_root_view(request):
    return JsonResponse({
        "status": "online",
        "project": "Gramin Health Connect API",
        "documentation": "Visit /admin/ for administrative control or /api/ for specific endpoints.",
        "endpoints": [
            "/api/auth/",
            "/api/users/",
            "/api/symptoms/",
            "/api/medicines/",
            "/api/consultations/",
            "/api/prescriptions/",
            "/api/alerts/",
            "/api/records/",
            "/api/patients/",
            "/api/asha/",
            "/api/chat/",
        ]
    })

urlpatterns = [
    path('', api_root_view, name='api_root'),
    path('admin/', admin.site.urls),
    path('api/auth/', include('apps.users.urls')), # login/register are actions in UserViewSet
    path('api/users/', include('apps.users.urls')),
    path('api/symptoms/', include('apps.symptom_analysis.urls')),
    path('api/medicines/', include('apps.medicine_tracker.urls')),
    path('api/doctors/', include('apps.doctors.urls')),
    path('api/consultations/', include('apps.consultations.urls')),
    path('api/prescriptions/', include('apps.prescriptions.urls')),
    path('api/alerts/', include('apps.alerts.urls')),
    path('api/records/', include('apps.health_records.urls')),
    path('api/patients/', include('apps.patients.urls')),
    path('api/asha/', include('apps.asha_workers.urls')),
    path('api/chat/', include('apps.chat.urls')),
]

