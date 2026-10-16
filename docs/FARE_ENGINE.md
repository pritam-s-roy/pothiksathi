# PothikSathi — TOTO Fare Engine Specification

## 1. Local Operating Context: Karimpur, Nadia
In Karimpur, battery-operated e-rickshaws (TOTOs) are the backbone of local transit. The tariff system balances passenger affordability with sustainable driver livelihood.

## 2. Shared Bookings Tariff
- **Per-Passenger Rate**: Strictly ₹10 per passenger on verified designated routes (e.g. Karimpur Bus Stand ↔ Pannadevi College, Karimpur Bus Stand ↔ Rural Hospital, Karimpur Bus Stand ↔ Regulated Market).
- **Formula**: `Total Fare = ₹10 * Passenger Count`
- **Capacity**: Minimum 1, Maximum 4 passengers. Any request exceeding 4 passengers is rejected at both client and backend levels.
- **Bargaining**: Prohibited on fixed-fare shared routes.

## 3. Private (Reserve) Bookings Tariff
- **Vehicle-Level Charge**: The price covers the entire TOTO vehicle, not a per-passenger charge.
- **Minimum Fare**: Guaranteed minimum base of ₹20 for short hops within town.
- **Formula**: `Total Fare = max(Configured Private Base Fare, Minimum Fare Threshold)`.
- **Audit Rule**: Driver cannot demand extra or negotiate arbitrary pricing for verified routes.

## 4. Unverified Routes
- The engine **never invents fares**.
- If a route does not match an approved entry in `routes` and `routeFares`, it is flagged with `isVerified = false` and routed to the Karimpur Dispatch Desk for manual quotation.

## 5. Surge Pricing Policy
- PothikSathi does **not** dynamically inflate fares due to weather (rain, heat) or traffic congestion. All fares remain grounded in administrator-verified public tariffs.

## 6. Fare Snapshot Integrity
When a booking is confirmed, a complete `FareSnapshot` is recorded in Firestore:
```json
{
  "tariffVersion": "KRM-TARIFF-2026",
  "bookingType": "shared",
  "passengerCount": 2,
  "perPassengerRate": 10.0,
  "baseVehicleRate": 0.0,
  "minimumFareThreshold": 0.0,
  "finalTotalFare": 20.0,
  "isTariffVerified": true,
  "calculatedAt": "2026-03-15T10:30:00Z"
}
```
Neither the mobile passenger app nor the driver app can modify this snapshot after creation.
