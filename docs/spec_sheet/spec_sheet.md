# Specification Sheet: TifliCare Software Platform

## 1. What it does
TifliCare is a digital infant health records platform (0–24 months) designed for the Algerian medical ecosystem:
- **Mobile App (Parents):** Growth tracking (WHO standards), nutritional logs, vaccination schedules, and smart push alerts.
- **AI Assistant Chatbot (Integrated in Mobile App):** Provides real-time pediatric guidance based on WHO guidelines and the national immunization schedule (CNPM), equipped with strict safety guardrails that refuse medical diagnoses and redirect to pediatricians.
- **Web Platform (Medical Staff & Admin):** Secure multi-role dashboard (RBAC) enabling instant QR code patient identification, clinical history management, and vaccine batch tracing.

## 2. Tech Stack & AI Services
- **Frontend:** Flutter (Cross-platform for Mobile & Web).
- **Backend & Database:** Firebase (Firestore real-time sync, Firebase Auth for strict role security).
- **AI & LLM Integration:** LLM API integration with strict System Prompt architecture, short-term conversational memory, and automated safety refusal guardrails.

## 3. Security & Compliance
- Role-Based Access Control (RBAC) separating Admin, Midwives, Doctors, Vaccinators, and Parents.
- Two-Factor Authentication (2FA) for medical professionals.
- Secure account provisioning via unique activation codes (`BABY-XXXX`).
- Ethical AI compliance: Strict adherence to non-diagnostic refusal guardrails for medical safety.
