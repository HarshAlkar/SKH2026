import requests
import json

url = "http://127.0.0.1:8000/api/records/"

# We need a token or we can just send it and see if we get 401 JSON or 500 HTML
payload = {
    'patient_id': '1', # Needs to be valid ID but doesn't matter, we want the crash
    'temperature': '100',
    'blood_pressure': '120/80',
    'blood_sugar': '113',
    'weight': '42',
    'symptoms': 'Always forget everything...',
    'notify_doctor': True
}
headers = {'Content-Type': 'application/json'}

try:
    response = requests.post(url, data=json.dumps(payload), headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Content: {response.text[:1000]}")
except Exception as e:
    print(f"Request failed: {e}")
