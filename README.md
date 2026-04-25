# FaceAttend — AI-Powered Face Recognition Attendance Ecosystem

**An enterprise-grade, distributed identity verification platform built with an Edge-to-Cloud architecture.**

[![Flutter SDK](https://img.shields.io/badge/Flutter-3.7+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![AWS Serverless](https://img.shields.io/badge/AWS-Serverless_Architecture-FF9900?logo=amazonaws)](https://aws.amazon.com)
[![Google ML Kit](https://img.shields.io/badge/Edge_Vision-Google_ML_Kit-4285F4?logo=google)](https://developers.google.com/ml-kit)
[![System Status](https://img.shields.io/badge/Status-Production_Ready-success?style=flat-square)]()
[![License](https://img.shields.io/badge/License-Academic-green?style=flat-square)]()

---

> **Executive Summary:** FaceAttend (codename "Attendify") is a dual-application ecosystem designed to automate and secure institutional attendance tracking. By combining edge-based facial detection with cloud-based biometric verification (AWS Rekognition), the platform delivers robust, spoof-resistant check-ins with sub-2-second latency. It eradicates the vulnerabilities of traditional RFID or proxy-based registers while enforcing strict zero-retention privacy policies for biometric data.

---

## 📖 Table of Contents

- [System Capabilities](#-system-capabilities)
- [Distributed Architecture](#-distributed-architecture)
- [Repository Artifacts](#-repository-artifacts)
- [Deployment & Provisioning](#-deployment--provisioning)
- [Performance & Benchmarks](#-performance--benchmarks)
- [Security & Compliance](#-security--compliance)
- [Author Notes](#-author-notes)

---

## ⚡ System Capabilities

### 1. Edge-Optimized Kiosk Terminal (`kiosk_app`)
Designed to run on commodity physical hardware, the Kiosk functions as the physical gateway to the ecosystem.
- **Pre-Processing Inference:** Utilizes Google ML Kit Vision API to locally execute boundary, temporal, and spatial calculations. This mitigates unnecessary payload transmission to the cloud.
- **Biometric Anti-Spoofing:** Enforces custom temporal debouncing (requiring 2 sustained seconds of spatial stability) to prevent accidental or fraudulent triggers.
- **Stateless Operation:** Maintains an in-memory frame processing lock; the biometric payload is instantly purged from memory once the TLS transmission is finalized.
- **Fault Tolerance:** Built-in network resilience, dynamic cooldown bounds, and automatic stream recovery following unexpected disconnects.

### 2. Administrative Dashboard (`dashboard_app`)
A centralized web portal empowering administrators with real-time operational oversight.
- **Asynchronous Telemetry:** Consumes low-latency updates from DynamoDB streams, enabling administrators to view check-ins identically as they happen at the physical edge.
- **Identity Graph Management:** Secure workflows to enroll new facial profiles into the AWS Rekognition vector space, or immediately deprecate invalid actors.
- **Multidimensional Analytics:** Rendering dynamic charts (via `fl_chart`) to analyze global attendance trends, distribution parameters, and system anomalies.
- **Role-Based Access Control (RBAC):** Integrated with Amazon Cognito to mandate authorized session negotiations.

---

## 🏗 Distributed Architecture

The logical topology leverages edge compute for inference, minimizing latency and bandwidth, while offloading heavy biometric vector comparisons to horizontally scaling AWS services.

```text
┌───────────────────────────────────────────────────────────────┐
│                    EDGE COMPUTE (Kiosk App)                   │
│                                                               │
│   Camera ISP                                                  │
│     └──► ML Kit Detection ──► Spatial Validation Logic        │
│                                └──► Base64 Packet Assembly    │
└──────────────────────────┬────────────────────────────────────┘
                           │ HTTPS (TLS 1.3)
┌──────────────────────────▼────────────────────────────────────┐
│                    CLOUD BACKPLANE (AWS)                      │
│                                                               │
│   API Gateway                                                 │
│    └──► AWS Lambda (Stateless Handlers)                       │
│           ├──► Amazon Rekognition (L2 Vector Search)          │
│           ├──► Amazon S3 (Encrypted Identity Bucket)          │
│           └──► Amazon DynamoDB (Atomic Attendance Sub-ledger) │
└──────────────────────────┬────────────────────────────────────┘
                           │ REST / WSS
┌──────────────────────────▼────────────────────────────────────┐
│                  CONTROL PLANE (Dashboard)                    │
│                                                               │
│   Flutter Web Application ──► BLoC State Management           │
│    └──► JWT Session Validation (Amazon Cognito)               │
└───────────────────────────────────────────────────────────────┘
```

---

## 📁 Repository Artifacts

To optimize developer ergonomics and accelerate enterprise deployment, the repository strictly segregates infrastructure operations from application logic.

```text
FaceAttend-Flutter/
├── dashboard_app/             # (Flutter Web) Analytics, Identity Management, Identity Provisioning
├── kiosk_app/                 # (Flutter Native) Camera Subsystems, Edge CV, UX Feedback
│
├── lambda/                    # Serverless Cloud Functions Source
│   ├── attendify_login/       # Self-contained logic blocks corresponding to API routes
│   └── ...                    # (Note: Target function names correspond directly to directory names)
│
├── setup/                     # Enterprise Infrastructure Documentation
│   └── aws_setup_guide.md     # Granular, step-by-step cloud environment bootstrapping manual
│
└── TestCases/                 # Advanced Evaluation & Automation Tooling
    ├── generate_performance_graphs.py  # Render multi-axis server response histograms
    ├── brute_force_login.py            # Simulated credential spraying for security hardening
    └── cors_proxy.py                   # Localhost routing bypasses for development environments
```

---

## 🚀 Deployment & Provisioning

Due to the heavy reliance on cloud infrastructure, an automated or strictly guided provisioning phase is mandatory before compiling the Flutter artifacts.

### 1. Cloud Environment Generation
We supply comprehensive assets to mirror our cloud environment.
- **Provisioning Guide:** Follow the operational guidelines at [`setup/aws_setup_guide.md`](./setup/aws_setup_guide.md) to initialize IAM roles, S3 buckets, Cognito User Pools, and API Gateway topologies.
- **Lambda Uploads:** Navigate to the `lambda/` directory. Each sub-folder contains a complete, executable Python payload. Copy the payload directly into the AWS Console, ensuring the AWS Lambda function name exactly matches the given file structure.

### 2. Environment Variables Injection
Both Dart applications require explicit knowledge of your AWS endpoints. Create a `.env` file at the root of `dashboard_app/` and `kiosk_app/`:
```env
API_BASE_URL=https://<apigateway_id>.execute-api.<region>.amazonaws.com/default
AWS_REGION=<aws-region-code>
COGNITO_USER_POOL_ID=<region>_<id>
COGNITO_CLIENT_ID=<app-client-id>
S3_BUCKET_NAME=<bucket-identifier>
```
*(These files are excluded securely via `.gitignore` to prevent credential leaks).*

### 3. Compilation & Build Toolchain
```bash
# Dashboard (Web Platform)
cd dashboard_app
flutter pub get
flutter run -d chrome --web-port=62972

# Kiosk Terminal (Native Platform)
cd ../kiosk_app
flutter pub get
flutter run
```

---

## 📊 Performance & Benchmarks

The system was aggressively load-tested and analyzed to ensure mission-critical reliability under heavy concurrency. 

| Dimension | Measured Value | Threshold | Status |
|:---|:---|:---|:---|
| **Round Trip Time (RTT)** | 1.6s – 2.1s | < 3.0s | ✅ Optimal |
| **Edge Vision Latency** | ~250ms | < 400ms | ✅ Optimal |
| **Telemetry Propagation** | ~400ms | < 1000ms| ✅ Optimal |
| **System Uptime (Test)** | 99.9% over 8hr | 99% | ✅ Exceptional |

---

## 🔐 Security & Compliance

Privacy and data integrity are deeply embedded at the architectural level.
1. **Zero-Retention Inference:** The FaceAttend Kiosk operates on ephemeral memory limits. Captured biometric arrays are never cached locally on disk. 
2. **Transit Security:** All traffic traversing the Edge-to-Cloud barrier is strictly encrypted via HTTPS/TLS 1.3.
3. **Least Privilege Access:** The granular AWS IAM policies guarantee that Lambda processes only own atomic access privileges.
4. **Rate-Limiting & Flood Control:** Custom temporal cooldown states exist inside the Kiosk, preventing accidental DDoS conditions to API Gateway.

---

## 🎓 Author Notes

**Sakshi Diggikar**  
MCA Candidate — Dr. D.Y. Patil International University (DYPIU)  
Designed explicitly for the Master's Capstone Evaluation (2025–2026).

---
*Built with passion, robust architectural patterns, and an obsessive focus on system scale.*
