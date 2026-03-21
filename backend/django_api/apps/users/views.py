from rest_framework import serializers, viewsets, status
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.db import transaction
from django.utils import timezone
from .models import User, OTPVerification
from apps.doctors.models import Doctor
from apps.asha_workers.models import ASHAWorker
from apps.patients.models import Patient
import re
import random
import datetime

class UserSerializer(serializers.ModelSerializer):
    profile_details = serializers.SerializerMethodField()
    
    profile_details = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'role', 'phone_number', 'village', 'name', 'created_at', 'profile_details']

    def get_profile_details(self, obj):
        if obj.role == 'doctor' and hasattr(obj, 'doctor_profile'):
            return {
                "specialization": obj.doctor_profile.specialization,
                "experience_years": obj.doctor_profile.experience_years,
                "hospital_name": obj.doctor_profile.hospital_name,
                "qualification": obj.doctor_profile.qualification,
                "is_available": obj.doctor_profile.is_available
            }
        elif obj.role == 'asha_worker' and hasattr(obj, 'asha_profile'):
            return {
                "assigned_village": obj.asha_profile.assigned_village,
                "phc_center": obj.asha_profile.phc_center
            }
        elif obj.role == 'user' and hasattr(obj, 'patient_profile'):
            return {
                "age": obj.patient_profile.age,
                "gender": obj.patient_profile.gender,
                "address": obj.patient_profile.address,
                "blood_group": obj.patient_profile.blood_group
            }
        return None
        fields = ['id', 'username', 'email', 'role', 'phone_number', 'village', 'name', 'created_at', 'profile_details']

    def get_profile_details(self, obj):
        if obj.role == 'doctor' and hasattr(obj, 'doctor_profile'):
            return {
                "specialization": obj.doctor_profile.specialization,
                "experience_years": obj.doctor_profile.experience_years,
                "hospital_name": obj.doctor_profile.hospital_name,
                "qualification": obj.doctor_profile.qualification,
                "is_available": obj.doctor_profile.is_available
            }
        elif obj.role == 'asha_worker' and hasattr(obj, 'asha_profile'):
            return {
                "assigned_village": obj.asha_profile.assigned_village,
                "phc_center": obj.asha_profile.phc_center
            }
        elif obj.role == 'user' and hasattr(obj, 'patient_profile'):
            return {
                "age": obj.patient_profile.age,
                "gender": obj.patient_profile.gender,
                "address": obj.patient_profile.address,
                "blood_group": obj.patient_profile.blood_group
            }
        return None

class RegisterSerializer(serializers.ModelSerializer):
    username = serializers.CharField(required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=6)
    role = serializers.ChoiceField(choices=User.ROLE_CHOICES)
    
    # Extra fields for profiles
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
        fields = ['username', 'email', 'password', 'role', 'phone_number', 'village', 'name',
                  'specialization', 'experience_years', 'hospital_name', 'assigned_village', 'phc_center', 'license_number', 'worker_id', 'district']
    
    def validate_phone_number(self, value):
        # Relaxed validation to support various formats or email-as-phone during transition
        if not value:
            return value
        # Relaxed validation to support various formats or email-as-phone during transition
        if not value:
            return value
        if User.objects.filter(phone_number=value).exists() or User.objects.filter(username=value).exists():
            raise serializers.ValidationError("This identifier is already registered.")
            raise serializers.ValidationError("This identifier is already registered.")
        return value

    def validate_name(self, value):
        if not value:
            raise serializers.ValidationError("Name cannot be empty.")
        return value

    def validate_village(self, value):
        if not value:
            raise serializers.ValidationError("Village cannot be empty.")
        return value

    @transaction.atomic
    def create(self, validated_data):
        specialization = validated_data.pop('specialization', None)
        experience_years = validated_data.pop('experience_years', None)
        hospital_name = validated_data.pop('hospital_name', None)
        assigned_village = validated_data.pop('assigned_village', None)
        phc_center = validated_data.pop('phc_center', None)
        license_number = validated_data.pop('license_number', None)
        worker_id = validated_data.pop('worker_id', None)
        district = validated_data.pop('district', None)
        
        # Use phone_number as username if username not provided
        if not validated_data.get('username'):
            validated_data['username'] = validated_data.get('phone_number')

        user = User.objects.create_user(**validated_data)
        
        if user.role == 'doctor':
            Doctor.objects.create(
                user=user,
                specialization=specialization or "General",
                experience_years=experience_years or 0,
                hospital_name=hospital_name or "General Hospital",
                license_number=license_number
            )
        elif user.role == 'asha_worker':
            ASHAWorker.objects.create(
                user=user,
                worker_id=worker_id,
                district=district,
                assigned_village=assigned_village or user.village,
                phc_center=phc_center or "Local PHC"
            )
        elif user.role == 'user':
            Patient.objects.create(
                user=user,
                age=0,
                gender="Not Set",
                address=user.village or "Not Set"
            )
        
        return user

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

    def get_permissions(self):
        if self.action in ['register', 'login', 'send_otp', 'verify_otp', 'reset_password']:
            return [AllowAny()]
        return [IsAuthenticated()]

    @action(detail=False, methods=['post'], url_path='register')
    def register(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token, created = Token.objects.get_or_create(user=user)
            return Response({
                "token": token.key,
                "user": UserSerializer(user).data
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'], url_path='login')
    def login(self, request):
        identifier = request.data.get('phone_number') or request.data.get('email') or request.data.get('username')
        identifier = request.data.get('phone_number') or request.data.get('email') or request.data.get('username')
        password = request.data.get('password')
        role = request.data.get('role')
        
        if not role:
            return Response({"error": "Role is required"}, status=status.HTTP_400_BAD_REQUEST)
        if not identifier or not password:
            return Response({"error": "Identifier and password are required"}, status=status.HTTP_400_BAD_REQUEST)
        if not identifier or not password:
            return Response({"error": "Identifier and password are required"}, status=status.HTTP_400_BAD_REQUEST)

        # Try to find user by phone number, email, or username
        from django.db.models import Q
        # Try to find user by phone number, email, or username
        from django.db.models import Q
        try:
            user_obj = User.objects.get(Q(phone_number=identifier) | Q(email=identifier) | Q(username=identifier))
            
            user_obj = User.objects.get(Q(phone_number=identifier) | Q(email=identifier) | Q(username=identifier))
            
            # Check if role matches
            if user_obj.role != role:
                return Response({
                    "error": f"Invalid module. Your account is registered as {user_obj.get_role_display()}."
                }, status=status.HTTP_403_FORBIDDEN)
                
            username = user_obj.username
            
        except User.DoesNotExist:
            return Response({"error": "Invalid credentials or user not found"}, status=status.HTTP_401_UNAUTHORIZED)
        except User.MultipleObjectsReturned:
            # Fallback for multiple users matching the identifier
            user_obj = User.objects.filter(Q(phone_number=identifier) | Q(email=identifier) | Q(username=identifier), role=role).first()
            if not user_obj:
                return Response({"error": "Invalid credentials or user not found for this role"}, status=status.HTTP_401_UNAUTHORIZED)
            username = user_obj.username

        user = authenticate(username=username, password=password)
        if user:
            token, created = Token.objects.get_or_create(user=user)
            return Response({
                "token": token.key,
                "user": UserSerializer(user).data
            })
        return Response({"error": "Invalid password"}, status=status.HTTP_401_UNAUTHORIZED)

    @action(detail=False, methods=['post'], url_path='logout')
    def logout(self, request):
        try:
            request.user.auth_token.delete()
            return Response({"message": "Successfully logged out"}, status=status.HTTP_200_OK)
        except Exception:
            return Response({"error": "Something went wrong"}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['post'], url_path='send-otp')
    def send_otp(self, request):
        phone_number = request.data.get('phone_number')
        if not phone_number or len(phone_number) != 10:
            return Response({"error": "Valid 10-digit phone number is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if user exists (Optional based on requirement, but user said "Phone number not registered" should be handled)
        try:
            user = User.objects.get(phone_number=phone_number)
        except User.DoesNotExist:
            return Response({"error": "User with this phone number does not exist"}, status=status.HTTP_404_NOT_FOUND)

        otp_code = str(random.randint(100000, 999999))
        expiry_time = timezone.now() + datetime.timedelta(minutes=5)
        
        OTPVerification.objects.create(
            phone_number=phone_number, 
            otp_code=otp_code, 
            expiry_time=expiry_time
        )
        
        # In a real scenario, send SMS. Here we just log it.
        print(f"DEBUG: OTP for {phone_number} is {otp_code}")
        
        return Response({
            "message": f"OTP sent to {phone_number}",
            "otp": otp_code # Returning for development ease
        }, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'], url_path='verify-otp')
    def verify_otp(self, request):
        phone_number = request.data.get('phone_number')
        otp_code = request.data.get('otp') # Use 'otp' instead of 'otp_code'
        role = request.data.get('role') # Optional: if login, verify role
        
        if not phone_number or not otp_code:
            return Response({"error": "Phone number and OTP code are required"}, status=status.HTTP_400_BAD_REQUEST)
        
        otp_record = OTPVerification.objects.filter(
            phone_number=phone_number, 
            otp_code=otp_code
        ).order_by('-created_at').first()
        
        if not otp_record:
            return Response({"error": "Invalid OTP"}, status=status.HTTP_400_BAD_REQUEST)
        
        if otp_record.is_expired():
            return Response({"error": "OTP has expired"}, status=status.HTTP_400_BAD_REQUEST)
        
        # Mark as verified
        otp_record.is_verified = True
        otp_record.save()
        
        # If this is for login, return token
        try:
            user = User.objects.get(phone_number=phone_number)
            
            # If role is provided, check if it matches
            if role and user.role != role:
                return Response({
                    "error": f"Invalid module. Your account is registered as {user.get_role_display()}."
                }, status=status.HTTP_403_FORBIDDEN)

            token, created = Token.objects.get_or_create(user=user)
            return Response({
                "message": "OTP verified successfully",
                "token": token.key,
                "user": UserSerializer(user).data
            }, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            # This shouldn't happen if they have an OTP, but just in case
            return Response({"message": "OTP verified for unregistered number"}, status=status.HTTP_200_OK)

    @action(detail=False, methods=['get'], url_path='doctors')
    def get_doctors(self, request):
        doctors = User.objects.filter(role='doctor')
        serializer = self.get_serializer(doctors, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='asha-workers')
    def get_asha_workers(self, request):
        workers = User.objects.filter(role='asha_worker')
        serializer = self.get_serializer(workers, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='patients')
    def get_patients(self, request):
        patients = User.objects.filter(role='user')
        serializer = self.get_serializer(patients, many=True)
        return Response(serializer.data)

    # Allow custom list behavior
    def list(self, request, *args, **kwargs):
        role = request.query_params.get('role')
        if role:
            self.queryset = User.objects.filter(role=role)
        return super().list(request, *args, **kwargs)

    @action(detail=False, methods=['get'], url_path='doctors')
    def get_doctors(self, request):
        doctors = User.objects.filter(role='doctor')
        serializer = self.get_serializer(doctors, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='asha-workers')
    def get_asha_workers(self, request):
        workers = User.objects.filter(role='asha_worker')
        serializer = self.get_serializer(workers, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='patients')
    def get_patients(self, request):
        patients = User.objects.filter(role='user')
        serializer = self.get_serializer(patients, many=True)
        return Response(serializer.data)

    # Allow custom list behavior
    def list(self, request, *args, **kwargs):
        role = request.query_params.get('role')
        if role:
            self.queryset = User.objects.filter(role=role)
        return super().list(request, *args, **kwargs)

    @action(detail=False, methods=['post'], url_path='reset-password')
    def reset_password(self, request):
        phone_number = request.data.get('phone_number')
        otp_code = request.data.get('otp_code')
        new_password = request.data.get('new_password')
        
        if not phone_number or not otp_code or not new_password:
            return Response({"error": "Phone number, OTP code, and new password are required"}, status=status.HTTP_400_BAD_REQUEST)
        
        if len(new_password) < 6:
            return Response({"error": "Password must be at least 6 characters"}, status=status.HTTP_400_BAD_REQUEST)

        otp_record = OTPVerification.objects.filter(phone_number=phone_number, otp_code=otp_code).order_by('-created_at').first()
        
        if not otp_record or otp_record.is_expired():
            return Response({"error": "Invalid or expired OTP"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(phone_number=phone_number)
            user.set_password(new_password)
            user.save()
            
            # Delete record after use
            otp_record.delete()
            
            return Response({"message": "Password reset successfully"}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({"error": "User does not exist"}, status=status.HTTP_404_NOT_FOUND)
