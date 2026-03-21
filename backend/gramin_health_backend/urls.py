from django.contrib import admin
def app_urls(app_name):
    return include(f'{app_name}.urls')
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('asha_worker.urls')),
    path('api/patients/', include('patients.urls')),
    path('api/visits/', include('visits.urls')),
    path('api/health/', include('health_records.urls')),
    path('api/alerts/', include('alerts.urls')),
    path('api/consultations/', include('consultation.urls')),
    path('api/referral/', include('referral.urls')),
    path('api/notifications/', include('notifications.urls')),
    path('api/sync/', include('offline_sync.urls')),
    path('api/doctors/', include('doctors.urls')),
]


