import React, { useState } from 'react';
import { adminService } from '../services/adminService';
import { Booking } from '../types';

export const BookingManagementPage: React.FC = () => {
  const [filter, setFilter] = useState<string>('pending');
  const [bookings, setBookings] = useState<Booking[]>(adminService.getBookings());
  const [selectedDriverMap, setSelectedDriverMap] = useState<Record<string, string>>({});
  const [expandedAuditMap, setExpandedAuditMap] = useState<Record<string, boolean>>({});
  const [reassignOpenMap, setReassignOpenMap] = useState<Record<string, boolean>>({});
  const [systemConfig, setSystemConfig] = useState(adminService.getConfig());

  const availableDrivers = adminService.getApprovedOnlineDrivers();
  const exhaustedBookings = bookings.filter((b) => b.autoDispatchExhausted && b.status === 'pending_assignment');
  const activeOffers = bookings.filter((b) => b.status === 'driver_assigned' && b.assignmentType === 'automatic');

  const reloadData = () => {
    setBookings(adminService.getBookings());
    setSystemConfig(adminService.getConfig());
  };

  const handleToggleDispatchMode = () => {
    const newMode = systemConfig.dispatchMode === 'automatic' ? 'manual' : 'automatic';
    adminService.setDispatchMode(newMode);
    reloadData();
  };

  const handleRunAutoDispatch = (bookingId: string) => {
    const success = adminService.runAutoDispatch(bookingId);
    reloadData();
    if (!success) {
      alert('Could not auto-match driver: No available approved online drivers within proximity or all candidates already attempted.');
    }
  };

  const handleRetryAutoDispatch = (bookingId: string) => {
    const success = adminService.retryAutoDispatch(bookingId);
    reloadData();
    if (success) {
      alert(`Auto-dispatch reset and candidate matching re-initiated for booking ${bookingId}.`);
    } else {
      alert('Could not match any driver: No approved online drivers currently available.');
    }
  };

  const handleAssignDriver = (bookingId: string) => {
    const driverId = selectedDriverMap[bookingId] || (availableDrivers[0] ? availableDrivers[0].driverId : '');
    if (!driverId) {
      alert('Please select an online approved driver to assign.');
      return;
    }

    const success = adminService.assignDriver(bookingId, driverId);
    if (success) {
      alert(`Driver assigned successfully to booking ${bookingId}! The driver app will now receive this assignment.`);
      setReassignOpenMap({ ...reassignOpenMap, [bookingId]: false });
      reloadData();
    }
  };

  const handleDriverOfferResponse = (bookingId: string, driverId: string, action: 'accepted' | 'rejected') => {
    adminService.respondDriverOffer(
      bookingId,
      driverId,
      action,
      action === 'accepted' ? 'Simulated driver app acceptance' : 'Simulated driver rejection or 30s timeout'
    );
    reloadData();
  };

  const handleCancelBooking = (bookingId: string) => {
    if (confirm(`Are you sure you want to cancel booking ${bookingId}?`)) {
      adminService.cancelBooking(bookingId);
      reloadData();
    }
  };

  const toggleAuditTrail = (bookingId: string) => {
    setExpandedAuditMap((prev) => ({
      ...prev,
      [bookingId]: !prev[bookingId],
    }));
  };

  const toggleReassign = (bookingId: string) => {
    setReassignOpenMap((prev) => ({
      ...prev,
      [bookingId]: !prev[bookingId],
    }));
  };

  const filteredBookings = bookings.filter((b) => {
    if (filter === 'pending') return b.status === 'pending_assignment';
    if (filter === 'offered') return b.status === 'driver_assigned' && b.assignmentType === 'automatic';
    if (filter === 'active') return ['driver_accepted', 'driver_arrived', 'in_progress'].includes(b.status);
    if (filter === 'completed') return b.status === 'completed';
    return true;
  });

  return (
    <div style={{ padding: '24px' }}>
      {/* Page Header with Dispatch Mode Switcher */}
      <div style={{
        backgroundColor: '#ffffff',
        border: '1px solid #e0e7e0',
        borderRadius: '12px',
        padding: '20px',
        marginBottom: '20px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        flexWrap: 'wrap',
        gap: '16px',
        boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
      }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <h2 style={{ fontSize: '20px', fontWeight: 'bold', color: '#1e261e', margin: 0 }}>
              Dispatch & Booking Control Console
            </h2>
            <span style={{
              padding: '3px 10px',
              borderRadius: '12px',
              fontSize: '11px',
              fontWeight: 'bold',
              backgroundColor: systemConfig.dispatchMode === 'automatic' ? '#e8f5e9' : '#fff3e0',
              color: systemConfig.dispatchMode === 'automatic' ? '#1b5e20' : '#e65100',
              border: `1px solid ${systemConfig.dispatchMode === 'automatic' ? '#a5d6a7' : '#ffcc80'}`,
            }}>
              {systemConfig.dispatchMode === 'automatic' ? '🤖 AUTOMATIC MATCHING ACTIVE' : '👤 MANUAL DISPATCH ONLY'}
            </span>
          </div>
          <p style={{ fontSize: '13px', color: '#5e6d5e', marginTop: '4px', marginBottom: 0 }}>
            {systemConfig.dispatchMode === 'automatic'
              ? 'Bookings are sequentially offered to nearest online approved drivers with a 30s countdown acceptance window before cascading.'
              : 'Automatic matching is paused. All passenger requests queue for manual administrator driver assignment.'}
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '14px', flexWrap: 'wrap' }}>
          <div style={{
            display: 'flex',
            gap: '12px',
            fontSize: '12px',
            backgroundColor: '#f8faf8',
            padding: '8px 14px',
            borderRadius: '8px',
            border: '1px solid #e0e7e0',
          }}>
            <div>Available Drivers: <strong style={{ color: '#2e7d32' }}>{availableDrivers.length}</strong></div>
            <div style={{ color: '#ccc' }}>|</div>
            <div>Active Offers: <strong style={{ color: '#0277bd' }}>{activeOffers.length}</strong></div>
            {exhaustedBookings.length > 0 && (
              <>
                <div style={{ color: '#ccc' }}>|</div>
                <div>Fallback Alerts: <strong style={{ color: '#c62828' }}>{exhaustedBookings.length}</strong></div>
              </>
            )}
          </div>

          <button
            onClick={handleToggleDispatchMode}
            style={{
              padding: '9px 18px',
              borderRadius: '8px',
              border: 'none',
              cursor: 'pointer',
              fontWeight: '600',
              fontSize: '13px',
              backgroundColor: systemConfig.dispatchMode === 'automatic' ? '#fff3e0' : '#e8f5e9',
              color: systemConfig.dispatchMode === 'automatic' ? '#d84315' : '#1b5e20',
              boxShadow: '0 1px 2px rgba(0,0,0,0.06)',
            }}
          >
            {systemConfig.dispatchMode === 'automatic' ? 'Switch to Manual Dispatch' : 'Switch to Automatic Dispatch'}
          </button>
        </div>
      </div>

      {/* High-visibility Alert for Auto-Dispatch Exhausted Bookings */}
      {exhaustedBookings.length > 0 && (
        <div style={{
          backgroundColor: '#ffebee',
          border: '1px solid #ffcdd2',
          borderRadius: '10px',
          padding: '16px 20px',
          marginBottom: '20px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '12px',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <span style={{ fontSize: '24px' }}>🚨</span>
            <div>
              <strong style={{ color: '#b71c1c', fontSize: '15px' }}>
                {exhaustedBookings.length} Booking(s) Require Immediate Manual Dispatch!
              </strong>
              <div style={{ fontSize: '13px', color: '#c62828', marginTop: '2px' }}>
                All nearby candidate drivers declined or timed out. Assign a driver manually below or retry auto-dispatch.
              </div>
            </div>
          </div>
          <button
            onClick={() => setFilter('pending')}
            style={{
              backgroundColor: '#b71c1c',
              color: '#ffffff',
              border: 'none',
              padding: '8px 16px',
              borderRadius: '6px',
              fontWeight: 'bold',
              fontSize: '12px',
              cursor: 'pointer',
            }}
          >
            Filter Pending Requests ({exhaustedBookings.length})
          </button>
        </div>
      )}

      {/* Filter Tabs */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '20px', flexWrap: 'wrap' }}>
        {[
          { id: 'pending', label: `Pending / Action Required (${bookings.filter((b) => b.status === 'pending_assignment').length})` },
          { id: 'offered', label: `Active 30s Offers (${activeOffers.length})` },
          { id: 'active', label: 'Active on Road' },
          { id: 'completed', label: 'Completed' },
          { id: 'all', label: `All Bookings (${bookings.length})` },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setFilter(tab.id)}
            style={{
              padding: '8px 16px',
              borderRadius: '6px',
              border: filter === tab.id ? '1px solid #1b5e20' : '1px solid #e0e7e0',
              backgroundColor: filter === tab.id ? '#1b5e20' : '#ffffff',
              color: filter === tab.id ? '#ffffff' : '#1e261e',
              fontSize: '13px',
              fontWeight: filter === tab.id ? '600' : 'normal',
              cursor: 'pointer',
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Bookings List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {filteredBookings.length === 0 ? (
          <div style={{
            backgroundColor: '#ffffff',
            border: '1px solid #e0e7e0',
            borderRadius: '10px',
            padding: '40px',
            textAlign: 'center',
            color: '#5e6d5e',
          }}>
            No bookings found under this filter.
          </div>
        ) : (
          filteredBookings.map((b) => (
            <div
              key={b.id}
              style={{
                backgroundColor: '#ffffff',
                border: b.autoDispatchExhausted
                  ? '2px solid #d32f2f'
                  : b.status === 'pending_assignment'
                  ? '2px solid #ef6c00'
                  : '1px solid #e0e7e0',
                borderRadius: '10px',
                padding: '20px',
                boxShadow: '0 1px 3px rgba(0,0,0,0.03)',
              }}
            >
              {/* Booking Header & Badges */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '12px' }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                    <span style={{ fontWeight: 'bold', fontSize: '15px' }}>{b.id}</span>

                    {/* Booking Type */}
                    <span style={{
                      padding: '2px 8px',
                      borderRadius: '12px',
                      fontSize: '11px',
                      fontWeight: 'bold',
                      backgroundColor: b.bookingType === 'shared' ? '#e8f5e9' : '#fff3e0',
                      color: b.bookingType === 'shared' ? '#1b5e20' : '#e65100',
                    }}>
                      {b.bookingType.toUpperCase()} ({b.passengerCount} passenger{b.passengerCount > 1 ? 's' : ''})
                    </span>

                    {/* Booking Status */}
                    <span style={{
                      padding: '2px 8px',
                      borderRadius: '12px',
                      fontSize: '11px',
                      fontWeight: '600',
                      backgroundColor: b.status === 'completed'
                        ? '#e8f5e9'
                        : b.status === 'pending_assignment'
                        ? '#fff3e0'
                        : '#e1f5fe',
                      color: b.status === 'completed'
                        ? '#2e7d32'
                        : b.status === 'pending_assignment'
                        ? '#e65100'
                        : '#0277bd',
                    }}>
                      {b.status.replace(/_/g, ' ')}
                    </span>

                    {/* Assignment Type Badge */}
                    <span style={{
                      padding: '2px 8px',
                      borderRadius: '12px',
                      fontSize: '11px',
                      fontWeight: 'bold',
                      backgroundColor: b.assignmentType === 'automatic'
                        ? '#e8f5e9'
                        : b.assignmentType === 'manual_fallback'
                        ? '#ffebee'
                        : '#ede7f6',
                      color: b.assignmentType === 'automatic'
                        ? '#1b5e20'
                        : b.assignmentType === 'manual_fallback'
                        ? '#c62828'
                        : '#4527a0',
                    }}>
                      {b.assignmentType === 'automatic'
                        ? '🤖 Auto-Dispatched'
                        : b.assignmentType === 'manual_fallback'
                        ? '⚠️ Auto-Exhausted Fallback'
                        : '👤 Manual Assignment'}
                    </span>
                  </div>

                  <div style={{ marginTop: '10px', fontSize: '14px' }}>
                    <strong>{b.originName}</strong> → <strong>{b.destinationName}</strong> ({b.distanceKm} km)
                  </div>
                  <div style={{ fontSize: '12px', color: '#5e6d5e', marginTop: '3px' }}>
                    Passenger: <strong>{b.passengerName}</strong> ({b.passengerPhone}) • Requested: {new Date(b.createdAt).toLocaleTimeString()}
                  </div>
                </div>

                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: '22px', fontWeight: 'bold', color: '#1b5e20' }}>₹{b.fare}</div>
                  <div style={{ fontSize: '11px', color: '#5e6d5e' }}>Agreed Cash Tariff</div>
                </div>
              </div>

              {/* Live Offering Box (For Automatic Offers during 30s window) */}
              {b.status === 'driver_assigned' && b.assignmentType === 'automatic' && (
                <div style={{
                  marginTop: '16px',
                  backgroundColor: '#e3f2fd',
                  border: '1px solid #90caf9',
                  borderRadius: '8px',
                  padding: '14px',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  flexWrap: 'wrap',
                  gap: '12px',
                }}>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span style={{ fontSize: '18px' }}>⏳</span>
                      <strong style={{ color: '#0d47a1', fontSize: '14px' }}>
                        Driver Offer Active (30-second window)
                      </strong>
                    </div>
                    <div style={{ fontSize: '12px', color: '#1565c0', marginTop: '2px' }}>
                      Offered to candidate: <strong>{b.driverName}</strong> ({b.vehicleNumber}) • Phone: {b.driverPhone}
                      {b.dispatchExpiresAt && ` • Expires: ${new Date(b.dispatchExpiresAt).toLocaleTimeString()}`}
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button
                      onClick={() => handleDriverOfferResponse(b.id, b.driverId!, 'accepted')}
                      style={{
                        backgroundColor: '#2e7d32',
                        color: '#ffffff',
                        border: 'none',
                        padding: '6px 12px',
                        borderRadius: '6px',
                        fontSize: '12px',
                        fontWeight: '600',
                        cursor: 'pointer',
                      }}
                      title="Simulate driver tapping Accept in the Flutter Driver App"
                    >
                      ✓ Simulate Driver Accept
                    </button>
                    <button
                      onClick={() => handleDriverOfferResponse(b.id, b.driverId!, 'rejected')}
                      style={{
                        backgroundColor: '#d84315',
                        color: '#ffffff',
                        border: 'none',
                        padding: '6px 12px',
                        borderRadius: '6px',
                        fontSize: '12px',
                        fontWeight: '600',
                        cursor: 'pointer',
                      }}
                      title="Simulate 30s timeout or driver decline (triggers auto-cascade to next candidate)"
                    >
                      ✗ Simulate Timeout / Decline
                    </button>
                  </div>
                </div>
              )}

              {/* Assignment Controls for Pending */}
              {b.status === 'pending_assignment' && (
                <div style={{
                  marginTop: '16px',
                  paddingTop: '16px',
                  borderTop: '1px dashed #e0e7e0',
                }}>
                  {b.autoDispatchExhausted && (
                    <div style={{
                      backgroundColor: '#ffebee',
                      border: '1px solid #ffcdd2',
                      borderRadius: '6px',
                      padding: '10px 12px',
                      fontSize: '12px',
                      color: '#c62828',
                      marginBottom: '12px',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                    }}>
                      <div>
                        <strong>⚠️ Automatic Matching Exhausted:</strong> All eligible candidates declined or timed out.
                        Please assign an available driver manually or retry.
                      </div>
                      <button
                        onClick={() => handleRetryAutoDispatch(b.id)}
                        style={{
                          backgroundColor: '#c62828',
                          color: '#ffffff',
                          border: 'none',
                          padding: '4px 10px',
                          borderRadius: '4px',
                          fontSize: '11px',
                          fontWeight: 'bold',
                          cursor: 'pointer',
                        }}
                      >
                        🔄 Retry Auto-Dispatch
                      </button>
                    </div>
                  )}

                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    flexWrap: 'wrap',
                    gap: '12px',
                  }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flex: 1, minWidth: '280px' }}>
                      <span style={{ fontSize: '13px', fontWeight: '600' }}>Manual Driver Assignment:</span>
                      <select
                        value={selectedDriverMap[b.id] || ''}
                        onChange={(e) => setSelectedDriverMap({ ...selectedDriverMap, [b.id]: e.target.value })}
                        style={{
                          padding: '8px 12px',
                          borderRadius: '6px',
                          border: '1px solid #1b5e20',
                          backgroundColor: '#ffffff',
                          fontSize: '13px',
                          flex: 1,
                        }}
                      >
                        <option value="">-- Choose Online Driver ({availableDrivers.length} available) --</option>
                        {availableDrivers.map((d) => (
                          <option key={d.driverId} value={d.driverId}>
                            {d.driverName} ({d.vehicleNumber}) - Hub: {d.registeredHub || 'Karimpur'} - ⭐{d.rating}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div style={{ display: 'flex', gap: '8px' }}>
                      {systemConfig.dispatchMode === 'automatic' && !b.autoDispatchExhausted && (
                        <button
                          onClick={() => handleRunAutoDispatch(b.id)}
                          style={{
                            backgroundColor: '#0277bd',
                            color: '#ffffff',
                            border: 'none',
                            padding: '8px 14px',
                            borderRadius: '6px',
                            fontWeight: '600',
                            fontSize: '13px',
                            cursor: 'pointer',
                          }}
                        >
                          🤖 Trigger Auto-Dispatch
                        </button>
                      )}
                      <button
                        onClick={() => handleAssignDriver(b.id)}
                        style={{
                          backgroundColor: '#1b5e20',
                          color: '#ffffff',
                          border: 'none',
                          padding: '8px 16px',
                          borderRadius: '6px',
                          fontWeight: '600',
                          fontSize: '13px',
                          cursor: 'pointer',
                        }}
                      >
                        Confirm Driver Assignment
                      </button>
                      <button
                        onClick={() => handleCancelBooking(b.id)}
                        style={{
                          backgroundColor: '#ffffff',
                          color: '#c62828',
                          border: '1px solid #c62828',
                          padding: '8px 12px',
                          borderRadius: '6px',
                          fontSize: '13px',
                          cursor: 'pointer',
                        }}
                      >
                        Reject / Cancel
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {/* Driver Details if Assigned (Accepted or Active) */}
              {b.driverName && b.status !== 'pending_assignment' && (
                <div style={{
                  marginTop: '12px',
                  paddingTop: '12px',
                  borderTop: '1px solid #f0f0f0',
                  fontSize: '12px',
                  color: '#5e6d5e',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  flexWrap: 'wrap',
                  gap: '8px',
                }}>
                  <div>
                    Assigned Captain: <strong>{b.driverName}</strong> ({b.driverPhone}) • Vehicle: <strong>{b.vehicleNumber}</strong>
                    {b.assignedAt && ` • Assigned: ${new Date(b.assignedAt).toLocaleTimeString()}`}
                  </div>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button
                      onClick={() => toggleReassign(b.id)}
                      style={{
                        backgroundColor: '#ffffff',
                        border: '1px solid #b0bec5',
                        color: '#37474f',
                        padding: '4px 8px',
                        borderRadius: '4px',
                        fontSize: '11px',
                        cursor: 'pointer',
                      }}
                    >
                      {reassignOpenMap[b.id] ? 'Close Reassign' : 'Admin Reassign Driver'}
                    </button>
                  </div>
                </div>
              )}

              {/* Reassign Panel for Admin Override */}
              {reassignOpenMap[b.id] && (
                <div style={{
                  marginTop: '10px',
                  padding: '12px',
                  backgroundColor: '#f5f5f5',
                  borderRadius: '6px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '10px',
                  flexWrap: 'wrap',
                }}>
                  <span style={{ fontSize: '12px', fontWeight: 'bold' }}>Reassign To:</span>
                  <select
                    value={selectedDriverMap[b.id] || ''}
                    onChange={(e) => setSelectedDriverMap({ ...selectedDriverMap, [b.id]: e.target.value })}
                    style={{
                      padding: '6px 10px',
                      borderRadius: '4px',
                      border: '1px solid #999',
                      fontSize: '12px',
                      flex: 1,
                    }}
                  >
                    <option value="">-- Choose New Driver ({availableDrivers.length} ready) --</option>
                    {availableDrivers.map((d) => (
                      <option key={d.driverId} value={d.driverId}>
                        {d.driverName} ({d.vehicleNumber}) - ⭐{d.rating}
                      </option>
                    ))}
                  </select>
                  <button
                    onClick={() => handleAssignDriver(b.id)}
                    style={{
                      backgroundColor: '#e65100',
                      color: '#ffffff',
                      border: 'none',
                      padding: '6px 12px',
                      borderRadius: '4px',
                      fontSize: '12px',
                      fontWeight: 'bold',
                      cursor: 'pointer',
                    }}
                  >
                    Override & Reassign
                  </button>
                </div>
              )}

              {/* Dispatch Audit History Toggle */}
              <div style={{ marginTop: '14px', paddingTop: '10px', borderTop: '1px solid #f9f9f9', display: 'flex', justifyContent: 'flex-end' }}>
                <button
                  onClick={() => toggleAuditTrail(b.id)}
                  style={{
                    backgroundColor: 'transparent',
                    border: 'none',
                    color: '#2e7d32',
                    fontSize: '12px',
                    fontWeight: '600',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                  }}
                >
                  📋 {expandedAuditMap[b.id] ? 'Hide Dispatch Audit Trail' : `View Dispatch Audit Trail (${b.dispatchAuditLog?.length || 0} events)`}
                </button>
              </div>

              {/* Expandable Audit Log Timeline */}
              {expandedAuditMap[b.id] && (
                <div style={{
                  marginTop: '10px',
                  backgroundColor: '#fafafa',
                  border: '1px solid #e0e7e0',
                  borderRadius: '6px',
                  padding: '12px',
                }}>
                  <div style={{ fontSize: '12px', fontWeight: 'bold', marginBottom: '8px', color: '#1b5e20' }}>
                    Dispatch & State Transition Audit Trail (ID: {b.id})
                  </div>
                  {!b.dispatchAuditLog || b.dispatchAuditLog.length === 0 ? (
                    <div style={{ fontSize: '11px', color: '#777' }}>No audit trail entries recorded yet.</div>
                  ) : (
                    <table style={{ width: '100%', fontSize: '11px', borderCollapse: 'collapse', textAlign: 'left' }}>
                      <thead>
                        <tr style={{ borderBottom: '1px solid #e0e7e0', color: '#555' }}>
                          <th style={{ padding: '4px 6px' }}>Time</th>
                          <th style={{ padding: '4px 6px' }}>Action</th>
                          <th style={{ padding: '4px 6px' }}>Target Driver</th>
                          <th style={{ padding: '4px 6px' }}>Details / Reason</th>
                        </tr>
                      </thead>
                      <tbody>
                        {b.dispatchAuditLog.map((log, idx) => (
                          <tr key={idx} style={{ borderBottom: '1px solid #f0f0f0' }}>
                            <td style={{ padding: '6px', color: '#555', whiteSpace: 'nowrap' }}>
                              {new Date(log.timestamp).toLocaleTimeString()}
                            </td>
                            <td style={{ padding: '6px' }}>
                              <span style={{
                                padding: '2px 6px',
                                borderRadius: '4px',
                                fontWeight: 'bold',
                                fontSize: '10px',
                                backgroundColor: log.action === 'offered'
                                  ? '#e3f2fd'
                                  : log.action === 'accepted'
                                  ? '#e8f5e9'
                                  : log.action === 'rejected'
                                  ? '#fff3e0'
                                  : log.action === 'timeout'
                                  ? '#ffebee'
                                  : '#ede7f6',
                                color: log.action === 'offered'
                                  ? '#0d47a1'
                                  : log.action === 'accepted'
                                  ? '#1b5e20'
                                  : log.action === 'rejected'
                                  ? '#e65100'
                                  : log.action === 'timeout'
                                  ? '#c62828'
                                  : '#4527a0',
                              }}>
                                {log.action.toUpperCase()}
                              </span>
                            </td>
                            <td style={{ padding: '6px', fontWeight: '500' }}>
                              {log.driverName || log.driverId || 'System'}
                            </td>
                            <td style={{ padding: '6px', color: '#444' }}>
                              {log.reason || 'N/A'}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
};
