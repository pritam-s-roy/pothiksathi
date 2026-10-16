import {
  Booking,
  DriverProfile,
  DriverApprovalStatus,
  Route,
  RouteFare,
  BusTimetable,
  SupportIssue,
  SystemConfig,
} from '../types';

class AdminService {
  private config: SystemConfig = {
    dispatchMode: 'automatic', // Default is Automatic dispatch
    offerTimeoutSeconds: 30,
    autoCascadeEnabled: true,
  };

  private bookings: Booking[] = [
    {
      id: 'BK-KRM-2026-101',
      passengerId: 'p_101',
      passengerName: 'Ananya Roy',
      passengerPhone: '+91 97321 00981',
      bookingType: 'shared',
      passengerCount: 2,
      routeId: 'krm_route_01',
      originName: 'Karimpur Bus Stand',
      destinationName: 'Karimpur Pannadevi College',
      distanceKm: 1.8,
      fare: 20,
      status: 'pending_assignment',
      assignmentType: 'automatic',
      attemptedDriverIds: [],
      autoDispatchExhausted: false,
      dispatchAuditLog: [
        {
          driverId: 'system',
          action: 'offered',
          timestamp: new Date().toISOString(),
          reason: 'Auto-dispatch initiated by passenger booking',
        },
      ],
      createdAt: new Date().toISOString(),
    },
    {
      id: 'BK-KRM-2026-102',
      passengerId: 'p_102',
      passengerName: 'Kallol Sarkar',
      passengerPhone: '+91 94340 11223',
      bookingType: 'private',
      passengerCount: 1,
      routeId: 'krm_route_02',
      originName: 'Karimpur Bus Stand',
      destinationName: 'Karimpur Rural Hospital',
      distanceKm: 1.2,
      fare: 20,
      status: 'pending_assignment',
      assignmentType: 'manual_fallback',
      attemptedDriverIds: ['drv_01', 'drv_02'],
      autoDispatchExhausted: true, // Candidate pool exhausted, alerted admin
      dispatchAuditLog: [
        {
          driverId: 'drv_01',
          driverName: 'Bapi Mondal',
          action: 'timeout',
          timestamp: new Date(Date.now() - 4 * 60000).toISOString(),
          reason: 'No response within 30s acceptance window',
        },
        {
          driverId: 'drv_02',
          driverName: 'Tarun Ghosh',
          action: 'rejected',
          timestamp: new Date(Date.now() - 2 * 60000).toISOString(),
          reason: 'Declined by driver: vehicle battery charging',
        },
      ],
      createdAt: new Date(Date.now() - 5 * 60000).toISOString(),
    },
    {
      id: 'BK-KRM-2026-098',
      passengerId: 'p_098',
      passengerName: 'Debabrata Pal',
      passengerPhone: '+91 98320 44556',
      bookingType: 'shared',
      passengerCount: 1,
      routeId: 'krm_route_03',
      originName: 'Karimpur Bus Stand',
      destinationName: 'Karimpur Regulated Market (Nizampur)',
      distanceKm: 1.0,
      fare: 10,
      status: 'driver_assigned',
      assignmentType: 'automatic',
      driverId: 'drv_01',
      driverName: 'Bapi Mondal',
      driverPhone: '+91 98000 12345',
      vehicleNumber: 'WB-52-TOTO-8812',
      dispatchOfferedAt: new Date(Date.now() - 10 * 1000).toISOString(),
      dispatchExpiresAt: new Date(Date.now() + 20 * 1000).toISOString(),
      attemptedDriverIds: ['drv_01'],
      autoDispatchExhausted: false,
      dispatchAuditLog: [
        {
          driverId: 'drv_01',
          driverName: 'Bapi Mondal',
          action: 'offered',
          timestamp: new Date(Date.now() - 10 * 1000).toISOString(),
          reason: 'Auto-matched: nearest captain at Karimpur Bus Stand (0.2km)',
        },
      ],
      createdAt: new Date(Date.now() - 15 * 60000).toISOString(),
      assignedAt: new Date(Date.now() - 10 * 1000).toISOString(),
    },
    {
      id: 'BK-KRM-2026-088',
      passengerId: 'p_088',
      passengerName: 'Priya Majumdar',
      passengerPhone: '+91 91234 56789',
      bookingType: 'private',
      passengerCount: 3,
      routeId: 'krm_route_04',
      originName: 'Karimpur Bus Stand',
      destinationName: 'Shikarpur Ghat / More',
      distanceKm: 7.5,
      fare: 80,
      status: 'completed',
      assignmentType: 'automatic',
      driverId: 'drv_01',
      driverName: 'Bapi Mondal',
      driverPhone: '+91 98000 12345',
      vehicleNumber: 'WB-52-TOTO-8812',
      createdAt: new Date(Date.now() - 120 * 60000).toISOString(),
      completedAt: new Date(Date.now() - 95 * 60000).toISOString(),
    },
  ];

  private drivers: DriverProfile[] = [
    {
      driverId: 'drv_01',
      driverName: 'Bapi Mondal',
      phoneNumber: '+91 98000 12345',
      vehicleNumber: 'WB-52-TOTO-8812',
      licenseOrId: 'AADHAAR-8921-1234',
      approvalStatus: 'approved',
      isOnline: true,
      currentBookingId: 'BK-KRM-2026-098',
      totalTrips: 42,
      rating: 4.9,
      registeredHub: 'Karimpur Bus Stand',
      latitude: 23.9682,
      longitude: 88.6201,
      locationUpdatedAt: new Date().toISOString(),
      approvedBy: 'admin_karimpur',
      approvedAt: '2026-02-15T10:00:00Z',
      updatedAt: new Date().toISOString(),
    },
    {
      driverId: 'drv_02',
      driverName: 'Tarun Ghosh',
      phoneNumber: '+91 97330 99887',
      vehicleNumber: 'WB-52-TOTO-3301',
      licenseOrId: 'AADHAAR-4412-5566',
      approvalStatus: 'approved',
      isOnline: true,
      currentBookingId: null,
      totalTrips: 28,
      rating: 4.8,
      registeredHub: 'Karimpur Rural Hospital',
      latitude: 23.9740,
      longitude: 88.6225,
      locationUpdatedAt: new Date().toISOString(),
      approvedBy: 'admin_karimpur',
      approvedAt: '2026-02-18T11:00:00Z',
      updatedAt: new Date().toISOString(),
    },
    {
      driverId: 'drv_05',
      driverName: 'Prabir Das',
      phoneNumber: '+91 94340 77112',
      vehicleNumber: 'WB-52-TOTO-5104',
      licenseOrId: 'AADHAAR-7788-9900',
      approvalStatus: 'approved',
      isOnline: true,
      currentBookingId: null,
      totalTrips: 15,
      rating: 4.7,
      registeredHub: 'Karimpur Pannadevi College',
      latitude: 23.9610,
      longitude: 88.6280,
      locationUpdatedAt: new Date().toISOString(),
      approvedBy: 'admin_karimpur',
      approvedAt: '2026-03-01T10:00:00Z',
      updatedAt: new Date().toISOString(),
    },
    {
      driverId: 'drv_03',
      driverName: 'Ratan Das',
      phoneNumber: '+91 98000 99999',
      vehicleNumber: 'WB-52-TOTO-4120',
      licenseOrId: 'AADHAAR-3112-9876',
      approvalStatus: 'pending',
      isOnline: false,
      currentBookingId: null,
      totalTrips: 0,
      rating: 5.0,
      registeredHub: 'Karimpur Bus Stand',
      approvedBy: null,
      approvedAt: null,
      updatedAt: new Date().toISOString(),
    },
    {
      driverId: 'drv_04',
      driverName: 'Shyamal Paul',
      phoneNumber: '+91 96470 12300',
      vehicleNumber: 'WB-52-TOTO-7014',
      licenseOrId: 'VOTER-WB52-0987',
      approvalStatus: 'pending',
      isOnline: false,
      currentBookingId: null,
      totalTrips: 0,
      rating: 5.0,
      registeredHub: 'Shikarpur Ghat / More',
      approvedBy: null,
      approvedAt: null,
      updatedAt: new Date().toISOString(),
    },
  ];

  private routes: Route[] = [
    {
      id: 'krm_route_01',
      name: 'Karimpur Bus Stand ↔ Pannadevi College',
      origin: 'Karimpur Bus Stand',
      destination: 'Karimpur Pannadevi College',
      distanceKm: 1.8,
      estimatedMinutes: 8,
      isSharedAvailable: true,
      isPrivateAvailable: true,
      isActive: true,
      landmarks: ['Karimpur Bazar', 'College Road'],
      lastVerifiedAt: '2026-03-01T10:00:00Z',
      verifiedBy: 'admin_karimpur',
    },
    {
      id: 'krm_route_02',
      name: 'Karimpur Bus Stand ↔ Rural Hospital',
      origin: 'Karimpur Bus Stand',
      destination: 'Karimpur Rural Hospital',
      distanceKm: 1.2,
      estimatedMinutes: 6,
      isSharedAvailable: true,
      isPrivateAvailable: true,
      isActive: true,
      landmarks: ['Hospital More', 'BPHC Gate'],
      lastVerifiedAt: '2026-03-01T10:00:00Z',
      verifiedBy: 'admin_karimpur',
    },
    {
      id: 'krm_route_03',
      name: 'Karimpur Bus Stand ↔ Regulated Market (Nizampur)',
      origin: 'Karimpur Bus Stand',
      destination: 'Karimpur Regulated Market (Nizampur)',
      distanceKm: 1.0,
      estimatedMinutes: 5,
      isSharedAvailable: true,
      isPrivateAvailable: true,
      isActive: true,
      landmarks: ['Bazar Crossing'],
      lastVerifiedAt: '2026-03-01T10:00:00Z',
      verifiedBy: 'admin_karimpur',
    },
    {
      id: 'krm_route_04',
      name: 'Karimpur Bus Stand ↔ Shikarpur Ghat',
      origin: 'Karimpur Bus Stand',
      destination: 'Shikarpur Ghat / More',
      distanceKm: 7.5,
      estimatedMinutes: 22,
      isSharedAvailable: true,
      isPrivateAvailable: true,
      isActive: true,
      landmarks: ['Madhubana', 'High School'],
      lastVerifiedAt: '2026-03-01T10:00:00Z',
      verifiedBy: 'admin_karimpur',
    },
  ];

  private fares: RouteFare[] = [
    {
      routeId: 'krm_route_01',
      sharedFarePerPassenger: 10,
      privateBaseFare: 25,
      minimumFare: 20,
      maxCapacity: 4,
      isNegotiable: false,
      lastVerifiedAt: '2026-03-01T10:00:00Z',
    },
    {
      routeId: 'krm_route_02',
      sharedFarePerPassenger: 10,
      privateBaseFare: 20,
      minimumFare: 20,
      maxCapacity: 4,
      isNegotiable: false,
      lastVerifiedAt: '2026-03-01T10:00:00Z',
    },
    {
      routeId: 'krm_route_03',
      sharedFarePerPassenger: 10,
      privateBaseFare: 20,
      minimumFare: 20,
      maxCapacity: 4,
      isNegotiable: false,
      lastVerifiedAt: '2026-03-01T10:00:00Z',
    },
    {
      routeId: 'krm_route_04',
      sharedFarePerPassenger: 20,
      privateBaseFare: 80,
      minimumFare: 20,
      maxCapacity: 4,
      isNegotiable: false,
      lastVerifiedAt: '2026-03-01T10:00:00Z',
    },
  ];

  private busTimetables: BusTimetable[] = [
    {
      id: 'bus_01',
      routeName: 'Karimpur – Krishnanagar',
      origin: 'Karimpur Bus Stand',
      destination: 'Krishnanagar Bus Stand',
      viaStops: ['Tehatta', 'Chapra', 'Dhubulia'],
      departureTime: '05:45',
      arrivalTime: '07:30',
      operatorName: 'SBSTC Ordinary',
      busType: 'Express',
      serviceDays: 'Daily',
      fareEstimate: 55,
      isVerified: true,
      isActive: true,
      lastVerifiedAt: '2026-03-10T09:00:00Z',
    },
    {
      id: 'bus_02',
      routeName: 'Karimpur – Kolkata (Esplanade)',
      origin: 'Karimpur Bus Stand',
      destination: 'Kolkata (Esplanade)',
      viaStops: ['Tehatta', 'Krishnanagar', 'Ranaghat', 'Barasat'],
      departureTime: '05:00',
      arrivalTime: '10:15',
      operatorName: 'NBSTC Rocket',
      busType: 'Fast Express',
      serviceDays: 'Daily',
      fareEstimate: 165,
      isVerified: true,
      isActive: true,
      lastVerifiedAt: '2026-03-10T09:00:00Z',
    },
    {
      id: 'bus_03',
      routeName: 'Karimpur – Berhampore (Mohona)',
      origin: 'Karimpur Bus Stand',
      destination: 'Berhampore Bus Stand (Mohona)',
      viaStops: ['Shikarpur', 'Jalangi', 'Domkal'],
      departureTime: '06:15',
      arrivalTime: '08:30',
      operatorName: 'Joint Syndicate',
      busType: 'Ordinary',
      serviceDays: 'Daily',
      fareEstimate: 60,
      isVerified: true,
      isActive: true,
      lastVerifiedAt: '2026-03-10T09:00:00Z',
    },
  ];

  private supportIssues: SupportIssue[] = [
    {
      id: 'ISSUE-01',
      bookingId: 'BK-KRM-2026-088',
      reportedBy: 'p_088',
      reporterName: 'Priya Majumdar',
      userRole: 'passenger',
      issueType: 'Fare Verification Query',
      description: 'Inquired whether reserve fare to Shikarpur Ghat is ₹80. Verified correct as per municipal tariff.',
      status: 'resolved',
      resolutionNotes: 'Explained standard approved private tariff for 7.5km outer route.',
      createdAt: new Date(Date.now() - 48 * 3600000).toISOString(),
    },
  ];

  // System Configuration & Dispatch Mode Controls
  getConfig(): SystemConfig {
    return { ...this.config };
  }

  setDispatchMode(mode: 'automatic' | 'manual') {
    this.config.dispatchMode = mode;
  }

  // Booking Queries & Actions
  getBookings(): Booking[] {
    return [...this.bookings];
  }

  getPendingBookings(): Booking[] {
    return this.bookings.filter((b) => b.status === 'pending_assignment');
  }

  getAutoExhaustedBookings(): Booking[] {
    return this.bookings.filter((b) => b.autoDispatchExhausted && b.status === 'pending_assignment');
  }

  // Trigger Automatic Matching & Cascading Algorithm
  runAutoDispatch(bookingId: string): boolean {
    const booking = this.bookings.find((b) => b.id === bookingId);
    if (!booking) return false;

    const attempted = booking.attemptedDriverIds || [];
    const available = this.drivers.filter(
      (d) => d.approvalStatus === 'approved' && d.isOnline && !d.currentBookingId && !attempted.includes(d.driverId)
    );

    if (available.length === 0) {
      booking.autoDispatchExhausted = true;
      booking.assignmentType = 'manual_fallback';
      booking.dispatchAuditLog?.push({
        driverId: 'system',
        action: 'timeout',
        timestamp: new Date().toISOString(),
        reason: 'All candidate drivers exhausted. Escalated to manual admin dispatch.',
      });
      return false;
    }

    // Rank candidate by proximity to pickup hub
    available.sort((a, b) => {
      const aSame = booking.originName.toLowerCase().includes((a.registeredHub || '').toLowerCase());
      const bSame = booking.originName.toLowerCase().includes((b.registeredHub || '').toLowerCase());
      if (aSame && !bSame) return -1;
      if (!aSame && bSame) return 1;
      return b.rating - a.rating;
    });

    const chosen = available[0];
    const now = new Date();
    const expiresAt = new Date(now.getTime() + this.config.offerTimeoutSeconds * 1000);

    booking.driverId = chosen.driverId;
    booking.driverName = chosen.driverName;
    booking.driverPhone = chosen.phoneNumber;
    booking.vehicleNumber = chosen.vehicleNumber;
    booking.status = 'driver_assigned';
    booking.assignmentType = 'automatic';
    booking.dispatchOfferedAt = now.toISOString();
    booking.dispatchExpiresAt = expiresAt.toISOString();
    booking.attemptedDriverIds = [...attempted, chosen.driverId];
    booking.autoDispatchExhausted = false;

    chosen.currentBookingId = booking.id;
    chosen.offeredBookingId = booking.id;

    booking.dispatchAuditLog?.push({
      driverId: chosen.driverId,
      driverName: chosen.driverName,
      action: 'offered',
      timestamp: now.toISOString(),
      reason: `Auto-offered with ${this.config.offerTimeoutSeconds}s countdown timer (Rank: 1st)`,
    });

    return true;
  }

  // Retry Auto-Dispatch after candidates were exhausted or reset
  retryAutoDispatch(bookingId: string): boolean {
    const booking = this.bookings.find((b) => b.id === bookingId);
    if (!booking) return false;
    booking.attemptedDriverIds = [];
    booking.autoDispatchExhausted = false;
    booking.status = 'pending_assignment';
    booking.driverId = null;
    booking.driverName = null;
    booking.dispatchAuditLog?.push({
      driverId: 'system',
      action: 'offered',
      timestamp: new Date().toISOString(),
      reason: 'Auto-dispatch reset and re-initiated by administrator.',
    });
    return this.runAutoDispatch(bookingId);
  }

  // Manual Driver Assignment (Admin Override / Fallback)
  assignDriver(bookingId: string, driverId: string): boolean {
    const booking = this.bookings.find((b) => b.id === bookingId);
    const driver = this.drivers.find((d) => d.driverId === driverId);

    if (!booking || !driver) return false;
    if (driver.approvalStatus !== 'approved' || !driver.isOnline) {
      alert('Selected driver must be approved and online to receive assignments.');
      return false;
    }

    booking.driverId = driver.driverId;
    booking.driverName = driver.driverName || 'Driver';
    booking.driverPhone = driver.phoneNumber;
    booking.vehicleNumber = driver.vehicleNumber;
    booking.status = 'driver_assigned';
    booking.assignmentType = 'manual';
    booking.assignedAt = new Date().toISOString();
    booking.dispatchOfferedAt = null;
    booking.dispatchExpiresAt = null;
    booking.autoDispatchExhausted = false;

    driver.currentBookingId = booking.id;

    booking.dispatchAuditLog?.push({
      driverId: driver.driverId,
      driverName: driver.driverName,
      action: 'manual_assigned',
      timestamp: new Date().toISOString(),
      reason: 'Assigned manually by Karimpur Dispatch Desk operator',
    });

    return true;
  }

  // Driver response simulator for testing cascade in the admin panel
  simulateDriverResponse(bookingId: string, accepted: boolean, reason?: string): boolean {
    const booking = this.bookings.find((b) => b.id === bookingId);
    if (!booking || !booking.driverId) return false;

    const driver = this.drivers.find((d) => d.driverId === booking.driverId);

    if (accepted) {
      booking.status = 'driver_accepted';
      booking.acceptedAt = new Date().toISOString();
      if (driver) driver.offeredBookingId = null;

      booking.dispatchAuditLog?.push({
        driverId: booking.driverId,
        driverName: booking.driverName || '',
        action: 'accepted',
        timestamp: new Date().toISOString(),
      });
      return true;
    } else {
      // Driver rejected or timed out -> Release driver and trigger cascade
      const rejectedDriverId = booking.driverId;
      const rejectedDriverName = booking.driverName || '';
      if (driver) {
        driver.currentBookingId = null;
        driver.offeredBookingId = null;
      }

      booking.driverId = null;
      booking.driverName = null;
      booking.driverPhone = null;
      booking.vehicleNumber = null;
      booking.status = 'pending_assignment';
      booking.dispatchOfferedAt = null;
      booking.dispatchExpiresAt = null;

      booking.dispatchAuditLog?.push({
        driverId: rejectedDriverId,
        driverName: rejectedDriverName,
        action: 'rejected',
        timestamp: new Date().toISOString(),
        reason: reason || 'Driver declined or timed out (30s window)',
      });

      // Automatically cascade to next candidate if automatic mode is on
      if (this.config.dispatchMode === 'automatic') {
        this.runAutoDispatch(bookingId);
      }

      return true;
    }
  }

  respondDriverOffer(bookingId: string, _driverId: string, action: 'accepted' | 'rejected', reason?: string): boolean {
    return this.simulateDriverResponse(bookingId, action === 'accepted', reason);
  }

  cancelBooking(bookingId: string): boolean {
    const booking = this.bookings.find((b) => b.id === bookingId);
    if (!booking) return false;
    booking.status = 'cancelled_by_admin';

    if (booking.driverId) {
      const driver = this.drivers.find((d) => d.driverId === booking.driverId);
      if (driver) {
        driver.currentBookingId = null;
        driver.offeredBookingId = null;
      }
    }
    return true;
  }

  // Driver Queries & Actions
  getDrivers(): DriverProfile[] {
    return [...this.drivers];
  }

  getApprovedOnlineDrivers(): DriverProfile[] {
    return this.drivers.filter(
      (d) => d.approvalStatus === 'approved' && d.isOnline && !d.currentBookingId
    );
  }

  setDriverApproval(driverId: string, status: DriverApprovalStatus): boolean {
    const driver = this.drivers.find((d) => d.driverId === driverId);
    if (!driver) return false;
    driver.approvalStatus = status;
    driver.approvedBy = status === 'approved' ? 'admin_karimpur' : null;
    driver.approvedAt = status === 'approved' ? new Date().toISOString() : null;
    driver.updatedAt = new Date().toISOString();
    return true;
  }

  // Route & Fare Queries & Actions
  getRoutes(): Route[] {
    return [...this.routes];
  }

  getFares(): RouteFare[] {
    return [...this.fares];
  }

  updateRouteFare(routeId: string, shared: number, privateBase: number, minFare: number): boolean {
    const fare = this.fares.find((f) => f.routeId === routeId);
    if (!fare) return false;
    fare.sharedFarePerPassenger = shared;
    fare.privateBaseFare = privateBase;
    fare.minimumFare = minFare;
    fare.lastVerifiedAt = new Date().toISOString();
    return true;
  }

  // Bus Timetable Queries & Actions
  getTimetables(): BusTimetable[] {
    return [...this.busTimetables];
  }

  addTimetable(item: Omit<BusTimetable, 'id' | 'isVerified' | 'lastVerifiedAt'>): BusTimetable {
    const newEntry: BusTimetable = {
      ...item,
      id: `bus_${Date.now()}`,
      isVerified: true,
      lastVerifiedAt: new Date().toISOString(),
    };
    this.busTimetables.push(newEntry);
    return newEntry;
  }

  verifyTimetable(id: string): boolean {
    const t = this.busTimetables.find((x) => x.id === id);
    if (!t) return false;
    t.isVerified = true;
    t.lastVerifiedAt = new Date().toISOString();
    return true;
  }

  deleteTimetable(id: string): boolean {
    const idx = this.busTimetables.findIndex((x) => x.id === id);
    if (idx === -1) return false;
    this.busTimetables.splice(idx, 1);
    return true;
  }

  // Support Queries
  getSupportIssues(): SupportIssue[] {
    return [...this.supportIssues];
  }

  resolveIssue(id: string, notes: string): boolean {
    const issue = this.supportIssues.find((s) => s.id === id);
    if (!issue) return false;
    issue.status = 'resolved';
    issue.resolutionNotes = notes;
    return true;
  }
}

export const adminService = new AdminService();
