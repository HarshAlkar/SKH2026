from rest_framework import serializers, viewsets, status
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.conf import settings
from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from .models import User, OTPVerification
from .sms import send_otp_sms
from apps.doctors.models import Doctor
from apps.asha_workers.models import ASHAWorker
from apps.patients.models import Patient
import random
import datetime
import re


def normalize_identifier(value):
    if not value:
        return value
    value = str(value).strip()
    digits = re.sub(r"\D", "", value)
    if digits.startswith("91") and len(digits) == 12:
        digits = digits[-10:]
    if len(digits) == 10:
        return digits
    return value


class UserSerializer(serializers.ModelSerializer):
    profile_details = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "role",
            "phone_number",
            "village",
            "name",
            "created_at",
            "profile_details",
        ]

    def get_profile_details(self, obj):
        if obj.role == "doctor" and hasattr(obj, "doctor_profile"):
            return {
                "specialization": obj.doctor_profile.specialization,
                "experience_years": obj.doctor_profile.experience_years,
                "hospital_name": obj.doctor_profile.hospital_name,
                "qualification": obj.doctor_profile.qualification,
                "is_available": obj.doctor_profile.is_available,
            }
        if obj.role == "asha_worker" and hasattr(obj, "asha_profile"):
            return {
                "assigned_village": obj.asha_profile.assigned_village,
                "phc_center": obj.asha_profile.phc_center,
                "worker_id": obj.asha_profile.worker_id,
                "district": obj.asha_profile.district,
            }
        if obj.role == "user" and hasattr(obj, "patient_profile"):
            return {
                "patient_id": obj.patient_profile.id,
                "user_id": obj.id,
                "age": obj.patient_profile.age,
                "gender": obj.patient_profile.gender,
                "address": obj.patient_profile.address,
                "blood_group": obj.patient_profile.blood_group,
            }
        return None


class RegisterSerializer(serializers.ModelSerializer):
    username = serializers.CharField(required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=6)
    role = serializers.ChoiceField(choices=User.ROLE_CHOICES)

    specialization = serializers.CharField(required=False, allow_blank=True)
    experience_years = serializers.IntegerField(required=False)
    hospital_name = serializers.CharField(required=False, allow_blank=True)
    assigned_village = serializers.CharField(required=False, allow_blank=True)
    phc_center = serializers.CharField(required=False, allow_blank=True)
    license_number = serializers.CharField(required=False, allow_blank=True)
    worker_id = serializers.CharField(required=False, allow_blank=True)
    district = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = [
            "username",
            "email",
            "password",
            "role",
            "phone_number",
            "village",
            "name",
            "specialization",
            "experience_years",
            "hospital_name",
            "assigned_village",
            "phc_center",
            "license_number",
            "worker_id",
            "district",
        ]

    def validate_phone_number(self, value):
        if not value:
            return value
        value = normalize_identifier(value)
        if User.objects.filter(Q(phone_number=value) | Q(username=value)).exists():
            raise serializers.ValidationError("This identifier is already registered.")
        return value

    def validate_name(self, value):
        if not value:
            raise serializers.ValidationError("Name cannot be empty.")
        return value

    def validate(self, attrs):
        role = attrs.get("role")
        village = attrs.get("village")
        if role == "user" and not village:
            raise serializers.ValidationError({"village": "Village cannot be empty."})
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        specialization = validated_data.pop("specialization", None)
        experience_years = validated_data.pop("experience_years", None)
        hospital_name = validated_data.pop("hospital_name", None)
        assigned_village = validated_data.pop("assigned_village", None)
        phc_center = validated_data.pop("phc_center", None)
        license_number = validated_data.pop("license_number", None)
        worker_id = validated_data.pop("worker_id", None)
        district = validated_data.pop("district", None)

        if not validated_data.get("username"):
            validated_data["username"] = validated_data.get("phone_number")

        if validated_data.get("phone_number"):
            validated_data["phone_number"] = normalize_identifier(validated_data["phone_number"])

        user = User.objects.create_user(**validated_data)

        if user.role == "doctor":
            Doctor.objects.create(
                user=user,
                specialization=specialization or "General",
                experience_years=experience_years or 0,
                hospital_name=hospital_name or "General Hospital",
                license_number=license_number,
            )
        elif user.role == "asha_worker":
            ASHAWorker.objects.create(
                user=user,
                assigned_village=assigned_village or user.village or "",
                phc_center=phc_center or "Local PHC",
                worker_id=worker_id or "",
                district=district or "",
            )
        elif user.role == "user":
            Patient.objects.create(
                user=user,
                age=0,
                gender="Not Set",
                address=user.village or "Not Set",
            )

        return user


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    http_method_names = ["get", "post", "patch", "head", "options"]

    def get_permissions(self):
        if self.action in ["register", "login", "send_otp", "verify_otp", "reset_password"]:
            return [AllowAny()]
        return [IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return User.objects.none()
        if self.action == "get_doctors":
            return User.objects.filter(role="doctor")
        if self.action == "get_asha_workers":
            qs = User.objects.filter(role="asha_worker")
            if user.role == "user" and user.village:
                qs = qs.filter(
                    Q(village__iexact=user.village)
                    | Q(asha_profile__assigned_village__iexact=user.village)
                )
            return qs
        if self.action == "get_patients":
            qs = User.objects.filter(role="user")
            if user.role == "asha_worker":
                village = ""
                if hasattr(user, "asha_profile") and user.asha_profile:
                    village = user.asha_profile.assigned_village or user.village or ""
                else:
                    village = user.village or ""
                if village:
                    qs = qs.filter(village__iexact=village)
            return qs.distinct()
        if self.action == "list":
            role = self.request.query_params.get("role")
            if role in dict(User.ROLE_CHOICES):
                return User.objects.filter(role=role)
            return User.objects.filter(pk=user.pk)
        return User.objects.filter(pk=user.pk)

    def create(self, request, *args, **kwargs):
        return Response(
            {"error": "Use /register/ to create accounts."},
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def update(self, request, *args, **kwargs):
        return Response(
            {"error": "Full user update is not allowed."},
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

    def partial_update(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.pk != request.user.pk:
            return Response({"error": "You can only update your own profile."}, status=status.HTTP_403_FORBIDDEN)
        allowed = {k: request.data.get(k) for k in ("name", "village", "email") if k in request.data}
        for key, value in allowed.items():
            setattr(instance, key, value)
        instance.save()
        return Response(UserSerializer(instance).data)

    @action(detail=False, methods=["post"], url_path="register")
    def register(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token, _created = Token.objects.get_or_create(user=user)
            return Response(
                {"token": token.key, "user": UserSerializer(user).data},
                status=status.HTTP_201_CREATED,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=["post"], url_path="login")
    def login(self, request):
        identifier = request.data.get("phone_number") or request.data.get("email") or request.data.get("username")
        password = request.data.get("password")
        role = request.data.get("role")

        if not role:
            return Response({"error": "Role is required"}, status=status.HTTP_400_BAD_REQUEST)
        if not identifier or not password:
            return Response(
                {"error": "Identifier and password are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        identifier = normalize_identifier(identifier)
        matches = User.objects.filter(role=role).filter(
            Q(phone_number=identifier) | Q(email=identifier) | Q(username=identifier)
        )
        user_obj = matches.first()
        if not user_obj:
            if User.objects.filter(Q(phone_number=identifier) | Q(email=identifier) | Q(username=identifier)).exists():
                existing = User.objects.filter(
                    Q(phone_number=identifier) | Q(email=identifier) | Q(username=identifier)
                ).first()
                return Response(
                    {
                        "error": f"Invalid login for this module. This account is registered as {existing.get_role_display()}."
                    },
                    status=status.HTTP_403_FORBIDDEN,
                )
            return Response({"error": "Invalid credentials or user not found"}, status=status.HTTP_401_UNAUTHORIZED)

        user = authenticate(username=user_obj.username, password=password)
        if user:
            token, _created = Token.objects.get_or_create(user=user)
            return Response({"token": token.key, "user": UserSerializer(user).data})
        return Response({"error": "Invalid password"}, status=status.HTTP_401_UNAUTHORIZED)

    @action(detail=False, methods=["post"], url_path="logout")
    def logout(self, request):
        try:
            request.user.auth_token.delete()
            return Response({"message": "Successfully logged out"}, status=status.HTTP_200_OK)
        except Exception:
            return Response({"error": "Something went wrong"}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=["post"], url_path="send-otp")
    def send_otp(self, request):
        phone_number = normalize_identifier(request.data.get("phone_number"))
        if not phone_number or len(str(phone_number)) != 10:
            return Response(
                {"error": "Valid 10-digit phone number is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = User.objects.filter(phone_number=phone_number).first()
        if not user:
            return Response(
                {"error": "User with this phone number does not exist"},
                status=status.HTTP_404_NOT_FOUND,
            )

        OTPVerification.objects.filter(phone_number=phone_number, is_verified=False).delete()

        otp_code = str(random.randint(100000, 999999))
        expiry_time = timezone.now() + datetime.timedelta(minutes=5)
        OTPVerification.objects.create(
            phone_number=phone_number,
            otp_code=otp_code,
            expiry_time=expiry_time,
        )

        sms_sent = send_otp_sms(phone_number, otp_code)
        payload = {"message": f"OTP sent to {phone_number}"}
        if settings.DEBUG and not sms_sent:
            print(f"DEBUG: OTP for {phone_number} is {otp_code}")
            payload["otp"] = otp_code
        elif not sms_sent and not settings.DEBUG:
            return Response(
                {"error": "SMS provider is not configured."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        return Response(payload, status=status.HTTP_200_OK)

    @action(detail=False, methods=["post"], url_path="verify-otp")
    def verify_otp(self, request):
        phone_number = normalize_identifier(request.data.get("phone_number"))
        otp_code = request.data.get("otp") or request.data.get("otp_code")
        role = request.data.get("role")

        if not phone_number or not otp_code:
            return Response(
                {"error": "Phone number and OTP code are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        otp_record = (
            OTPVerification.objects.filter(phone_number=phone_number, otp_code=otp_code, is_verified=False)
            .order_by("-created_at")
            .first()
        )

        if not otp_record:
            return Response({"error": "Invalid OTP"}, status=status.HTTP_400_BAD_REQUEST)
        if otp_record.is_expired():
            otp_record.delete()
            return Response({"error": "OTP has expired"}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.filter(phone_number=phone_number).first()
        if not user:
            otp_record.delete()
            return Response({"error": "User with this phone number does not exist"}, status=status.HTTP_404_NOT_FOUND)

        if role and user.role != role:
            return Response(
                {"error": f"Invalid module. Your account is registered as {user.get_role_display()}."},
                status=status.HTTP_403_FORBIDDEN,
            )

        otp_record.delete()
        token, _created = Token.objects.get_or_create(user=user)
        return Response(
            {
                "message": "OTP verified successfully",
                "token": token.key,
                "user": UserSerializer(user).data,
            },
            status=status.HTTP_200_OK,
        )

    @action(detail=False, methods=["get"], url_path="doctors")
    def get_doctors(self, request):
        serializer = self.get_serializer(self.get_queryset(), many=True)
        return Response(serializer.data)

    @action(detail=False, methods=["get"], url_path="asha-workers")
    def get_asha_workers(self, request):
        serializer = self.get_serializer(self.get_queryset(), many=True)
        return Response(serializer.data)

    @action(detail=False, methods=["get"], url_path="patients")
    def get_patients(self, request):
        serializer = self.get_serializer(self.get_queryset(), many=True)
        return Response(serializer.data)

    @action(detail=False, methods=["post"], url_path="reset-password")
    def reset_password(self, request):
        phone_number = normalize_identifier(request.data.get("phone_number"))
        otp_code = request.data.get("otp_code") or request.data.get("otp")
        new_password = request.data.get("new_password")

        if not phone_number or not otp_code or not new_password:
            return Response(
                {"error": "Phone number, OTP code, and new password are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if len(new_password) < 6:
            return Response(
                {"error": "Password must be at least 6 characters"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        otp_record = (
            OTPVerification.objects.filter(phone_number=phone_number, otp_code=otp_code)
            .order_by("-created_at")
            .first()
        )

        if not otp_record or otp_record.is_expired():
            return Response({"error": "Invalid or expired OTP"}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.filter(phone_number=phone_number).first()
        if not user:
            return Response({"error": "User does not exist"}, status=status.HTTP_404_NOT_FOUND)

        user.set_password(new_password)
        user.save()
        otp_record.delete()
        return Response({"message": "Password reset successfully"}, status=status.HTTP_200_OK)
