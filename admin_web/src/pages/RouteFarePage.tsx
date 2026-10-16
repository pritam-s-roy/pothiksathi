import React, { useState } from 'react';
import { adminService } from '../services/adminService';
import { Route, RouteFare } from '../types';

export const RouteFarePage: React.FC = () => {
  const [routes] = useState<Route[]>(adminService.getRoutes());
  const [fares, setFares] = useState<RouteFare[]>(adminService.getFares());
  const [editingFare, setEditingFare] = useState<RouteFare | null>(null);

  const [sharedRate, setSharedRate] = useState<number>(10);
  const [privateRate, setPrivateRate] = useState<number>(20);
  const [minFare, setMinFare] = useState<number>(20);

  const startEdit = (fare: RouteFare) => {
    setEditingFare(fare);
    setSharedRate(fare.sharedFarePerPassenger);
    setPrivateRate(fare.privateBaseFare);
    setMinFare(fare.minimumFare);
  };

  const handleSave = () => {
    if (!editingFare) return;
    adminService.updateRouteFare(editingFare.routeId, sharedRate, privateRate, minFare);
    setFares(adminService.getFares());
    setEditingFare(null);
    alert('Tariff updated and verified for route!');
  };

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <div>
          <h2 style={{ fontSize: '20px', fontWeight: 'bold' }}>Karimpur Route & Tariff Management</h2>
          <p style={{ fontSize: '13px', color: '#5e6d5e' }}>
            Maintain verified public tariffs. Fares are re-validated by server Cloud Functions on every booking.
          </p>
        </div>
      </div>

      {/* Verified Local Tariff Notice Banner */}
      <div style={{
        backgroundColor: '#e8f5e9',
        border: '1px solid #c8e6c9',
        borderRadius: '8px',
        padding: '16px',
        marginBottom: '24px',
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
      }}>
        <span style={{ fontSize: '24px' }}>📜</span>
        <div>
          <strong style={{ color: '#1b5e20', fontSize: '14px' }}>Karimpur Municipal & Panchayat Rate Card Rules</strong>
          <p style={{ fontSize: '12px', color: '#2e7d32', marginTop: '2px' }}>
            1. Standard Local Shared TOTO: Fixed ₹10/seat on designated town corridors. Max 4 passengers.<br/>
            2. Private Reserve Rides: Full vehicle charge with minimum floor of ₹20. No bargaining on verified routes.
          </p>
        </div>
      </div>

      {/* Routes Table */}
      <div style={{ backgroundColor: '#ffffff', border: '1px solid #e0e7e0', borderRadius: '10px', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
          <thead>
            <tr style={{ backgroundColor: '#f9fbf9', borderBottom: '2px solid #e0e7e0', color: '#5e6d5e' }}>
              <th style={{ padding: '12px 16px' }}>Route ID & Name</th>
              <th style={{ padding: '12px 16px' }}>Endpoints</th>
              <th style={{ padding: '12px 16px' }}>Distance / Time</th>
              <th style={{ padding: '12px 16px' }}>Shared Tariff</th>
              <th style={{ padding: '12px 16px' }}>Private Base</th>
              <th style={{ padding: '12px 16px' }}>Min Threshold</th>
              <th style={{ padding: '12px 16px', textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {routes.map((r) => {
              const fare = fares.find((f) => f.routeId === r.id);
              return (
                <tr key={r.id} style={{ borderBottom: '1px solid #f0f0f0' }}>
                  <td style={{ padding: '14px 16px' }}>
                    <div style={{ fontWeight: 'bold' }}>{r.name}</div>
                    <div style={{ fontSize: '11px', color: '#5e6d5e' }}>ID: {r.id}</div>
                  </td>
                  <td style={{ padding: '14px 16px' }}>
                    <div>{r.origin}</div>
                    <div style={{ fontSize: '11px', color: '#5e6d5e' }}>↕ {r.destination}</div>
                  </td>
                  <td style={{ padding: '14px 16px' }}>
                    <div>{r.distanceKm} km</div>
                    <div style={{ fontSize: '11px', color: '#5e6d5e' }}>~{r.estimatedMinutes} mins</div>
                  </td>
                  <td style={{ padding: '14px 16px' }}>
                    <strong style={{ color: '#1b5e20', fontSize: '14px' }}>₹{fare?.sharedFarePerPassenger || 10}</strong>
                    <span style={{ fontSize: '11px', color: '#5e6d5e' }}> / seat</span>
                  </td>
                  <td style={{ padding: '14px 16px' }}>
                    <strong>₹{fare?.privateBaseFare || 20}</strong>
                    <div style={{ fontSize: '10px', color: '#5e6d5e' }}>whole vehicle</div>
                  </td>
                  <td style={{ padding: '14px 16px' }}>
                    <span style={{ backgroundColor: '#f5f5f5', padding: '2px 6px', borderRadius: '4px', fontSize: '11px' }}>
                      ₹{fare?.minimumFare || 20} min
                    </span>
                  </td>
                  <td style={{ padding: '14px 16px', textAlign: 'right' }}>
                    {fare && (
                      <button
                        onClick={() => startEdit(fare)}
                        style={{
                          backgroundColor: '#e8f5e9',
                          color: '#1b5e20',
                          border: '1px solid #c8e6c9',
                          padding: '6px 12px',
                          borderRadius: '4px',
                          fontWeight: '600',
                          fontSize: '12px',
                        }}
                      >
                        Edit Tariff
                      </button>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Edit Tariff Modal */}
      {editingFare && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(0,0,0,0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 999,
        }}>
          <div style={{
            backgroundColor: '#ffffff',
            borderRadius: '10px',
            padding: '24px',
            width: '420px',
            maxWidth: '90%',
            boxShadow: '0 8px 30px rgba(0,0,0,0.2)',
          }}>
            <h3 style={{ fontSize: '16px', fontWeight: 'bold', marginBottom: '4px' }}>
              Edit Route Tariff: {editingFare.routeId}
            </h3>
            <p style={{ fontSize: '12px', color: '#5e6d5e', marginBottom: '16px' }}>
              Adjust rates for this designated corridor. Fares apply immediately to new bookings.
            </p>

            <div style={{ marginBottom: '14px' }}>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>
                Shared Fare Per Passenger (₹):
              </label>
              <input
                type="number"
                value={sharedRate}
                onChange={(e) => setSharedRate(Number(e.target.value))}
                style={{ width: '100%', padding: '8px 12px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
              />
            </div>

            <div style={{ marginBottom: '14px' }}>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>
                Private Base Fare (Whole Vehicle) (₹):
              </label>
              <input
                type="number"
                value={privateRate}
                onChange={(e) => setPrivateRate(Number(e.target.value))}
                style={{ width: '100%', padding: '8px 12px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
              />
            </div>

            <div style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>
                Minimum Floor Fare (₹):
              </label>
              <input
                type="number"
                value={minFare}
                onChange={(e) => setMinFare(Number(e.target.value))}
                style={{ width: '100%', padding: '8px 12px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
              <button
                onClick={() => setEditingFare(null)}
                style={{
                  backgroundColor: '#ffffff',
                  border: '1px solid #e0e7e0',
                  padding: '8px 16px',
                  borderRadius: '6px',
                  fontSize: '13px',
                }}
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                style={{
                  backgroundColor: '#1b5e20',
                  color: '#ffffff',
                  border: 'none',
                  padding: '8px 16px',
                  borderRadius: '6px',
                  fontWeight: '600',
                  fontSize: '13px',
                }}
              >
                Save & Verify Tariff
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
