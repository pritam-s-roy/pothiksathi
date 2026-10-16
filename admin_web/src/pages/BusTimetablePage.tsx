import React, { useState } from 'react';
import { adminService } from '../services/adminService';
import { BusTimetable } from '../types';

export const BusTimetablePage: React.FC = () => {
  const [timetables, setTimetables] = useState<BusTimetable[]>(adminService.getTimetables());
  const [showAddModal, setShowAddModal] = useState<boolean>(false);

  // New timetable form state
  const [routeName, setRouteName] = useState('Karimpur – Krishnanagar');
  const [origin, setOrigin] = useState('Karimpur Bus Stand');
  const [destination, setDestination] = useState('Krishnanagar Bus Stand');
  const [viaStops, setViaStops] = useState('Tehatta, Chapra');
  const [departureTime, setDepartureTime] = useState('08:30');
  const [arrivalTime, setArrivalTime] = useState('10:15');
  const [operatorName, setOperatorName] = useState('SBSTC Express');
  const [busType, setBusType] = useState('Express');
  const [serviceDays, setServiceDays] = useState('Daily');
  const [fareEstimate, setFareEstimate] = useState<number>(55);

  const reloadData = () => {
    setTimetables(adminService.getTimetables());
  };

  const handleVerify = (id: string) => {
    adminService.verifyTimetable(id);
    reloadData();
    alert('Timetable schedule verified and stamped with current timestamp!');
  };

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to delete this bus schedule?')) {
      adminService.deleteTimetable(id);
      reloadData();
    }
  };

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    adminService.addTimetable({
      routeName,
      origin,
      destination,
      viaStops: viaStops.split(',').map((s) => s.trim()),
      departureTime,
      arrivalTime,
      operatorName,
      busType,
      serviceDays,
      fareEstimate,
      isActive: true,
    });
    setShowAddModal(false);
    reloadData();
    alert('New bus timetable entry created successfully!');
  };

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <div>
          <h2 style={{ fontSize: '20px', fontWeight: 'bold' }}>Karimpur Bus Timetable Hub</h2>
          <p style={{ fontSize: '13px', color: '#5e6d5e' }}>
            Maintain verified public departure schedules from Karimpur Bus Stand. These are cached for offline passenger viewing.
          </p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          style={{
            backgroundColor: '#1b5e20',
            color: '#ffffff',
            border: 'none',
            padding: '10px 18px',
            borderRadius: '6px',
            fontWeight: '600',
            fontSize: '13px',
          }}
        >
          + Add New Bus Schedule
        </button>
      </div>

      {/* Timetables Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '16px' }}>
        {timetables.map((t) => (
          <div
            key={t.id}
            style={{
              backgroundColor: '#ffffff',
              border: '1px solid #e0e7e0',
              borderRadius: '10px',
              padding: '18px',
              position: 'relative',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div>
                <span style={{
                  fontSize: '11px',
                  fontWeight: 'bold',
                  backgroundColor: '#e3f2fd',
                  color: '#0d47a1',
                  padding: '2px 8px',
                  borderRadius: '10px',
                }}>
                  {t.busType} • {t.serviceDays}
                </span>
                <h3 style={{ fontSize: '15px', fontWeight: 'bold', marginTop: '6px' }}>{t.routeName}</h3>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: '18px', fontWeight: 'bold', color: '#1b5e20' }}>{t.departureTime}</div>
                <div style={{ fontSize: '11px', color: '#5e6d5e' }}>Departs Karimpur</div>
              </div>
            </div>

            <div style={{ marginTop: '12px', fontSize: '12px', color: '#5e6d5e' }}>
              <div>Via: <strong>{t.viaStops.join(' → ')}</strong></div>
              <div>Destination Arrival: <strong>{t.arrivalTime}</strong></div>
              <div>Operator: <strong>{t.operatorName}</strong></div>
              <div>Est. Fare: <strong>₹{t.fareEstimate}</strong></div>
            </div>

            <div style={{
              marginTop: '14px',
              paddingTop: '12px',
              borderTop: '1px solid #f0f0f0',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              fontSize: '11px',
            }}>
              <span style={{ color: t.isVerified ? '#2e7d32' : '#e65100', fontWeight: '600' }}>
                {t.isVerified ? `✓ Verified on ${new Date(t.lastVerifiedAt).toLocaleDateString()}` : '⚠️ Unverified'}
              </span>

              <div style={{ display: 'flex', gap: '6px' }}>
                <button
                  onClick={() => handleVerify(t.id)}
                  style={{
                    backgroundColor: '#e8f5e9',
                    color: '#1b5e20',
                    border: '1px solid #c8e6c9',
                    padding: '4px 8px',
                    borderRadius: '4px',
                    fontSize: '11px',
                    fontWeight: '600',
                  }}
                >
                  Verify Stamp
                </button>
                <button
                  onClick={() => handleDelete(t.id)}
                  style={{
                    backgroundColor: '#ffebee',
                    color: '#c62828',
                    border: 'none',
                    padding: '4px 8px',
                    borderRadius: '4px',
                    fontSize: '11px',
                  }}
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Add Modal */}
      {showAddModal && (
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
          <form
            onSubmit={handleCreate}
            style={{
              backgroundColor: '#ffffff',
              borderRadius: '10px',
              padding: '24px',
              width: '460px',
              maxWidth: '90%',
              maxHeight: '90vh',
              overflowY: 'auto',
              boxShadow: '0 8px 30px rgba(0,0,0,0.2)',
            }}
          >
            <h3 style={{ fontSize: '18px', fontWeight: 'bold', marginBottom: '14px' }}>Add Bus Timetable Entry</h3>

            <div style={{ marginBottom: '10px' }}>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Route Title:</label>
              <input
                type="text"
                value={routeName}
                onChange={(e) => setRouteName(e.target.value)}
                required
                style={{ width: '100%', padding: '8px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
              />
            </div>

            <div style={{ display: 'flex', gap: '10px', marginBottom: '10px' }}>
              <div style={{ flex: 1 }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Origin:</label>
                <input
                  type="text"
                  value={origin}
                  onChange={(e) => setOrigin(e.target.value)}
                  required
                  style={{ width: '100%', padding: '8px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
                />
              </div>
              <div style={{ flex: 1 }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Destination:</label>
                <input
                  type="text"
                  value={destination}
                  onChange={(e) => setDestination(e.target.value)}
                  required
                  style={{ width: '100%', padding: '8px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
                />
              </div>
            </div>

            <div style={{ marginBottom: '10px' }}>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Via Stops (comma-separated):</label>
              <input
                type="text"
                value={viaStops}
                onChange={(e) => setViaStops(e.target.value)}
                placeholder="e.g. Tehatta, Chapra"
                required
                style={{ width: '100%', padding: '8px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
              />
            </div>

            <div style={{ display: 'flex', gap: '10px', marginBottom: '10px' }}>
              <div style={{ flex: 1 }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Departure Time:</label>
                <input
                  type="text"
                  value={departureTime}
                  onChange={(e) => setDepartureTime(e.target.value)}
                  placeholder="08:30"
                  required
                  style={{ width: '100%', padding: '8px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
                />
              </div>
              <div style={{ flex: 1 }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Arrival Time:</label>
                <input
                  type="text"
                  value={arrivalTime}
                  onChange={(e) => setArrivalTime(e.target.value)}
                  placeholder="10:15"
                  required
                  style={{ width: '100%', padding: '8px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
                />
              </div>
            </div>

            <div style={{ display: 'flex', gap: '10px', marginBottom: '10px' }}>
              <div style={{ flex: 1 }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Bus Type:</label>
                <select
                  value={busType}
                  onChange={(e) => setBusType(e.target.value)}
                  style={{ width: '100%', padding: '8px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
                >
                  <option value="Ordinary">Ordinary</option>
                  <option value="Express">Express</option>
                  <option value="Rocket">Fast Rocket</option>
                  <option value="Night Express">Night Express</option>
                </select>
              </div>
              <div style={{ flex: 1 }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Service Days:</label>
                <input
                  type="text"
                  value={serviceDays}
                  onChange={(e) => setServiceDays(e.target.value)}
                  placeholder="Daily or Mon-Sat"
                  required
                  style={{ width: '100%', padding: '8px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
                />
              </div>
            </div>

            <div style={{ display: 'flex', gap: '10px', marginBottom: '16px' }}>
              <div style={{ flex: 1 }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Operator:</label>
                <input
                  type="text"
                  value={operatorName}
                  onChange={(e) => setOperatorName(e.target.value)}
                  style={{ width: '100%', padding: '8px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
                />
              </div>
              <div style={{ flex: 1 }}>
                <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>Est. Fare (₹):</label>
                <input
                  type="number"
                  value={fareEstimate}
                  onChange={(e) => setFareEstimate(Number(e.target.value))}
                  style={{ width: '100%', padding: '8px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
                />
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
              <button
                type="button"
                onClick={() => setShowAddModal(false)}
                style={{ padding: '8px 16px', borderRadius: '6px', border: '1px solid #e0e7e0', backgroundColor: '#ffffff' }}
              >
                Cancel
              </button>
              <button
                type="submit"
                style={{ padding: '8px 16px', borderRadius: '6px', border: 'none', backgroundColor: '#1b5e20', color: '#ffffff', fontWeight: '600' }}
              >
                Publish Schedule
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
};
