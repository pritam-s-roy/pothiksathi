# PothikSathi — System Architecture & Technical Specification

## 1. Executive Summary
PothikSathi (পথিকসাথী) is an ultra-lightweight, resilient local mobility and public transit timetable platform engineered for semi-urban and rural West Bengal, commencing in **Karimpur, Nadia (PIN 741152)**.

The system addresses the unique operational realities of local battery-operated electric rickshaws (TOTOs) and regional bus connectivity:
- Low data bandwidth and poor intermittent connectivity.
- Fixed ₹10/seat passenger tariffs on municipal corridors without sudden surge pricing.
- Controlled whole-vehicle private reserve bookings with a ₹20 minimum floor.
- **Automatic Driver Matching as the default dispatch mode**, sequentially offering rides to the nearest eligible captain with a 30s countdown window, backed by automated cascading.
- **Configurable manual dispatch fallback and admin override** for full operational control.
- Concurrency-safe Firestore transactions preventing double-assignment or race conditions.
- Offline-capable bus timetables connecting Karimpur to Krishnanagar, Kolkata, Berhampore, and Malda.

---

## 2. Automatic Dispatch & System Architecture

```mermaid
flowchart TD
    subgraph MobileApp["Flutter Android Application"]
        P_UI["Passenger UI (Booking, Auto-Match Status)"]
        D_UI["Captain UI (30s Live Offer Banner, Accept/Decline)"]
        LocalCache["SharedPreferences Offline Cache"]
        DomainCore["Domain (FareCalculator, StateMachine)"]
    end

    subgraph AdminPortal["Admin Web Portal (React + TS)"]
        DispatchDesk["Dispatch Console (Auto/Manual Toggle & Audit Log)"]
        DriverKYC["Driver Verification & Approval Desk"]
        TariffDesk["Route & Fare Rate Card Manager"]
        TimetableDesk["Bus Schedule Verification Desk"]
    end

    subgraph FirebaseBackend["Firebase Cloud Infrastructure"]
        Auth["Firebase Auth (Role-based)"]
        Firestore["Cloud Firestore (8 Collections)"]
        Functions["Cloud Functions (Auto-Dispatch Engine & Cascading)"]
        Rules["Airtight Firestore Security Rules"]
    end

    P_UI -->|1. Submit Booking Request| Firestore
    Firestore -->|2. Trigger onBookingCreated| Functions
    Functions -->|3. Query & Rank Approved Online Drivers| Firestore
    Functions -->|4. Offer to Candidate #1 with 30s Timer| Firestore
    Firestore -->|5. Real-time Offer Stream| D_UI
    D_UI -->|6a. Driver Accepts| Functions
    D_UI -->|6b. Driver Rejects / 30s Timeout| Functions
    Functions -->|7. Auto-Cascade to Candidate #2| Firestore
    Functions -->|8. If All Exhausted: Alert Admin Fallback| DispatchDesk
    DispatchDesk -->|9. Manual Admin Override Assignment| Functions
    D_UI -->|10. Milestone Steps: arrived, in_progress, completed| Firestore
    Firestore -->|11. Active Status Stream| P_UI
```

---

## 3. Automatic Dispatch Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor P as Passenger
    participant CF as Cloud Function (Dispatch Engine)
    participant FS as Cloud Firestore
    actor D1 as Candidate Driver 1 (Nearest)
    actor D2 as Candidate Driver 2
    actor Admin as Admin Dispatch Console

    P->>FS: Create booking (pending_assignment)
    FS-->>CF: Trigger triggerAutoDispatch()
    CF->>FS: Rank candidates (Fresh GPS <10m -> Hub -> Rating)
    CF->>FS: Lock Driver 1 (offeredBookingId, 30s timeout)
    FS-->>D1: Live 30s Offer Push / Notification
    alt Driver 1 Accepts within 30s
        D1->>CF: respondToBookingOffer(accepted)
        CF->>FS: Transition to driver_accepted & lock driver
        FS-->>P: Passenger sees driver details & ETA
    else Driver 1 Rejects or 30s Times Out
        D1->>CF: respondToBookingOffer(rejected / timeout)
        CF->>FS: Release Driver 1, record in attemptedDriverIds
        CF->>FS: Cascade: Lock Driver 2 (offeredBookingId, 30s timeout)
        FS-->>D2: Live 30s Offer Push
        alt Driver 2 Accepts
            D2->>CF: respondToBookingOffer(accepted)
            CF->>FS: Transition to driver_accepted
        else Driver 2 Rejects & No Candidates Left
            CF->>FS: Set autoDispatchExhausted = true, assignmentType = manual_fallback
            FS-->>Admin: High-priority Alert in Dispatch Console
            Admin->>CF: assignDriverToBooking(manual override)
            CF->>FS: Status updated to driver_assigned
        end
    end
```

---

## 4. Core Modules & Responsibilities

| Layer | Component | Description |
|---|---|---|
| **Mobile Client** | `mobile_app/lib/presentation/passenger/` | Clean green-and-white booking flow, capacity stepper, fare preview, auto-match progress, active trip status. |
| **Mobile Client** | `mobile_app/lib/presentation/driver/` | Captain dashboard, online/offline toggle, 30s countdown offer banner, accept/decline actions, milestone advancement. |
| **Mobile Client** | `mobile_app/lib/core/services/booking_service.dart` | Client-side auto-dispatch fallback simulator, 30s countdown ticker, cascade handler, real-time sync. |
| **Mobile Client** | `mobile_app/lib/presentation/timetable/` | Offline-first timetable search with verification date stamps and stale cache warning. |
| **Domain Layer** | `mobile_app/lib/domain/fare_calculator.dart` | Fixed ₹10/seat calculator, capacity enforcement (max 4), ₹20 minimum private reserve rule. |
| **Domain Layer** | `mobile_app/lib/domain/booking_state_machine.dart` | Pure state transition guard enforcing actor roles and system dispatch privileges. |
| **Security Layer** | `backend/firestore.rules` | 8-collection access enforcement, preventing self-approval, tariff tampering, and cross-driver data leaks. |
| **Backend Logic** | `backend/functions/src/autoDispatch.ts` | Candidate filtering, Haversine distance ranking (<10m fresh GPS vs hub fallback), offer locks, and cascading logic. |
| **Backend Logic** | `backend/functions/src/index.ts` | Concurrency-safe Cloud Functions: `triggerAutoDispatch`, `respondToBookingOffer`, `assignDriverToBooking`. |
| **Admin Portal** | `admin_web/src/pages/BookingManagementPage.tsx` | Master Auto/Manual toggle, live 30s offer monitor, candidate exhaustion alerts, manual override, and audit trail drawer. |

---

## 5. Milestone-Based Trip State Machine

```mermaid
stateDiagram-v2
    [*] --> pending_assignment: Passenger requests booking
    pending_assignment --> driver_assigned: Auto-match offers candidate or Admin manual dispatch
    pending_assignment --> cancelled_by_passenger: Passenger cancels before assignment
    pending_assignment --> cancelled_by_admin: Admin rejects/cancels request

    driver_assigned --> driver_accepted: Driver accepts offer (within 30s)
    driver_assigned --> driver_rejected: Driver declines or 30s times out
    driver_rejected --> pending_assignment: Engine cascades to candidate #2 or alerts manual fallback

    driver_accepted --> driver_arrived: Driver reaches pickup location
    driver_arrived --> in_progress: Driver confirms passenger boarding
    in_progress --> completed: Driver completes trip & collects cash
    completed --> [*]
```

