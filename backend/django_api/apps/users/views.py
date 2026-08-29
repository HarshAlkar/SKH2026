from rest_framework import serializers, viewsets, status
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.throttling import ScopedRateThrottle
from django.contrib.auth import authenticate
from django.conf import settings
from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from .models import User, OTPVerification
from .sms import send_otp_sms
from apps.doctors.models import Doctor, DoctorDocument
from apps.asha_workers.models import ASHAWorker, ASHADocument
from apps.patients.models import Patient
from apps.inventory.models import MedicalStaffProfile, HealthcareFacility
from apps.common.authentication import rotate_token
from apps.common.uploads import validate_image_upload, safe_upload_name
from apps.security_audit.audit import log_security_event
import json
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


def _document_payload(documents, request=None):
    rows = []
    for doc in documents:
        file_url = doc.file.url if doc.file else ''
        if request and file_url and not file_url.startswith('http'):
            file_url = request.build_absolute_uri(file_url)
        rows.append({
            'id': doc.id,
            'document_type': doc.document_type,
            'file': file_url,
            'uploaded_at': doc.uploaded_at.isoformat() if doc.uploaded_at else None,
        })
    return rows


class UserSerializer(serializers.ModelSerializer):
    profile_details = serializers.SerializerMethodField()
    photo_url = serializers.SerializerMethodField()

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
            "photo_url",
            "profile_details",
        ]

    def get_photo_url(self, obj):
        if not obj.photo:
            return None
        try:
            return obj.photo.url
        except ValueError:
            return None

    def get_profile_details(self, obj):
        request = self.context.get('request')
        if obj.role == "doctor" and hasattr(obj, "doctor_profile"):
            profile = obj.doctor_profile
            details = {
                "specialization": profile.specialization,
                "experience_years": profile.experience_years,
                "hospital_name": profile.hospital_name,
                "qualification": profile.qualification,
                "license_number": profile.license_number,
                "bio": profile.bio,
                "is_available": profile.is_available,
                "verification_status": profile.verification_status,
                "rejection_reason": profile.rejection_reason,
            }
            request = self.context.get('request')
            viewer = getattr(request, 'user', None) if request else None
            if viewer and (
                viewer.is_staff
                or viewer.pk == obj.pk
            ):
                details["documents"] = _document_payload(profile.documents.all(), request)
            return details
        if obj.role == "asha_worker" and hasattr(obj, "asha_profile"):
            profile = obj.asha_profile
            details = {
                "asha_id": profile.id,
                "assigned_village": profile.assigned_village,
                "phc_center": profile.phc_center,
                "worker_id": profile.worker_id,
                "district": profile.district,
                "verification_status": profile.verification_status,
                "rejection_reason": profile.rejection_reason,
            }
            request = self.context.get('request')
            viewer = getattr(request, 'user', None) if request else None
            if viewer and (viewer.is_staff or viewer.pk == obj.pk):
                details["documents"] = _document_payload(profile.documents.all(), request)
            return details
        if obj.role == "user" and hasattr(obj, "patient_profile"):
            return {
                "patient_id": obj.patient_profile.id,
                "user_id": obj.id,
                "age": obj.patient_profile.age,
                "gender": obj.patient_profile.gender,
                "address": obj.patient_profile.address,
                "blood_group": obj.patient_profile.blood_group,
                "medical_history": obj.patient_profile.medical_history,
            }
        if obj.role == "medical_staff" and hasattr(obj, "medical_staff_profile"):
            profile = obj.medical_staff_profile
            facility = profile.facility
            return {
                "designation": profile.designation,
                "facility_id": facility.id if facility else None,
                "facility_name": facility.name if facility else None,
                "facility_village": facility.village if facility else None,
            }
        return None


class RegisterSerializer(serializers.ModelSerializer):
    username = serializers.CharField(required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=8)
    role = serializers.ChoiceField(choices=User.ROLE_CHOICES)

    specialization = serializers.CharField(required=False, allow_blank=True)
    experience_years = serializers.IntegerField(required=False)
    hospital_name = serializers.CharField(required=False, allow_blank=True)
    assigned_village = serializers.CharField(required=False, allow_blank=True)
    phc_center = serializers.CharField(required=False, allow_blank=True)
    license_number = serializers.CharField(required=False, allow_blank=True)
    worker_id = serializers.CharField(required=False, allow_blank=True)
    district = serializers.CharField(required=False, allow_blank=True)
    # Optional patient profile fields (used when role=user, e.g. ASHA registration)
    age = serializers.IntegerField(required=False, min_value=0, max_value=150)
    gender = serializers.CharField(required=False, allow_blank=True)
    blood_group = serializers.CharField(required=False, allow_blank=True)
    medical_history = serializers.CharField(required=False, allow_blank=True)
    facility_id = serializers.IntegerField(required=False, allow_null=True)
    designation = serializers.CharField(required=False, allow_blank=True)

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
            "age",
            "gender",
            "blood_group",
            "medical_history",
            "facility_id",
            "designation",
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
        request = self.context.get("request")
        # When an authenticated ASHA registers a patient, force village to their assignment
        if (
            role == "user"
            and request is not None
            and getattr(request, "user", None) is not None
            and request.user.is_authenticated
            and getattr(request.user, "role", None) == "asha_worker"
        ):
            asha = getattr(request.user, "asha_profile", None)
            forced = ""
            if asha is not None:
                forced = (asha.assigned_village or request.user.village or "").strip()
            else:
                forced = (request.user.village or "").strip()
            if forced:
                attrs["village"] = forced

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
        age = validated_data.pop("age", None)
        gender = validated_data.pop("gender", None)
        blood_group = validated_data.pop("blood_group", None)
        medical_history = validated_data.pop("medical_history", None)
        facility_id = validated_data.pop("facility_id", None)
        designation = validated_data.pop("designation", None)

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
        elif user.role == "medical_staff":
            facility = None
            if facility_id:
                facility = HealthcareFacility.objects.filter(pk=facility_id).first()
            MedicalStaffProfile.objects.create(
                user=user,
                facility=facility,
                designation=(designation or "Pharmacist")[:100],
            )
        elif user.role == "user":
            bg = (blood_group or "").strip()
            if bg.lower() in ("not known", "unknown", "n/a"):
                bg = ""
            bg = bg[:5]  # Patient.blood_group max_length=5
            Patient.objects.create(
                user=user,
                age=age if age is not None else 0,
                gender=((gender or "").strip() or "Not Set")[:10],
                blood_group=bg,
                address=user.village or "Not Set",
                medical_history=(medical_history or "").strip(),
            )

        return user


def _parse_profile_details(raw):
    if raw is None:
        return None
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str) and raw.strip():
        try:
            parsed = json.loads(raw)
            return parsed if isinstance(parsed, dict) else None
        except json.JSONDecodeError:
            return None
    return None


def _apply_role_profile(user, details):
    if user.role == "user":
        patient, _ = Patient.objects.get_or_create(
            user=user,
            defaults={
                "age": 0,
                "gender": "Not Set",
                "blood_group": "",
                "address": user.village or "Not Set",
                "medical_history": "",
            },
        )
        if "age" in details and details["age"] not in (None, ""):
            try:
                patient.age = int(details["age"])
            except (TypeError, ValueError):
                pass
        if "gender" in details and details["gender"] is not None:
            patient.gender = str(details["gender"])[:10] or patient.gender
        if "blood_group" in details and details["blood_group"] is not None:
            patient.blood_group = str(details["blood_group"])[:5]
        if "address" in details and details["address"] is not None:
            patient.address = str(details["address"])
        if "medical_history" in details and details["medical_history"] is not None:
            patient.medical_history = str(details["medical_history"])
        patient.save()
    elif user.role == "doctor":
        doctor, _ = Doctor.objects.get_or_create(
            user=user,
            defaults={
                "specialization": "General",
                "experience_years": 0,
                "hospital_name": "General Hospital",
            },
        )
        for field in ("specialization", "hospital_name", "qualification", "license_number", "bio"):
            if field in details and details[field] is not None:
                setattr(doctor, field, details[field])
        if "experience_years" in details and details["experience_years"] not in (None, ""):
            try:
                doctor.experience_years = int(details["experience_years"])
            except (TypeError, ValueError):
                pass
        if "is_available" in details:
            value = details["is_available"]
            if isinstance(value, str):
                doctor.is_available = value.lower() in ("1", "true", "yes")
            else:
                doctor.is_available = bool(value)
        doctor.save()
    elif user.role == "asha_worker":
        asha, _ = ASHAWorker.objects.get_or_create(
            user=user,
            defaults={
                "assigned_village": user.village or "",
                "phc_center": "Local PHC",
            },
        )
        for field in ("assigned_village", "phc_center", "worker_id", "district"):
            if field in details and details[field] is not None:
                setattr(asha, field, details[field])
        asha.save()
        if asha.assigned_village:
            user.village = asha.assigned_village
            user.save(update_fields=["village"])
    elif user.role == "medical_staff":
        profile, _ = MedicalStaffProfile.objects.get_or_create(
            user=user,
            defaults={"designation": "Pharmacist"},
        )
        if "designation" in details and details["designation"] is not None:
            profile.designation = str(details["designation"])[:100]
        if "facility_id" in details and details["facility_id"] not in (None, ""):
            try:
                profile.facility = HealthcareFacility.objects.get(pk=int(details["facility_id"]))
            except (TypeError, ValueError, HealthcareFacility.DoesNotExist):
                pass
        profile.save()


class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    http_method_names = ["get", "post", "patch", "head", "options"]

    throttle_classes = [ScopedRateThrottle]

    def get_throttles(self):
        scope_map = {
            'login': 'login',
            'register': 'register',
            'send_otp': 'otp',
            'verify_otp': 'otp',
            'reset_password': 'otp',
            'upload_photo': 'upload',
        }
        self.throttle_scope = scope_map.get(self.action, 'user')
        return super().get_throttles()

    def get_permissions(self):
        if self.action in ["register", "login", "send_otp", "verify_otp", "reset_password"]:
            return [AllowAny()]
        return [IsAuthenticated()]

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            return User.objects.none()
        if self.action == "list" and not user.is_staff:
            # Prevent arbitrary role enumeration via GET /api/users/?role=
            role_filter = (self.request.query_params.get("role") or "").strip()
            if role_filter and user.role not in ("doctor", "asha_worker", "medical_staff"):
                return User.objects.none()
            if role_filter == "doctor":
                return User.objects.filter(role="doctor")
            if role_filter == "asha_worker":
                return User.objects.filter(role="asha_worker")
            if user.is_staff:
                return User.objects.all()
            return User.objects.filter(pk=user.pk)
        if self.action == "get_doctors":
            return User.objects.filter(role="doctor")
        if self.action == "get_asha_workers":
            qs = User.objects.filter(role="asha_worker")
            village = (self.request.query_params.get("village") or "").strip()
            if user.role == "user":
                village = (user.village or village or "").strip()
            if village:
                exact = qs.filter(
                    Q(village__iexact=village)
                    | Q(asha_profile__assigned_village__iexact=village)
                )
                if exact.exists():
                    return exact
                fuzzy = qs.filter(
                    Q(village__icontains=village)
                    | Q(asha_profile__assigned_village__icontains=village)
                    | Q(asha_profile__district__icontains=village)
                )
                return fuzzy
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
        return self._save_profile(instance, request)

    def _save_profile(self, user, request):
        data = request.data
        if "phone_number" in data and data.get("phone_number") not in (None, ""):
            phone = normalize_identifier(data.get("phone_number"))
            taken = User.objects.exclude(pk=user.pk).filter(
                Q(phone_number=phone) | Q(username=phone)
            ).exists()
            if taken:
                return Response(
                    {"error": "This phone number is already registered."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            user.phone_number = phone
        for key in ("name", "village", "email"):
            if key in data and data.get(key) is not None:
                setattr(user, key, data.get(key))
        user.save()
        details = _parse_profile_details(data.get("profile_details"))
        if details:
            _apply_role_profile(user, details)
        user.refresh_from_db()
        return Response(UserSerializer(user, context={"request": request}).data)

    @action(detail=False, methods=["get", "patch"], url_path="me")
    def me(self, request):
        if request.method.lower() == "get":
            return Response(UserSerializer(request.user, context={"request": request}).data)
        return self._save_profile(request.user, request)

    @action(detail=False, methods=["post"], url_path="me/photo")
    def upload_photo(self, request):
        photo = request.FILES.get("photo") or request.FILES.get("image")
        if not photo:
            return Response({"error": "photo is required"}, status=status.HTTP_400_BAD_REQUEST)
        try:
            ext = validate_image_upload(photo, max_bytes=3 * 1024 * 1024)
        except Exception as exc:
            return Response({"error": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        photo.name = safe_upload_name(ext, prefix='profile')
        request.user.photo = photo
        request.user.save(update_fields=["photo"])
        log_security_event(request, action='upload_photo', object_type='User', object_id=request.user.pk)
        return Response(UserSerializer(request.user, context={"request": request}).data)

    @action(detail=False, methods=["post"], url_path="change-password")
    def change_password(self, request):
        current_password = request.data.get("current_password") or ""
        new_password = request.data.get("new_password") or ""
        if not current_password or not new_password:
            return Response(
                {"error": "Current password and new password are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if len(new_password) < 8:
            return Response(
                {"error": "Password must be at least 8 characters"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not request.user.check_password(current_password):
            return Response({"error": "Current password is incorrect"}, status=status.HTTP_400_BAD_REQUEST)
        request.user.set_password(new_password)
        request.user.save()
        rotate_token(request.user)
        log_security_event(request, action='change_password', object_type='User', object_id=request.user.pk)
        return Response({"message": "Password changed successfully. Please log in again."})

    @action(detail=False, methods=["post"], url_path="register")
    def register(self, request):
        phone = normalize_identifier(request.data.get("phone_number"))
        role = request.data.get("role")
        if phone and role:
            existing = User.objects.filter(role=role).filter(
                Q(phone_number=phone) | Q(username=phone)
            ).first()
            if existing:
                log_security_event(
                    request, action='register', success=False,
                    metadata={'reason': 'already_exists', 'role': role},
                )
                return Response(
                    {
                        "error": "An account with this phone number and role already exists. Please log in.",
                        "already_exists": True,
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )
        serializer = RegisterSerializer(data=request.data, context={"request": request})
        if serializer.is_valid():
            user = serializer.save()
            token = rotate_token(user)
            log_security_event(
                request, action='register', object_type='User', object_id=user.pk,
                actor=user, metadata={'role': user.role},
            )
            return Response(
                {"token": token.key, "user": UserSerializer(user, context={"request": request}).data},
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
                log_security_event(request, action='login', success=False, metadata={'reason': 'wrong_module'})
                return Response(
                    {
                        "error": f"Invalid login for this module. This account is registered as {existing.get_role_display()}."
                    },
                    status=status.HTTP_403_FORBIDDEN,
                )
            log_security_event(request, action='login', success=False, metadata={'reason': 'not_found'})
            return Response({"error": "Invalid credentials or user not found"}, status=status.HTTP_401_UNAUTHORIZED)

        user = authenticate(username=user_obj.username, password=password)
        if user:
            token = rotate_token(user)
            log_security_event(request, action='login', object_type='User', object_id=user.pk, actor=user)
            return Response({"token": token.key, "user": UserSerializer(user, context={"request": request}).data})
        log_security_event(
            request, action='login', success=False, actor=user_obj,
            object_type='User', object_id=user_obj.pk, metadata={'reason': 'bad_password'},
        )
        return Response({"error": "Invalid password"}, status=status.HTTP_401_UNAUTHORIZED)

    @action(detail=False, methods=["post"], url_path="logout")
    def logout(self, request):
        try:
            request.user.auth_token.delete()
            log_security_event(request, action='logout', object_type='User', object_id=request.user.pk)
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
        # Only expose OTP when explicitly enabled for local SMS-less testing
        if getattr(settings, 'EXPOSE_OTP_FOR_DEV', False) and not sms_sent:
            payload["otp"] = otp_code
        elif not sms_sent and not settings.DEBUG:
            return Response(
                {"error": "SMS provider is not configured."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        elif not sms_sent and settings.DEBUG and not getattr(settings, 'EXPOSE_OTP_FOR_DEV', False):
            # Dev without SMS: still allow testing via server logs only (not API body)
            import logging
            logging.getLogger(__name__).info('OTP generated for %s (not returned in response)', phone_number)

        log_security_event(request, action='send_otp', success=True, metadata={'sms_sent': bool(sms_sent)})
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
            log_security_event(request, action='verify_otp', success=False)
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
        token = rotate_token(user)
        log_security_event(request, action='verify_otp', object_type='User', object_id=user.pk, actor=user)
        return Response(
            {
                "message": "OTP verified successfully",
                "token": token.key,
                "user": UserSerializer(user, context={"request": request}).data,
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
