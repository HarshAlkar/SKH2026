from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin
from .models import User, OTPVerification


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    fieldsets = DjangoUserAdmin.fieldsets + (
        ("VitalReach", {"fields": ("role", "phone_number", "village", "name", "photo")}),
    )
    add_fieldsets = DjangoUserAdmin.add_fieldsets + (
        ("VitalReach", {"fields": ("role", "phone_number", "village", "name")}),
    )
    list_display = ("username", "name", "phone_number", "role", "is_staff", "is_active")
    list_filter = ("role", "is_active", "is_staff")
    search_fields = ("username", "name", "phone_number", "email")


@admin.register(OTPVerification)
class OTPVerificationAdmin(admin.ModelAdmin):
    list_display = ("phone_number", "is_verified", "expiry_time", "created_at")
    list_filter = ("is_verified",)
    exclude = ("otp_code",)
    readonly_fields = ("phone_number", "is_verified", "expiry_time", "created_at")
