from rest_framework import viewsets, status, serializers
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from .models import Patient
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
                "name": p.user.name or p.user.username,
                "age": p.age,
                "village": p.user.village or "Unknown",
                "phone_number": p.user.phone_number,
                "gender": p.gender,
                "blood_group": p.blood_group,
                "address": p.address,
                "status": "Stable" 
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
        patient.save()
        
        return Response({"message": "Patient updated successfully"}, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'], url_path='create-patient') # Alias for clarity if needed
    def create_patient(self, request):
        return self.create(request)
