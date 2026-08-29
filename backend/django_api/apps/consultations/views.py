from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from django.utils import timezone
from .models import Consultation, Appointment
from .serializers import ConsultationSerializer, AppointmentSerializer
from apps.patients.models import Patient
from apps.doctors.models import Doctor
from apps.asha_workers.models import ASHAWorker
import uuid


def _resolve_doctor(doctor_id):
    if not doctor_id:
        return None
    doctor = Doctor.objects.filter(pk=doctor_id).first()
    if not doctor:
        doctor = Doctor.objects.filter(user_id=doctor_id).first()
    return doctor


def _resolve_patient(patient_id):
    if not patient_id:
        return None
    patient = Patient.objects.filter(pk=patient_id).first()
    if not patient:
        patient = Patient.objects.filter(user_id=patient_id).first()
    return patient


def _resolve_asha(asha_id):
    if not asha_id:
        return None
    asha = ASHAWorker.objects.filter(pk=asha_id).first()
    if not asha:
        asha = ASHAWorker.objects.filter(user_id=asha_id).first()
    return asha


class ConsultationViewSet(viewsets.ModelViewSet):
    serializer_class = ConsultationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'doctor':
            return Consultation.objects.filter(
                Q(doctor__user=user) | Q(initiated_by=user)
            )
        if user.role == 'user':
            return Consultation.objects.filter(
                Q(patient__user=user) | Q(initiated_by=user)
            )
        if user.role == 'asha_worker':
            return Consultation.objects.filter(
                Q(asha_worker__user=user) | Q(initiated_by=user)
            )
        return Consultation.objects.none()

    @action(detail=False, methods=['post'])
    def start(self, request):
        doctor_id = request.data.get('doctor_id')
        patient_id = request.data.get('patient_id')
        asha_id = request.data.get('asha_id')
        call_type = request.data.get('call_type', 'VIDEO')
        is_emergency = bool(request.data.get('is_emergency'))
        user = request.user

        doctor = _resolve_doctor(doctor_id)
        patient = _resolve_patient(patient_id)
        asha = _resolve_asha(asha_id)

        if user.role == 'user':
            patient = Patient.objects.filter(user=user).first()
            if not patient:
                return Response(
                    {'error': 'Patient profile not found'},
                    status=status.HTTP_404_NOT_FOUND,
                )
            if not doctor and not asha:
                return Response(
                    {'error': 'doctor_id or asha_id is required'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        elif user.role == 'asha_worker':
            asha = getattr(user, 'asha_profile', None) or asha
            if not asha:
                return Response(
                    {'error': 'ASHA profile not found'},
                    status=status.HTTP_404_NOT_FOUND,
                )
            if not doctor and not patient:
                return Response(
                    {'error': 'doctor_id or patient_id is required'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        elif user.role == 'doctor':
            doctor = getattr(user, 'doctor_profile', None) or doctor
            if not doctor:
                return Response(
                    {'error': 'Doctor profile not found'},
                    status=status.HTTP_404_NOT_FOUND,
                )
            if doctor.verification_status != 'VERIFIED':
                return Response(
                    {'error': 'Doctor profile must be verified to start a consultation.'},
                    status=status.HTTP_403_FORBIDDEN,
                )
            if not patient and not asha:
                return Response(
                    {'error': 'patient_id or asha_id is required'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        else:
            return Response(
                {'error': 'Invalid role for starting a consultation'},
                status=status.HTTP_403_FORBIDDEN,
            )

        meeting_link = (
            f"https://meet.jit.si/CareSync-{uuid.uuid4().hex[:8]}"
            if str(call_type).upper() == 'VIDEO'
            else None
        )

        consultation = Consultation.objects.create(
            patient=patient,
            doctor=doctor,
            asha_worker=asha,
            initiated_by=user,
            call_type=str(call_type).upper(),
            status='PENDING',
            meeting_link=meeting_link,
            is_emergency=is_emergency,
        )

        serializer = self.get_serializer(consultation)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def end(self, request, pk=None):
        consultation = self.get_object()
        consultation.status = 'COMPLETED'
        consultation.end_time = timezone.now()
        consultation.save()
        return Response({'status': 'Consultation ended'})

    @action(detail=False, methods=['get'])
    def history(self, request):
        queryset = self.get_queryset().order_by('-created_at')
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class AppointmentViewSet(viewsets.ModelViewSet):
    serializer_class = AppointmentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = Appointment.objects.all()

        if user.role == 'doctor':
            doctor = getattr(user, 'doctor_profile', None)
            if not doctor:
                doctor = Doctor.objects.filter(user=user).first()
            if not doctor:
                return Appointment.objects.none()
            qs = qs.filter(doctor=doctor)
        elif user.role == 'user':
            patient = getattr(user, 'patient_profile', None)
            if not patient:
                patient = Patient.objects.filter(user=user).first()
            if not patient:
                return Appointment.objects.none()
            qs = qs.filter(patient=patient)
        elif user.role == 'asha_worker':
            asha = getattr(user, 'asha_profile', None)
            village = asha.assigned_village if asha else ''
            if village:
                qs = qs.filter(patient__user__village__iexact=village)
            else:
                return Appointment.objects.none()
        else:
            return Appointment.objects.none()

        date_param = self.request.query_params.get('date')
        if date_param:
            if date_param.lower() == 'today':
                today = timezone.localdate()
                qs = qs.filter(appointment_date=today)
            elif date_param.lower() == 'upcoming':
                today = timezone.localdate()
                qs = qs.filter(appointment_date__gte=today)
            else:
                qs = qs.filter(appointment_date=date_param)

        status_param = self.request.query_params.get('status')
        if status_param:
            qs = qs.filter(status__iexact=status_param)

        return qs.select_related('patient__user', 'doctor__user').order_by('appointment_date', 'appointment_time')

    def create(self, request, *args, **kwargs):
        user = request.user
        patient_id = request.data.get('patient_id') or request.data.get('patient')
        doctor_id = request.data.get('doctor_id') or request.data.get('doctor')
        appointment_date = request.data.get('appointment_date')
        appointment_time = request.data.get('appointment_time')
        consultation_type = (request.data.get('consultation_type') or 'VIDEO').upper()
        notes = request.data.get('notes', '')

        patient = _resolve_patient(patient_id)
        doctor = _resolve_doctor(doctor_id)

        if user.role == 'doctor':
            doctor = getattr(user, 'doctor_profile', None) or doctor or Doctor.objects.filter(user=user).first()
        elif user.role == 'user':
            patient = getattr(user, 'patient_profile', None) or patient or Patient.objects.filter(user=user).first()

        if not patient:
            return Response({'error': 'Valid patient is required'}, status=status.HTTP_400_BAD_REQUEST)
        if not doctor:
            return Response({'error': 'Valid doctor is required'}, status=status.HTTP_400_BAD_REQUEST)
        if not appointment_date or not appointment_time:
            return Response({'error': 'appointment_date and appointment_time are required'}, status=status.HTTP_400_BAD_REQUEST)

        # Standardize appointment time to HH:MM:SS if HH:MM
        if len(str(appointment_time)) == 5:
            appointment_time = f"{appointment_time}:00"

        # Check for slot conflict
        conflict = Appointment.objects.filter(
            doctor=doctor,
            appointment_date=appointment_date,
            appointment_time__startswith=str(appointment_time)[:5],
            status='SCHEDULED'
        ).exists()

        if conflict:
            return Response(
                {'error': 'This appointment slot is no longer available. Please choose another available time.'},
                status=status.HTTP_409_CONFLICT
            )

        if consultation_type not in ('VIDEO', 'AUDIO', 'OFFLINE'):
            consultation_type = 'VIDEO'

        appointment = Appointment.objects.create(
            patient=patient,
            doctor=doctor,
            appointment_date=appointment_date,
            appointment_time=appointment_time,
            consultation_type=consultation_type,
            status='SCHEDULED',
            notes=notes,
        )

        serializer = self.get_serializer(appointment)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'], url_path='smart-match')
    def smart_match(self, request):
        symptoms = request.data.get('symptoms', '').strip()
        duration = request.data.get('duration', '').strip()
        patient_severity = (request.data.get('severity') or '').strip().upper()

        if not symptoms:
            return Response(
                {'error': 'Please describe what is happening to you.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        import datetime
        lower = symptoms.lower()
        urgency = 'MODERATE'
        specialization = 'General Physician'
        rec_type = 'VIDEO'
        reason = "Based on your reported symptoms, consultation with a General Physician is recommended."

        # Clinical Categorization & Urgency Rules
        if any(k in lower for k in ['chest pain', 'heart', 'attack', 'breathing', 'breath', 'unconscious', 'faint', 'choking', 'severe bleeding', 'stroke', 'paralysis']) or patient_severity == 'EMERGENCY':
            urgency = 'EMERGENCY'
            specialization = 'Cardiology / Emergency Care'
            rec_type = 'OFFLINE'
            reason = "Urgent medical attention recommended based on critical symptoms. Immediate care priority assigned."
        elif any(k in lower for k in ['child', 'baby', 'infant', 'pediatric', 'kid', 'newborn', 'vomiting child']):
            urgency = 'HIGH' if patient_severity in ('SEVERE', 'EMERGENCY') else 'MODERATE'
            specialization = 'Pediatrician'
            rec_type = 'VIDEO'
            reason = "Pediatric consultation recommended for child-related health concerns."
        elif any(k in lower for k in ['skin', 'rash', 'itching', 'eczema', 'allergy', 'boil', 'fungal', 'pimple', 'scabies']):
            urgency = 'HIGH' if patient_severity == 'SEVERE' else 'LOW'
            specialization = 'Dermatologist'
            rec_type = 'VIDEO'
            reason = "Preliminary screening suggests that a Dermatology consultation is most appropriate for your skin condition."
        elif any(k in lower for k in ['pregnant', 'pregnancy', 'maternity', 'period', 'menstrual', 'gyneco', 'delivery']):
            urgency = 'HIGH' if patient_severity in ('SEVERE', 'EMERGENCY') else 'MODERATE'
            specialization = 'Gynecologist'
            rec_type = 'VIDEO'
            reason = "Consultation with a Gynecologist / Women's Health Specialist is recommended."
        elif any(k in lower for k in ['bone', 'fracture', 'joint', 'knee', 'spine', 'back pain', 'ortho', 'dislocation']):
            urgency = 'HIGH' if ('fracture' in lower or 'dislocation' in lower or patient_severity == 'SEVERE') else 'MODERATE'
            specialization = 'Orthopedic Surgeon'
            rec_type = 'OFFLINE' if ('fracture' in lower or 'dislocation' in lower) else 'VIDEO'
            reason = "Orthopedic evaluation recommended for joint and musculoskeletal symptoms."
        elif any(k in lower for k in ['high fever', 'dengue', 'malaria', 'severe pain', 'vomiting blood']) or patient_severity == 'SEVERE':
            urgency = 'HIGH'
            specialization = 'General Physician'
            rec_type = 'VIDEO'
            reason = "Priority General Physician consultation recommended for acute illness symptoms."
        else:
            urgency = 'LOW' if patient_severity == 'MILD' else 'MODERATE'
            specialization = 'General Physician'
            rec_type = 'VIDEO'
            reason = "General Physician consultation recommended for common symptoms and evaluation."

        # Query active verified doctors with valid user accounts
        doctors = list(
            Doctor.objects.filter(
                verification_status='VERIFIED',
                is_available=True,
                user__name__isnull=False,
            ).exclude(user__name='').select_related('user')
        )
        matched_doctor = None
        other_doctors = []
        spec_keyword = specialization.lower().split('/')[0].split(' ')[0]

        for doc in doctors:
            doc_spec = (doc.specialization or '').lower()
            if spec_keyword in doc_spec:
                if not matched_doctor:
                    matched_doctor = doc
                else:
                    other_doctors.append(doc)
            else:
                other_doctors.append(doc)

        if not matched_doctor:
            matched_doctor = doctors[0] if doctors else None
            if doctors:
                other_doctors = doctors[1:]

        if not matched_doctor:
            # Fallback to any doctor in system
            matched_doctor = Doctor.objects.select_related('user').first()

        if not matched_doctor:
            return Response(
                {'error': 'We could not find an available doctor at this moment. Please try again shortly.'},
                status=status.HTTP_404_NOT_FOUND
            )

        today = timezone.localdate()
        base_days_offset = 0 if urgency in ('EMERGENCY', 'HIGH') else 1

        dates = []
        for i in range(base_days_offset, base_days_offset + 4):
            d = today + datetime.timedelta(days=i)
            dates.append(d.strftime('%Y-%m-%d'))

        standard_slots = ['09:00:00', '10:30:00', '11:15:00', '12:00:00', '14:30:00', '16:00:00', '17:30:00']

        # Query existing appointments to find true availability
        booked_appts = Appointment.objects.filter(
            doctor=matched_doctor,
            appointment_date__in=dates,
            status='SCHEDULED'
        ).values_list('appointment_date', 'appointment_time')

        booked_map = set()
        for b_date, b_time in booked_appts:
            time_str = b_time.strftime('%H:%M:%S') if hasattr(b_time, 'strftime') else str(b_time)[:8]
            booked_map.add((b_date.strftime('%Y-%m-%d'), time_str))

        rec_date = dates[0]
        rec_time = '10:30:00'
        found_rec = False

        # Find first non-conflicting slot
        for d in dates:
            for s in standard_slots:
                if (d, s) not in booked_map:
                    rec_date = d
                    rec_time = s
                    found_rec = True
                    break
            if found_rec:
                break

        # Calculate available times for the recommended date
        avail_times = [s for s in standard_slots if (rec_date, s) not in booked_map]
        if not avail_times:
            avail_times = standard_slots

        doc_user = matched_doctor.user
        doc_name = doc_user.name if doc_user and doc_user.name else 'Doctor'
        if not doc_name.startswith('Dr.'):
            doc_name = f"Dr. {doc_name}"

        # Format other suitable doctors
        other_docs_data = []
        for odoc in other_doctors[:4]:
            od_user = odoc.user
            od_name = od_user.name if od_user and od_user.name else 'Doctor'
            if not od_name.startswith('Dr.'):
                od_name = f"Dr. {od_name}"
            other_docs_data.append({
                "id": odoc.id,
                "name": od_name,
                "specialization": odoc.specialization or "General Physician",
                "hospital_name": odoc.hospital_name or "Kopargaon Rural Hospital",
            })

        return Response({
            "symptoms_analyzed": symptoms,
            "duration": duration,
            "severity": patient_severity or urgency,
            "urgency": urgency,
            "recommended_specialization": matched_doctor.specialization or specialization,
            "recommendation_reason": reason,
            "recommended_doctor": {
                "id": matched_doctor.id,
                "name": doc_name,
                "specialization": matched_doctor.specialization or specialization,
                "hospital_name": matched_doctor.hospital_name or "Kopargaon Rural Hospital",
                "phone_number": getattr(doc_user, 'phone_number', '') or '',
            },
            "recommended_date": rec_date,
            "recommended_time": rec_time,
            "recommended_type": rec_type,
            "alternative_dates": dates,
            "alternative_times": avail_times,
            "other_doctors": other_docs_data,
            "is_emergency": (urgency == 'EMERGENCY'),
            "disclaimer": "Preliminary screening and triage recommendation only. This does not constitute a formal medical diagnosis."
        }, status=status.HTTP_200_OK)

    @action(detail=False, methods=['get'], url_path='doctor-slots')
    def doctor_slots(self, request):
        doctor_id = request.query_params.get('doctor_id')
        date_str = request.query_params.get('date')

        if not doctor_id or not date_str:
            return Response({'error': 'doctor_id and date query parameters are required'}, status=status.HTTP_400_BAD_REQUEST)

        doctor = _resolve_doctor(doctor_id)
        if not doctor:
            return Response({'error': 'Doctor not found'}, status=status.HTTP_404_NOT_FOUND)

        standard_slots = ['09:00:00', '10:30:00', '11:15:00', '12:00:00', '14:30:00', '16:00:00', '17:30:00']
        booked_times = Appointment.objects.filter(
            doctor=doctor,
            appointment_date=date_str,
            status='SCHEDULED'
        ).values_list('appointment_time', flat=True)

        booked_set = set()
        for b_time in booked_times:
            time_str = b_time.strftime('%H:%M:%S') if hasattr(b_time, 'strftime') else str(b_time)[:8]
            booked_set.add(time_str)

        available_slots = [s for s in standard_slots if s not in booked_set]
        return Response({
            'doctor_id': doctor.id,
            'date': date_str,
            'available_slots': available_slots,
            'all_slots': standard_slots,
            'booked_slots': list(booked_set)
        })

    def perform_update(self, serializer):
        user = self.request.user
        if user.role == 'doctor':
            doctor = getattr(user, 'doctor_profile', None) or Doctor.objects.filter(user=user).first()
            if not doctor or doctor.verification_status != 'VERIFIED':
                raise permissions.exceptions.PermissionDenied('Doctor profile must be verified to accept or modify appointments.')
        serializer.save()

