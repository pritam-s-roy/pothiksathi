import React from 'react';

interface SidebarProps {
  currentTab: string;
  onSelectTab: (tab: string) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ currentTab, onSelectTab }) => {
  const menuItems = [
    { id: 'dashboard', label: 'Dashboard', icon: '📊' },
    { id: 'bookings', label: 'Booking Dispatch', icon: '🛺', badge: 'Manual Assign' },
    { id: 'drivers', label: 'Driver Approvals', icon: '👨‍✈️', badge: 'KYC' },
    { id: 'routes', label: 'Routes & Tariffs', icon: '🛣️' },
    { id: 'timetables', label: 'Bus Timetables', icon: '🚌' },
    { id: 'support', label: 'Support & Issues', icon: '🎧' },
  ];

  return (
    <aside style={{
      width: '240px',
      backgroundColor: '#1b5e20',
      color: '#ffffff',
      display: 'flex',
      flexDirection: 'column',
      height: '100vh',
      flexShrink: 0,
    }}>
      {/* Brand Header */}
      <div style={{ padding: '24px 20px', borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <span style={{ fontSize: '28px' }}>🛺</span>
          <div>
            <h1 style={{ fontSize: '18px', fontWeight: 'bold', letterSpacing: '0.5px' }}>PothikSathi</h1>
            <p style={{ fontSize: '11px', color: '#a5d6a7' }}>Karimpur Control Desk</p>
          </div>
        </div>
      </div>

      {/* Navigation Links */}
      <nav style={{ flex: 1, padding: '16px 10px', overflowY: 'auto' }}>
        {menuItems.map((item) => {
          const isActive = currentTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onSelectTab(item.id)}
              style={{
                width: '100%',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '12px 14px',
                marginBottom: '6px',
                borderRadius: '8px',
                border: 'none',
                backgroundColor: isActive ? '#2e7d32' : 'transparent',
                color: isActive ? '#ffffff' : '#e8f5e9',
                fontSize: '14px',
                fontWeight: isActive ? '600' : 'normal',
                textAlign: 'left',
                transition: 'background-color 0.15s ease',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <span style={{ fontSize: '16px' }}>{item.icon}</span>
                <span>{item.label}</span>
              </div>
              {item.badge && (
                <span style={{
                  fontSize: '9px',
                  backgroundColor: isActive ? '#1b5e20' : 'rgba(255,255,255,0.2)',
                  color: '#ffffff',
                  padding: '2px 6px',
                  borderRadius: '10px',
                  fontWeight: '600',
                }}>
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </nav>

      {/* Footer info */}
      <div style={{ padding: '16px 20px', borderTop: '1px solid rgba(255,255,255,0.1)', fontSize: '11px', color: '#a5d6a7' }}>
        <div>Zone: Karimpur, Nadia (741152)</div>
        <div>Tariff: Verified 2026-V1</div>
      </div>
    </aside>
  );
};
