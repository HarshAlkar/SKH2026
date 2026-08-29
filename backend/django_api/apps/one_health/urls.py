from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    LivestockCaseViewSet,
    ScreeningEventViewSet,
    AnimalScreeningView,
    VeterinarianListView,
)

router = DefaultRouter()
router.register(r'livestock', LivestockCaseViewSet, basename='livestock')
router.register(r'screenings', ScreeningEventViewSet, basename='screenings')

urlpatterns = [
    path('animal/analyze/', AnimalScreeningView.as_view(), name='animal-analyze'),
    path('veterinarians/', VeterinarianListView.as_view(), name='veterinarians'),
    path('', include(router.urls)),
]
