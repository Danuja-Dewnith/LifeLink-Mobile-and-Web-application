import React, { useState } from 'react';
import { Link, useLocation } from "react-router-dom";

const Settings = () => {
  const [activeNav, setActiveNav] = useState('settings');
  const [activeTab, setActiveTab] = useState('facility');
  const [saved, setSaved] = useState(false);
   const location = useLocation();

  // Facility Profile state
  const [centerName, setCenterName] = useState('City General Hospital & Blood Center');
  const [hospitalId, setHospitalId] = useState('HOSP-2024-LL-9912');
  const [contactPerson, setContactPerson] = useState('Dr. Aris Thorne');
  const [officialEmail, setOfficialEmail] = useState('admin@citygeneral.org');
  const [phone, setPhone] = useState('+1 (555) 123-4567');
  const [address, setAddress] = useState('742 Evergreen Terrace, Medical District, Springfield');

  // System Config state
  const [dispatchNotif, setDispatchNotif] = useState(true);
  const [criticalAlerts, setCriticalAlerts] = useState(true);
  const [autoMatch, setAutoMatch] = useState(false);
  const [alertRadius, setAlertRadius] = useState('25');
  const [reportFreq, setReportFreq] = useState('Weekly (Mondays)');
  const [retentionDays, setRetentionDays] = useState('90');
  const [timezone, setTimezone] = useState('UTC-5 (Eastern Time)');

  // User Management state
  const [users] = useState([
    { name: 'Dr. Aris Thorne', email: 'aris@citygeneral.org', role: 'Super Admin', status: true },
    { name: 'Sarah Jenkins', email: 'sarah@citygeneral.org', role: 'Administrator', status: true },
    { name: 'Marcus R.', email: 'marcus@citygeneral.org', role: 'Logistics Officer', status: true },
    { name: 'Jane M.', email: 'jane@citygeneral.org', role: 'Medical Staff', status: false },
  ]);

  // Security state
  const [twoFA, setTwoFA] = useState(true);
  const [sessionTimeout, setSessionTimeout] = useState('30');
  const [ipRestriction, setIpRestriction] = useState(false);
  const [auditLog, setAuditLog] = useState(true);

  const navItems = [
    { key: 'dashboard', icon: '⊞', label: 'Dashboard', path: '/bloodbank/dashboard' },
  { key: 'inventory', icon: '📦', label: 'Inventory', path: '/bloodbank/inventory' },
  { key: 'dispatch', icon: '🚚', label: 'Dispatch', path: '/bloodbank/dispatch' },
  { key: 'reports', icon: '📊', label: 'Reports', path: '/bloodbank/reports' },
  { key: 'settings', icon: '⚙️', label: 'Settings', path: '/bloodbank/setting' },
  ];

  const tabs = [
    { key: 'facility', label: 'Facility Profile' },
    { key: 'system', label: 'System Configuration' },
    { key: 'users', label: 'User Management' },
    { key: 'security', label: 'Security' },
  ];

  const handleSave = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  };

  const Toggle = ({ value, onChange }) => (
    <div
      onClick={() => onChange(!value)}
      style={{
        width: 46, height: 26,
        borderRadius: 13,
        background: value ? '#2563EB' : '#CBD5E1',
        cursor: 'pointer',
        position: 'relative',
        transition: 'background 0.2s',
        flexShrink: 0,
      }}
    >
      <div style={{
        position: 'absolute',
        top: 3,
        left: value ? 23 : 3,
        width: 20, height: 20,
        background: 'white',
        borderRadius: '50%',
        transition: 'left 0.2s',
        boxShadow: '0 1px 4px rgba(0,0,0,0.15)',
      }} />
    </div>
  );

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&family=Space+Mono:wght@400;700&display=swap');

        * { margin: 0; padding: 0; box-sizing: border-box; }

        .st-app {
          display: flex;
          min-height: 100vh;
          background: #F8FAFC;
          font-family: 'DM Sans', -apple-system, sans-serif;
        }

        /* ── SIDEBAR ── */
        .st-sidebar {
          width: 238px;
          background: white;
          border-right: 1px solid #E2E8F0;
          display: flex;
          flex-direction: column;
          position: fixed;
          top: 0; left: 0;
          height: 100vh;
          z-index: 100;
        }

        .st-logo {
          padding: 0 20px;
          height: 60px;
          border-bottom: 1px solid #F1F5F9;
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .st-logo-icon {
          width: 36px; height: 36px;
          background: linear-gradient(135deg, #3B82F6, #2563EB);
          border-radius: 9px;
          display: flex; align-items: center; justify-content: center;
          font-size: 17px;
        }

        .st-logo-name {
          font-size: 16px;
          font-weight: 800;
          color: #0F172A;
          letter-spacing: -0.3px;
        }

        .st-nav {
          padding: 16px 12px;
          flex: 1;
          display: flex;
          flex-direction: column;
          gap: 2px;
        }

        .st-nav-item {
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 10px 12px;
          border-radius: 8px;
          font-size: 13.5px;
          font-weight: 500;
          color: #64748B;
          cursor: pointer;
          transition: all 0.15s;
          border: none;
          background: none;
          width: 100%;
          text-align: left;
          font-family: 'DM Sans', sans-serif;
        }

        .st-nav-item:hover { background: #F8FAFC; color: #0F172A; }
        .st-nav-item.active { background: #EFF6FF; color: #2563EB; font-weight: 600; }
        .st-nav-icon { font-size: 15px; width: 20px; text-align: center; }

        .st-user-section {
          border-top: 1px solid #F1F5F9;
        }

        .st-user-card {
          padding: 14px 16px;
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .st-user-avatar {
          width: 36px; height: 36px;
          background: linear-gradient(135deg, #6EE7B7, #3B82F6);
          border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          font-size: 14px;
          color: white;
          font-weight: 700;
          flex-shrink: 0;
        }

        .st-user-name {
          font-size: 13px;
          font-weight: 700;
          color: #0F172A;
        }

        .st-user-role {
          font-size: 11px;
          color: #94A3B8;
        }

        .st-logout-btn {
          width: calc(100% - 28px);
          margin: 0 14px 16px;
          background: none;
          border: 1.5px solid #FECACA;
          color: #EF4444;
          border-radius: 8px;
          padding: 9px;
          font-size: 13px;
          font-weight: 700;
          cursor: pointer;
          font-family: 'DM Sans', sans-serif;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 6px;
          transition: all 0.15s;
        }

        .st-logout-btn:hover { background: #FEE2E2; }

        /* ── TOPBAR ── */
        .st-topbar {
          position: fixed;
          top: 0; left: 238px; right: 0;
          height: 60px;
          background: white;
          border-bottom: 1px solid #E2E8F0;
          display: flex;
          align-items: center;
          padding: 0 28px;
          gap: 10px;
          z-index: 200;
        }

        .st-breadcrumb {
          font-size: 13px;
          color: #94A3B8;
          display: flex;
          align-items: center;
          gap: 6px;
          flex: 1;
        }

        .st-breadcrumb-sep { color: #CBD5E1; }
        .st-breadcrumb-active { color: #0F172A; font-weight: 600; }

        .st-topbar-right {
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .st-icon-btn {
          width: 36px; height: 36px;
          border-radius: 50%;
          background: white;
          border: 1px solid #E2E8F0;
          display: flex; align-items: center; justify-content: center;
          font-size: 15px;
          cursor: pointer;
          position: relative;
          transition: background 0.12s;
        }

        .st-icon-btn:hover { background: #F8FAFC; }

        .st-notif-dot {
          position: absolute;
          top: 5px; right: 5px;
          width: 8px; height: 8px;
          background: #EF4444;
          border: 2px solid white;
          border-radius: 50%;
        }

        /* ── MAIN ── */
        .st-main {
          margin-left: 238px;
          margin-top: 60px;
          flex: 1;
          padding: 28px;
          display: flex;
          flex-direction: column;
          gap: 0;
        }

        /* ── PAGE HEADER ── */
        .st-page-header {
          display: flex;
          align-items: flex-start;
          justify-content: space-between;
          margin-bottom: 22px;
        }

        .st-page-title {
          font-size: 24px;
          font-weight: 800;
          color: #0F172A;
          letter-spacing: -0.4px;
        }

        .st-page-sub {
          font-size: 13px;
          color: #94A3B8;
          margin-top: 4px;
        }

        .st-header-btns {
          display: flex;
          gap: 10px;
          align-items: center;
        }

        .st-btn {
          padding: 9px 20px;
          border-radius: 9px;
          font-size: 13.5px;
          font-weight: 700;
          cursor: pointer;
          font-family: 'DM Sans', sans-serif;
          transition: all 0.15s;
        }

        .st-btn-outline {
          background: white;
          color: #374151;
          border: 1.5px solid #D1D5DB;
        }

        .st-btn-outline:hover { background: #F9FAFB; }

        .st-btn-primary {
          background: #2563EB;
          color: white;
          border: none;
          box-shadow: 0 4px 12px rgba(37,99,235,0.2);
        }

        .st-btn-primary:hover { background: #1D4ED8; }
        .st-btn-primary.success { background: #10B981; box-shadow: 0 4px 12px rgba(16,185,129,0.2); }

        /* ── TABS ── */
        .st-tabs {
          display: flex;
          gap: 0;
          border-bottom: 2px solid #F1F5F9;
          margin-bottom: 22px;
        }

        .st-tab {
          padding: 10px 18px;
          font-size: 13.5px;
          font-weight: 600;
          color: #94A3B8;
          cursor: pointer;
          border: none;
          background: none;
          font-family: 'DM Sans', sans-serif;
          border-bottom: 2.5px solid transparent;
          margin-bottom: -2px;
          transition: all 0.15s;
        }

        .st-tab:hover { color: #374151; }
        .st-tab.active { color: #2563EB; border-bottom-color: #2563EB; }

        /* ── SECTION PANEL ── */
        .st-panel {
          background: white;
          border: 1px solid #E2E8F0;
          border-radius: 14px;
          padding: 26px;
          margin-bottom: 18px;
        }

        .st-section-title {
          font-size: 15px;
          font-weight: 700;
          color: #0F172A;
        }

        .st-section-sub {
          font-size: 13px;
          color: #94A3B8;
          margin-top: 3px;
          margin-bottom: 22px;
        }

        /* ── FORM GRID ── */
        .st-form-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 18px 24px;
        }

        .st-form-group {
          display: flex;
          flex-direction: column;
          gap: 6px;
        }

        .st-form-label {
          font-size: 11px;
          font-weight: 700;
          color: #94A3B8;
          text-transform: uppercase;
          letter-spacing: 0.07em;
        }

        .st-input, .st-select {
          padding: 10px 14px;
          border: 1.5px solid #E2E8F0;
          border-radius: 9px;
          font-size: 13.5px;
          color: #0F172A;
          background: white;
          font-family: 'DM Sans', sans-serif;
          outline: none;
          transition: border-color 0.15s, box-shadow 0.15s;
          width: 100%;
        }

        .st-input:focus, .st-select:focus {
          border-color: #2563EB;
          box-shadow: 0 0 0 3px rgba(37,99,235,0.08);
        }

        .st-input-with-suffix {
          position: relative;
        }

        .st-input-suffix {
          position: absolute;
          right: 14px;
          top: 50%;
          transform: translateY(-50%);
          font-size: 12px;
          font-weight: 700;
          color: #94A3B8;
        }

        .st-select {
          appearance: none;
          -webkit-appearance: none;
          background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%2394A3B8' d='M6 8L1 3h10z'/%3E%3C/svg%3E");
          background-repeat: no-repeat;
          background-position: right 14px center;
          padding-right: 36px;
          cursor: pointer;
        }

        /* ── TOGGLE ROW ── */
        .st-toggle-row {
          display: flex;
          align-items: flex-start;
          justify-content: space-between;
          padding: 18px 0;
          border-bottom: 1px solid #F8FAFC;
          gap: 16px;
        }

        .st-toggle-row:last-child { border-bottom: none; }

        .st-toggle-label {
          font-size: 14px;
          font-weight: 600;
          color: #0F172A;
        }

        .st-toggle-desc {
          font-size: 12.5px;
          color: #94A3B8;
          margin-top: 3px;
          line-height: 1.5;
        }

        /* ── DIVIDER ── */
        .st-divider {
          height: 1px;
          background: #F1F5F9;
          margin: 20px 0;
        }

        /* ── USER TABLE ── */
        .st-user-table { width: 100%; border-collapse: collapse; }

        .st-user-table th {
          text-align: left;
          padding: 10px 16px;
          font-size: 10.5px;
          color: #94A3B8;
          text-transform: uppercase;
          letter-spacing: 0.07em;
          font-weight: 700;
          background: #FAFBFC;
          border-bottom: 1px solid #F1F5F9;
        }

        .st-user-table td {
          padding: 14px 16px;
          font-size: 13px;
          color: #374151;
          border-bottom: 1px solid #F8FAFC;
          vertical-align: middle;
        }

        .st-user-table tbody tr:last-child td { border-bottom: none; }
        .st-user-table tbody tr:hover { background: #F8FAFC; }

        .st-user-name-cell { font-weight: 600; color: #0F172A; }
        .st-user-email { font-size: 11.5px; color: #94A3B8; margin-top: 2px; }

        .st-role-chip {
          display: inline-block;
          padding: 3px 10px;
          border-radius: 20px;
          font-size: 11.5px;
          font-weight: 600;
          background: #EFF6FF;
          color: #2563EB;
        }

        .st-user-action-btn {
          background: #F8FAFC;
          border: 1px solid #E2E8F0;
          border-radius: 6px;
          padding: 5px 10px;
          font-size: 11.5px;
          font-weight: 600;
          color: #374151;
          cursor: pointer;
          font-family: 'DM Sans', sans-serif;
          transition: all 0.12s;
          margin-right: 4px;
        }

        .st-user-action-btn:hover { border-color: #2563EB; color: #2563EB; }

        .st-add-user-btn {
          background: #2563EB;
          color: white;
          border: none;
          border-radius: 8px;
          padding: 9px 16px;
          font-size: 13px;
          font-weight: 700;
          cursor: pointer;
          font-family: 'DM Sans', sans-serif;
          display: flex;
          align-items: center;
          gap: 6px;
          transition: background 0.15s;
        }

        .st-add-user-btn:hover { background: #1D4ED8; }

        /* ── SECURITY ── */
        .st-security-note {
          background: #FFF7ED;
          border: 1px solid #FED7AA;
          border-radius: 10px;
          padding: 14px 16px;
          font-size: 12.5px;
          color: #92400E;
          display: flex;
          align-items: flex-start;
          gap: 8px;
          margin-top: 16px;
        }

        @media (max-width: 900px) {
          .st-form-grid { grid-template-columns: 1fr; }
        }
        @media (max-width: 768px) {
          .st-sidebar { display: none; }
          .st-main { margin-left: 0; }
          .st-topbar { left: 0; }
        }
      `}</style>

      <div className="st-app">

        {/* ── SIDEBAR ── */}
        <aside className="st-sidebar">
          <div className="st-logo">
            <div className="st-logo-icon">💧</div>
            <div className="st-logo-name">LifeLink</div>
          </div>

          <nav className="st-nav">
                      {navItems.map(item => (
                        <Link
                          key={item.key}
                          to={item.path}
                          className={`st-nav-item${location.pathname === item.path ? ' active' : ''}`}
                        >
                          <span className="st-nav-icon">{item.icon}</span>
                          {item.label}
                        </Link>
                      ))}
                    </nav>
          

          <div className="st-user-section">
            <div className="st-user-card">
              <div className="st-user-avatar">AT</div>
              <div>
                <div className="st-user-name">Dr. Aris Thorne</div>
                <div className="st-user-role">Super Admin</div>
              </div>
            </div>
            <button className="st-logout-btn">⬅ Logout</button>
          </div>
        </aside>

        {/* ── TOPBAR ── */}
        <header className="st-topbar">
          <div className="st-breadcrumb">
            <span>Admin</span>
            <span className="st-breadcrumb-sep">›</span>
            <span className="st-breadcrumb-active">Blood Bank & Hospital Center Settings</span>
          </div>
          <div className="st-topbar-right">
            <button className="st-icon-btn">
              🔔
              <span className="st-notif-dot"></span>
            </button>
            <button className="st-icon-btn">❓</button>
          </div>
        </header>

        {/* ── MAIN ── */}
        <div className="st-main">

          {/* PAGE HEADER */}
          <div className="st-page-header">
            <div>
              <div className="st-page-title">Blood Bank & Hospital Center Settings</div>
              <div className="st-page-sub">Configure your facility details, operational parameters, and user access.</div>
            </div>
            <div className="st-header-btns">
              <button className="st-btn st-btn-outline">Discard</button>
              <button
                className={`st-btn st-btn-primary${saved ? ' success' : ''}`}
                onClick={handleSave}
              >
                {saved ? '✓ Saved!' : 'Save Changes'}
              </button>
            </div>
          </div>

          {/* TABS */}
          <div className="st-tabs">
            {tabs.map(tab => (
              <button
                key={tab.key}
                className={`st-tab${activeTab === tab.key ? ' active' : ''}`}
                onClick={() => setActiveTab(tab.key)}
              >
                {tab.label}
              </button>
            ))}
          </div>

          {/* ── FACILITY PROFILE TAB ── */}
          {activeTab === 'facility' && (
            <div className="st-panel">
              <div className="st-section-title">Facility Profile</div>
              <div className="st-section-sub">Essential information about your medical institution.</div>

              <div className="st-form-grid">
                <div className="st-form-group">
                  <label className="st-form-label">Center Name</label>
                  <input
                    type="text"
                    className="st-input"
                    value={centerName}
                    onChange={e => setCenterName(e.target.value)}
                  />
                </div>
                <div className="st-form-group">
                  <label className="st-form-label">Hospital Registration ID</label>
                  <input
                    type="text"
                    className="st-input"
                    value={hospitalId}
                    onChange={e => setHospitalId(e.target.value)}
                  />
                </div>
                <div className="st-form-group">
                  <label className="st-form-label">Contact Person</label>
                  <input
                    type="text"
                    className="st-input"
                    value={contactPerson}
                    onChange={e => setContactPerson(e.target.value)}
                  />
                </div>
                <div className="st-form-group">
                  <label className="st-form-label">Official Email</label>
                  <input
                    type="email"
                    className="st-input"
                    value={officialEmail}
                    onChange={e => setOfficialEmail(e.target.value)}
                  />
                </div>
                <div className="st-form-group">
                  <label className="st-form-label">Phone</label>
                  <input
                    type="text"
                    className="st-input"
                    value={phone}
                    onChange={e => setPhone(e.target.value)}
                  />
                </div>
                <div className="st-form-group">
                  <label className="st-form-label">Address</label>
                  <input
                    type="text"
                    className="st-input"
                    value={address}
                    onChange={e => setAddress(e.target.value)}
                  />
                </div>
              </div>
            </div>
          )}

          {/* ── SYSTEM CONFIGURATION TAB ── */}
          {activeTab === 'system' && (
            <div className="st-panel">
              <div className="st-section-title">System Configuration</div>
              <div className="st-section-sub">Manage automated logic and notification triggers.</div>

              <div className="st-toggle-row">
                <div>
                  <div className="st-toggle-label">Asset Dispatch Notifications</div>
                  <div className="st-toggle-desc">Immediately alert Logistics Officers when a request matches stock.</div>
                </div>
                <Toggle value={dispatchNotif} onChange={setDispatchNotif} />
              </div>

              <div className="st-toggle-row">
                <div>
                  <div className="st-toggle-label">Critical Blood/Organ Alerts</div>
                  <div className="st-toggle-desc">Send priority alerts when inventory falls below critical thresholds.</div>
                </div>
                <Toggle value={criticalAlerts} onChange={setCriticalAlerts} />
              </div>

              <div className="st-toggle-row">
                <div>
                  <div className="st-toggle-label">Auto-Match Donors to Recipients</div>
                  <div className="st-toggle-desc">Automatically suggest compatible donor-recipient pairs using blood type and location.</div>
                </div>
                <Toggle value={autoMatch} onChange={setAutoMatch} />
              </div>

              <div className="st-divider"></div>

              <div className="st-form-grid">
                <div className="st-form-group">
                  <label className="st-form-label">Emergency Blood/Organ Alert Radius (KM)</label>
                  <div className="st-input-with-suffix">
                    <input
                      type="number"
                      className="st-input"
                      value={alertRadius}
                      onChange={e => setAlertRadius(e.target.value)}
                      style={{ paddingRight: 42 }}
                    />
                    <span className="st-input-suffix">km</span>
                  </div>
                </div>
                <div className="st-form-group">
                  <label className="st-form-label">Report Auto-Generation Frequency</label>
                  <select
                    className="st-select"
                    value={reportFreq}
                    onChange={e => setReportFreq(e.target.value)}
                  >
                    <option>Daily</option>
                    <option>Weekly (Mondays)</option>
                    <option>Bi-Weekly</option>
                    <option>Monthly</option>
                  </select>
                </div>
                <div className="st-form-group">
                  <label className="st-form-label">Data Retention Period (Days)</label>
                  <div className="st-input-with-suffix">
                    <input
                      type="number"
                      className="st-input"
                      value={retentionDays}
                      onChange={e => setRetentionDays(e.target.value)}
                      style={{ paddingRight: 52 }}
                    />
                    <span className="st-input-suffix">days</span>
                  </div>
                </div>
                <div className="st-form-group">
                  <label className="st-form-label">Timezone</label>
                  <select
                    className="st-select"
                    value={timezone}
                    onChange={e => setTimezone(e.target.value)}
                  >
                    <option>UTC-5 (Eastern Time)</option>
                    <option>UTC-6 (Central Time)</option>
                    <option>UTC-7 (Mountain Time)</option>
                    <option>UTC-8 (Pacific Time)</option>
                    <option>UTC+0 (Greenwich)</option>
                    <option>UTC+5:30 (India)</option>
                  </select>
                </div>
              </div>
            </div>
          )}

          {/* ── USER MANAGEMENT TAB ── */}
          {activeTab === 'users' && (
            <div className="st-panel" style={{ padding: 0, overflow: 'hidden' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '20px 22px', borderBottom: '1px solid #F1F5F9' }}>
                <div>
                  <div className="st-section-title">User Management</div>
                  <div style={{ fontSize: 13, color: '#94A3B8', marginTop: 2 }}>Manage staff access and permissions.</div>
                </div>
                <button className="st-add-user-btn">+ Add User</button>
              </div>
              <table className="st-user-table">
                <thead>
                  <tr>
                    <th>User</th>
                    <th>Role</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map((user, i) => (
                    <tr key={i}>
                      <td>
                        <div className="st-user-name-cell">{user.name}</div>
                        <div className="st-user-email">{user.email}</div>
                      </td>
                      <td><span className="st-role-chip">{user.role}</span></td>
                      <td>
                        <Toggle value={user.status} onChange={() => {}} />
                      </td>
                      <td>
                        <button className="st-user-action-btn">✏ Edit</button>
                        <button className="st-user-action-btn" style={{ color: '#EF4444', borderColor: '#FECACA' }}>🗑 Remove</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* ── SECURITY TAB ── */}
          {activeTab === 'security' && (
            <div className="st-panel">
              <div className="st-section-title">Security Settings</div>
              <div className="st-section-sub">Manage authentication, session, and access controls.</div>

              <div className="st-toggle-row">
                <div>
                  <div className="st-toggle-label">Two-Factor Authentication (2FA)</div>
                  <div className="st-toggle-desc">Require all admin users to verify identity via email or authenticator app.</div>
                </div>
                <Toggle value={twoFA} onChange={setTwoFA} />
              </div>

              <div className="st-toggle-row">
                <div>
                  <div className="st-toggle-label">IP Address Restriction</div>
                  <div className="st-toggle-desc">Limit portal access to approved IP ranges only.</div>
                </div>
                <Toggle value={ipRestriction} onChange={setIpRestriction} />
              </div>

              <div className="st-toggle-row">
                <div>
                  <div className="st-toggle-label">Audit Log</div>
                  <div className="st-toggle-desc">Record all admin actions, logins, and data changes for compliance.</div>
                </div>
                <Toggle value={auditLog} onChange={setAuditLog} />
              </div>

              <div className="st-divider"></div>

              <div className="st-form-grid">
                <div className="st-form-group">
                  <label className="st-form-label">Session Timeout (Minutes)</label>
                  <div className="st-input-with-suffix">
                    <input
                      type="number"
                      className="st-input"
                      value={sessionTimeout}
                      onChange={e => setSessionTimeout(e.target.value)}
                      style={{ paddingRight: 42 }}
                    />
                    <span className="st-input-suffix">min</span>
                  </div>
                </div>
                <div className="st-form-group">
                  <label className="st-form-label">Password Policy</label>
                  <select className="st-select">
                    <option>Strong (min. 12 chars, special chars)</option>
                    <option>Medium (min. 8 chars)</option>
                    <option>Custom</option>
                  </select>
                </div>
              </div>

              <div className="st-security-note">
                ⚠️ Changes to security settings take effect immediately and will end all active sessions.
              </div>
            </div>
          )}

        </div>
      </div>
    </>
  );
};

export default Settings;