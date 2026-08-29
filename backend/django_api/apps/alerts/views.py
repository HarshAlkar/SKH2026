from collections import Counter

from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Q

from apps.common.ownership import asha_assigned_village, user_can_access_patient
from apps.security_audit.audit import log_security_event
from .models import EmergencyAlert, AlertNotification, EmergencyReferral
from .serializers import EmergencyAlertSerializer, AlertNotificationSerializer, EmergencyReferralSerializer
from .notify import notify_village_care_team

User = get_user_model()


class EmergencyAlertViewSet(viewsets.ModelViewSet):
    queryset = EmergencyAlert.objects.all()
    serializer_class = EmergencyAlertSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        qs = EmergencyAlert.objects.all().order_by('-timestamp')
        if user.is_staff:
            return qs
        role = getattr(user, 'role', None)
        if role == 'user':
            return qs.filter(user=user)
        if role == 'doctor':
            village = (user.village or '').strip()
            return qs.filter(
                Q(assigned_doctor__user=user)
                | Q(user__village__iexact=village)
                | Q(is_resolved=False, assigned_doctor__isnull=True)
            ).distinct()
        if role == 'asha_worker':
            village = asha_assigned_village(user)
            if village:
                return qs.filter(Q(user=user) | Q(user__village__iexact=village))
            return qs.filter(user=user)
        return qs.filter(user=user)

    def perform_create(self, serializer):
        alert = serializer.save(user=self.request.user)
        log_security_event(
            self.request, action='emergency_alert_create',
            object_type='EmergencyAlert', object_id=alert.pk,
        )
        notify_village_care_team(
            self.request.user,
            disease=alert.alert_type or 'Emergency',
            severity='High',
        )

    def perform_update(self, serializer):
        instance = self.get_object()
        if instance.user_id != self.request.user.id and not self.request.user.is_staff:
            if getattr(self.request.user, 'role', None) not in ('doctor', 'asha_worker'):
                from rest_framework.exceptions import PermissionDenied
                raise PermissionDenied('Cannot update another user\'s alert.')
        serializer.save()
        log_security_event(
            self.request, action='emergency_alert_update',
            object_type='EmergencyAlert', object_id=instance.pk,
        )


class NotificationViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = AlertNotificationSerializer
    http_method_names = ['get', 'post']

    def get_queryset(self):
        user = self.request.user
        if user.role == 'doctor':
            return AlertNotification.objects.filter(doctor__user=user).order_by('-created_at')
        elif user.role == 'asha_worker':
            return AlertNotification.objects.filter(asha_worker__user=user).order_by('-created_at')
        return AlertNotification.objects.filter(patient=user).order_by('-created_at')

    def create(self, request, *args, **kwargs):
        disease = (request.data.get('disease') or 'Health alert').strip()
        severity = (request.data.get('severity') or 'Moderate').strip()
        user = request.user

        if user.role == 'user':
            patient = user
        else:
            patient_id = request.data.get('patient_id')
            patient = User.objects.filter(id=patient_id, role='user').first() if patient_id else None
            if patient is None:
                return Response(
                    {'error': 'patient_id is required to create an alert.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            # ASHA may only alert for patients in their village
            if user.role == 'asha_worker':
                village = asha_assigned_village(user)
                if village and (patient.village or '').strip().lower() != village:
                    return Response({'error': 'Patient not in your assigned village.'}, status=403)

        notification, created = notify_village_care_team(patient, disease, severity)
        serializer = self.get_serializer(notification)
        notified = bool(notification and notification.asha_worker_id)
        log_security_event(
            request, action='alert_notification_create',
            object_type='AlertNotification',
            object_id=getattr(notification, 'pk', ''),
            metadata={'created': created},
        )
        return Response(
            {
                **serializer.data,
                'created': created,
                'notified': notified,
                'reason': None if notified else 'no_asha',
                'village': getattr(patient, 'village', '') or '',
            },
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )

    @action(detail=False, methods=['get'], url_path='village-summary')
    def village_summary(self, request):
        user = request.user
        village = user.village or ''
        if user.role == 'asha_worker' and hasattr(user, 'asha_profile') and user.asha_profile:
            village = user.asha_profile.assigned_village or village

        patients = User.objects.filter(role='user')
        alerts = AlertNotification.objects.all()
        if village:
            patients = patients.filter(village__iexact=village)
            alerts = alerts.filter(patient__village__iexact=village)
        if user.role == 'asha_worker':
            alerts = alerts.filter(asha_worker__user=user)
        elif user.role == 'doctor':
            alerts = alerts.filter(doctor__user=user)
        elif user.role == 'user':
            alerts = alerts.filter(patient=user)
            patients = patients.filter(pk=user.pk)

        disease_counts = Counter(
            (a.disease or 'Unknown').strip() for a in alerts
        )
        high_risk = alerts.filter(severity__in=['High', 'Critical']).count()
        return Response({
            'village': village or 'Unknown',
            'total_patients': patients.count(),
            'total_alerts': alerts.count(),
            'high_risk': high_risk,
            'diseases': [
                {'name': name, 'count': count}
                for name, count in disease_counts.most_common(8)
            ],
        })


class EmergencyReferralViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = EmergencyReferralSerializer
    http_method_names = ['get', 'post', 'patch']

    def get_queryset(self):
        user = self.request.user
        qs = EmergencyReferral.objects.all().order_by('-created_at')
        if user.role == 'asha_worker':
            return qs.filter(asha_worker__user=user)
        if user.role == 'doctor':
            return qs.filter(status__in=['sent', 'pending', 'accepted'])
        return qs.filter(patient__user=user)

    def perform_create(self, serializer):
        if getattr(self.request.user, 'role', None) != 'asha_worker':
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Only ASHA workers can create emergency referrals.')
        asha = getattr(self.request.user, 'asha_profile', None)
        patient = serializer.validated_data.get('patient')
        if patient and not user_can_access_patient(self.request.user, patient):
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Patient not in your assigned village.')
        referral = serializer.save(asha_worker=asha, status='sent')
        log_security_event(
            self.request, action='emergency_referral_create',
            object_type='EmergencyReferral', object_id=referral.pk,
        )
        severity = 'Critical' if referral.severity == 'critical' else 'High'
        notify_village_care_team(
            referral.patient.user,
            disease=referral.symptoms or 'Emergency referral',
            severity=severity,
        )
