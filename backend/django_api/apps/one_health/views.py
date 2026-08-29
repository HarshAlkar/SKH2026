from django.conf import settings
from rest_framework import serializers, viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from apps.common.ownership import strip_client_identity_fields, validate_client_timestamp
from apps.doctors.models import Doctor
from apps.security_audit.audit import log_security_event

from .animal_screen import screen_animal_symptoms, DISCLAIMER
from .models import LivestockCase, ScreeningEvent

_ALLOWED_SEVERITY = {'Low', 'Moderate', 'High', 'Critical', 'Unknown'}


class LivestockCaseSerializer(serializers.ModelSerializer):
    class Meta:
        model = LivestockCase
        fields = [
            'id', 'owner', 'name', 'species', 'age_months', 'village',
            'notes', 'created_at', 'updated_at',
        ]
        read_only_fields = ['owner', 'created_at', 'updated_at']


class ScreeningEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = ScreeningEvent
        fields = [
            'id', 'domain', 'user', 'livestock_case', 'input_type', 'input_text',
            'possible_condition', 'severity_level', 'confidence', 'advice',
            'result_json', 'client_id', 'status', 'created_at',
        ]
        read_only_fields = ['user', 'created_at', 'status']


class LivestockCaseViewSet(viewsets.ModelViewSet):
    serializer_class = LivestockCaseSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return LivestockCase.objects.filter(owner=self.request.user)

    def perform_create(self, serializer):
        village = serializer.validated_data.get('village') or getattr(self.request.user, 'village', '') or ''
        serializer.save(owner=self.request.user, village=village)


class ScreeningEventViewSet(viewsets.ModelViewSet):
    serializer_class = ScreeningEventSerializer
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = 'sync'
    http_method_names = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        # Users only see released history (held stays in TEMP vault until admin restore)
        qs = ScreeningEvent.objects.filter(
            user=self.request.user,
            status=ScreeningEvent.STATUS_RELEASED,
        )
        domain = self.request.query_params.get('domain')
        if domain:
            qs = qs.filter(domain=domain.upper())
        return qs

    def create(self, request, *args, **kwargs):
        """Idempotent create for OfflineApi outbox (client_id)."""
        client_id = (request.data.get('client_id') or '').strip()
        if client_id:
            existing = ScreeningEvent.objects.filter(user=request.user, client_id=client_id).first()
            if existing:
                return Response(ScreeningEventSerializer(existing).data, status=status.HTTP_200_OK)

        data = strip_client_identity_fields(
            request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
        )
        created_at = data.get('created_at') or data.get('client_timestamp')
        ok, err = validate_client_timestamp(
            created_at,
            max_skew_days=getattr(settings, 'SYNC_TIMESTAMP_MAX_SKEW_DAYS', 30),
        )
        if not ok:
            return Response({'error': err}, status=status.HTTP_400_BAD_REQUEST)
        severity = (data.get('severity_level') or 'Unknown')
        if severity not in _ALLOWED_SEVERITY:
            data['severity_level'] = 'Unknown'
        # Never trust client livestock ownership
        case_id = data.get('livestock_case')
        if case_id:
            if not LivestockCase.objects.filter(pk=case_id, owner=request.user).exists():
                data.pop('livestock_case', None)

        domain = (data.get('domain') or 'HUMAN').upper()
        # Livestock (and optionally all) go to TEMP vault first — not history until restore
        hold = domain == 'ANIMAL'

        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        event = serializer.save(
            user=request.user,
            status=ScreeningEvent.STATUS_HELD if hold else ScreeningEvent.STATUS_RELEASED,
        )
        log_security_event(
            request, action='screening_create',
            object_type='ScreeningEvent', object_id=event.pk,
            metadata={
                'domain': event.domain,
                'client_id': client_id or None,
                'held_in_temp_vault': hold,
            },
        )
        try:
            from apps.blackout.service import snapshot_screenings
            snapshot_screenings(reason='screening_held' if hold else 'screening_create')
        except Exception:
            pass
        payload = ScreeningEventSerializer(event).data
        if hold:
            payload['held_in_temp_vault'] = True
            payload['message'] = (
                'Livestock screening held in TEMP vault. '
                'It will appear in history after admin Restore.'
            )
        return Response(payload, status=status.HTTP_201_CREATED)


class AnimalScreeningView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        symptoms = request.data.get('symptoms') or request.data.get('symptoms_text') or ''
        species = (request.data.get('species') or 'CATTLE').upper()
        case_id = request.data.get('livestock_case_id') or request.data.get('livestock_case')
        client_id = (request.data.get('client_id') or '').strip()
        language = request.data.get('language', 'en')

        if client_id:
            existing = ScreeningEvent.objects.filter(user=request.user, client_id=client_id).first()
            if existing:
                return Response({
                    'screening_id': existing.id,
                    'domain': 'ANIMAL',
                    'possible_condition': existing.possible_condition,
                    'disease': existing.possible_condition,
                    'disease_display': existing.possible_condition,
                    'severity': existing.severity_level,
                    'confidence': existing.confidence,
                    'advice': existing.advice,
                    'disclaimer': DISCLAIMER,
                    'alert_sent': False,
                    'language': language,
                    'top_predictions': (existing.result_json or {}).get('top_predictions', []),
                })

        result = screen_animal_symptoms(symptoms, species=species, language=language)
        case = None
        if case_id:
            case = LivestockCase.objects.filter(pk=case_id, owner=request.user).first()

        event = ScreeningEvent.objects.create(
            domain='ANIMAL',
            user=request.user,
            livestock_case=case,
            input_type='symptoms',
            input_text=symptoms,
            possible_condition=result['possible_condition'],
            severity_level=result['severity'],
            confidence=result['confidence'],
            advice=result['advice'],
            result_json=result,
            client_id=client_id,
            status=ScreeningEvent.STATUS_HELD,
        )

        # No care-team alert until admin releases from TEMP vault.
        try:
            from apps.blackout.service import snapshot_screenings
            snapshot_screenings(reason='animal_screening_held')
        except Exception:
            pass

        return Response({
            'screening_id': event.id,
            'domain': 'ANIMAL',
            'possible_condition': result['possible_condition'],
            'disease': result['possible_condition'],
            'disease_display': result.get('disease_display') or result['possible_condition'],
            'severity': result['severity'],
            'severity_display': result.get('severity_display') or result['severity'],
            'confidence': result['confidence'],
            'advice': result['advice'],
            'disclaimer': result['disclaimer'],
            'alert_sent': False,
            'held_in_temp_vault': True,
            'message': (
                'Held in TEMP vault. Result appears in livestock history '
                'after admin Restore.'
            ),
            'language': result.get('language') or language,
            'species': species,
            'top_predictions': result.get('top_predictions', []),
            'livestock_case_id': case.id if case else None,
        }, status=status.HTTP_200_OK)


class VeterinarianListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        qs = Doctor.objects.filter(is_veterinarian=True).select_related('user')
        if not qs.exists():
            qs = Doctor.objects.filter(specialization__icontains='veterinar').select_related('user')
        data = []
        for d in qs:
            data.append({
                'id': d.id,
                'user_id': d.user_id,
                'full_name': d.user.name or d.user.username,
                'specialization': d.specialization,
                'phone_number': d.user.phone_number or '',
                'hospital_name': d.hospital_name,
                'is_veterinarian': True,
                'is_available': d.is_available,
            })
        return Response(data)
