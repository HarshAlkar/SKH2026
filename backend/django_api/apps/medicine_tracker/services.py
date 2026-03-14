from .models import MedicineReminder

class MedicineService:
    @staticmethod
    def get_patient_medicines(patient):
        return MedicineReminder.objects.filter(patient=patient)

    @staticmethod
    def create_reminder(patient, data):
        return MedicineReminder.objects.create(patient=patient, **data)

    @staticmethod
    def toggle_taken_status(reminder_id):
        reminder = MedicineReminder.objects.get(id=reminder_id)
        reminder.is_taken = not reminder.is_taken
        reminder.save()
        return reminder
