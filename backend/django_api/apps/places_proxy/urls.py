from django.urls import path

from .views import NearbyPlacesView, PlacesStatusView

urlpatterns = [
    path('nearby/', NearbyPlacesView.as_view(), name='places_nearby'),
    path('status/', PlacesStatusView.as_view(), name='places_status'),
]
