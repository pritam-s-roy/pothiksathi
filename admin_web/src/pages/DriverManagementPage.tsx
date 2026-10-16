import React, { useState } from 'react';
import { adminService } from '../services/adminService';
import { DriverProfile, DriverApprovalStatus } from '../types';

export const DriverManagementPage: React.FC = () => {
  const [drivers, setDrivers] = useState<DriverProfile[]>(adminService.getDrivers());
  const [filter, setFilter] = useState<string>('all');

  const reloadData = () => {
    setDrivers(adminService.getDrivers());
  };

  const handleUpdateStatus = (driverId: string, status: DriverApprovalStatus) => {
    const success = adminService.setDriverApproval(driverId, status);
    if (success) {
      alert(`Driver ${driverId} status updated to ${status.toUpperCase()}!`);
      reloadData();
    }
  };

  const filtered = drivers.filter((d) => {
    if (filter === 'pending') return d.approvalStatus === 'pending';
    if (filter === 'approved') return d.approvalStatus === 'approved';
    if (filter === 'online') return d.approvalStatus === 'approved' && d.isOnline;
    return true;
  });

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <div>
          <h2 style={{ fontSize: '20px', fontWeight: 'bold' }}>TOTO Driver Approval & Management</h2>
          <p style={{ fontSize: '13px', color: '#5e6d5e' }}>
            Verify registrations, audit vehicle numbers, and authorize drivers before dispatch in Karimpur.
          </p>
        </div>
      </div>

      {/* Filter Tabs */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '20px' }}>
        {[
          { id: 'all', label: 'All Drivers' },
          { id: 'pending', label: 'Pending Verification' },
          { id: 'approved', label: 'Approved Captains' },
          { id: 'online', label: 'Currently Online' },
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
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Drivers Table */}
      <div style={{ backgroundColor: '#ffffff', border: '1px solid #e0e7e0', borderRadius: '10px', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
          <thead>
            <tr style={{ backgroundColor: '#f9fbf9', borderBottom: '2px solid #e0e7e0', color: '#5e6d5e' }}>
              <th style={{ padding: '12px 16px' }}>Driver / Contact</th>
              <th style={{ padding: '12px 16px' }}>Vehicle Number</th>
              <th style={{ padding: '12px 16px' }}>ID / KYC Document</th>
              <th style={{ padding: '12px 16px' }}>Approval Status</th>
              <th style={{ padding: '12px 16px' }}>Availability</th>
              <th style={{ padding: '12px 16px' }}>Trips & Rating</th>
              <th style={{ padding: '12px 16px', textAlign: 'right' }}>Admin Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((d) => (
              <tr key={d.driverId} style={{ borderBottom: '1px solid #f0f0f0' }}>
                <td style={{ padding: '14px 16px' }}>
                  <div style={{ fontWeight: 'bold' }}>{d.driverName || 'Driver ' + d.driverId}</div>
                  <div style={{ fontSize: '11px', color: '#5e6d5e' }}>{d.phoneNumber || 'Phone not set'}</div>
                </td>
                <td style={{ padding: '14px 16px', fontWeight: '600' }}>
                  <span style={{ backgroundColor: '#e8f5e9', padding: '3px 8px', borderRadius: '4px', border: '1px solid #c8e6c9' }}>
                    {d.vehicleNumber}
                  </span>
                </td>
                <td style={{ padding: '14px 16px', color: '#5e6d5e' }}>
                  {d.licenseOrId || 'Aadhaar / Voter ID'}
                </td>
                <td style={{ padding: '14px 16px' }}>
                  <span style={{
                    padding: '4px 10px',
                    borderRadius: '12px',
                    fontSize: '11px',
                    fontWeight: 'bold',
                    backgroundColor: d.approvalStatus === 'approved' ? '#e8f5e9' : d.approvalStatus === 'pending' ? '#fff3e0' : '#ffebee',
                    color: d.approvalStatus === 'approved' ? '#2e7d32' : d.approvalStatus === 'pending' ? '#e65100' : '#c62828',
                  }}>
                    {d.approvalStatus.toUpperCase()}
                  </span>
                </td>
                <td style={{ padding: '14px 16px' }}>
                  {d.isOnline ? (
                    <span style={{ color: '#2e7d32', fontWeight: 'bold' }}>● ONLINE</span>
                  ) : (
                    <span style={{ color: '#9e9e9e' }}>○ Offline</span>
                  )}
                </td>
                <td style={{ padding: '14px 16px' }}>
                  <div>{d.totalTrips} trips</div>
                  <div style={{ fontSize: '11px', color: '#f57c00' }}>⭐ {d.rating.toFixed(1)}</div>
                </td>
                <td style={{ padding: '14px 16px', textAlign: 'right' }}>
                  {d.approvalStatus === 'pending' ? (
                    <div style={{ display: 'flex', gap: '6px', justifyContent: 'flex-end' }}>
                      <button
                        onClick={() => handleUpdateStatus(d.driverId, 'approved')}
                        style={{
                          backgroundColor: '#1b5e20',
                          color: '#ffffff',
                          border: 'none',
                          padding: '6px 12px',
                          borderRadius: '4px',
                          fontWeight: '600',
                          fontSize: '12px',
                        }}
                      >
                        ✓ Approve
                      </button>
                      <button
                        onClick={() => handleUpdateStatus(d.driverId, 'rejected')}
                        style={{
                          backgroundColor: '#ffffff',
                          color: '#c62828',
                          border: '1px solid #c62828',
                          padding: '6px 10px',
                          borderRadius: '4px',
                          fontSize: '12px',
                        }}
                      >
                        ✕ Reject
                      </button>
                    </div>
                  ) : d.approvalStatus === 'approved' ? (
                    <button
                      onClick={() => handleUpdateStatus(d.driverId, 'suspended')}
                      style={{
                        backgroundColor: '#ffffff',
                        color: '#d84315',
                        border: '1px solid #d84315',
                        padding: '6px 12px',
                        borderRadius: '4px',
                        fontSize: '12px',
                      }}
                    >
                      Suspend
                    </button>
                  ) : (
                    <button
                      onClick={() => handleUpdateStatus(d.driverId, 'approved')}
                      style={{
                        backgroundColor: '#1b5e20',
                        color: '#ffffff',
                        border: 'none',
                        padding: '6px 12px',
                        borderRadius: '4px',
                        fontSize: '12px',
                      }}
                    >
                      Re-Approve
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
