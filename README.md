# FaceAttend — AI-Powered Face Recognition Attendance System

<div align="center">

**A robust, high-performance attendance management platform built with a distributed Edge-to-Cloud architecture.**  
Designed for enterprise and institutional scalability.

[![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B?logo=flutter)](https://flutter.dev)
[![AWS](https://img.shields.io/badge/AWS-Rekognition%20%7C%20Lambda%20%7C%20DynamoDB-FF9900?logo=amazonaws)](https://aws.amazon.com)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Academic-green)](.)

</div>

---

## Project Status: COMPLETED

This repository contains the finalized core implementation for the Face Recognition Attendance System (MCA Capstone). All core modules (Edge Face Detection, AWS Cloud Verification, and Real-Time Dashboard) have been successfully integrated, rigorously evaluated, and deployed to a production-ready state.

---

## Project Overview

Attendify is a dual-application, distributed attendance management ecosystem that utilizes advanced computer vision and machine learning (AWS Rekognition / Google ML Kit) to automate identity verification. It provides a touchless, high-accuracy alternative to traditional proxy-vulnerable systems like RFID or manual registers.

- **Kiosk Application**: A physical, edge-deployed scanning terminal that auto-detects and verifies identities securely in under two seconds.
- **Administrative Dashboard**: A centralized, real-time web portal for administrators to monitor telemetry, evaluate attendance distribution, and manage identity databases.

---

## Core Specifications

### Physical Kiosk System (Edge Application)
| Specification | Implementation Details |
|---|---|
| Edge Detection | Local processing utilizing Google ML Kit Vision API reduces unnecessary cloud payloads. |
| Temporal Lock-in | Custom debounce logic requiring 2 seconds of spatial stability before triggering capture. |
| Privacy Assurance | In-memory frame processing; biometric images are discarded immediately post-transmission. |
| Duplicate Prevention | Stateful logic intercepts consecutive identical scans, preventing redundant log entries. |
| System Resilience | Automatic recovery capabilities and cooldown thresholds counter rapid scanning abuse. |

### Administrative Dashboard (Web Portal)
| Specification | Implementation Details |
|---|---|
| Analytics Engine | Four-dimensional real-time reporting (Overview, Distribution, Performace, Activity). |
| Event Auditing | Synchronous updates from DynamoDB provide millisecond-accurate check-in tracking. |
| Identity Management | Secure interfaces for biometric template enrollment and record removal. |
| Access Control | AWS Cognito integration ensures multi-factor authenticated administrator access. |

---

## System Architecture

```text
┌──────────────────────────────────────────────────────────────────────┐
│                        EDGE LAYER (Kiosk App)                        │
│                                                                      │
│    Camera → ML Kit Inference → Temporal Lock → Frame Pre-processing  │
│           ↓ (Base64 Translation, Local Memory Cleared)               │
└──────────────────────────┬───────────────────────────────────────────┘
                           │ HTTPS / TLS Enforced
┌──────────────────────────▼───────────────────────────────────────────┐
│                       CLOUD INFRASTRUCTURE (AWS)                     │
│                                                                      │
│  API Gateway ──► Lambda (Authentication / Routing)                   │
│                      ├──► AWS Rekognition (Biometric Comparison)     │
│                      ├──► AWS S3 (Encrypted Isometric Templates)     │
│                      └──► DynamoDB (Atomic Audit Logs)               │
│                                                                      │
└──────────────────────────┬───────────────────────────────────────────┘
                           │ HTTPS / REST
┌──────────────────────────▼───────────────────────────────────────────┐
│                   PRESENTATION LAYER (Dashboard App)                 │
│                                                                      │
│   Flutter Web → BLoC State Management → Aggregated Data Pipelines    │
│                             ↓                                        │
│            Real-time Telemetry, Metric Strips, Activity Logs         │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```text
FaceAttend-Flutter/
├── dashboard_app/             # Administrative Web Portal
│   └── lib/features/
│       ├── auth/              # Cognito Identity management
│       └── dashboard/         # Analytics layer, BLoC logic, API models
│
├── kiosk_app/                 # Edge Scanning Terminal
│   └── lib/features/
│       ├── auth/              # Terminal authentication
│       └── attendance/        # Camera controllers, ML Kit integration
│
└── scripts/                   # Evaluation & Utility Scripts
    ├── generate_performance_graphs.py  # Render telemetry via matplotlib
    ├── brute_force_login.py            # Security & penetration testing
    └── cors_proxy.py                   # Custom HTTP relay
```

---

## Technology Stack

| Architecture Layer | Framework / Service |
|---|---|
| **Frontend Framework** | Flutter 3.7+ (Dart 3.x) |
| **State Management** | BLoC (Business Logic Component) Pattern |
| **Edge Computer Vision** | Google ML Kit |
| **Cloud Compute** | AWS Lambda Serverless (Python 3.11) |
| **Biometric Engine** | AWS Rekognition |
| **NoSQL Datastore** | Amazon DynamoDB |
| **Identity Management** | Amazon Cognito |
| **Data Visualization** | fl_chart |

---

## Deployment Configuration

### Base Dependencies
- **Flutter SDK**: `^3.7.0` (Stable branch)
- **Local Toolchain**: Android SDK 36 (required for camera abstraction layers)
- **Environment**: Configured AWS Infrastructure (API Gateway, IAM Roles, Rekognition Collections)

### Environment Variable Injectors
A `.env` schema must be established at the root of both `dashboard_app/` and `kiosk_app/`:

```env
API_BASE_URL=https://[api-gateway-id].execute-api.ap-south-1.amazonaws.com/default
AWS_REGION=ap-south-1
COGNITO_USER_POOL_ID=ap-south-1_XXXXXXXXX
COGNITO_CLIENT_ID=XXXXXXXXXXXXXXXXXXXXXXXX
```
*Note: `.env` files are strategically ignored by version control to prevent credential exposure.*

### Initializing the Software Build
```bash
# Dashboard Web Artifacts
cd dashboard_app
flutter pub get
flutter run -d chrome --web-port=62972

# Kiosk Native Artifacts
cd ../kiosk_app
flutter pub get
flutter run
```

---

## Performance Evaluation Summarization

During the Week 8 metrics assessment, the system demonstrated exceptional stability in controlled environments:

| Evaluation Metric | Observed Result |
|---|---|
| **Local Inference Latency** | 220 - 280 milliseconds |
| **Cloud Verification Round-Trip** | 1.6 - 2.1 seconds |
| **Telemetry Sync Latency** | < 500 milliseconds |
| **Database Consistency** | Strong Read/Write consistency achieved |
| **System Reliability Bound** | 99.8% process uptime over 4-hour stress tests |

---

## Security Compliance

- **Transit Encryption**: All API interactions enforce strict HTTPS/TLS protocols.
- **Data Minimization**: High-resolution face captures exist strictly in volatile memory and are purged pre-transmission.
- **Least Privilege Access**: AWS IAM policies restrict Lambda operations exclusively to target resources.
- **Secret Management**: Execution tokens and gateway paths are segregated from source control.

---

## Author Declaration

**Sakshi Diggikar**  
MCA Candidate — Dr. D.Y. Patil International University (DYPIU)  
Capstone Master Project — 2025–2026

*Engineered with comprehensive emphasis on structural integrity, scalability, and biometric privacy.*
