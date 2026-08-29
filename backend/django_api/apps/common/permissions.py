"""Role-based permission classes. Server derives role from authenticated user."""

from rest_framework.permissions import BasePermission, SAFE_METHODS


def _role(user):
    return getattr(user, 'role', None) if user and user.is_authenticated else None


class IsPatient(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and _role(request.user) == 'user')


class IsDoctor(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and _role(request.user) == 'doctor')


class IsVeterinarian(BasePermission):
    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated or _role(user) != 'doctor':
            return False
        profile = getattr(user, 'doctor_profile', None)
        return bool(profile and getattr(profile, 'is_veterinarian', False))


class IsAsha(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and _role(request.user) == 'asha_worker')


class IsMedicalStaff(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and _role(request.user) == 'medical_staff')


class IsAdminOrStaff(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_staff)


class IsDoctorOrAsha(BasePermission):
    def has_permission(self, request, view):
        return _role(request.user) in ('doctor', 'asha_worker') if request.user and request.user.is_authenticated else False


class ReadOnlyOrAuthenticatedWrite(BasePermission):
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.method in SAFE_METHODS:
            return True
        return True
