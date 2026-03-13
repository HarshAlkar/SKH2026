# Gramin Health Connect - Project Structure

This document provides an overview of the directory structure and organization of the **Gramin Health Connect** Flutter application.

## Directory Hierarchy

```text
hs053/
├── android/                  # Android-specific native code and configurations
├── assets/                   # Static assets like images, fonts, and icons
│   └── images/               # App-specific images (logos, banners, icons)
├── ios/                      # iOS-specific native code and configurations
├── lib/                      # Core Flutter application source code
│   ├── core/                 # Shared utilities, services, and theme configurations
│   │   ├── constants/        # App-wide constants (strings, dimensions)
│   │   ├── network/          # API clients and network-related logic
│   │   ├── services/         # Background services (location, storage)
│   │   ├── theme/            # App colors, typography, and theme data
│   │   └── utils/            # Helper functions and extensions
│   ├── dataset/              # Local datasets or mock data for offline support
│   ├── features/             # Feature-based modules (Vertical Slices)
│   │   ├── ai_symptom_checker/ # AI-driven symptom analysis
│   │   ├── alerts/           # Notification and alert systems
│   │   ├── asha_worker/      # ASHA worker specific dashboard and workflows
│   │   ├── auth/             # Authentication screens (Login, Register, Role Selection)
│   │   ├── doctor/           # Doctor specific dashboard and medical tools
│   │   ├── health_records/   # Digital health record management
│   │   ├── patient/          # Patient profile and management features
│   │   ├── reports/          # Health analytics and report generation
│   │   ├── user/             # Core USER features (Dashboard, Medicine Tracker, Emergency)
│   │   ├── video_call/       # Tele-consultation features
│   │   └── visits/           # Field visit tracking and scheduling
│   ├── localization/         # Internationalization and translation files
│   ├── models/               # Data models for JSON serialization/deserialization
│   ├── providers/            # State management using Provider pattern
│   ├── routes/               # Navigation and routing configurations
│   ├── widgets/              # Library of reusable UI components (Buttons, Inputs)
│   ├── app.dart              # Root application widget and config
│   └── main.dart             # Application entry point
├── test/                     # Unit, widget, and integration tests
├── pubspec.yaml              # Package dependencies and project metadata
└── README.md                 # Project introduction and setup instructions
```

## Key Directories Explained

### `lib/features/`
Following a **Feature-First** architecture. Each subdirectory represents a standalone feature or a user role within the ecosystem. This makes the app highly modular and easier to scale.
- **`user/`**: Contains screens for the general patient/user, including the `UserDashboardScreen` and `EmergencyHelpScreen`.
- **`asha_worker/`**: Specialized tools for local health volunteers.

### `lib/core/`
Contains the "engine" of the app. If a piece of code is used by more than one feature (like a custom theme or a date formatter), it belongs here.

### `lib/providers/`
The business logic layer. Providers handle data fetching and notify the UI of state changes, ensuring a clean separation between UI and Logic.

### `lib/models/`
Plain Old Dart Objects (PODOs) that represent the structure of our data. Used for type-safe interactions with APIs and local databases.

---
*Created on: 2026-03-13*
