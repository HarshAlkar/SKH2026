from rest_framework import viewsets, status, serializers
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from .models import Patient, FamilyMember, PatientReport
from apps.prescriptions.models import Prescription
from apps.symptom_analysis.models import SymptomRecord, SymptomAnalysis
from apps.asha_workers.models import ASHAWorker
from apps.users.models import User
from django.db import IntegrityError, transaction
import random

class PatientViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.role == 'asha_worker':
            try:
                asha = ASHAWorker.objects.get(user=user)
                return Patient.objects.filter(user__village=asha.assigned_village)
            except ASHAWorker.DoesNotExist:
                return Patient.objects.none()
        elif user.role == 'doctor':
            return Patient.objects.all()
        return Patient.objects.filter(user=user)

    def get_serializer_class(self):
        class DefaultPatientSerializer(serializers.ModelSerializer):
            name = serializers.CharField(source='user.name', read_only=True)
            village = serializers.CharField(source='user.village', read_only=True)
            class Meta:
                model = Patient
                fields = ['id', 'name', 'age', 'village', 'gender', 'blood_group', 'address', 'medical_history']
        return DefaultPatientSerializer

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        data = []
        for p in queryset:
            data.append({
                "id": p.id,
                "user_id": p.user.id,
                "name": p.user.name or p.user.username,
                "age": p.age,
                "village": p.user.village or "Unknown",
                "phone_number": p.user.phone_number,
                "gender": p.gender,
                "blood_group": p.blood_group,
                "address": p.address,
                "status": "Stable",
                "abha_id": p.user.abha_id,
            })
        return Response(data, status=status.HTTP_200_OK)

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        return Response({
            "id": instance.id,
            "name": instance.user.name or instance.user.username,
            "age": instance.age,
            "village": instance.user.village or "Unknown",
            "phone_number": instance.user.phone_number,
            "gender": instance.gender,
            "blood_group": instance.blood_group,
            "address": instance.address,
            "medical_history": instance.medical_history,
            "status": "Stable"
        }, status=status.HTTP_200_OK)

    def create(self, request, *args, **kwargs):
        from apps.users.models import User
        from django.db import IntegrityError
        from apps.asha_workers.models import ASHAWorker
        import random
        
        data = request.data
        phone_number = data.get('phone_number')
        if not phone_number:
            phone_number = f"NoPhone_{random.randint(10000, 99999)}"
            
        village_input = data.get('village')
        assigned_village = village_input
        if request.user.role == 'asha_worker':
            try:
                asha = ASHAWorker.objects.get(user=request.user)
                # We use the assigned village for the filterable user field
                assigned_village = asha.assigned_village 
            except ASHAWorker.DoesNotExist:
                pass
            
        try:
            # Create core user for the patient
            new_user = User.objects.create(
                username=phone_number + str(random.randint(100, 999)), # ensure unique
                phone_number=phone_number,
                name=data.get('name'),
                village=assigned_village or "Unknown",
                role='user'
            )
            new_user.set_password('12345678') # Default passcode
            new_user.save()
            
            patient = Patient.objects.create(
                user=new_user,
                age=data.get('age', 0),
                gender=data.get('gender', 'Not Set'),
                blood_group=data.get('blood_group', 'Not Known'),
                address=village_input or assigned_village,
                medical_history=data.get('disease', '')
            )
            
            return Response({"message": "Patient created successfully", "id": patient.id}, status=status.HTTP_201_CREATED)
        except IntegrityError:
            return Response({"error": "Phone number or user already exists."}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

    def update(self, request, *args, **kwargs):
        patient = self.get_object()
        data = request.data
        
        # Update associated User fields if provided
        user = patient.user
        if 'name' in data:
            user.name = data['name']
        if 'phone_number' in data:
            user.phone_number = data['phone_number']
        user.save()
        
        # Update Patient model fields
        patient.age = data.get('age', patient.age)
        patient.gender = data.get('gender', patient.gender)
        patient.blood_group = data.get('blood_group', patient.blood_group)
        patient.address = data.get('address', patient.address)
        patient.medical_history = data.get('medical_history', patient.medical_history)
        patient.allergies = data.get('allergies', patient.allergies)
        patient.emergency_notes = data.get('emergency_notes', patient.emergency_notes)
        patient.save()
        
        return Response({"message": "Patient updated successfully", "id": patient.id}, status=status.HTTP_200_OK)

    @action(detail=False, methods=['get'], url_path='emergency-details')
    def emergency_details(self, request):
        abha_id = request.query_params.get('abha_id')
        if not abha_id:
            return Response({"error": "ABHA ID required"}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Find user by ABHA ID
            user = User.objects.get(abha_id=abha_id)
            patient = user.patient_profile
            
            # Fetch family members
            family = FamilyMember.objects.filter(patient=patient)
            family_data = [{
                "name": f.name,
                "relationship": f.relationship,
                "phone_number": f.phone_number
            } for f in family]

            # Fetch prescriptions
            prescriptions = Prescription.objects.filter(patient=patient).order_by('-issued_at')[:5]
            prescription_data = [{
                "medications": p.medications,
                "doctor": p.doctor.user.name if p.doctor else "Unknown",
                "date": p.issued_at.strftime('%Y-%m-%d'),
                "notes": p.notes
            } for p in prescriptions]
            
            return Response({
                "name": user.name or user.username,
                "phone_number": user.phone_number,
                "abha_id": user.abha_id,
                "age": patient.age,
                "gender": patient.gender,
                "blood_group": patient.blood_group,
                "allergies": patient.allergies,
                "emergency_notes": patient.emergency_notes,
                "medical_history": patient.medical_history,
                "family_members": family_data,
                "prescriptions": prescription_data
            }, status=status.HTTP_200_OK)
            
        except User.DoesNotExist:
            return Response({"error": "User with this ABHA ID not found."}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'], url_path='clinical-details')
    def clinical_details(self, request):
        if request.user.role != 'doctor':
            return Response({"error": "Only doctors can access clinical details"}, status=status.HTTP_403_FORBIDDEN)
            
        abha_id = request.query_params.get('abha_id')
        if not abha_id:
            return Response({"error": "ABHA ID is required"}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            user = User.objects.get(abha_id=abha_id)
            patient = user.patient_profile
            
            # Fetch family members
            family = FamilyMember.objects.filter(patient=patient)
            family_data = [{"name": f.name, "relationship": f.relationship, "phone_number": f.phone_number} for f in family]

            # Fetch prescriptions
            prescriptions = Prescription.objects.filter(patient=patient).order_by('-issued_at')
            prescription_data = [{
                "medications": p.medications,
                "doctor": p.doctor.user.name if p.doctor else "Unknown",
                "date": p.issued_at.strftime('%Y-%m-%d'),
                "notes": p.notes
            } for p in prescriptions]

            # Fetch reports
            reports = PatientReport.objects.filter(patient=patient).order_by('-created_at')
            report_data = [{
                "title": r.title,
                "file": request.build_absolute_uri(r.report_file.url) if r.report_file else None,
                "image": request.build_absolute_uri(r.report_image.url) if r.report_image else None,
                "notes": r.notes,
                "date": r.created_at.strftime('%Y-%m-%d')
            } for r in reports]

            # Fetch AI Analysis
            ai_history = SymptomAnalysis.objects.filter(user=user).order_by('-created_at')
            ai_data = [{
                "disease": a.predicted_disease,
                "severity": a.severity_level,
                "symptoms": a.symptoms_text,
                "date": a.created_at.strftime('%Y-%m-%d')
            } for a in ai_history]
            
            return Response({
                "basic_info": {
                    "name": user.name or user.username,
                    "phone": user.phone_number,
                    "abha_id": user.abha_id,
                    "age": patient.age,
                    "gender": patient.gender,
                    "address": patient.address
                },
                "medical_info": {
                    "blood_group": patient.blood_group,
                    "allergies": patient.allergies,
                    "emergency_notes": patient.emergency_notes,
                    "medical_history": patient.medical_history,
                },
                "family_members": family_data,
                "prescriptions": prescription_data,
                "reports": report_data,
                "ai_history": ai_data
            }, status=status.HTTP_200_OK)
            
        except User.DoesNotExist:
            return Response({"error": "User with this ABHA ID not found"}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    @action(detail=False, methods=['post'], url_path='create-patient') # Alias for clarity if needed
    def create_patient(self, request):
        return self.create(request)

class FamilyMemberViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    
    class FamilyMemberSerializer(serializers.ModelSerializer):
        class Meta:
            model = FamilyMember
            fields = '__all__'

    def get_queryset(self):
        try:
            patient = self.request.user.patient_profile
            return FamilyMember.objects.filter(patient=patient)
        except:
            return FamilyMember.objects.none()

    def get_serializer_class(self):
        return self.FamilyMemberSerializer

    def perform_create(self, serializer):
        serializer.save(patient=self.request.user.patient_profile)
