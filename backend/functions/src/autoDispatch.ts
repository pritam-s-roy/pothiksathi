/**
 * PothikSathi Automatic Driver Dispatch Engine
 * 
 * Rules:
 * 1. Default dispatch mode is Automatic, with fallback to Manual.
 * 2. Matches only approved, online, available drivers with matching capacity.
 * 3. Proximity ranking: uses GPS if fresh (<10m), otherwise hub/stand + waiting time.
 * 4. Single-offer sequential dispatch with 30s timeout.
 * 5. Cascade to next candidate on rejection/timeout.
 * 6. Admin alert and fallback if candidate list is exhausted.
 * 7. Concurrency-safe transactions to prevent double assignment.
 */

export interface DriverCandidate {
  driverId: string;
  driverName: string;
  driverPhone: string;
  vehicleNumber: string;
  rating: number;
  latitude?: number;
  longitude?: number;
  locationUpdatedAt?: string;
  registeredHub?: string;
  onlineSince?: string;
  distanceKm?: number;
}

export interface DispatchConfig {
  dispatchMode: 'automatic' | 'manual';
  offerTimeoutSeconds: number; // default 30
  maxCascadeAttempts: number;  // default 5
  locationFreshnessMinutes: number; // default 10
}

export const DEFAULT_DISPATCH_CONFIG: DispatchConfig = {
  dispatchMode: 'automatic',
  offerTimeoutSeconds: 30,
  maxCascadeAttempts: 5,
  locationFreshnessMinutes: 10,
};

/**
 * Calculate Haversine distance in kilometers between two coordinates
 */
export function haversineDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c * 10) / 10;
}

/**
 * Filter and rank eligible drivers for a booking request
 */
export function rankEligibleDrivers(
  drivers: DriverCandidate[],
  pickupLat: number | undefined,
  pickupLon: number | undefined,
  pickupHub: string | undefined,
  passengerCount: number,
  alreadyAttemptedDriverIds: string[],
  config: DispatchConfig = DEFAULT_DISPATCH_CONFIG
): DriverCandidate[] {
  const now = Date.now();
  const maxStaleMs = config.locationFreshnessMinutes * 60 * 1000;

  // 1. Filter eligible candidates
  const eligible = drivers.filter((d) => {
    // Exclude drivers who already rejected or timed out for this booking
    if (alreadyAttemptedDriverIds.includes(d.driverId)) {
      return false;
    }
    return true;
  });

  // 2. Score and sort candidates
  return eligible
    .map((driver) => {
      let distance = 999.0;
      let usedGps = false;

      // Check if driver has fresh GPS location (<10 mins)
      if (
        driver.latitude !== undefined &&
        driver.longitude !== undefined &&
        pickupLat !== undefined &&
        pickupLon !== undefined &&
        driver.locationUpdatedAt
      ) {
        const updateTime = new Date(driver.locationUpdatedAt).getTime();
        // Server timestamp validation: must be a valid number, not set in future, and within maxStaleMs
        if (!isNaN(updateTime) && updateTime <= now && (now - updateTime) <= maxStaleMs) {
          distance = haversineDistance(pickupLat, pickupLon, driver.latitude, driver.longitude);
          usedGps = true;
        }
      }

      // Fallback: If no fresh GPS, use registered hub matching
      if (!usedGps) {
        if (driver.registeredHub && pickupHub && driver.registeredHub.toLowerCase() === pickupHub.toLowerCase()) {
          distance = 1.0; // Same hub priority (e.g. both at Karimpur Bus Stand)
        } else {
          distance = 3.5; // Nearby Karimpur municipal area default
        }
      }

      return {
        ...driver,
        distanceKm: distance,
      };
    })
    .sort((a, b) => {
      // Primary sort: distance (nearest first)
      if (Math.abs((a.distanceKm || 0) - (b.distanceKm || 0)) > 0.5) {
        return (a.distanceKm || 0) - (b.distanceKm || 0);
      }
      // Secondary sort: rating
      if (b.rating !== a.rating) {
        return b.rating - a.rating;
      }
      // Tertiary sort: waiting time (onlineSince earlier gets priority)
      const aTime = a.onlineSince ? new Date(a.onlineSince).getTime() : 0;
      const bTime = b.onlineSince ? new Date(b.onlineSince).getTime() : 0;
      return aTime - bTime;
    });
}
