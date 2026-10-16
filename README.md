# PothikSathi (পথিকসাথী)
**Lightweight Local Mobility & Bus Timetable Platform for Karimpur, Nadia, West Bengal**

---

## Quick Navigation

- **Mobile Application**: [mobile_app/](mobile_app/) (Flutter Android-First single codebase, dual role)
- **Admin Portal**: [admin_web/](admin_web/) (React + TypeScript dispatch & management console)
- **Firebase Backend**: [backend/](backend/) (Firestore rules, compound indexes, cloud functions, seed data)
- **Technical Documentation**:
  - [System Architecture](docs/ARCHITECTURE.md)
  - [Firestore Schema & Security](docs/FIREBASE_SCHEMA.md)
  - [Fare Engine Specification](docs/FARE_ENGINE.md)
  - [Deployment & Operating Costs](docs/DEPLOYMENT_AND_COSTS.md)

---

## 1. What is PothikSathi?

PothikSathi is a low-cost, low-bandwidth, Android-first mobility solution tailored for rural and semi-urban Bengal, launching initially in Karimpur (Nadia, PIN 741152).

### Key Features
1. **TOTO (E-Rickshaw) Booking**:
   - **Shared Ride**: Fixed ₹10/seat on verified Karimpur municipal routes (Karimpur Bus Stand ↔ Pannadevi College, Rural Hospital, Regulated Market). Max 4 passengers. Zero surge pricing.
   - **Private Reserve**: Whole-vehicle booking with a ₹20 minimum floor.
2. **Bus Timetable Hub**:
   - Public schedules from Karimpur Bus Stand to Krishnanagar, Kolkata (Esplanade), Berhampore, and Malda.
   - Offline-first cached view with clear visual indicators if data is dated.
   - Administrator verification date stamps.
3. **Manual Dispatch Console**:
   - Dispatch desk manually assigns incoming requests to available, approved, online drivers.
4. **Driver KYC & Security Guard**:
   - Drivers cannot self-approve or alter confirmed fares. Accounts remain pending until reviewed by the Karimpur administrator.

---

## 2. Running Automated Tests

A comprehensive Python test suite validates all core domain logic, fare calculations, capacity bounds, and state machine transitions:

```bash
python scripts/run_all_tests.py
```

### Running Flutter Unit Tests
```bash
cd mobile_app
flutter test
```

### Running Admin Portal
```bash
cd admin_web
npm install
npm run dev
```

---

## 3. Demo Roles & Instant Login

The mobile app includes convenient one-tap demo profiles on the login screen:
- **Passenger**: `9876543210` (Sourav Biswas)
- **Approved Driver**: `9800012345 (driver)` (Bapi Mondal, TOTO `WB-52-TOTO-8812`)
- **Pending Driver**: `9800099999 (pending)` (Ratan Das, application under review)
