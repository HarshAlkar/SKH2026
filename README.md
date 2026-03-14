# hs053 - Full-Stack Healthcare Platform

This repository contains a comprehensive healthcare ecosystem spanning mobile, web, backend, and AI.

## Architecture Overview

- **`mobile_app/`**: Flutter-based mobile application for Patients and ASHA workers. Supports offline-first data management with SQLite.
- **`backend/django_api/`**: Django REST Framework backend handling authentication, user management, and medical records.
- **`ai_engine/`**: Python-based AI service for symptom-to-disease prediction using Random Forest.
- **`web_admin/react_dashboard/`**: React-based administrative dashboard for monitoring consultations, managing doctors/workers, and viewing analytics.
- **`realtime_server/node_signaling_server/`**: Node.js + Socket.io server for WebRTC signaling and real-time consultation coordination.

## Getting Started

### Backend
1. `cd backend/django_api`
2. `python -m venv venv && source venv/bin/activate`
3. `pip install -r requirements.txt`
4. `python manage.py migrate`
5. `python manage.py runserver`

### Mobile App
1. `cd mobile_app`
2. `flutter pub get`
3. `flutter run`

### Web Admin
1. `cd web_admin/react_dashboard`
2. `npm install`
3. `npm run dev`

### Realtime Server
1. `cd realtime_server/node_signaling_server`
2. `npm install`
3. `node server.js`

### AI Engine
1. `cd ai_engine/services`
2. `python train_model.py` (to generate the model)

## Telemedicine Flow
1. Patient initiate video call in **Flutter App**.
2. **Node.js Signaling Server** facilitates Peer-to-Peer connection.
3. Doctor accepts call via **Flutter App** or **Web Admin**.
4. Secure WebRTC connection established for video/audio.

## Security
See [SECURITY.md](SECURITY.md) for detailed information on how we protect patient data and user identity.
