from rest_framework import serializers
from django.db.models import Q

from apps.users.models import User
from apps.users.views import UserSerializer, RegisterSerializer, normalize_identifier
from apps.patients.models import Patient
from apps.doctors.models import Doctor, DoctorDocument
from apps.asha_workers.models import ASHAWorker, VillageVisit, ASHADocument
from apps.consultations.models import Consultation
from apps.prescriptions.models import Prescription
from apps.alerts.models import EmergencyAlert, AlertNotification, EmergencyReferral
from apps.health_records.models import HealthRecord
from apps.medicine_tracker.models import MedicineSchedule
from apps.symptom_analysis.models import SymptomAnalysis
from apps.chat.models import ChatThread, ChatMessage


class AdminUserSerializer(UserSerializer):
    is_staff = serializers.BooleanField(read_only=True)
    is_superuser = serializers.BooleanField(read_only=True)
    is_active = serializers.BooleanField()

    class Meta(UserSerializer.Meta):
        fields = UserSerializer.Meta.fields + [
            'is_staff',
            'is_superuser',
            'is_active',
        ]


class AdminUserWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['name', 'email', 'phone_number', 'village', 'is_active', 'role']

    def validate_phone_number(self, value):
        if not value:
            return value
        value = normalize_identifier(value)
        qs = User.objects.filter(Q(phone_number=value) | Q(username=value))
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError('This identifier is already registered.')
        return value


class AdminPatientSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='user.name', required=False)
    village = serializers.CharField(source='user.village', required=False)
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    is_active = serializers.BooleanField(source='user.is_active', required=False)
    email = serializers.CharField(source='user.email', read_only=True)

    class Meta:
        model = Patient
        fields = [
            'id', 'user_id', 'name', 'age', 'village', 'gender',
            'blood_group', 'address', 'medical_history', 'phone_number',
            'is_active', 'email',
        ]

    def update(self, instance, validated_data):
        user_data = validated_data.pop('user', {})
        if user_data:
            user = instance.user
            for field in ('name', 'village', 'is_active'):
                if field in user_data:
                    setattr(user, field, user_data[field])
            user.save()
        return super().update(instance, validated_data)


class AdminDoctorDocumentSerializer(serializers.ModelSerializer):
    file = serializers.SerializerMethodField()

    class Meta:
        model = DoctorDocument
        fields = ['id', 'document_type', 'file', 'uploaded_at']

    def get_file(self, obj):
        if not obj.file:
            return ''
        request = self.context.get('request')
        url = obj.file.url
        if request and url and not url.startswith('http'):
            return request.build_absolute_uri(url)
        return url


class AdminAshaDocumentSerializer(serializers.ModelSerializer):
    file = serializers.SerializerMethodField()

    class Meta:
        model = ASHADocument
        fields = ['id', 'document_type', 'file', 'uploaded_at']

    def get_file(self, obj):
        if not obj.file:
            return ''
        request = self.context.get('request')
        url = obj.file.url
        if request and url and not url.startswith('http'):
            return request.build_absolute_uri(url)
        return url


class AdminDoctorSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(source='user.name', required=False)
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    village = serializers.CharField(source='user.village', required=False)
    is_active = serializers.BooleanField(source='user.is_active', required=False)
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    documents = AdminDoctorDocumentSerializer(many=True, read_only=True)

    class Meta:
        model = Doctor
        fields = [
            'id', 'user_id', 'full_name', 'phone_number', 'email', 'village',
            'specialization', 'qualification', 'experience_years',
            'hospital_name', 'license_number', 'bio', 'is_available', 'is_active',
            'verification_status', 'rejection_reason', 'documents',
        ]

    def update(self, instance, validated_data):
        user_data = validated_data.pop('user', {})
        if user_data:
            user = instance.user
            if 'name' in user_data:
                user.name = user_data['name']
            if 'village' in user_data:
                user.village = user_data['village']
            if 'is_active' in user_data:
                user.is_active = user_data['is_active']
            user.save()
        return super().update(instance, validated_data)


class AdminAshaSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(source='user.name', required=False)
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    village = serializers.CharField(source='user.village', required=False)
    is_active = serializers.BooleanField(source='user.is_active', required=False)
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    documents = AdminAshaDocumentSerializer(many=True, read_only=True)

    class Meta:
        model = ASHAWorker
        fields = [
            'id', 'user_id', 'full_name', 'phone_number', 'email', 'village',
            'assigned_village', 'phc_center', 'worker_id', 'district', 'is_active',
            'verification_status', 'rejection_reason', 'documents',
        ]

    def update(self, instance, validated_data):
        user_data = validated_data.pop('user', {})
        if user_data:
            user = instance.user
            if 'name' in user_data:
                user.name = user_data['name']
            if 'village' in user_data:
                user.village = user_data['village']
            if 'is_active' in user_data:
                user.is_active = user_data['is_active']
            user.save()
        if 'assigned_village' in validated_data and validated_data['assigned_village']:
            instance.user.village = validated_data['assigned_village']
            instance.user.save(update_fields=['village'])
        return super().update(instance, validated_data)


class AdminConsultationSerializer(serializers.ModelSerializer):
    doctor_name = serializers.SerializerMethodField()
    patient_name = serializers.SerializerMethodField()
    asha_name = serializers.SerializerMethodField()

    class Meta:
        model = Consultation
        fields = [
            'id', 'patient', 'doctor', 'asha_worker', 'doctor_name',
            'patient_name', 'asha_name', 'initiated_by', 'call_type',
            'status', 'created_at', 'end_time', 'meeting_link', 'notes',
            'is_emergency',
        ]

    def get_doctor_name(self, obj):
        if obj.doctor and obj.doctor.user:
            return obj.doctor.user.name or obj.doctor.user.username
        return None

    def get_patient_name(self, obj):
        if obj.patient and obj.patient.user:
            return obj.patient.user.name or obj.patient.user.username
        if obj.initiated_by:
            return obj.initiated_by.name or obj.initiated_by.username
        return 'Unknown'

    def get_asha_name(self, obj):
        if obj.asha_worker and obj.asha_worker.user:
            return obj.asha_worker.user.name or obj.asha_worker.user.username
        return None


class AdminPrescriptionSerializer(serializers.ModelSerializer):
    doctor_name = serializers.CharField(source='doctor.user.name', read_only=True)
    patient_name = serializers.CharField(source='patient.user.name', read_only=True)
    has_file = serializers.SerializerMethodField()
    file_url = serializers.SerializerMethodField()

    class Meta:
        model = Prescription
        fields = [
            'id', 'patient', 'doctor', 'medications', 'dosage_instructions',
            'notes', 'issued_at', 'consultation', 'doctor_name', 'patient_name',
            'prescription_type', 'file_content_type', 'file_size', 'status',
            'has_file', 'file_url',
        ]

    def get_has_file(self, obj):
        return bool(obj.file)

    def get_file_url(self, obj):
        if not obj.file:
            return None
        return f'/api/prescriptions/{obj.pk}/file/'


class AdminEmergencySerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    village = serializers.CharField(source='user.village', read_only=True)
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)
    assigned_doctor_name = serializers.SerializerMethodField()

    class Meta:
        model = EmergencyAlert
        fields = [
            'id', 'user', 'user_name', 'village', 'phone_number',
            'alert_type', 'location', 'latitude', 'longitude',
            'assigned_doctor', 'assigned_doctor_name',
            'timestamp', 'is_resolved',
        ]

    def get_user_name(self, obj):
        return obj.user.name or obj.user.username

    def get_assigned_doctor_name(self, obj):
        if obj.assigned_doctor and obj.assigned_doctor.user:
            return obj.assigned_doctor.user.name or obj.assigned_doctor.user.username
        return None


class AdminNotificationSerializer(serializers.ModelSerializer):
    patient_name = serializers.SerializerMethodField()
    patient_phone = serializers.CharField(source='patient.phone_number', read_only=True)
    village = serializers.CharField(source='patient.village', read_only=True)

    class Meta:
        model = AlertNotification
        fields = '__all__'

    def get_patient_name(self, obj):
        return obj.patient.name or obj.patient.username or 'Unknown'


class AdminReferralSerializer(serializers.ModelSerializer):
    patient_name = serializers.SerializerMethodField()
    village = serializers.CharField(source='patient.user.village', read_only=True)
    asha_name = serializers.SerializerMethodField()

    class Meta:
        model = EmergencyReferral
        fields = '__all__'

    def get_patient_name(self, obj):
        return obj.patient.user.name or obj.patient.user.username

    def get_asha_name(self, obj):
        if obj.asha_worker and obj.asha_worker.user:
            return obj.asha_worker.user.name or obj.asha_worker.user.username
        return None


class AdminRecordSerializer(serializers.ModelSerializer):
    patient_name = serializers.CharField(source='patient.user.name', read_only=True)
    village = serializers.CharField(source='patient.user.village', read_only=True)

    class Meta:
        model = HealthRecord
        fields = [
            'id', 'patient', 'patient_name', 'village', 'temperature',
            'blood_pressure', 'blood_sugar', 'weight', 'symptoms',
            'risk_level', 'created_at',
        ]


class AdminMedicineSerializer(serializers.ModelSerializer):
    patient_name = serializers.CharField(source='patient.user.name', read_only=True)
    village = serializers.CharField(source='patient.user.village', read_only=True)

    class Meta:
        model = MedicineSchedule
        fields = '__all__'


class AdminVisitSerializer(serializers.ModelSerializer):
    patient_name = serializers.SerializerMethodField()
    asha_name = serializers.SerializerMethodField()
    village = serializers.CharField(source='patient.user.village', read_only=True)
    patient_id = serializers.IntegerField(source='patient.id', read_only=True)

    class Meta:
        model = VillageVisit
        fields = [
            'id', 'asha_worker', 'asha_name', 'patient', 'patient_id',
            'patient_name', 'village', 'visit_date', 'visit_time',
            'status', 'notes', 'created_at',
        ]

    def get_patient_name(self, obj):
        return obj.patient.user.name or obj.patient.user.username

    def get_asha_name(self, obj):
        return obj.asha_worker.user.name or obj.asha_worker.user.username


class AdminSymptomSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    village = serializers.CharField(source='user.village', read_only=True)
    role = serializers.CharField(source='user.role', read_only=True)

    class Meta:
        model = SymptomAnalysis
        fields = [
            'id', 'user', 'user_name', 'village', 'role',
            'symptoms_text', 'predicted_disease', 'severity_level', 'created_at',
        ]

    def get_user_name(self, obj):
        return obj.user.name or obj.user.username


class AdminChatMessageSerializer(serializers.ModelSerializer):
    sender_name = serializers.SerializerMethodField()

    class Meta:
        model = ChatMessage
        fields = ['id', 'sender', 'sender_name', 'text', 'created_at', 'is_read']

    def get_sender_name(self, obj):
        return obj.sender.name or obj.sender.username


class AdminChatThreadSerializer(serializers.ModelSerializer):
    user_a_name = serializers.SerializerMethodField()
    user_b_name = serializers.SerializerMethodField()
    user_a_role = serializers.CharField(source='user_a.role', read_only=True)
    user_b_role = serializers.CharField(source='user_b.role', read_only=True)
    last_message = serializers.SerializerMethodField()

    class Meta:
        model = ChatThread
        fields = [
            'id', 'user_a', 'user_b', 'user_a_name', 'user_b_name',
            'user_a_role', 'user_b_role', 'last_message', 'created_at', 'updated_at',
        ]

    def get_user_a_name(self, obj):
        return obj.user_a.name or obj.user_a.username

    def get_user_b_name(self, obj):
        return obj.user_b.name or obj.user_b.username

    def get_last_message(self, obj):
        msg = obj.messages.order_by('-created_at').first()
        if not msg:
            return None
        return AdminChatMessageSerializer(msg).data


class AdminCreateUserSerializer(RegisterSerializer):
    """Staff-only register; village optional for non-patient roles."""

    def validate(self, attrs):
        role = attrs.get('role')
        village = attrs.get('village')
        if role == 'user' and not village:
            raise serializers.ValidationError({'village': 'Village cannot be empty.'})
        return attrs
