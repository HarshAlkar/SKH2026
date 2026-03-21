import requests
import json

BASE_URL = "http://127.0.0.1:8000/api"

def print_step(msg):
    with open('log.txt', 'a', encoding='utf-8') as f:
        f.write(f"\n[{'='*50}]\n--- {msg} ---\n")
        
def log(msg):
    with open('log.txt', 'a', encoding='utf-8') as f:
        f.write(msg + '\n')

def run_simulation():
    # 1. Register Patient
    print_step("Step 1: Patient Registers")
    patient_data = {
        "phone_number": "1111111111",
        "password": "password123",
        "role": "user",
        "name": "Ramu (Simulated Patient)",
        "village": "VitalReach Village"
    }
    r_patient = requests.post(f"{BASE_URL}/users/register/", json=patient_data)
    if r_patient.status_code == 400 and "already registered" in r_patient.text:
        r_patient = requests.post(f"{BASE_URL}/users/login/", json=patient_data)
        
    patient_token = r_patient.json()['token']
    patient_id = r_patient.json()['user']['id']
    log(f"Patient created. Token: {patient_token}")

    # 2. Register ASHA Worker
    print_step("Step 2: ASHA Worker Registers for same village")
    asha_data = {
        "phone_number": "2222222222",
        "password": "password123",
        "role": "asha_worker",
        "name": "Sita Devi (ASHA)",
        "village": "VitalReach Village",
        "assigned_village": "VitalReach Village"
    }
    r_asha = requests.post(f"{BASE_URL}/users/register/", json=asha_data)
    if r_asha.status_code == 400 and "already registered" in r_asha.text:
        r_asha = requests.post(f"{BASE_URL}/users/login/", json=asha_data)
        
    asha_token = r_asha.json()['token']
    log(f"ASHA Worker created. Token: {asha_token}")

    # 3. Register Doctor
    print_step("Step 3: Doctor Registers")
    doctor_data = {
        "phone_number": "3333333333",
        "password": "password123",
        "role": "doctor",
        "name": "Dr. Sharma",
        "village": "City Center",
        "specialization": "General Physician"
    }
    r_doctor = requests.post(f"{BASE_URL}/users/register/", json=doctor_data)
    if r_doctor.status_code == 400 and "already registered" in r_doctor.text:
        r_doctor = requests.post(f"{BASE_URL}/users/login/", json=doctor_data)
        
    doctor_token = r_doctor.json()['token']
    doctor_profile_id = r_doctor.json()['user']['id']
    log(f"Doctor created. Token: {doctor_token}")

    # 4. ASHA Creates Health Record for Patient
    print_step("Step 4: ASHA Creates Health Record for Patient")
    record_data = {
        "patient_id": patient_id,
        "temperature": "102F",
        "blood_pressure": "140/90",
        "symptoms": "High fever, dizziness",
        "notify_doctor": True
    }
    headers_asha = {"Authorization": f"Token {asha_token}"}
    r_record = requests.post(f"{BASE_URL}/records/", json=record_data, headers=headers_asha)
    log(f"Health Record Response: {r_record.json()}")

    # 5. ASHA Starts Consultation with Doctor
    print_step("Step 5: ASHA Schedules Consultation on behalf of Patient")
    consult_data = {
        "patient_id": patient_id,
        "doctor_user_id": doctor_profile_id,
        "call_type": "video"
    }
    r_consult = requests.post(f"{BASE_URL}/consultations/start/", json=consult_data, headers=headers_asha)
    if r_consult.status_code == 201:
        consultation_id = r_consult.json()['id']
        log(f"Consultation Scheduled! ID: {consultation_id}")
    else:
        log(f"Failed: {r_consult.text}")
        return

    # 6. Doctor Issues Prescription
    print_step("Step 6: Doctor Reviews Consultation & Issues Prescription")
    rx_data = {
        "consultation": consultation_id,
        "patient": patient_id,
        "diagnosis": "Viral Fever",
        "medicines": [
            {
                "name": "Paracetamol 500mg",
                "dosage": "1 tablet",
                "frequency": "Twice a day",
                "duration_days": 3,
                "instructions": "After food"
            }
        ],
        "notes": "Rest for 3 days and drink plenty of fluids."
    }
    headers_doc = {"Authorization": f"Token {doctor_token}"}
    r_rx = requests.post(f"{BASE_URL}/prescriptions/", json=rx_data, headers=headers_doc)
    log(f"Prescription Created Response: {r_rx.status_code} - {r_rx.text[:300]}")

    # 7. Patient Checks Prescriptions
    print_step("Step 7: Patient Views Their Prescriptions")
    headers_patient = {"Authorization": f"Token {patient_token}"}
    r_patient_rx = requests.get(f"{BASE_URL}/prescriptions/user/", headers=headers_patient)
    log(f"Patient's Prescriptions: {json.dumps(r_patient_rx.json(), indent=2)}")

    print_step("SUCCESS! The Data Flow Simulation Completed End-to-End.")

if __name__ == "__main__":
    import traceback
    try:
        run_simulation()
    except Exception as e:
        log(f"CRASHED: {e}\n{traceback.format_exc()}")
