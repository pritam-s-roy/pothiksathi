import React, { useState } from 'react';
import { Sidebar } from './components/Sidebar';
import { Navbar } from './components/Navbar';
import { DashboardPage } from './pages/DashboardPage';
import { BookingManagementPage } from './pages/BookingManagementPage';
import { DriverManagementPage } from './pages/DriverManagementPage';
import { RouteFarePage } from './pages/RouteFarePage';
import { BusTimetablePage } from './pages/BusTimetablePage';
import { SupportIssuesPage } from './pages/SupportIssuesPage';

export const App: React.FC = () => {
  const [isAdminAuthenticated, setIsAdminAuthenticated] = useState<boolean>(true);
  const [currentTab, setCurrentTab] = useState<string>('dashboard');
  const [username, setUsername] = useState('admin@pothiksathi.in');
  const [password, setPassword] = useState('admin123');

  if (!isAdminAuthenticated) {
    return (
      <div style={{
        height: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#f8faf8',
      }}>
        <div style={{
          backgroundColor: '#ffffff',
          border: '1px solid #e0e7e0',
          borderRadius: '12px',
          padding: '32px',
          width: '380px',
          boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
        }}>
          <div style={{ textAlign: 'center', marginBottom: '24px' }}>
            <span style={{ fontSize: '40px' }}>🛺</span>
            <h1 style={{ fontSize: '22px', fontWeight: 'bold', color: '#1b5e20', marginTop: '8px' }}>
              PothikSathi Admin Portal
            </h1>
            <p style={{ fontSize: '13px', color: '#5e6d5e' }}>Karimpur Municipal Dispatch & Operations</p>
          </div>

          <form onSubmit={(e) => {
            e.preventDefault();
            setIsAdminAuthenticated(true);
          }}>
            <div style={{ marginBottom: '14px' }}>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>
                Admin Email / Username
              </label>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                style={{ width: '100%', padding: '10px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
                required
              />
            </div>

            <div style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', marginBottom: '4px' }}>
                Secure Password
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                style={{ width: '100%', padding: '10px', border: '1px solid #e0e7e0', borderRadius: '6px' }}
                required
              />
            </div>

            <button
              type="submit"
              style={{
                width: '100%',
                backgroundColor: '#1b5e20',
                color: '#ffffff',
                border: 'none',
                padding: '12px',
                borderRadius: '6px',
                fontWeight: 'bold',
                fontSize: '14px',
              }}
            >
              Sign In to Control Desk
            </button>
          </form>
        </div>
      </div>
    );
  }

  const renderContent = () => {
    switch (currentTab) {
      case 'bookings':
        return <BookingManagementPage />;
      case 'drivers':
        return <DriverManagementPage />;
      case 'routes':
        return <RouteFarePage />;
      case 'timetables':
        return <BusTimetablePage />;
      case 'support':
        return <SupportIssuesPage />;
      case 'dashboard':
      default:
        return <DashboardPage onNavigate={(tab) => setCurrentTab(tab)} />;
    }
  };

  const getTitle = () => {
    switch (currentTab) {
      case 'bookings':
        return 'Booking Dispatch Console';
      case 'drivers':
        return 'Driver Approvals & KYC';
      case 'routes':
        return 'Verified Routes & Tariffs';
      case 'timetables':
        return 'Bus Timetable Management';
      case 'support':
        return 'Support & Complaints';
      case 'dashboard':
      default:
        return 'Operations Dashboard';
    }
  };

  return (
    <div style={{ display: 'flex', height: '100vh', width: '100vw', overflow: 'hidden' }}>
      <Sidebar currentTab={currentTab} onSelectTab={(tab) => setCurrentTab(tab)} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', height: '100vh', overflow: 'hidden' }}>
        <Navbar title={getTitle()} />
        <main style={{ flex: 1, overflowY: 'auto', backgroundColor: '#f8faf8' }}>
          {renderContent()}
        </main>
      </div>
    </div>
  );
};
