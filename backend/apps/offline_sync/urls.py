from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SyncLogViewSet

router = DefaultRouter()
router.register(r'', SyncLogViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
