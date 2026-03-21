import os
import django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from apps.patients.models import Patient
import traceback

try:
    patient = Patient.objects.first()
    if not patient:
        print("No patient to test")
    else:
        from apps.health_records.models import HealthRecord
        from apps.alerts.models import AlertNotification
        from apps.asha_workers.models import ASHAWorker
        
        request_data = {
            'patient_id': patient.id,
            'temperature': '100',
            'blood_pressure': '120/80',
            'blood_sugar': '113',
            'weight': '42',
            'symptoms': 'Always forget everything...',
            'notify_doctor': True
        }
        notify_doctor = True
        risk_level = 'highRisk'
        record = HealthRecord.objects.create(
            patient=patient,
            temperature=request_data.get('temperature'),
            blood_pressure=request_data.get('blood_pressure'),
            blood_sugar=request.data.get('blood_sugar'),
            weight=request.data.get('weight'),
            symptoms=request_data.get('symptoms'),
            risk_level=risk_level
        )
        print("Created record", record.id)
        
        asha = ASHAWorker.objects.first()
        if asha:
            AlertNotification.objects.create(
                patient=patient.user,
                asha_worker=asha,
                disease=request_data.get('symptoms') or "Vital Warning via Update Health",
                severity=risk_level
            )
            print("Created alert")
except Exception as e:
    traceback.print_exc()
