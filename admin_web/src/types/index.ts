export type UserRole = 'passenger' | 'driver' | 'admin';

export interface User {
  id: string;
  name: string;
  phoneNumber: string;
  email?: string;
  role: UserRole;
  createdAt: string;
}

export type DriverApprovalStatus = 'pending' | 'approved' | 'suspended' | 'rejected';

export interface DriverProfile {
  driverId: string;
  driverName?: string;
  phoneNumber?: string;
  vehicleNumber: string;
  licenseOrId?: string;
  approvalStatus: DriverApprovalStatus;
  isOnline: boolean;
  currentBookingId?: string | null;
  offeredBookingId?: string | null;
  totalTrips: number;
  rating: number;
  latitude?: number;
  longitude?: number;
  locationUpdatedAt?: string;
  registeredHub?: string;
  onlineSince?: string;
  approvedBy?: string | null;
  approvedAt?: string | null;
  updatedAt: string;
}

export interface Route {
  id: string;
  name: string;
  origin: string;
  destination: string;
  distanceKm: number;
  estimatedMinutes: number;
  isSharedAvailable: boolean;
  isPrivateAvailable: boolean;
  isActive: boolean;
  landmarks: string[];
  lastVerifiedAt: string;
  verifiedBy: string;
}

export interface RouteFare {
  routeId: string;
  sharedFarePerPassenger: number;
  privateBaseFare: number;
  minimumFare: number;
  maxCapacity: number;
  isNegotiable: boolean;
  lastVerifiedAt: string;
}

export type BookingStatus =
  | 'pending_assignment'
  | 'driver_assigned'
  | 'driver_accepted'
  | 'driver_rejected'
  | 'driver_arrived'
  | 'in_progress'
  | 'completed'
  | 'cancelled_by_passenger'
  | 'cancelled_by_admin';

export interface DispatchAuditEntry {
  driverId: string;
  driverName?: string;
  action: 'offered' | 'accepted' | 'rejected' | 'timeout' | 'manual_assigned';
  timestamp: string;
  reason?: string;
}

export interface Booking {
  id: string;
  passengerId: string;
  passengerName: string;
  passengerPhone: string;
  bookingType: 'shared' | 'private';
  passengerCount: number;
  routeId: string;
  originName: string;
  destinationName: string;
  distanceKm: number;
  fare: number;
  status: BookingStatus;
  driverId?: string | null;
  driverName?: string | null;
  driverPhone?: string | null;
  vehicleNumber?: string | null;
  assignmentType: 'automatic' | 'manual' | 'manual_fallback';
  dispatchOfferedAt?: string | null;
  dispatchExpiresAt?: string | null;
  attemptedDriverIds?: string[];
  autoDispatchExhausted?: boolean;
  dispatchAuditLog?: DispatchAuditEntry[];
  createdAt: string;
  assignedAt?: string | null;
  acceptedAt?: string | null;
  completedAt?: string | null;
}

export interface BusTimetable {
  id: string;
  routeName: string;
  origin: string;
  destination: string;
  viaStops: string[];
  departureTime: string;
  arrivalTime: string;
  operatorName: string;
  busType: string;
  serviceDays: string;
  fareEstimate: number;
  isVerified: boolean;
  isActive: boolean;
  lastVerifiedAt: string;
}

export interface SupportIssue {
  id: string;
  bookingId?: string | null;
  reportedBy: string;
  reporterName?: string;
  userRole: string;
  issueType: string;
  description: string;
  status: 'open' | 'investigating' | 'resolved';
  resolutionNotes?: string;
  createdAt: string;
}

export interface SystemConfig {
  dispatchMode: 'automatic' | 'manual';
  offerTimeoutSeconds: number;
  autoCascadeEnabled: boolean;
}
