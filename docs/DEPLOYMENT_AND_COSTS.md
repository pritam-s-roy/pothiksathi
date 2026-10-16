# PothikSathi — Deployment, Optimization & Operating Cost Guide

## 1. Android Release & App Size Optimization

To maintain the core objective of **low mobile data consumption and small download size** in rural/semi-urban West Bengal:

### Split-per-ABI Build
Instead of generating a heavy universal APK (~40+ MB), compile ABI-targeted APKs:
```bash
cd mobile_app
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=./build/symbols
```
This produces:
- `app-arm64-v8a-release.apk` (~14 MB)
- `app-armeabi-v7a-release.apk` (~12 MB)

### Asset & Library Hygiene
- No bloated map renderers or continuous GPS tracking engines bundled into the binary.
- Standard vector Material symbols used instead of heavy PNG/JPEG raster asset packs.
- Proguard rules (`android/app/proguard-rules.pro`) strip dead code and obfuscate models.

---

## 2. Operating Cost Structure & Free-Tier Maximization

> [!IMPORTANT]
> While PothikSathi is architected for ultra-low overhead, operating costs depend on user scale. Budget alerts must be configured before production launch.

### Firebase Spark (Free Tier) vs Blaze Plan
Firestore provides generous daily free quotas:
- **50,000 document reads/day** (Free)
- **20,000 document writes/day** (Free)
- **20,000 document deletes/day** (Free)
- **1 GB stored data** (Free)

#### How PothikSathi avoids burning read/write quotas:
1. **Zero continuous real-time listening on catalog collections**: `routes`, `routeFares`, and `busTimetables` are read once and cached locally in `SharedPreferences`. Commuters can check bus schedules 100 times without generating a single Firestore read.
2. **Single document listener**: Real-time listening is restricted strictly to the **active booking** document (`bookings/{bookingId}`) while the passenger or driver is on the active tracking screen.
3. **No continuous GPS tracking**: Drivers do not write latitude/longitude every 2 seconds. Instead, milestones are updated on meaningful discrete state changes (`accepted`, `arrived`, `in_progress`, `completed`), saving tens of thousands of Firestore writes per day.

---

## 3. Google Maps Platform & Routing Cost Protection

The Google Maps Routes API costs approximately $5.00 per 1,000 requests after free monthly credit.
To eliminate unnecessary billing:
1. **Pre-computed verified distance matrix**: For the designated Karimpur local corridors (Bus Stand ↔ Pannadevi College, Bus Stand ↔ Rural Hospital, Bus Stand ↔ Shikarpur Ghat), distances and driving times are pre-computed and stored in `routes`.
2. **Backend Proxy & Key Isolation**: Maps API keys are never exposed in mobile client source code. Any dynamic route calculation is performed via Cloud Functions with strict rate limiting.
3. **Budget Alert Setup**:
   - In Google Cloud Console -> Billing -> Budgets & Alerts:
     - Set monthly budget alert at ₹500 ($6.00) with triggers at 50%, 80%, and 100%.

---

## 4. Automatic Dispatch Configuration & Index Strategy

### System Configuration Document (`systemConfig/default`)
```json
{
  "dispatchMode": "automatic",
  "offerTimeoutSeconds": 30,
  "autoCascadeEnabled": true,
  "maxSearchRadiusKm": 5.0,
  "locationFreshnessThresholdMinutes": 10
}
```

### Required Firestore Compound Indexes
To ensure sub-second driver matching and query performance without scan overhead:
1. **Eligible Driver Selection Index**:
   - Collection: `driverProfiles`
   - Fields: `approvalStatus` (ASC), `isOnline` (ASC), `currentBookingId` (ASC), `rating` (DESC)
2. **Booking Dispatch Queue Index**:
   - Collection: `bookings`
   - Fields: `status` (ASC), `assignmentType` (ASC), `createdAt` (DESC)
3. **Driver Private Booking History Index**:
   - Collection: `bookings`
   - Fields: `driverId` (ASC), `status` (ASC), `createdAt` (DESC)

---

## 5. Production Deployment Checklist

1. **Firebase Authentication**:
   - Enable Phone Auth (with SMS OTP) and Email/Password in Firebase Console.
   - Configure SHA-256 fingerprint in Android Firebase settings.
2. **Firestore Rules & Indexes**:
   - Deploy security rules: `firebase deploy --only firestore:rules`
   - Deploy compound indexes: `firebase deploy --only firestore:indexes`
3. **Cloud Functions**:
   - Install dependencies: `cd backend/functions && npm install`
   - Compile TypeScript: `npm run build`
   - Deploy trusted backend functions: `firebase deploy --only functions`
4. **Admin Web Portal**:
   - Build static bundle: `cd admin_web && npm run build`
   - Deploy to Firebase Hosting: `firebase deploy --only hosting` (or Vercel / Cloudflare Pages free tiers).
