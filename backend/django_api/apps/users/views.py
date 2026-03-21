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
from apps.patients.models import Patient, FamilyMember, EmergencyContact
from apps.prescriptions.serializers import PrescriptionSerializer
from apps.symptom_analysis.models import SymptomAnalysis
from apps.symptom_analysis.serializers import SymptomAnalysisSerializer
import re
import random
import datetime

class UserSerializer(serializers.ModelSerializer):
    profile_details = serializers.SerializerMethodField()
    
    profile_details = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'role', 'phone_number', 'village', 'name', 'abha_id', 'created_at', 'profile_details']

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
                "blood_group": obj.patient_profile.blood_group,
                "abha_id": obj.patient_profile.abha_id
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
                "blood_group": obj.patient_profile.blood_group,
                "abha_id": obj.patient_profile.abha_id
            }
        return None

class FamilyMemberSerializer(serializers.ModelSerializer):
    class Meta:
        from apps.patients.models import FamilyMember
        model = FamilyMember
        fields = '__all__'

class EmergencyContactSerializer(serializers.ModelSerializer):
    class Meta:
        from apps.patients.models import EmergencyContact
        model = EmergencyContact
        fields = '__all__'

class FamilyMemberSerializer(serializers.ModelSerializer):
    class Meta:
        from apps.patients.models import FamilyMember
        model = FamilyMember
        fields = '__all__'

class EmergencyContactSerializer(serializers.ModelSerializer):
    class Meta:
        from apps.patients.models import EmergencyContact
        model = EmergencyContact
        fields = '__all__'

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
        print(f"DEBUG LOGIN request.data: {request.data}")
        identifier = request.data.get('phone_number') or request.data.get('email') or request.data.get('username')
        if identifier:
            identifier = str(identifier).strip()
        password = request.data.get('password')
        role = request.data.get('role')
        
        if not role:
            print("DEBUG: missing role")
            return Response({"error": "Role is required"}, status=status.HTTP_400_BAD_REQUEST)
        if not identifier or not password:
            print("DEBUG: missing identifier or password")
            return Response({"error": "Identifier and password are required"}, status=status.HTTP_400_BAD_REQUEST)
        if not identifier or not password:
            print("DEBUG: missing identifier or password")
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
            
            # Delete record
            otp_record.delete()
            
            return Response({"message": "Password reset successfully"}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({"error": "User does not exist"}, status=status.HTTP_404_NOT_FOUND)

    @action(detail=False, methods=['get', 'put'], url_path='profile/me')
    def profile_me(self, request):
        user = request.user
        if request.method == 'GET':
            serializer = self.get_serializer(user)
            return Response(serializer.data)
        
        # Handle profile update
        data = request.data
        user.name = data.get('name', user.name)
        user.email = data.get('email', user.email)
        user.village = data.get('village', user.village)
        user.save()
        
        if user.role == 'user' and hasattr(user, 'patient_profile'):
            profile = user.patient_profile
            profile.age = data.get('age', profile.age)
            profile.gender = data.get('gender', profile.gender)
            profile.address = data.get('address', profile.address)
            profile.blood_group = data.get('blood_group', profile.blood_group)
            profile.abha_id = data.get('abha_id', profile.abha_id)
            profile.save()
            
        return Response(self.get_serializer(user).data)

    @action(detail=False, methods=['get', 'post'], url_path='family-members')
    def family_members(self, request):
        if not hasattr(request.user, 'patient_profile'):
            return Response({"error": "Only patients have family members"}, status=400)
            
        patient = request.user.patient_profile
        if request.method == 'GET':
            members = patient.family_members.all()
            serializer = FamilyMemberSerializer(members, many=True)
            return Response(serializer.data)
            
        # POST: Create new family member
        data = request.data.copy()
        data['patient'] = patient.id
        serializer = FamilyMemberSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)

    @action(detail=False, methods=['get', 'post', 'put'], url_path='emergency-info')
    def emergency_info(self, request):
        if not hasattr(request.user, 'patient_profile'):
            return Response({"error": "Only patients have emergency info"}, status=400)
            
        patient = request.user.patient_profile
        
        if request.method == 'GET':
            try:
                contact = patient.emergency_contact
                serializer = EmergencyContactSerializer(contact)
                return Response(serializer.data)
            except:
                return Response({"error": "No emergency contact found"}, status=404)
        
        # POST/PUT: Update emergency info
        try:
            contact = patient.emergency_contact
            serializer = EmergencyContactSerializer(contact, data=request.data, partial=True)
        except:
            data = request.data.copy()
            data['patient'] = patient.id
            serializer = EmergencyContactSerializer(data=data)
            
        if serializer.is_valid():
            serializer.save()  # Fix: was missing .save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)

    @action(detail=False, methods=['get'], url_path='profile-by-abha')
    def profile_by_abha(self, request):
        abha_id = request.query_params.get('abha_id')
        if not abha_id:
            return Response({"error": "ABHA ID is required"}, status=400)
        try:
            user = User.objects.get(abha_id=abha_id)
            serializer = self.get_serializer(user)
            data = dict(serializer.data)

            if user.role == 'user' and hasattr(user, 'patient_profile'):
                profile = user.patient_profile
                # Fetch detailed history
                data['prescriptions'] = PrescriptionSerializer(profile.prescriptions.all().order_by('-issued_at'), many=True).data
                data['reports'] = [
                    {
                        "id": r.id,
                        "title": r.title, 
                        "type": r.report_type, 
                        "date": str(r.created_at),
                        "file_url": request.build_absolute_uri(r.file.url) if r.file else None
                    } 
                    for r in profile.reports.all().order_by('-created_at')
                ]
                
                # AI History
                ai_history = SymptomAnalysis.objects.filter(user=user).order_by('-created_at')
                data['ai_history'] = SymptomAnalysisSerializer(ai_history, many=True).data
                
                try:
                    ec = profile.emergency_contact
                    data['emergency_contact'] = EmergencyContactSerializer(ec).data
                except Exception:
                    data['emergency_contact'] = None
                data['family_members'] = FamilyMemberSerializer(profile.family_members.all(), many=True).data
            
            return Response(data)
        except User.DoesNotExist:
            return Response({"error": "User with this ABHA ID not found"}, status=404)


# ── Standalone view for DELETE /users/family-members/<pk>/ ──

from rest_framework.decorators import api_view, permission_classes

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_family_member(request, pk):
    from apps.patients.models import FamilyMember
    try:
        member = FamilyMember.objects.get(pk=pk, patient=request.user.patient_profile)
        member.delete()
        return Response({"message": "Family member deleted"}, status=204)
    except FamilyMember.DoesNotExist:
        return Response({"error": "Family member not found"}, status=404)
    except Exception:
        return Response({"error": "Patient profile not found"}, status=400)
