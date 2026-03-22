# FaceAttend: AI-Powered Attendance Management System

FaceAttend is a comprehensive attendance management solution leveraging facial recognition for seamless, secure, and automated attendance tracking. This project consists of two primary Flutter applications: a **Dashboard** for administrators and an **Attendance Kiosk** for students/employees.

---

## 📂 Project Structure

```text
FaceAttend-Flutter/
├── dashboard_app/             # Admin & Management Portal (Flutter Web)
│   ├── lib/
│   │   ├── core/              # Constants, Theme, UI Utils
│   │   ├── features/          # Feature-based modular architecture (BLoC)
│   │   │   ├── auth/          # Authentication & Role Management
│   │   │   └── dashboard/     # Employee management, Stats & Analytics
│   │   └── di/                # Dependency Injection (GetIt)
│   └── web/                   # Web-specific configurations
├── kiosk_app/                 # Attendance Entry Portal (Flutter Web/Tablet)
│   ├── lib/
│   │   ├── features/
│   │   │   ├── attendance/    # Facial Recognition & Attendance Submission
│   │   │   └── auth/          # Student/Employee Portal Login
│   │   └── shared/            # Shared UI components
├── scripts/                   # Python utility & test scripts
└── RUN_INSTRUCTIONS.md        # Detailed setup and run guide
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Git**: [Install Git](https://git-scm.com/downloads)
- **Environment Variables**: Ensure you have a `.env` file in both `dashboard_app/` and `kiosk_app/` with the required `API_BASE_URL`.

### Installation

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/the-shreyashmaurya/FaceAttend-Flutter.git
    cd FaceAttend-Flutter
    ```

2.  **Environment Setup**:
    *Copies of `.env.example` should be renamed to `.env` and populated with your AWS API endpoint.*

---

## 🛠 Running the Applications

### 1. Dashboard Portal
Used for managing employees, viewing analytics, and monitoring real-time attendance.

```powershell
cd dashboard_app
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

### 2. Kiosk App
Used by students/employees to mark their attendance via facial recognition.

```powershell
cd kiosk_app
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

> **Note**: For development, the default credentials are `admin` / `admin`.

---

## 🧪 Testing & Debugging

We have included several Python scripts in the root directory for testing individual API endpoints:
- `test_stats.py`: Verifies today's attendance counts.
- `test_login.py`: Tests the authentication service.
- `test_get_employees.py`: Fetches the current employee database.

---

## 📝 Recent Improvements

- **Real-time Stats**: Connected dashboard cards directly to AWS Lambda attendance analytics.
- **Dynamic UI**: Integrated `AuthBloc` to display actual user names and roles across the app.
- **Robust Parsing**: Enhanced data handling for numeric attendance counts from the backend.
- **Security Bypass**: Implemented BLoC-level bypass for testing in environments with restricted API access.

---

## 👨‍💻 Contributors
Developed for **D.Y. Patil International University (DYPIU)** projects.
