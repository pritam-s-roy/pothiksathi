"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.calculateTrustedFare = calculateTrustedFare;
function calculateTrustedFare(request, tariff) {
    // 1. Capacity validation
    if (request.passengerCount < 1 || request.passengerCount > 4) {
        return {
            valid: false,
            totalFare: 0,
            perPassengerRate: 0,
            baseVehicleRate: 0,
            tariffVersion: 'INVALID',
            isTariffVerified: false,
            errorMessage: `Invalid passenger count: ${request.passengerCount}. TOTO max capacity is 4.`
        };
    }
    // 2. Route existence validation
    if (!tariff) {
        return {
            valid: false,
            totalFare: 0,
            perPassengerRate: 0,
            baseVehicleRate: 0,
            tariffVersion: 'UNVERIFIED',
            isTariffVerified: false,
            errorMessage: `No verified tariff found for route ${request.routeId}. Requires admin quotation.`
        };
    }
    // 3. Shared ride calculation
    if (request.bookingType === 'shared') {
        const perPassenger = tariff.sharedFarePerPassenger;
        const total = perPassenger * request.passengerCount;
        return {
            valid: true,
            totalFare: total,
            perPassengerRate: perPassenger,
            baseVehicleRate: 0,
            tariffVersion: 'KRM-2026-V1',
            isTariffVerified: true
        };
    }
    // 4. Private reserve ride calculation
    const baseRate = tariff.privateBaseFare;
    const minThreshold = tariff.minimumFare > 0 ? tariff.minimumFare : 20;
    const total = baseRate < minThreshold ? minThreshold : baseRate;
    return {
        valid: true,
        totalFare: total,
        perPassengerRate: 0,
        baseVehicleRate: baseRate,
        tariffVersion: 'KRM-2026-V1',
        isTariffVerified: true
    };
}
//# sourceMappingURL=fareCalculator.js.map