import React, { useState } from 'react';
import { adminService } from '../services/adminService';
import { SupportIssue } from '../types';

export const SupportIssuesPage: React.FC = () => {
  const [issues, setIssues] = useState<SupportIssue[]>(adminService.getSupportIssues());
  const [selectedIssue, setSelectedIssue] = useState<SupportIssue | null>(null);
  const [notes, setNotes] = useState('');

  const reloadData = () => {
    setIssues(adminService.getSupportIssues());
  };

  const handleResolve = (id: string) => {
    if (!notes.trim()) {
      alert('Please enter resolution notes before resolving.');
      return;
    }
    adminService.resolveIssue(id, notes);
    setSelectedIssue(null);
    setNotes('');
    reloadData();
    alert('Issue marked as resolved.');
  };

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <div>
          <h2 style={{ fontSize: '20px', fontWeight: 'bold' }}>Passenger & Driver Support Management</h2>
          <p style={{ fontSize: '13px', color: '#5e6d5e' }}>
            Resolve disputes, fare grievances, and driver compliance queries in Karimpur.
          </p>
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {issues.map((issue) => (
          <div
            key={issue.id}
            style={{
              backgroundColor: '#ffffff',
              border: '1px solid #e0e7e0',
              borderRadius: '10px',
              padding: '16px',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div>
                <span style={{
                  padding: '3px 8px',
                  borderRadius: '12px',
                  fontSize: '11px',
                  fontWeight: 'bold',
                  backgroundColor: issue.status === 'resolved' ? '#e8f5e9' : '#fff3e0',
                  color: issue.status === 'resolved' ? '#2e7d32' : '#e65100',
                }}>
                  {issue.status.toUpperCase()}
                </span>
                <h3 style={{ fontSize: '15px', fontWeight: 'bold', marginTop: '6px' }}>{issue.issueType}</h3>
                <div style={{ fontSize: '12px', color: '#5e6d5e', marginTop: '2px' }}>
                  Reported by: <strong>{issue.reporterName || issue.reportedBy}</strong> ({issue.userRole}) • {new Date(issue.createdAt).toLocaleString()}
                </div>
              </div>
              <div style={{ fontSize: '12px', color: '#5e6d5e' }}>
                {issue.bookingId && <span>Booking: <strong>{issue.bookingId}</strong></span>}
              </div>
            </div>

            <p style={{ fontSize: '13px', color: '#1e261e', marginTop: '10px', lineHeight: '1.4' }}>
              {issue.description}
            </p>

            {issue.resolutionNotes && (
              <div style={{
                marginTop: '10px',
                padding: '10px',
                backgroundColor: '#f9fbf9',
                borderRadius: '6px',
                borderLeft: '3px solid #2e7d32',
                fontSize: '12px',
              }}>
                <strong>Resolution:</strong> {issue.resolutionNotes}
              </div>
            )}

            {issue.status !== 'resolved' && (
              <div style={{ marginTop: '12px', textAlign: 'right' }}>
                <button
                  onClick={() => {
                    setSelectedIssue(issue);
                    setNotes('');
                  }}
                  style={{
                    backgroundColor: '#1b5e20',
                    color: '#ffffff',
                    border: 'none',
                    padding: '6px 14px',
                    borderRadius: '4px',
                    fontSize: '12px',
                    fontWeight: '600',
                  }}
                >
                  Resolve Issue
                </button>
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Resolve Dialog */}
      {selectedIssue && (
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
          }}>
            <h3 style={{ fontSize: '16px', fontWeight: 'bold', marginBottom: '10px' }}>
              Resolve Support Issue: {selectedIssue.id}
            </h3>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Enter resolution details, action taken with driver/passenger..."
              rows={4}
              style={{ width: '100%', padding: '10px', border: '1px solid #e0e7e0', borderRadius: '6px', fontSize: '13px', marginBottom: '16px' }}
            />
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
              <button
                onClick={() => setSelectedIssue(null)}
                style={{ padding: '8px 16px', borderRadius: '6px', border: '1px solid #e0e7e0', backgroundColor: '#ffffff' }}
              >
                Cancel
              </button>
              <button
                onClick={() => handleResolve(selectedIssue.id)}
                style={{ padding: '8px 16px', borderRadius: '6px', border: 'none', backgroundColor: '#1b5e20', color: '#ffffff', fontWeight: '600' }}
              >
                Save Resolution
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
