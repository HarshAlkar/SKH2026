from django.contrib.auth import authenticate
from django.db.models import Count, Q
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.common.authentication import rotate_token
from apps.security_audit.audit import log_security_event

from apps.users.models import User
from apps.users.views import normalize_identifier
from apps.patients.models import Patient, assign_patient_to_asha
from apps.doctors.models import Doctor
from apps.asha_workers.models import ASHAWorker, VillageVisit
from apps.consultations.models import Consultation
from apps.prescriptions.models import Prescription
from apps.alerts.models import EmergencyAlert, AlertNotification, EmergencyReferral
from apps.health_records.models import HealthRecord
from apps.medicine_tracker.models import MedicineSchedule
from apps.symptom_analysis.models import SymptomAnalysis
from apps.one_health.models import ScreeningEvent, LivestockCase
from apps.chat.models import ChatThread, ChatMessage
from apps.inventory.models import (
    HealthcareFacility,
    MedicineCatalog,
    Supplier,
    StockBatch,
    StockMovement,
)
from apps.inventory.serializers import (
    HealthcareFacilitySerializer,
    MedicineCatalogSerializer,
    SupplierSerializer,
    StockBatchSerializer,
    StockMovementSerializer,
)
from apps.inventory.services import facility_stock_health
from apps.inventory.views import DashboardView as StockDashboardView

from .serializers import (
    AdminUserSerializer,
    AdminUserWriteSerializer,
    AdminCreateUserSerializer,
    AdminSetPasswordSerializer,
    AdminPatientSerializer,
    AdminDoctorSerializer,
    AdminAshaSerializer,
    AdminConsultationSerializer,
    AdminPrescriptionSerializer,
    AdminEmergencySerializer,
    AdminNotificationSerializer,
    AdminReferralSerializer,
    AdminRecordSerializer,
    AdminMedicineSerializer,
    AdminVisitSerializer,
    AdminSymptomSerializer,
    AdminChatThreadSerializer,
    AdminChatMessageSerializer,
)


class AdminLoginView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        identifier = (
            request.data.get('username')
            or request.data.get('email')
            or request.data.get('phone_number')
        )
        password = request.data.get('password')
        if not identifier or not password:
            return Response(
                {'error': 'Username/email/phone and password are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        identifier = str(identifier).strip()
        phone = normalize_identifier(identifier)
        user_obj = (
            User.objects.filter(username__iexact=identifier).first()
            or User.objects.filter(email__iexact=identifier).first()
            or User.objects.filter(phone_number=phone).first()
        )
        if not user_obj:
            return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

        user = authenticate(username=user_obj.username, password=password)
        if not user:
            return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)
        if not user.is_staff:
            return Response(
                {'error': 'This account is not a staff admin.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        if not user.is_active:
            return Response({'error': 'This account is disabled.'}, status=status.HTTP_403_FORBIDDEN)

        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user': AdminUserSerializer(user, context={'request': request}).data,
        })


class AdminStatsView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        pending = Consultation.objects.filter(status__in=['PENDING', 'ONGOING']).count()
        recent_consults = AdminConsultationSerializer(
            Consultation.objects.select_related(
                'patient__user', 'doctor__user', 'asha_worker__user', 'initiated_by',
            ).order_by('-created_at')[:8],
            many=True,
        ).data
        open_alerts = AdminEmergencySerializer(
            EmergencyAlert.objects.select_related('user').filter(is_resolved=False).order_by('-timestamp')[:8],
            many=True,
        ).data
        asha_rows = []
        for asha in ASHAWorker.objects.select_related('user').all()[:8]:
            asha_rows.append({
                'id': asha.id,
                'name': asha.user.name or asha.user.username,
                'village': asha.assigned_village or asha.user.village,
                'visits_today': VillageVisit.objects.filter(
                    asha_worker=asha,
                    visit_date=timezone.now().date(),
                ).count(),
            })
        pending_doctors = Doctor.objects.select_related('user').prefetch_related('documents').filter(
            verification_status='PENDING_VERIFICATION',
        )
        pending_asha = ASHAWorker.objects.select_related('user').prefetch_related('documents').filter(
            verification_status='PENDING_VERIFICATION',
        )
        ctx = {'request': request}
        return Response({
            'patients': Patient.objects.count(),
            'doctors': Doctor.objects.count(),
            'asha_workers': ASHAWorker.objects.count(),
            'active_doctors': Doctor.objects.filter(is_available=True, user__is_active=True).count(),
            'pending_consultations': pending,
            'emergency_alerts': EmergencyAlert.objects.filter(is_resolved=False).count(),
            'prescriptions': Prescription.objects.count(),
            'symptom_analyses': SymptomAnalysis.objects.count(),
            'human_screenings': ScreeningEvent.objects.filter(domain='HUMAN').count(),
            'animal_screenings': ScreeningEvent.objects.filter(domain='ANIMAL').count(),
            'livestock_cases': LivestockCase.objects.count(),
            'veterinarians': Doctor.objects.filter(is_veterinarian=True).count(),
            'visits': VillageVisit.objects.count(),
            'chat_threads': ChatThread.objects.count(),
            'recent_consultations': recent_consults,
            'open_alerts': open_alerts,
            'asha_activity': asha_rows,
            'pending_doctor_verifications': pending_doctors.count(),
            'pending_asha_verifications': pending_asha.count(),
            'pending_verifications': pending_doctors.count() + pending_asha.count(),
            'pending_doctor_queue': AdminDoctorSerializer(pending_doctors[:8], many=True, context=ctx).data,
            'pending_asha_queue': AdminAshaSerializer(pending_asha[:8], many=True, context=ctx).data,
        })


def _parse_coords(alert):
    lat = alert.latitude
    lng = alert.longitude
    if lat is not None and lng is not None:
        return lat, lng
    loc = (alert.location or '').strip()
    if not loc:
        return None, None
    parts = [p.strip() for p in loc.replace(';', ',').split(',')]
    if len(parts) >= 2:
        try:
            return float(parts[0]), float(parts[1])
        except ValueError:
            pass
    return None, None


class AdminMapMarkersView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        emergencies = []
        for alert in EmergencyAlert.objects.select_related('user', 'assigned_doctor__user').filter(is_resolved=False):
            lat, lng = _parse_coords(alert)
            if lat is None or lng is None:
                continue
            emergencies.append({
                'id': alert.id,
                'type': 'emergency',
                'lat': lat,
                'lng': lng,
                'label': alert.user.name or alert.user.username,
                'alert_type': alert.alert_type,
                'village': alert.user.village,
                'timestamp': alert.timestamp.isoformat() if alert.timestamp else None,
            })

        visits = []
        today = timezone.now().date()
        for visit in VillageVisit.objects.select_related('patient__user', 'asha_worker__user').filter(visit_date=today):
            lat, lng = _parse_coords_from_text(visit.village or (visit.patient.user.village if visit.patient else ''))
            if lat is None:
                continue
            visits.append({
                'id': visit.id,
                'type': 'visit',
                'lat': lat,
                'lng': lng,
                'label': visit.patient.user.name if visit.patient else 'Visit',
                'village': visit.village,
                'status': visit.status,
            })

        asha_workers = []
        for asha in ASHAWorker.objects.select_related('user').filter(user__is_active=True):
            village = asha.assigned_village or asha.user.village
            lat, lng = _parse_coords_from_text(village)
            if lat is None:
                continue
            asha_workers.append({
                'id': asha.id,
                'type': 'asha',
                'lat': lat,
                'lng': lng,
                'label': asha.user.name or asha.user.username,
                'village': village,
            })

        pharmacies = []
        for facility in HealthcareFacility.objects.filter(
            is_active=True,
            latitude__isnull=False,
            longitude__isnull=False,
        ):
            health = facility_stock_health(facility)
            pharmacies.append({
                'id': facility.id,
                'type': 'pharmacy',
                'lat': facility.latitude,
                'lng': facility.longitude,
                'label': facility.name,
                'village': facility.village,
                'facility_type': facility.facility_type,
                'low_stock': health['low_stock'],
                'out_of_stock': health['out_of_stock'],
                'expiring_soon': health['expiring_soon'],
                'expired': health['expired'],
                'total_batches': health['total_batches'],
            })

        return Response({
            'emergencies': emergencies,
            'visits': visits,
            'asha_workers': asha_workers,
            'pharmacies': pharmacies,
        })


def _parse_coords_from_text(text):
    """Fallback: no geocoding — skip unless text looks like lat,lng."""
    if not text:
        return None, None
    parts = [p.strip() for p in str(text).replace(';', ',').split(',')]
    if len(parts) >= 2:
        try:
            return float(parts[0]), float(parts[1])
        except ValueError:
            pass
    return None, None


def _admin_set_user_password(request, user):
    """Staff can set any module account password and revoke existing sessions."""
    serializer = AdminSetPasswordSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    new_password = serializer.validated_data['new_password']

    if user.is_superuser and not request.user.is_superuser:
        return Response(
            {'error': 'You cannot change a superuser password.'},
            status=status.HTTP_403_FORBIDDEN,
        )

    user.set_password(new_password)
    user.save(update_fields=['password'])
    token = rotate_token(user)
    log_security_event(
        request,
        action='admin_set_password',
        object_type='User',
        object_id=user.pk,
        metadata={'role': user.role, 'target_username': user.username},
    )
    payload = {
        'status': 'Password updated.',
        'user_id': user.pk,
        'sessions_revoked': True,
    }
    if user.pk == request.user.pk:
        payload['token'] = token.key
    return Response(payload)


class AdminUserViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    queryset = User.objects.select_related(
        'patient_profile',
        'doctor_profile',
        'asha_profile',
        'medical_staff_profile__facility',
    ).all().order_by('-created_at')
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_serializer_class(self):
        if self.action == 'create':
            return AdminCreateUserSerializer
        if self.action in ('partial_update', 'update'):
            return AdminUserWriteSerializer
        return AdminUserSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        role = self.request.query_params.get('role')
        village = self.request.query_params.get('village')
        active = self.request.query_params.get('is_active')
        staff = self.request.query_params.get('is_staff')
        q = (self.request.query_params.get('q') or '').strip()
        if role:
            qs = qs.filter(role=role)
        if village:
            qs = qs.filter(village__icontains=village)
        if active in ('true', 'false', '1', '0'):
            qs = qs.filter(is_active=active in ('true', '1'))
        if staff in ('true', 'false', '1', '0'):
            qs = qs.filter(is_staff=staff in ('true', '1'))
        if q:
            qs = qs.filter(
                Q(name__icontains=q)
                | Q(username__icontains=q)
                | Q(phone_number__icontains=q)
                | Q(email__icontains=q)
            )
        return qs

    def create(self, request, *args, **kwargs):
        serializer = AdminCreateUserSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(
            AdminUserSerializer(user, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['post'], url_path='set-password')
    def set_password(self, request, pk=None):
        return _admin_set_user_password(request, self.get_object())


class AdminPatientViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminPatientSerializer
    queryset = Patient.objects.select_related('user', 'assigned_asha__user').all().order_by('-id')
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_queryset(self):
        qs = super().get_queryset()
        q = (self.request.query_params.get('q') or '').strip()
        village = self.request.query_params.get('village')
        asha_id = (self.request.query_params.get('assigned_asha') or '').strip()
        unassigned = (self.request.query_params.get('unassigned') or '').strip().lower()
        if village:
            qs = qs.filter(user__village__icontains=village)
        if asha_id:
            qs = qs.filter(assigned_asha_id=asha_id)
        if unassigned in ('1', 'true', 'yes'):
            qs = qs.filter(assigned_asha__isnull=True)
        if q:
            qs = qs.filter(
                Q(user__name__icontains=q)
                | Q(user__phone_number__icontains=q)
                | Q(user__village__icontains=q)
            )
        return qs

    def create(self, request, *args, **kwargs):
        payload = {**request.data, 'role': 'user'}
        serializer = AdminCreateUserSerializer(data=payload, context={'request': request})
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        patient = user.patient_profile
        asha_id = request.data.get('assigned_asha')
        if asha_id and not patient.assigned_asha_id:
            asha = ASHAWorker.objects.filter(pk=asha_id).first()
            if asha:
                assign_patient_to_asha(patient, asha)
        return Response(
            AdminPatientSerializer(patient).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['post'], url_path='set-password')
    def set_password(self, request, pk=None):
        return _admin_set_user_password(request, self.get_object().user)


class AdminDoctorViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminDoctorSerializer
    queryset = Doctor.objects.select_related('user').prefetch_related('documents').all().order_by('-id')
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        qs = super().get_queryset()
        q = (self.request.query_params.get('q') or '').strip()
        if q:
            qs = qs.filter(
                Q(user__name__icontains=q)
                | Q(specialization__icontains=q)
                | Q(hospital_name__icontains=q)
            )
        vs = (self.request.query_params.get('verification_status') or '').strip()
        if vs:
            qs = qs.filter(verification_status=vs)
        return qs

    def create(self, request, *args, **kwargs):
        payload = {**request.data, 'role': 'doctor'}
        if payload.get('full_name') and not payload.get('name'):
            payload['name'] = payload['full_name']
        serializer = AdminCreateUserSerializer(data=payload, context={'request': request})
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(
            AdminDoctorSerializer(user.doctor_profile, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        doctor = self.get_object()
        doctor.verification_status = 'VERIFIED'
        doctor.verified_at = timezone.now()
        doctor.verified_by = request.user
        doctor.rejection_reason = None
        doctor.save()
        return Response({'status': 'Doctor verified successfully.'})

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        doctor = self.get_object()
        reason = request.data.get('reason')
        if not reason:
            return Response({'error': 'Reason is required for rejection.'}, status=status.HTTP_400_BAD_REQUEST)
        doctor.verification_status = 'REJECTED'
        doctor.rejection_reason = reason
        doctor.save()
        return Response({'status': 'Doctor verification rejected.'})

    @action(detail=True, methods=['post'], url_path='set-password')
    def set_password(self, request, pk=None):
        return _admin_set_user_password(request, self.get_object().user)


class AdminAshaViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminAshaSerializer
    queryset = ASHAWorker.objects.select_related('user').prefetch_related('documents').annotate(
        assigned_patient_count=Count('assigned_patients'),
    ).all().order_by('-id')
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def get_queryset(self):
        qs = super().get_queryset()
        vs = (self.request.query_params.get('verification_status') or '').strip()
        if vs:
            qs = qs.filter(verification_status=vs)
        return qs

    def create(self, request, *args, **kwargs):
        payload = {**request.data, 'role': 'asha_worker'}
        if payload.get('full_name') and not payload.get('name'):
            payload['name'] = payload['full_name']
        if payload.get('assigned_village') and not payload.get('village'):
            payload['village'] = payload['assigned_village']
        serializer = AdminCreateUserSerializer(data=payload, context={'request': request})
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(
            AdminAshaSerializer(user.asha_profile, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=['post'])
    def approve(self, request, pk=None):
        asha = self.get_object()
        asha.verification_status = 'VERIFIED'
        asha.verified_at = timezone.now()
        asha.verified_by = request.user
        asha.rejection_reason = None
        asha.save()
        return Response({'status': 'ASHA worker verified successfully.'})

    @action(detail=True, methods=['post'])
    def reject(self, request, pk=None):
        asha = self.get_object()
        reason = request.data.get('reason')
        if not reason:
            return Response({'error': 'Reason is required for rejection.'}, status=status.HTTP_400_BAD_REQUEST)
        asha.verification_status = 'REJECTED'
        asha.rejection_reason = reason
        asha.save()
        return Response({'status': 'ASHA worker verification rejected.'})

    @action(detail=True, methods=['post'], url_path='set-password')
    def set_password(self, request, pk=None):
        return _admin_set_user_password(request, self.get_object().user)

    @action(detail=True, methods=['get'])
    def patients(self, request, pk=None):
        asha = self.get_object()
        rows = Patient.objects.select_related('user', 'assigned_asha__user').filter(assigned_asha=asha)
        return Response(AdminPatientSerializer(rows, many=True).data)

    @action(detail=True, methods=['post'], url_path='assign-patients')
    def assign_patients(self, request, pk=None):
        asha = self.get_object()
        ids = request.data.get('patient_ids') or []
        if not isinstance(ids, list) or not ids:
            return Response({'error': 'patient_ids must be a non-empty list'}, status=status.HTTP_400_BAD_REQUEST)
        patients = Patient.objects.select_related('user').filter(id__in=ids)
        for patient in patients:
            assign_patient_to_asha(patient, asha)
        rows = Patient.objects.select_related('user', 'assigned_asha__user').filter(assigned_asha=asha)
        return Response({
            'status': f'{patients.count()} patients assigned to this ASHA worker.',
            'count': patients.count(),
            'patients': AdminPatientSerializer(rows, many=True).data,
        })


class AdminConsultationViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminConsultationSerializer
    queryset = Consultation.objects.select_related(
        'patient__user', 'doctor__user', 'asha_worker__user', 'initiated_by',
    ).all().order_by('-created_at')
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_queryset(self):
        qs = super().get_queryset()
        st = self.request.query_params.get('status')
        if st:
            qs = qs.filter(status=st)
        return qs

    @action(detail=True, methods=['post'])
    def end(self, request, pk=None):
        consultation = self.get_object()
        consultation.status = 'COMPLETED'
        consultation.end_time = timezone.now()
        consultation.save(update_fields=['status', 'end_time'])
        return Response(AdminConsultationSerializer(consultation).data)


class AdminPrescriptionViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminPrescriptionSerializer
    queryset = Prescription.objects.select_related('patient__user', 'doctor__user').all().order_by('-issued_at')
    http_method_names = ['get', 'post', 'patch', 'head', 'options']


class AdminEmergencyViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminEmergencySerializer
    queryset = EmergencyAlert.objects.select_related('user', 'assigned_doctor__user').all().order_by('-timestamp')
    http_method_names = ['get', 'patch', 'head', 'options']

    def get_queryset(self):
        qs = super().get_queryset()
        resolved = self.request.query_params.get('is_resolved')
        if resolved is not None:
            qs = qs.filter(is_resolved=str(resolved).lower() in ('1', 'true', 'yes'))
        village = self.request.query_params.get('village')
        if village:
            qs = qs.filter(user__village__icontains=village)
        return qs


class AdminNotificationViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminNotificationSerializer
    queryset = AlertNotification.objects.select_related('patient', 'doctor__user', 'asha_worker__user').all().order_by('-created_at')
    http_method_names = ['get', 'head', 'options']


class AdminReferralViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminReferralSerializer
    queryset = EmergencyReferral.objects.select_related('patient__user', 'asha_worker__user').all().order_by('-created_at')
    http_method_names = ['get', 'patch', 'head', 'options']


class AdminRecordViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminRecordSerializer
    queryset = HealthRecord.objects.select_related('patient__user').all().order_by('-created_at')
    http_method_names = ['get', 'post', 'patch', 'head', 'options']


class AdminMedicineViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminMedicineSerializer
    queryset = MedicineSchedule.objects.select_related('patient__user').all().order_by('-created_at')
    http_method_names = ['get', 'post', 'patch', 'head', 'options']


class AdminVisitViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminVisitSerializer
    queryset = VillageVisit.objects.select_related('patient__user', 'asha_worker__user').all().order_by('-visit_date', '-visit_time')
    http_method_names = ['get', 'post', 'patch', 'head', 'options']


class AdminSymptomViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminSymptomSerializer
    queryset = SymptomAnalysis.objects.select_related('user').all().order_by('-created_at')


class AdminChatViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = AdminChatThreadSerializer
    queryset = ChatThread.objects.select_related('user_a', 'user_b').all()

    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        thread = self.get_object()
        msgs = ChatMessage.objects.filter(thread=thread).select_related('sender')
        return Response(AdminChatMessageSerializer(msgs, many=True).data)


class AdminFacilityViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = HealthcareFacilitySerializer
    queryset = HealthcareFacility.objects.all().order_by('name')
    http_method_names = ['get', 'post', 'patch', 'head', 'options']


class AdminCatalogViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = MedicineCatalogSerializer
    queryset = MedicineCatalog.objects.all().order_by('name')
    http_method_names = ['get', 'post', 'patch', 'head', 'options']


class AdminSupplierViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = SupplierSerializer
    queryset = Supplier.objects.all().order_by('name')
    http_method_names = ['get', 'post', 'patch', 'head', 'options']


class AdminStockBatchViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = StockBatchSerializer
    queryset = StockBatch.objects.select_related(
        'catalog', 'facility', 'supplier',
    ).all().order_by('expiry_date')
    http_method_names = ['get', 'post', 'patch', 'head', 'options']

    def get_queryset(self):
        from datetime import timedelta
        from django.db.models import F

        qs = super().get_queryset()
        q = (self.request.query_params.get('q') or '').strip()
        if q:
            qs = qs.filter(
                Q(catalog__name__icontains=q)
                | Q(batch_no__icontains=q)
                | Q(facility__name__icontains=q)
            )
        status_f = (self.request.query_params.get('status') or '').strip()
        today = timezone.now().date()
        soon = today + timedelta(days=30)
        if status_f == 'out_of_stock':
            qs = qs.filter(quantity=0)
        elif status_f == 'low_stock':
            qs = qs.filter(quantity__gt=0, quantity__lte=F('reorder_level'))
        elif status_f == 'expiring':
            qs = qs.filter(expiry_date__gte=today, expiry_date__lte=soon, quantity__gt=0)
        elif status_f == 'expired':
            qs = qs.filter(expiry_date__lt=today)
        facility = self.request.query_params.get('facility')
        if facility:
            qs = qs.filter(facility_id=facility)
        return qs


class AdminStockMovementViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAdminUser]
    serializer_class = StockMovementSerializer
    queryset = StockMovement.objects.select_related(
        'batch__catalog', 'batch__facility', 'actor',
    ).all().order_by('-created_at')


class AdminInventoryStatsView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        view = StockDashboardView()
        view.request = request
        return view.get(request)
