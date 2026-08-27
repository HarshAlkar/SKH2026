from rest_framework.permissions import BasePermission, SAFE_METHODS


class IsMedicalStaffOrAsha(BasePermission):
    """Pharmacists and ASHA workers can write stock."""

    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if user.is_staff:
            return True
        return getattr(user, 'role', None) in ('medical_staff', 'asha_worker')


class IsStockWriter(BasePermission):
    """Only medical_staff and asha_worker may mutate stock (not patients/doctors)."""

    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if request.method in SAFE_METHODS:
            return True
        if user.is_staff:
            return True
        return getattr(user, 'role', None) in ('medical_staff', 'asha_worker')


class CanReadStock(BasePermission):
    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated)
