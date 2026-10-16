import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { calculateTrustedFare, RouteFareData } from './fareCalculator';
import {
  rankEligibleDrivers,
  DriverCandidate,
  DEFAULT_DISPATCH_CONFIG,
  DispatchConfig,
} from './autoDispatch';

admin.initializeApp();
const db = admin.firestore();

/**
 * 1. Trusted backend fare verification endpoint.
 */
export const verifyBookingFare = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { bookingType, passengerCount, routeId } = data;
  if (!routeId || !bookingType || !passengerCount) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required booking parameters.');
  }

  const tariffSnap = await db.collection('routeFares').doc(routeId).get();
  const tariff = tariffSnap.exists ? (tariffSnap.data() as RouteFareData) : null;

  const result = calculateTrustedFare({ bookingType, passengerCount, routeId }, tariff);
  if (!result.valid) {
    throw new functions.https.HttpsError('failed-precondition', result.errorMessage || 'Invalid fare.');
  }

  return result;
});

/**
 * 2. Automatic Driver Dispatch Engine endpoint
 * Runs concurrency-safe transaction to find and offer booking to top candidate driver.
 */
export const triggerAutoDispatch = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  const { bookingId } = data;
  if (!bookingId) {
    throw new functions.https.HttpsError('invalid-argument', 'bookingId required.');
  }

  return db.runTransaction(async (transaction) => {
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await transaction.get(bookingRef);

    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Booking not found.');
    }

    const booking = bookingDoc.data()!;

    // Check if booking is in assignable state
    if (booking.status !== 'pending_assignment') {
      return { success: false, message: `Booking already in state ${booking.status}` };
    }

    // Retrieve global system dispatch config (checks default, falls back to dispatch)
    let configSnap = await transaction.get(db.collection('systemConfig').doc('default'));
    if (!configSnap.exists) {
      configSnap = await transaction.get(db.collection('systemConfig').doc('dispatch'));
    }
    const config: DispatchConfig = configSnap.exists
      ? (configSnap.data() as DispatchConfig)
      : DEFAULT_DISPATCH_CONFIG;

    if (config.dispatchMode === 'manual') {
      // Manual mode is active: keep booking in pending_assignment for admin
      return {
        success: true,
        mode: 'manual',
        message: 'System is in manual dispatch mode. Awaiting admin operator.',
      };
    }

    // Fetch all online, approved drivers who do not have an active booking
    const driverProfilesSnap = await db
      .collection('driverProfiles')
      .where('approvalStatus', '==', 'approved')
      .where('isOnline', '==', true)
      .get();

    const attemptedDrivers: string[] = booking.attemptedDriverIds || [];

    const candidates: DriverCandidate[] = [];
    for (const doc of driverProfilesSnap.docs) {
      const d = doc.data();
      // Preliminary filter: driver must not have currentBookingId or offeredBookingId
      if (!d.currentBookingId && !d.offeredBookingId) {
        const userSnap = await transaction.get(db.collection('users').doc(doc.id));
        const userData = userSnap.data();
        candidates.push({
          driverId: doc.id,
          driverName: userData?.name || 'TOTO Captain',
          driverPhone: userData?.phoneNumber || '',
          vehicleNumber: d.vehicleNumber,
          rating: d.rating || 5.0,
          latitude: d.latitude,
          longitude: d.longitude,
          locationUpdatedAt: d.locationUpdatedAt,
          registeredHub: d.registeredHub || 'Karimpur Bus Stand',
          onlineSince: d.onlineSince,
        });
      }
    }

    // Rank candidates
    const ranked = rankEligibleDrivers(
      candidates,
      booking.pickupLat,
      booking.pickupLon,
      booking.originName,
      booking.passengerCount,
      attemptedDrivers,
      config
    );

    // Concurrency Protection: Verify candidate driver is STILL available within the transaction
    let chosen: DriverCandidate | null = null;
    let chosenDriverRef: admin.firestore.DocumentReference | null = null;

    for (const cand of ranked) {
      const ref = db.collection('driverProfiles').doc(cand.driverId);
      const snap = await transaction.get(ref);
      if (snap.exists) {
        const data = snap.data()!;
        if (
          data.isOnline === true &&
          data.approvalStatus === 'approved' &&
          !data.currentBookingId &&
          !data.offeredBookingId
        ) {
          chosen = cand;
          chosenDriverRef = ref;
          break; // First verified free candidate chosen
        }
      }
    }

    const now = new Date();
    const timeoutSeconds = config.offerTimeoutSeconds || 30;
    const expiresAt = new Date(now.getTime() + timeoutSeconds * 1000).toISOString();

    // Case 1: No eligible driver available or all candidates occupied -> Mark awaiting manual dispatch
    if (!chosen || !chosenDriverRef) {
      transaction.update(bookingRef, {
        status: 'pending_assignment',
        autoDispatchExhausted: true,
        exhaustedAt: now.toISOString(),
        assignmentType: 'manual_fallback',
        updatedAt: now.toISOString(),
      });

      return {
        success: false,
        exhausted: true,
        message: 'No eligible online drivers found or all candidates currently occupied. Escalated to Karimpur Admin Desk.',
      };
    }

    // Case 2: Best candidate verified free -> Offer booking sequentially with transactional lock
    transaction.update(bookingRef, {
      driverId: chosen.driverId,
      driverName: chosen.driverName,
      driverPhone: chosen.driverPhone,
      vehicleNumber: chosen.vehicleNumber,
      status: 'driver_assigned',
      assignmentType: 'automatic',
      dispatchOfferedAt: now.toISOString(),
      dispatchExpiresAt: expiresAt,
      attemptedDriverIds: admin.firestore.FieldValue.arrayUnion(chosen.driverId),
      updatedAt: now.toISOString(),
    });

    transaction.update(chosenDriverRef, {
      currentBookingId: bookingId,
      offeredBookingId: bookingId,
      updatedAt: now.toISOString(),
    });

    return {
      success: true,
      mode: 'automatic',
      assignedDriverId: chosen.driverId,
      driverName: chosen.driverName,
      timeoutSeconds,
    };
  });
});

/**
 * 3. Driver accepts or rejects the offered booking
 * Includes concurrency-safe timeout validation and automatic cascade on rejection.
 */
export const respondToBookingOffer = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Driver authentication required.');
  }

  const { bookingId, accepted, reason } = data;
  const driverId = context.auth.uid;

  if (!bookingId || accepted === undefined) {
    throw new functions.https.HttpsError('invalid-argument', 'bookingId and accepted boolean required.');
  }

  return db.runTransaction(async (transaction) => {
    const bookingRef = db.collection('bookings').doc(bookingId);
    const driverRef = db.collection('driverProfiles').doc(driverId);

    const bookingDoc = await transaction.get(bookingRef);
    const driverDoc = await transaction.get(driverRef);

    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Booking not found.');
    }
    if (!driverDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Driver profile not found.');
    }

    const booking = bookingDoc.data()!;
    const now = new Date();

    // Verify this driver is the currently offered candidate
    if (booking.driverId !== driverId) {
      throw new functions.https.HttpsError('permission-denied', 'You are not the designated driver for this offer.');
    }

    // Check if offer expired
    const isExpired = booking.dispatchExpiresAt && new Date(booking.dispatchExpiresAt).getTime() < now.getTime();

    // --- ACCEPT FLOW ---
    if (accepted) {
      if (isExpired) {
        throw new functions.https.HttpsError('deadline-exceeded', 'Offer acceptance window expired.');
      }
      if (booking.status !== 'driver_assigned') {
        throw new functions.https.HttpsError('failed-precondition', 'Booking is no longer awaiting acceptance.');
      }

      transaction.update(bookingRef, {
        status: 'driver_accepted',
        acceptedAt: now.toISOString(),
        updatedAt: now.toISOString(),
      });

      transaction.update(driverRef, {
        offeredBookingId: null,
        currentBookingId: bookingId,
        updatedAt: now.toISOString(),
      });

      return { success: true, status: 'driver_accepted' };
    }

    // --- REJECT / TIMEOUT FLOW (CASCADE TRIGGER) ---
    // Release driver
    transaction.update(driverRef, {
      offeredBookingId: null,
      currentBookingId: null,
      updatedAt: now.toISOString(),
    });

    // Reset booking to pending_assignment and record audit
    transaction.update(bookingRef, {
      driverId: null,
      driverName: null,
      driverPhone: null,
      vehicleNumber: null,
      status: 'pending_assignment',
      lastRejectionReason: reason || (isExpired ? 'timeout' : 'driver_rejected'),
      dispatchAuditLog: admin.firestore.FieldValue.arrayUnion({
        driverId,
        action: isExpired ? 'timeout' : 'rejected',
        timestamp: now.toISOString(),
      }),
      updatedAt: now.toISOString(),
    });

    return {
      success: true,
      status: 'pending_assignment',
      triggerCascade: true,
      message: 'Offer declined. Cascading to next candidate.',
    };
  });
});

/**
 * 4. Admin Manual Driver Assignment (Preserved Fallback)
 */
export const assignDriverToBooking = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Admin authentication required.');
  }

  const callerSnap = await db.collection('users').doc(context.auth.uid).get();
  if (callerSnap.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only administrators can manually assign drivers.');
  }

  const { bookingId, driverId } = data;
  if (!bookingId || !driverId) {
    throw new functions.https.HttpsError('invalid-argument', 'bookingId and driverId required.');
  }

  return db.runTransaction(async (transaction) => {
    const bookingRef = db.collection('bookings').doc(bookingId);
    const driverRef = db.collection('driverProfiles').doc(driverId);
    const driverUserRef = db.collection('users').doc(driverId);

    const bookingDoc = await transaction.get(bookingRef);
    const driverDoc = await transaction.get(driverRef);
    const driverUserDoc = await transaction.get(driverUserRef);

    if (!bookingDoc.exists || !driverDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Booking or Driver profile not found.');
    }

    const driverData = driverDoc.data()!;
    if (driverData.approvalStatus !== 'approved' || !driverData.isOnline) {
      throw new functions.https.HttpsError('failed-precondition', 'Driver must be approved and online.');
    }

    const now = new Date().toISOString();

    // Release previously assigned driver if this is a reassignment
    const oldDriverId = bookingDoc.data()?.driverId;
    if (oldDriverId && oldDriverId !== driverId) {
      const oldDriverRef = db.collection('driverProfiles').doc(oldDriverId);
      transaction.update(oldDriverRef, {
        currentBookingId: null,
        offeredBookingId: null,
        updatedAt: now,
      });
    }

    transaction.update(bookingRef, {
      driverId,
      driverName: driverUserDoc.data()?.name || 'Assigned Driver',
      driverPhone: driverUserDoc.data()?.phoneNumber || '',
      vehicleNumber: driverData.vehicleNumber,
      status: 'driver_assigned',
      assignmentType: 'manual',
      assignedAt: now,
      autoDispatchExhausted: false,
      updatedAt: now,
    });

    transaction.update(driverRef, {
      currentBookingId: bookingId,
      offeredBookingId: null,
      updatedAt: now,
    });

    return { success: true, bookingId, driverId, status: 'driver_assigned' };
  });
});

/**
 * 5. Driver Approval (Admin-only privilege)
 */
export const approveDriver = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Admin authentication required.');
  }

  const callerSnap = await db.collection('users').doc(context.auth.uid).get();
  if (callerSnap.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only administrators can approve drivers.');
  }

  const { driverId, approve } = data;
  const driverRef = db.collection('driverProfiles').doc(driverId);
  const now = new Date().toISOString();

  await driverRef.update({
    approvalStatus: approve ? 'approved' : 'rejected',
    approvedBy: approve ? context.auth.uid : null,
    approvedAt: approve ? now : null,
    updatedAt: now,
  });

  return { success: true, driverId, status: approve ? 'approved' : 'rejected' };
});

/**
 * 6. Passenger or Admin Booking Cancellation
 * Atomically releases assigned driver availability and prevents illegal cancellations.
 */
export const cancelBooking = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  const { bookingId, reason } = data;
  if (!bookingId) {
    throw new functions.https.HttpsError('invalid-argument', 'bookingId required.');
  }

  return db.runTransaction(async (transaction) => {
    const bookingRef = db.collection('bookings').doc(bookingId);
    const bookingDoc = await transaction.get(bookingRef);
    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Booking not found.');
    }

    const booking = bookingDoc.data()!;
    const callerId = context.auth!.uid;
    const callerSnap = await transaction.get(db.collection('users').doc(callerId));
    const isCallerAdmin = callerSnap.data()?.role === 'admin';
    const isCallerPassenger = booking.passengerId === callerId;

    if (!isCallerAdmin && !isCallerPassenger) {
      throw new functions.https.HttpsError('permission-denied', 'Only passenger or admin can cancel this booking.');
    }

    if (booking.status === 'in_progress' || booking.status === 'completed') {
      throw new functions.https.HttpsError('failed-precondition', 'Cannot cancel a trip that is in progress or completed.');
    }

    const now = new Date().toISOString();
    const newStatus = isCallerAdmin ? 'cancelled_by_admin' : 'cancelled_by_passenger';

    // Release assigned or offered driver if any
    if (booking.driverId) {
      const driverRef = db.collection('driverProfiles').doc(booking.driverId);
      transaction.update(driverRef, {
        currentBookingId: null,
        offeredBookingId: null,
        updatedAt: now,
      });
    }

    transaction.update(bookingRef, {
      status: newStatus,
      cancellationReason: reason || 'Cancelled by user',
      cancelledAt: now,
      updatedAt: now,
    });

    return { success: true, bookingId, status: newStatus };
  });
});

/**
 * 7. Driver Trip Completion
 * Releases driver availability upon final completion and increments totalTrips.
 */
export const completeBookingTrip = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Driver authentication required.');
  }

  const { bookingId } = data;
  const driverId = context.auth.uid;

  return db.runTransaction(async (transaction) => {
    const bookingRef = db.collection('bookings').doc(bookingId);
    const driverRef = db.collection('driverProfiles').doc(driverId);
    const bookingDoc = await transaction.get(bookingRef);
    const driverDoc = await transaction.get(driverRef);

    if (!bookingDoc.exists || !driverDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Booking or driver not found.');
    }

    const booking = bookingDoc.data()!;
    if (booking.driverId !== driverId) {
      throw new functions.https.HttpsError('permission-denied', 'You are not assigned to this booking.');
    }

    if (booking.status !== 'in_progress') {
      throw new functions.https.HttpsError('failed-precondition', 'Trip must be in_progress to complete.');
    }

    const now = new Date().toISOString();
    transaction.update(bookingRef, {
      status: 'completed',
      completedAt: now,
      updatedAt: now,
    });

    transaction.update(driverRef, {
      currentBookingId: null,
      offeredBookingId: null,
      totalTrips: admin.firestore.FieldValue.increment(1),
      updatedAt: now,
    });

    return { success: true, status: 'completed' };
  });
});

/**
 * 8. System Dispatch Mode Configuration (Admin-only privilege)
 * Sets backend systemConfig/default document for automatic vs manual dispatch.
 */
export const updateSystemConfig = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Admin authentication required.');
  }

  const callerSnap = await db.collection('users').doc(context.auth.uid).get();
  if (callerSnap.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only administrators can update system dispatch config.');
  }

  const { dispatchMode, offerTimeoutSeconds, autoCascadeEnabled } = data;
  const configRef = db.collection('systemConfig').doc('default');
  const now = new Date().toISOString();

  await configRef.set(
    {
      dispatchMode: dispatchMode || 'automatic',
      offerTimeoutSeconds: offerTimeoutSeconds || 30,
      autoCascadeEnabled: autoCascadeEnabled !== undefined ? autoCascadeEnabled : true,
      updatedAt: now,
      updatedBy: context.auth.uid,
    },
    { merge: true }
  );

  return { success: true, dispatchMode: dispatchMode || 'automatic' };
});

/**
 * 9. Server-side Expired Offer Sweeper
 * Sweeps bookings where dispatchExpiresAt has elapsed and cascades offers.
 */
export const sweepExpiredOffers = functions.https.onCall(async (_data, _context) => {
  const now = new Date();
  const snapshot = await db
    .collection('bookings')
    .where('status', '==', 'driver_assigned')
    .where('assignmentType', '==', 'automatic')
    .get();

  const expiredBookings: string[] = [];
  for (const doc of snapshot.docs) {
    const booking = doc.data();
    if (booking.dispatchExpiresAt && new Date(booking.dispatchExpiresAt).getTime() <= now.getTime()) {
      expiredBookings.push(doc.id);

      await db.runTransaction(async (transaction) => {
        const bRef = db.collection('bookings').doc(doc.id);
        const bDoc = await transaction.get(bRef);
        if (!bDoc.exists) return;
        const bData = bDoc.data()!;
        if (bData.status !== 'driver_assigned') return;

        if (bData.driverId) {
          const dRef = db.collection('driverProfiles').doc(bData.driverId);
          transaction.update(dRef, {
            offeredBookingId: null,
            currentBookingId: null,
            updatedAt: now.toISOString(),
          });
        }

        transaction.update(bRef, {
          driverId: null,
          driverName: null,
          driverPhone: null,
          vehicleNumber: null,
          status: 'pending_assignment',
          lastRejectionReason: 'server_timeout_sweep',
          dispatchAuditLog: admin.firestore.FieldValue.arrayUnion({
            driverId: bData.driverId || 'unknown',
            action: 'timeout',
            timestamp: now.toISOString(),
            reason: 'Reaped by server-side 30s timeout sweeper',
          }),
          updatedAt: now.toISOString(),
        });
      });
    }
  }

  return { success: true, reapedCount: expiredBookings.length, expiredBookings };
});
