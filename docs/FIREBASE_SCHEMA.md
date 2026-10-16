# PothikSathi — Firestore Database Architecture & Security Model

## 1. Overview
The PothikSathi backend is architected around Cloud Firestore, designed to maintain strict role separation, minimal bandwidth consumption, and strong security.

## 2. Collections Schema

### `users`
- `id`: `string` (Firebase Auth UID)
- `name`: `string`
- `phoneNumber`: `string`
- `email`: `string?`
- `role`: `'passenger' | 'driver' | 'admin'`
- `createdAt`: `timestamp`
- `updatedAt`: `timestamp`

*Access Rules*: Users can read and update their own document. They cannot escalate their `role` field. Admins have full access.

---

### `driverProfiles`
- `driverId`: `string` (Matches Auth UID)
- `vehicleNumber`: `string` (e.g. `WB-52-TOTO-8812`)
- `licenseOrId`: `string?` (Aadhaar / Voter ID)
- `approvalStatus`: `'pending' | 'approved' | 'suspended' | 'rejected'`
- `isOnline`: `boolean`
- `currentBookingId`: `string?`
- `totalTrips`: `number`
- `rating`: `number` (Default 5.0)
- `approvedBy`: `string?` (Admin UID)
- `approvedAt`: `timestamp?`
- `updatedAt`: `timestamp`

*Access Rules*: Read by authenticated users. Drivers can only toggle `isOnline`. Only admins can modify `approvalStatus`.

---

### `routes`
- `id`: `string` (e.g. `krm_route_01`)
- `name`: `string` (e.g. `Karimpur Bus Stand ↔ Pannadevi College`)
- `origin`: `string`
- `destination`: `string`
- `distanceKm`: `number`
- `estimatedMinutes`: `number`
- `isSharedAvailable`: `boolean`
- `isPrivateAvailable`: `boolean`
- `isActive`: `boolean`
- `landmarks`: `string[]`
- `lastVerifiedAt`: `timestamp`
- `verifiedBy`: `string`

*Access Rules*: Publicly readable. Admin write only.

---

### `routeFares`
- `routeId`: `string` (Document ID matches `routes.id`)
- `sharedFarePerPassenger`: `number` (₹10.0 on verified local routes)
- `privateBaseFare`: `number`
- `minimumFare`: `number` (₹20.0 default threshold)
- `maxCapacity`: `number` (4 passengers for TOTO)
- `isNegotiable`: `boolean` (false)
- `lastVerifiedAt`: `timestamp`

*Access Rules*: Publicly readable. Strictly admin write only. Fares are never client mutable.

---

### `busTimetables`
- `id`: `string`
- `routeName`: `string` (e.g. `Karimpur – Krishnanagar`)
- `origin`: `string` (e.g. `Karimpur Bus Stand`)
- `destination`: `string`
- `viaStops`: `string[]`
- `departureTime`: `string` (e.g. `05:45`)
- `arrivalTime`: `string`
- `operatorName`: `string`
- `busType`: `string`
- `serviceDays`: `string` (e.g. `Daily`)
- `fareEstimate`: `number`
- `isVerified`: `boolean`
- `isActive`: `boolean`
- `lastVerifiedAt`: `timestamp`

*Access Rules*: Publicly readable. Client caches locally in `SharedPreferences`. Admin write only.

---

### `bookings`
- `id`: `string` (e.g. `BK-KRM-2026-081`)
- `passengerId`: `string`
- `passengerName`: `string`
- `passengerPhone`: `string`
- `bookingType`: `'shared' | 'private'`
- `passengerCount`: `number` (1 to 4)
- `routeId`: `string`
- `originName`: `string`
- `destinationName`: `string`
- `distanceKm`: `number`
- `fare`: `number`
- `fareSnapshot`: `map` (Contains immutable calculation audit snapshot)
- `status`: `'pending_assignment' | 'driver_assigned' | 'driver_accepted' | 'driver_rejected' | 'driver_arrived' | 'in_progress' | 'completed' | 'cancelled_by_passenger' | 'cancelled_by_admin'`
- `driverId`: `string?`
- `driverName`: `string?`
- `driverPhone`: `string?`
- `vehicleNumber`: `string?`
- `assignedAt`: `timestamp?`
- `acceptedAt`: `timestamp?`
- `arrivedAt`: `timestamp?`
- `startedAt`: `timestamp?`
- `completedAt`: `timestamp?`
- `createdAt`: `timestamp`
- `updatedAt`: `timestamp`

*Access Rules*: Visible to involved passenger, assigned driver, and admin. State machine transitions are enforced by rules.

---

### `supportIssues`
- `id`: `string`
- `bookingId`: `string?`
- `reportedBy`: `string` (UID)
- `userRole`: `string`
- `issueType`: `string`
- `description`: `string`
- `status`: `'open' | 'investigating' | 'resolved'`
- `resolutionNotes`: `string?`
- `createdAt`: `timestamp`
- `resolvedAt`: `timestamp?`
