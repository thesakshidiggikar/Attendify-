# 🎓 Attendify — AI-Powered Face Recognition Attendance System

<div align="center">

**A complete, production-ready attendance management platform built with Flutter & AWS.**  
Designed for institutions. Powered by AI. Deployed at the edge.

[![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B?logo=flutter)](https://flutter.dev)
[![AWS](https://img.shields.io/badge/AWS-Rekognition%20%7C%20Lambda%20%7C%20DynamoDB-FF9900?logo=amazonaws)](https://aws.amazon.com)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Academic-green)](.)

</div>

---

## 🚀 What is Attendify?

Attendify is a **dual-app, cloud-connected attendance system** that uses AI face recognition to automate student attendance — no ID cards, no manual rolls, no friction.

- 📸 **Kiosk App** — A physical scanning station that auto-detects and verifies student faces in **~2 seconds**
- 🖥️ **Dashboard App** — A real-time web portal for administrators to track, manage, and analyze attendance

---

## ✨ Key Features

### 🔷 Kiosk App (Physical Attendance Terminal)
| Feature | Details |
|---|---|
| 🎯 Face Detection | On-device via Google ML Kit — no internet needed for detection |
| ⚡ 2-Second Scan | Face held stable for 2 seconds triggers automatic capture |
| 🔐 Privacy-First | Captured images are sent to AWS and **immediately deleted** from device |
| 🔁 Duplicate Prevention | "Already Marked" overlay shown if student re-scans |
| 📋 Live Log | Today's attendance list visible on the right side of the kiosk |
| ⏸️ Pause / Resume | Admin can pause the system at any time |
| 🖥️ Responsive | Adapts to all screen sizes (mobile, tablet, desktop) |

### 🔷 Admin Dashboard (Web Portal)
| Feature | Details |
|---|---|
| 📊 4-Tab Analytics | Overview, Graphs, Distribution, Activity Log — all real-time |
| 👥 Student Management | Register, view, search, and delete students |
| ✅ Manual Attendance | Mark attendance manually for any student |
| 🔄 Auto-Refresh | Syncs with Kiosk every 30 seconds automatically |
| 🔃 Manual Sync | One-click refresh button in the header |
| 🔑 Secure Login | Enter key + button click supported for smooth login |
| 📱 Responsive Layout | Works on all screen sizes with adaptive grids |

---

## 🏗️ System Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        EDGE LAYER (Kiosk App)                        │
│                                                                      │
│   📷 Camera → ML Kit Detection → 2s Scan → Image Capture            │
│           ↓ (base64 encode, temp file deleted)                       │
└──────────────────────────┬───────────────────────────────────────────┘
                           │ HTTPS / REST
┌──────────────────────────▼───────────────────────────────────────────┐
│                       CLOUD BACKEND (AWS)                            │
│                                                                      │
│  API Gateway ──► Lambda (mark_attendance)                            │
│                      ├──► AWS Rekognition (Face Match)               │
│                      └──► DynamoDB (Attendance Record)               │
│                                                                      │
│  API Gateway ──► Lambda (get-all-employees, attendance-stats,        │
│                          recent-attendance, manual-attendance)       │
└──────────────────────────┬───────────────────────────────────────────┘
                           │ HTTPS / REST
┌──────────────────────────▼───────────────────────────────────────────┐
│                   MANAGEMENT LAYER (Dashboard App)                   │
│                                                                      │
│   Flutter Web → BLoC → Cross-reference Employees + Attendance        │
│                             ↓                                        │
│            Real-time Analytics, Charts, Activity Log                 │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
FaceAttend-Flutter/
├── 📂 dashboard_app/          # Admin Web Dashboard
│   └── lib/features/
│       ├── auth/              # Login, Cognito integration
│       └── dashboard/
│           ├── data/          # API calls, models
│           ├── domain/        # Entities, repo interfaces
│           └── presentation/  # BLoC, Pages, Widgets
│
└── 📂 kiosk_app/             # Physical Kiosk Terminal
    └── lib/features/
        ├── auth/              # Machine authentication
        └── attendance/
            ├── data/          # API calls, data sources
            └── presentation/  # Camera, face detection, UI
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter 3.7+ (Dart) |
| **State Management** | BLoC Pattern (flutter_bloc) |
| **Face Detection** | Google ML Kit |
| **Cloud Compute** | AWS Lambda (Python) |
| **Face Recognition** | AWS Rekognition |
| **Database** | AWS DynamoDB |
| **Authentication** | AWS Cognito |
| **API** | AWS API Gateway (REST) |
| **Charts** | fl_chart ^0.70.0 |

---

## ⚙️ Installation & Setup

### Prerequisites
- **Flutter SDK** `^3.7.0` (Stable channel)
- **Android Studio** with Android SDK (for Kiosk on Android)
- **Chrome** (for Dashboard web app)
- **AWS Account** — API Gateway, Rekognition, DynamoDB, Cognito configured

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/thesakshidiggikar/Attendify-.git
cd Attendify-
```

### 2️⃣ Environment Configuration
Create a `.env` file inside **both** `dashboard_app/` and `kiosk_app/`:

```env
API_BASE_URL=https://[your-api-gateway-id].execute-api.ap-south-1.amazonaws.com/default
AWS_REGION=ap-south-1
COGNITO_USER_POOL_ID=ap-south-1_XXXXXXXXX
COGNITO_CLIENT_ID=XXXXXXXXXXXXXXXXXXXXXXXX
```

> ⚠️ Never commit `.env` files. They are already excluded in `.gitignore`.

### 3️⃣ Install Dependencies
```bash
# Dashboard App
cd dashboard_app && flutter pub get

# Kiosk App
cd ../kiosk_app && flutter pub get
```

### 4️⃣ Run the Apps

**Dashboard (Web):**
```bash
cd dashboard_app
flutter run -d chrome --web-port=62972
```

**Kiosk App (Windows Desktop):**
```bash
cd kiosk_app
flutter run -d windows
```

**Kiosk App (Android):**
```bash
cd kiosk_app
flutter run  # Select your connected device
```

---

## 📊 System Performance (Test Results)

| Metric | Result |
|---|---|
| ⚡ Face Detection Time | ~2 seconds |
| ✅ Attendance Accuracy | High (tested in good indoor lighting) |
| 🔄 Dashboard Sync Delay | ≤ 30 seconds (auto-refresh) |
| 📱 Device Support | Android, Windows, Web (Chrome) |
| 🗄️ Local File Storage | None — images deleted after AWS upload |

---

## 🔒 Security & Privacy

- 🔐 All API calls are over **HTTPS / TLS**
- 🧹 Face images are **never stored on device** — deleted immediately after AWS recognition
- 🛡️ AWS IAM roles restrict Lambda function permissions
- 🔑 Admin authentication via **AWS Cognito**
- 📵 `.env` secrets are excluded from version control

---

## 🎯 Use Cases

- 🏫 **Universities & Colleges** — Automated student attendance for lectures
- 🏢 **Offices** — Touchless employee check-in
- 🏋️ **Gyms / Events** — Fast member/attendee verification

---

## 👩‍💻 Author

**Sakshi Diggikar**  
MCA Student — DYPIU (Dr. D.Y. Patil International University)  
Capstone Project — 2025–2026

---

<div align="center">

*Designed for security. Engineered for scale. Built with Flutter & AWS.*

</div>
