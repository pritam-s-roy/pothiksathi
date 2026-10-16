import React from 'react';
import { adminService } from '../services/adminService';

export const DashboardPage: React.FC<{ onNavigate: (tab: string) => void }> = ({ onNavigate }) => {
  const bookings = adminService.getBookings();
  const drivers = adminService.getDrivers();
  const timetables = adminService.getTimetables();

  const config = adminService.getConfig();
  const exhaustedBookings = bookings.filter((b) => b.autoDispatchExhausted && b.status === 'pending_assignment').length;
  const pendingBookings = bookings.filter((b) => b.status === 'pending_assignment').length;
  const activeBookings = bookings.filter((b) => ['driver_assigned', 'driver_accepted', 'driver_arrived', 'in_progress'].includes(b.status)).length;
  const completedToday = bookings.filter((b) => b.status === 'completed').length;
  const pendingDrivers = drivers.filter((d) => d.approvalStatus === 'pending').length;
  const onlineDrivers = drivers.filter((d) => d.approvalStatus === 'approved' && d.isOnline).length;
  const totalRevenue = bookings.filter((b) => b.status === 'completed').reduce((sum, b) => sum + b.fare, 0);

  return (
    <div style={{ padding: '24px' }}>
      {/* Alert banner if pending manual assignment or exhausted requests exist */}
      {(exhaustedBookings > 0 || (config.dispatchMode === 'manual' && pendingBookings > 0)) && (
        <div style={{
          backgroundColor: exhaustedBookings > 0 ? '#ffebee' : '#fff3e0',
          border: `1px solid ${exhaustedBookings > 0 ? '#ffcdd2' : '#ffe0b2'}`,
          borderRadius: '8px',
          padding: '16px',
          marginBottom: '24px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <span style={{ fontSize: '24px' }}>{exhaustedBookings > 0 ? '🚨' : '⚠️'}</span>
            <div>
              <strong style={{ color: exhaustedBookings > 0 ? '#b71c1c' : '#e65100', fontSize: '15px' }}>
                {exhaustedBookings > 0
                  ? `${exhaustedBookings} Booking(s) Require Immediate Manual Driver Assignment (Auto-Dispatch Exhausted)!`
                  : `${pendingBookings} Booking Request(s) Awaiting Manual Driver Assignment!`}
              </strong>
              <p style={{ fontSize: '13px', color: '#5e6d5e', marginTop: '2px' }}>
                {exhaustedBookings > 0
                  ? 'All eligible candidate drivers timed out or declined. Manual administrator dispatch needed.'
                  : 'Manual dispatch mode is active. Please review and assign an approved online captain.'}
              </p>
            </div>
          </div>
          <button
            onClick={() => onNavigate('bookings')}
            style={{
              backgroundColor: exhaustedBookings > 0 ? '#b71c1c' : '#e65100',
              color: '#ffffff',
              border: 'none',
              padding: '8px 16px',
              borderRadius: '6px',
              fontWeight: '600',
              fontSize: '13px',
              cursor: 'pointer',
            }}
          >
            Open Dispatch Console →
          </button>
        </div>
      )}

      {/* KPI Cards Grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: '16px',
        marginBottom: '24px',
      }}>
        <div style={{ backgroundColor: '#ffffff', border: '1px solid #e0e7e0', borderRadius: '10px', padding: '16px' }}>
          <div style={{ fontSize: '12px', color: '#5e6d5e', fontWeight: 'bold' }}>PENDING ASSIGNMENTS</div>
          <div style={{ fontSize: '28px', fontWeight: 'bold', color: '#e65100', marginTop: '4px' }}>{pendingBookings}</div>
          <div style={{ fontSize: '11px', color: '#5e6d5e', marginTop: '4px' }}>Requires manual dispatch</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', border: '1px solid #e0e7e0', borderRadius: '10px', padding: '16px' }}>
          <div style={{ fontSize: '12px', color: '#5e6d5e', fontWeight: 'bold' }}>ACTIVE TRIPS ON ROAD</div>
          <div style={{ fontSize: '28px', fontWeight: 'bold', color: '#0277bd', marginTop: '4px' }}>{activeBookings}</div>
          <div style={{ fontSize: '11px', color: '#5e6d5e', marginTop: '4px' }}>In progress across Karimpur</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', border: '1px solid #e0e7e0', borderRadius: '10px', padding: '16px' }}>
          <div style={{ fontSize: '12px', color: '#5e6d5e', fontWeight: 'bold' }}>ONLINE APPROVED DRIVERS</div>
          <div style={{ fontSize: '28px', fontWeight: 'bold', color: '#2e7d32', marginTop: '4px' }}>{onlineDrivers}</div>
          <div style={{ fontSize: '11px', color: '#5e6d5e', marginTop: '4px' }}>Available for assignment</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', border: '1px solid #e0e7e0', borderRadius: '10px', padding: '16px' }}>
          <div style={{ fontSize: '12px', color: '#5e6d5e', fontWeight: 'bold' }}>DRIVER KYC APPROVALS</div>
          <div style={{ fontSize: '28px', fontWeight: 'bold', color: '#d84315', marginTop: '4px' }}>{pendingDrivers}</div>
          <div style={{ fontSize: '11px', color: '#5e6d5e', marginTop: '4px' }}>Applications awaiting review</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', border: '1px solid #e0e7e0', borderRadius: '10px', padding: '16px' }}>
          <div style={{ fontSize: '12px', color: '#5e6d5e', fontWeight: 'bold' }}>COMPLETED TRIPS (TODAY)</div>
          <div style={{ fontSize: '28px', fontWeight: 'bold', color: '#1b5e20', marginTop: '4px' }}>{completedToday}</div>
          <div style={{ fontSize: '11px', color: '#5e6d5e', marginTop: '4px' }}>Total cash: ₹{totalRevenue}</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', border: '1px solid #e0e7e0', borderRadius: '10px', padding: '16px' }}>
          <div style={{ fontSize: '12px', color: '#5e6d5e', fontWeight: 'bold' }}>BUS TIMETABLE ROUTES</div>
          <div style={{ fontSize: '28px', fontWeight: 'bold', color: '#1565c0', marginTop: '4px' }}>{timetables.length}</div>
          <div style={{ fontSize: '11px', color: '#5e6d5e', marginTop: '4px' }}>Offline-cached for commuters</div>
        </div>
      </div>

      {/* Quick Status Table: Recent Bookings */}
      <div style={{ backgroundColor: '#ffffff', border: '1px solid #e0e7e0', borderRadius: '10px', padding: '20px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 'bold' }}>Live Karimpur Booking Log</h3>
          <button
            onClick={() => onNavigate('bookings')}
            style={{
              backgroundColor: '#e8f5e9',
              color: '#1b5e20',
              border: 'none',
              padding: '6px 12px',
              borderRadius: '6px',
              fontWeight: '600',
              fontSize: '12px',
            }}
          >
            View All ({bookings.length}) →
          </button>
        </div>

        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
          <thead>
            <tr style={{ borderBottom: '2px solid #e0e7e0', color: '#5e6d5e' }}>
              <th style={{ padding: '10px 8px' }}>Booking ID</th>
              <th style={{ padding: '10px 8px' }}>Passenger</th>
              <th style={{ padding: '10px 8px' }}>Route</th>
              <th style={{ padding: '10px 8px' }}>Type</th>
              <th style={{ padding: '10px 8px' }}>Fare</th>
              <th style={{ padding: '10px 8px' }}>Driver</th>
              <th style={{ padding: '10px 8px' }}>Status</th>
            </tr>
          </thead>
          <tbody>
            {bookings.slice(0, 5).map((b) => (
              <tr key={b.id} style={{ borderBottom: '1px solid #f0f0f0' }}>
                <td style={{ padding: '12px 8px', fontWeight: '600' }}>{b.id}</td>
                <td style={{ padding: '12px 8px' }}>
                  <div>{b.passengerName}</div>
                  <div style={{ fontSize: '11px', color: '#5e6d5e' }}>{b.passengerPhone}</div>
                </td>
                <td style={{ padding: '12px 8px' }}>{b.originName} → {b.destinationName}</td>
                <td style={{ padding: '12px 8px' }}>
                  <span style={{
                    padding: '3px 8px',
                    borderRadius: '12px',
                    fontSize: '11px',
                    fontWeight: '600',
                    backgroundColor: b.bookingType === 'shared' ? '#e8f5e9' : '#fff3e0',
                    color: b.bookingType === 'shared' ? '#1b5e20' : '#e65100',
                  }}>
                    {b.bookingType.toUpperCase()} ({b.passengerCount}p)
                  </span>
                </td>
                <td style={{ padding: '12px 8px', fontWeight: 'bold' }}>₹{b.fare}</td>
                <td style={{ padding: '12px 8px' }}>
                  {b.driverName ? (
                    <div>
                      <div>{b.driverName}</div>
                      <div style={{ fontSize: '10px', color: '#5e6d5e' }}>{b.vehicleNumber}</div>
                    </div>
                  ) : (
                    <span style={{ color: '#e65100', fontStyle: 'italic' }}>Unassigned</span>
                  )}
                </td>
                <td style={{ padding: '12px 8px' }}>
                  <span style={{
                    padding: '3px 8px',
                    borderRadius: '12px',
                    fontSize: '11px',
                    fontWeight: '600',
                    backgroundColor: b.status === 'completed' ? '#e8f5e9' : b.status === 'pending_assignment' ? '#fff3e0' : '#e1f5fe',
                    color: b.status === 'completed' ? '#2e7d32' : b.status === 'pending_assignment' ? '#e65100' : '#0277bd',
                  }}>
                    {b.status.replace(/_/g, ' ')}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
