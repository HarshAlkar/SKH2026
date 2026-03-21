import requests
try:
    r = requests.get('http://localhost:8000/api/users/patients/')
    print(r.json()[:2])
except Exception as e:
    print(e)
