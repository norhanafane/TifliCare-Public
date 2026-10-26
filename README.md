# 🍼 TifliCare — Digital Infant Health Record Platform & AI Parenting Assistant

---

About the Project
**TifliCare** is an integrated mobile and web platform designed to digitize infant health records (0–24 months) and bridge the communication gap between parents and healthcare professionals. Developed as an advanced software solution, it features a multi-role architecture and a dedicated AI assistant to guide parents based on official health guidelines.

* **Founder & Developer:** AFANE Nourhene Amaria
---

## ⚠️ The Problem
Traditional paper-based infant health record books used in Algeria present critical flaws:
1. **Loss & Damage:** Books get easily lost, torn, or ruined, destroying vital medical histories, especially during emergency situations.
2. **Medical Fragmentation:** Total isolation between private pediatricians, general practitioners, and hospital emergency staff.
3. **Zero Automated Reminders:** No built-in notification system for mandatory vaccines or periodic developmental check-ups.

---

## ✨ The TifliCare Solution & Core Features
TifliCare provides a secure, role-based digital ecosystem divided into a mobile app for families and a web platform for medical staff:

* **🔐 4-Level Role-Based Access Control (RBAC):** Secure separation of dashboards for **Parents**, **Pediatricians**, **Midwives/Neonatologists**, and **Vaccinators**.
* **📊 Growth & Anthropometric Tracking:** Digital charts for weight, height, head circumference, and BMI, aligned with **WHO Child Growth Standards (2006)** with automated warning alerts.
* **💉 National Vaccination Schedule:** Complete tracking of the Algerian immunization calendar (CNPM 2022) with automated push notifications (J-7 / J-1 alerts).
* **🍼 Nutritional & Care Guide:** Age-appropriate nutritional milestones and daily tracking modules.
* **🤖 AI Parenting Assistant (New Feature):** An integrated AI chatbot designed to support parents in real-time. It answers childcare queries, guides nutrition according to the baby's exact age, and references official **WHO standards** to ensure reliable, safe parental guidance.
* **⚡ Instant QR Code Access:** Generates a secure unique QR code per infant, allowing medical staff to instantly pull up complete medical histories in seconds during consultations.

---

## 📱 Tech Stack & Architecture

* **Mobile App:** Flutter (Cross-platform Android / iOS)
* **Web Platform:** Responsive web interface for doctors and medical personnel
* **Backend & Cloud Infrastructure:** Firebase (Firebase Authentication for RBAC security, Cloud Firestore for real-time data sync, and Cloud Storage)
* **AI Integration:** LLM-powered conversational agent tuned for pediatric nutritional and health guidelines.

---

## 📂 Repository Structure
* `/docs` : System architecture diagrams and workflow documentation.
* `/screenshots` : User interface captures of the Flutter mobile app and medical web dashboards.
* `README.md` : Comprehensive technical and functional project overview.
* `lib` : source code of the project

