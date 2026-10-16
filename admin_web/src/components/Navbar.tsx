import React from 'react';

interface NavbarProps {
  title: string;
}

export const Navbar: React.FC<NavbarProps> = ({ title }) => {
  return (
    <header style={{
      height: '64px',
      backgroundColor: '#ffffff',
      borderBottom: '1px solid #e0e7e0',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 24px',
      flexShrink: 0,
    }}>
      <div>
        <h2 style={{ fontSize: '18px', fontWeight: 'bold', color: '#1e261e' }}>{title}</h2>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          backgroundColor: '#e8f5e9',
          padding: '6px 12px',
          borderRadius: '20px',
          fontSize: '12px',
          color: '#1b5e20',
          fontWeight: '600',
        }}>
          <span style={{ width: '8px', height: '8px', backgroundColor: '#43a047', borderRadius: '50%' }}></span>
          Dispatch Online
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{
            width: '36px',
            height: '36px',
            backgroundColor: '#1b5e20',
            color: '#ffffff',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontWeight: 'bold',
            fontSize: '14px',
          }}>
            A
          </div>
          <div style={{ textAlign: 'left', lineHeight: '1.2' }}>
            <div style={{ fontSize: '13px', fontWeight: 'bold' }}>Admin Desk</div>
            <div style={{ fontSize: '11px', color: '#5e6d5e' }}>Karimpur Station</div>
          </div>
        </div>
      </div>
    </header>
  );
};
