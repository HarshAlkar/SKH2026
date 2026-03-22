from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Prescription
from .serializers import PrescriptionSerializer
from apps.patients.models import Patient
from apps.doctors.models import Doctor
from apps.users.models import User
from django.db.models import Q

class PrescriptionViewSet(viewsets.ModelViewSet):
    queryset = Prescription.objects.all().order_by('-issued_at')
    serializer_class = PrescriptionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def create(self, request, *args, **kwargs):
        data = request.data.copy()
        patient_id = data.get('patient')
        doctor_id = data.get('doctor')
        
        print(f"DEBUG: Creating prescription for patient_id={patient_id}, doctor_id={doctor_id}")

        # Resolve patient
        if patient_id:
            patient = Patient.objects.filter(Q(id=patient_id) | Q(user_id=patient_id)).first()
            if patient:
                data['patient'] = patient.id
            else:
                # If only User exists, find User and try to get/create profile
                user = User.objects.filter(id=patient_id).first()
                if user and user.role == 'user':
                    patient, _ = Patient.objects.get_or_create(user=user, defaults={'age': 0, 'gender': 'Not Set'})
                    data['patient'] = patient.id
                else:
                    return Response({"error": f"Patient profile not found for ID {patient_id}"}, status=status.HTTP_400_BAD_REQUEST)
            
        # Resolve doctor
        if doctor_id:
            doctor = Doctor.objects.filter(Q(id=doctor_id) | Q(user_id=doctor_id)).first()
            if doctor:
                data['doctor'] = doctor.id
            else:
                user = User.objects.filter(id=doctor_id).first()
                if user and user.role == 'doctor':
                    doctor, _ = Doctor.objects.get_or_create(user=user, defaults={'specialization': 'General'})
                    data['doctor'] = doctor.id
        elif request.user.role == 'doctor':
            doctor = getattr(request.user, 'doctor_profile', None)
            if doctor:
                data['doctor'] = doctor.id

        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'], url_path='user')
    def user_prescriptions(self, request):
        if request.user.role != 'user':
            return Response({"error": "Only patients can access this"}, status=status.HTTP_403_FORBIDDEN)
        
        patient_profile = getattr(request.user, 'patient_profile', None)
        if not patient_profile:
            print(f"DEBUG: User {request.user.id} has no patient profile")
            return Response([], status=status.HTTP_200_OK)
            
        prescriptions = self.queryset.filter(patient=patient_profile)
        print(f"DEBUG: Found {prescriptions.count()} prescriptions for user {request.user.id}")
        serializer = self.get_serializer(prescriptions, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='asha')
    def asha_prescriptions(self, request):
        if request.user.role != 'asha_worker':
            return Response({"error": "Only ASHA workers can access this"}, status=status.HTTP_403_FORBIDDEN)
        
        village = request.user.asha_profile.assigned_village
        prescriptions = self.queryset.filter(patient__user__village=village)
        serializer = self.get_serializer(prescriptions, many=True)
        return Response(serializer.data)
