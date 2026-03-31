import React, { useState } from 'react';
import { Link, useLocation } from "react-router-dom";

const InventoryManagement = () => {
  const [activeTab, setActiveTab] = useState('blood');
  const [searchQuery, setSearchQuery] = useState('');
  const location = useLocation();

  const bloodStock = [
    { type: 'A+', units: 42, status: 'SAFE', statusColor: '#10B981', statusBg: '#D1FAE5', critical: false },
    { type: 'A-', units: 12, status: 'LOW', statusColor: '#F59E0B', statusBg: '#FEF3C7', critical: false },
    { type: 'B+', units: 38, status: 'SAFE', statusColor: '#10B981', statusBg: '#D1FAE5', critical: false },
    { type: 'B-', units: 8, status: 'CRITICAL', statusColor: '#EF4444', statusBg: '#FEE2E2', critical: true },
    { type: 'O+', units: 55, status: 'SAFE', statusColor: '#10B981', statusBg: '#D1FAE5', critical: false },
    { type: 'O-', units: 5, status: 'CRITICAL', statusColor: '#EF4444', statusBg: '#FEE2E2', critical: true },
    { type: 'AB+', units: 22, status: 'SAFE', statusColor: '#10B981', statusBg: '#D1FAE5', critical: false },
    { type: 'AB-', units: 15, status: 'LOW', statusColor: '#F59E0B', statusBg: '#FEF3C7', critical: false },
  ];

  const bloodBatches = [
    {
      id: '#BLD-9921',
      bloodType: 'O-',
      units: '4 Units',
      collectionDate: 'Oct 24, 2023',
      expiryDate: 'Nov 28, 2023',
      expiryColor: '#374151',
      storageLocation: 'Main Freezer A-12',
      status: 'Healthy',
      statusColor: '#059669',
      statusBg: '#D1FAE5',
      statusDot: '#10B981',
    },
    {
      id: '#BLD-8840',
      bloodType: 'A+',
      units: '12 Units',
      collectionDate: 'Oct 22, 2023',
      expiryDate: 'Oct 30, 2023',
      expiryColor: '#F59E0B',
      storageLocation: 'Station B-04',
      status: 'Expiring Soon',
      statusColor: '#D97706',
      statusBg: '#FEF3C7',
      statusDot: '#F59E0B',
    },
    {
      id: '#BLD-7712',
      bloodType: 'AB-',
      units: '2 Units',
      collectionDate: 'Oct 25, 2023',
      expiryDate: 'Nov 30, 2023',
      expiryColor: '#374151',
      storageLocation: 'Reserved Box-1',
      status: 'Reserved',
      statusColor: '#2563EB',
      statusBg: '#DBEAFE',
      statusDot: '#3B82F6',
    },
  ];

  const organInventory = [
    {
      assetId: '#ORG-HK441',
      organType: 'Kidney',
      organIcon: '💙',
      organIconBg: '#EFF6FF',
      donorId: 'D-****298',
      preservationStart: 'Oct 26, 08:30 AM',
      viability: 85,
      viabilityColor: '#10B981',
      timeLeft: '18h left',
      hospitalUnit: 'Surgical Unit 4A',
      status: 'AVAILABLE',
      statusColor: '#2563EB',
      statusBg: '#DBEAFE',
    },
    {
      assetId: '#ORG-HT902',
      organType: 'Heart',
      organIcon: '❤️',
      organIconBg: '#FFF1F2',
      donorId: 'D-****102',
      preservationStart: 'Oct 26, 11:45 AM',
      viability: 15,
      viabilityColor: '#EF4444',
      timeLeft: '45m left',
      hospitalUnit: 'Emergency Ward C',
      status: 'URGENT ACTION',
      statusColor: '#EF4444',
      statusBg: '#FEE2E2',
    },
    {
      assetId: '#ORG-LV330',
      organType: 'Liver',
      organIcon: '🫀',
      organIconBg: '#FFFBEB',
      donorId: 'D-****774',
      preservationStart: 'Oct 26, 09:15 AM',
      viability: 60,
      viabilityColor: '#F59E0B',
      timeLeft: '12h left',
      hospitalUnit: 'Central ICU',
      status: 'AVAILABLE',
      statusColor: '#2563EB',
      statusBg: '#DBEAFE',
    },
  ];

  const navItems = [
    { key: 'dashboard', icon: '⊞', label: 'Dashboard', path: '/bloodbank/dashboard' },
  { key: 'inventory', icon: '📦', label: 'Inventory', path: '/bloodbank/inventory' },
  { key: 'dispatch', icon: '🚚', label: 'Dispatch', path: '/bloodbank/dispatch' },
  { key: 'reports', icon: '📊', label: 'Reports', path: '/bloodbank/reports' },
  { key: 'settings', icon: '⚙️', label: 'Settings', path: '/bloodbank/setting' },
  ];

  const [activeNav, setActiveNav] = useState('inventory');

  const getInitials = (name) => {
  if (!name) return "BB"; // fallback

  const words = name.trim().split(" ");

  if (words.length === 1) {
    return words[0].substring(0, 2).toUpperCase();
  }

  return words
    .slice(0, 2)
    .map(word => word[0])
    .join("")
    .toUpperCase();
};

const instituteName = localStorage.getItem("institutionName");
const avatarText = getInitials(instituteName);

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&family=Space+Mono:wght@400;700&display=swap');

        * { margin: 0; padding: 0; box-sizing: border-box; }

        .im-app {
          display: flex;
          min-height: 100vh;
          background: #F8FAFC;
          font-family: 'DM Sans', -apple-system, sans-serif;
        }

        /* ── SIDEBAR ── */
        .im-sidebar {
          width: 240px;
          background: white;
          border-right: 1px solid #E2E8F0;
          display: flex;
          flex-direction: column;
          position: fixed;
          top: 0; left: 0;
          height: 100vh;
          z-index: 100;
        }

        .im-logo {
          padding: 18px 20px;
          border-bottom: 1px solid #F1F5F9;
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .im-logo-icon {
          width: 40px; height: 40px;
          background: linear-gradient(135deg, #3B82F6 0%, #2563EB 100%);
          border-radius: 10px;
          display: flex; align-items: center; justify-content: center;
          font-size: 18px;
          color: white;
        }

        .im-logo-name {
          font-size: 14px;
          font-weight: 700;
          color: #0F172A;
        }

        .im-logo-sub {
          font-size: 10.5px;
          color: #94A3B8;
          font-weight: 500;
          text-transform: uppercase;
          letter-spacing: 0.04em;
        }

        .im-nav {
          padding: 16px 12px;
          flex: 1;
          display: flex;
          flex-direction: column;
          gap: 2px;
        }

        .im-nav-item {
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

        .im-nav-item:hover {
          background: #F8FAFC;
          color: #0F172A;
        }

        .im-nav-item.active {
          background: #EFF6FF;
          color: #2563EB;
          font-weight: 600;
        }

        .im-nav-icon { font-size: 15px; width: 20px; text-align: center; }

        .im-emergency-btn {
          margin: 16px 14px;
          background: #EF4444;
          color: white;
          border: none;
          border-radius: 10px;
          padding: 12px 16px;
          font-size: 13px;
          font-weight: 700;
          cursor: pointer;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
          font-family: 'DM Sans', sans-serif;
          transition: background 0.15s;
          box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
        }

        .im-emergency-btn:hover { background: #DC2626; }

        /* ── MAIN ── */
        .im-main {
          margin-left: 240px;
          flex: 1;
          display: flex;
          flex-direction: column;
          min-height: 100vh;
        }

        /* ── TOPBAR ── */
        .im-topbar {
          background: white;
          border-bottom: 1px solid #E2E8F0;
          padding: 0 28px;
          height: 64px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          position: sticky;
          top: 0;
          z-index: 50;
        }

        .im-page-title {
          font-size: 18px;
          font-weight: 700;
          color: #0F172A;
        }

        .im-topbar-right {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .im-search-wrap {
          position: relative;
        }

        .im-search-icon {
          position: absolute;
          left: 10px;
          top: 50%;
          transform: translateY(-50%);
          font-size: 13px;
          color: #94A3B8;
        }

        .im-search-input {
          background: #F8FAFC;
          border: 1px solid #E2E8F0;
          border-radius: 20px;
          padding: 7px 14px 7px 32px;
          font-family: 'DM Sans', sans-serif;
          font-size: 13px;
          color: #0F172A;
          outline: none;
          width: 220px;
          transition: border-color 0.15s;
        }

        .im-search-input:focus { border-color: #2563EB; background: white; }
        .im-search-input::placeholder { color: #94A3B8; }

        .im-notif-btn {
          position: relative;
          width: 38px; height: 38px;
          background: white;
          border: 1px solid #E2E8F0;
          border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          cursor: pointer; font-size: 16px;
          transition: background 0.15s;
        }

        .im-notif-btn:hover { background: #F8FAFC; }

        .im-notif-dot {
          position: absolute;
          top: 6px; right: 6px;
          width: 8px; height: 8px;
          background: #EF4444;
          border: 2px solid white;
          border-radius: 50%;
        }

        .im-avatar {
          width: 38px; height: 38px;
          background: #2563EB;
          color: white;
          border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          font-size: 12px;
          font-weight: 700;
          cursor: pointer;
        }

        /* ── CONTENT ── */
        .im-content {
          padding: 24px 28px;
          display: flex;
          flex-direction: column;
          gap: 20px;
        }

        /* ── TAB ROW ── */
        .im-tab-row {
          display: flex;
          align-items: center;
          justify-content: space-between;
        }

        .im-tabs {
          display: flex;
          background: #F1F5F9;
          border-radius: 10px;
          padding: 4px;
          gap: 2px;
        }

        .im-tab {
          padding: 8px 20px;
          border-radius: 7px;
          font-size: 13.5px;
          font-weight: 600;
          cursor: pointer;
          border: none;
          background: none;
          color: #64748B;
          font-family: 'DM Sans', sans-serif;
          transition: all 0.15s;
        }

        .im-tab.active {
          background: white;
          color: #2563EB;
          box-shadow: 0 1px 4px rgba(0,0,0,0.08);
        }

        .im-tab:hover:not(.active) { color: #0F172A; }

        .im-action-btns {
          display: flex;
          gap: 8px;
        }

        .im-btn {
          padding: 8px 16px;
          border-radius: 8px;
          font-size: 13px;
          font-weight: 600;
          cursor: pointer;
          border: none;
          font-family: 'DM Sans', sans-serif;
          display: flex;
          align-items: center;
          gap: 6px;
          transition: all 0.15s;
        }

        .im-btn-primary {
          background: #2563EB;
          color: white;
        }

        .im-btn-primary:hover { background: #1D4ED8; }

        .im-btn-dark {
          background: #0F172A;
          color: white;
        }

        .im-btn-dark:hover { background: #1E293B; }

        .im-btn-icon {
          background: #F1F5F9;
          color: #374151;
          border: 1px solid #E2E8F0;
          width: 36px; height: 36px;
          padding: 0;
          display: flex; align-items: center; justify-content: center;
          border-radius: 8px;
          font-size: 14px;
        }

        .im-btn-icon:hover { background: #E2E8F0; }

        /* ── BLOOD STOCK SECTION ── */
        .im-section-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          margin-bottom: 14px;
        }

        .im-section-title {
          font-size: 15px;
          font-weight: 700;
          color: #0F172A;
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .im-last-updated {
          font-size: 12px;
          color: #94A3B8;
        }

        /* ── BLOOD STOCK GRID ── */
        .im-blood-grid {
          display: grid;
          grid-template-columns: repeat(8, 1fr);
          gap: 10px;
        }

        .im-blood-card {
          background: white;
          border: 1px solid #E2E8F0;
          border-radius: 10px;
          padding: 14px 12px;
          text-align: center;
          transition: box-shadow 0.15s, border-color 0.15s;
          cursor: pointer;
        }

        .im-blood-card:hover {
          box-shadow: 0 4px 12px rgba(0,0,0,0.08);
        }

        .im-blood-card.critical {
          border-color: #FECACA;
          background: linear-gradient(135deg, white 60%, #FFF5F5);
        }

        .im-blood-type {
          font-size: 12px;
          font-weight: 600;
          color: #94A3B8;
          margin-bottom: 6px;
        }

        .im-blood-units {
          font-family: 'Space Mono', monospace;
          font-size: 26px;
          font-weight: 700;
          color: #0F172A;
          line-height: 1;
          margin-bottom: 8px;
        }

        .im-blood-card.critical .im-blood-units { color: #EF4444; }

        .im-blood-status {
          display: inline-block;
          padding: 2px 8px;
          border-radius: 4px;
          font-size: 9.5px;
          font-weight: 800;
          letter-spacing: 0.05em;
          text-transform: uppercase;
        }

        /* ── PANEL ── */
        .im-panel {
          background: white;
          border: 1px solid #E2E8F0;
          border-radius: 12px;
          overflow: hidden;
        }

        .im-panel-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 16px 20px;
          border-bottom: 1px solid #F1F5F9;
        }

        .im-panel-title {
          font-size: 14px;
          font-weight: 700;
          color: #0F172A;
        }

        .im-view-all {
          font-size: 12.5px;
          color: #2563EB;
          font-weight: 600;
          background: none;
          border: none;
          cursor: pointer;
          font-family: 'DM Sans', sans-serif;
        }

        /* ── TABLE ── */
        .im-table { width: 100%; border-collapse: collapse; }

        .im-table th {
          text-align: left;
          padding: 10px 20px;
          font-size: 10.5px;
          color: #94A3B8;
          text-transform: uppercase;
          letter-spacing: 0.06em;
          font-weight: 700;
          background: #FAFBFC;
          border-bottom: 1px solid #F1F5F9;
        }

        .im-table tbody tr {
          transition: background 0.12s;
          cursor: pointer;
        }

        .im-table tbody tr:hover { background: #F8FAFC; }

        .im-table td {
          padding: 14px 20px;
          font-size: 13px;
          color: #374151;
          border-bottom: 1px solid #F8FAFC;
          vertical-align: middle;
        }

        .im-table tbody tr:last-child td { border-bottom: none; }

        .im-batch-id {
          font-family: 'Space Mono', monospace;
          font-size: 12px;
          color: #2563EB;
          font-weight: 700;
        }

        .im-expiry-urgent { color: #F59E0B; font-weight: 600; }

        .im-status-chip {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          padding: 4px 10px;
          border-radius: 20px;
          font-size: 12px;
          font-weight: 600;
        }

        .im-status-dot {
          width: 7px; height: 7px;
          border-radius: 50%;
        }

        .im-more-btn {
          background: none;
          border: none;
          cursor: pointer;
          color: #94A3B8;
          font-size: 16px;
          padding: 4px 6px;
          border-radius: 4px;
          transition: all 0.12s;
        }

        .im-more-btn:hover { background: #F1F5F9; color: #374151; }

        /* ── ORGAN SECTION ── */
        .im-organ-section-title {
          font-size: 15px;
          font-weight: 700;
          color: #0F172A;
          display: flex;
          align-items: center;
          gap: 8px;
          padding: 16px 20px;
          border-bottom: 1px solid #F1F5F9;
        }

        .im-organ-icon-wrap {
          width: 28px; height: 28px;
          background: #EFF6FF;
          border-radius: 7px;
          display: flex; align-items: center; justify-content: center;
          font-size: 14px;
        }

        .im-organ-type-cell {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .im-organ-emoji-wrap {
          width: 34px; height: 34px;
          border-radius: 8px;
          display: flex; align-items: center; justify-content: center;
          font-size: 16px;
        }

        .im-organ-name {
          font-weight: 600;
          color: #0F172A;
          font-size: 13.5px;
        }

        .im-viability-cell {
          display: flex;
          flex-direction: column;
          gap: 5px;
          min-width: 110px;
        }

        .im-viability-row {
          display: flex;
          justify-content: space-between;
          font-size: 12px;
          font-weight: 700;
        }

        .im-viability-bar {
          height: 5px;
          background: #F1F5F9;
          border-radius: 3px;
          overflow: hidden;
        }

        .im-viability-fill {
          height: 100%;
          border-radius: 3px;
          transition: width 0.6s ease;
        }

        .im-viability-time {
          font-size: 10px;
          color: #94A3B8;
          font-family: 'Space Mono', monospace;
        }

        .im-org-status {
          display: inline-block;
          padding: 3px 9px;
          border-radius: 5px;
          font-size: 10.5px;
          font-weight: 800;
          letter-spacing: 0.04em;
          font-family: 'Space Mono', monospace;
        }

        @media (max-width: 1200px) {
          .im-blood-grid { grid-template-columns: repeat(4, 1fr); }
        }
        @media (max-width: 768px) {
          .im-sidebar { display: none; }
          .im-main { margin-left: 0; }
          .im-blood-grid { grid-template-columns: repeat(2, 1fr); }
        }
      `}</style>

      <div className="im-app">

        {/* ── SIDEBAR ── */}
        <aside className="im-sidebar">
          <div className="im-logo">
            <div className="im-logo-icon">📈</div>
            <div>
              <div className="im-logo-name">Blood & Organ</div>
              <div className="im-logo-sub">Admin Portal</div>
            </div>
          </div>

           <nav className="im-nav">
            {navItems.map(item => (
              <Link
                key={item.key}
                to={item.path}
                className={`im-nav-item${location.pathname === item.path ? ' active' : ''}`}
              >
                <span className="im-nav-icon">{item.icon}</span>
                {item.label}
              </Link>
            ))}
          </nav>

          <button className="im-emergency-btn">
            🔴 Emergency Request
          </button>
        </aside>

        {/* ── MAIN ── */}
        <div className="im-main">

          {/* ── TOPBAR ── */}
          <header className="im-topbar">
            <div className="im-page-title">Inventory Management</div>
            <div className="im-topbar-right">
              <div className="im-search-wrap">
                <span className="im-search-icon">🔍</span>
                <input
                  type="text"
                  className="im-search-input"
                  placeholder="Search batch, asset, or type..."
                  value={searchQuery}
                  onChange={e => setSearchQuery(e.target.value)}
                />
              </div>
              <button className="im-notif-btn">
                🔔
                <span className="im-notif-dot"></span>
              </button>
              {/* Inside the im-topbar-right div */}
                 <Link to="/bloodbank/profile" style={{ textDecoration: 'none' }}>
  <div className="im-avatar" title={instituteName}>
    {avatarText}
  </div>
</Link>
            </div>
          </header>
          

          {/* ── CONTENT ── */}
          <div className="im-content">

            {/* ── TAB ROW ── */}
            <div className="im-tab-row">
              <div className="im-tabs">
                <button
                  className={`im-tab${activeTab === 'blood' ? ' active' : ''}`}
                  onClick={() => setActiveTab('blood')}
                >
                  Blood Inventory
                </button>
                <button
                  className={`im-tab${activeTab === 'organ' ? ' active' : ''}`}
                  onClick={() => setActiveTab('organ')}
                >
                  Organ Inventory
                </button>
              </div>
              <div className="im-action-btns">
                <button className="im-btn im-btn-primary">⬆ Update Stock</button>
                <button className="im-btn im-btn-dark">🔖 Reserve Asset</button>
                <button className="im-btn im-btn-icon">⬇</button>
              </div>
            </div>

            {/* ── BLOOD STOCK SUMMARY ── */}
            <div>
              <div className="im-section-header">
                <div className="im-section-title">🩸 Blood Stock Summary</div>
                <div className="im-last-updated">Last updated: Just now</div>
              </div>
              <div className="im-blood-grid">
                {bloodStock.map((item, i) => (
                  <div
                    key={i}
                    className={`im-blood-card${item.critical ? ' critical' : ''}`}
                  >
                    <div className="im-blood-type">{item.type}</div>
                    <div className="im-blood-units">{String(item.units).padStart(2, '0')}</div>
                    <div
                      className="im-blood-status"
                      style={{ background: item.statusBg, color: item.statusColor }}
                    >
                      {item.status}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* ── RECENT BLOOD BATCHES ── */}
            <div className="im-panel">
              <div className="im-panel-header">
                <span className="im-panel-title">Recent Blood Batches</span>
                <button className="im-view-all">View All</button>
              </div>
              <table className="im-table">
                <thead>
                  <tr>
                    <th>Batch ID</th>
                    <th>Blood Type</th>
                    <th>Units</th>
                    <th>Collection Date</th>
                    <th>Expiry Date</th>
                    <th>Storage Location</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {bloodBatches
                    .filter(b =>
                      !searchQuery ||
                      b.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
                      b.bloodType.toLowerCase().includes(searchQuery.toLowerCase()) ||
                      b.storageLocation.toLowerCase().includes(searchQuery.toLowerCase())
                    )
                    .map((batch, i) => (
                      <tr key={i}>
                        <td><span className="im-batch-id">{batch.id}</span></td>
                        <td style={{ fontWeight: 600, color: '#0F172A' }}>{batch.bloodType}</td>
                        <td>{batch.units}</td>
                        <td>{batch.collectionDate}</td>
                        <td style={{ color: batch.expiryColor, fontWeight: batch.expiryColor !== '#374151' ? 600 : 400 }}>
                          {batch.expiryDate}
                        </td>
                        <td>{batch.storageLocation}</td>
                        <td>
                          <span
                            className="im-status-chip"
                            style={{ background: batch.statusBg, color: batch.statusColor }}
                          >
                            <span
                              className="im-status-dot"
                              style={{ background: batch.statusDot }}
                            />
                            {batch.status}
                          </span>
                        </td>
                        <td>
                          <button className="im-more-btn">⋮</button>
                        </td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </div>

            {/* ── ORGAN INVENTORY ── */}
            <div className="im-panel">
              <div className="im-organ-section-title">
                <div className="im-organ-icon-wrap">📋</div>
                Organ Inventory
              </div>
              <table className="im-table">
                <thead>
                  <tr>
                    <th>Asset ID</th>
                    <th>Organ Type</th>
                    <th>Donor ID</th>
                    <th>Preservation Start</th>
                    <th>Estimated Viability</th>
                    <th>Hospital Unit</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {organInventory
                    .filter(o =>
                      !searchQuery ||
                      o.assetId.toLowerCase().includes(searchQuery.toLowerCase()) ||
                      o.organType.toLowerCase().includes(searchQuery.toLowerCase()) ||
                      o.hospitalUnit.toLowerCase().includes(searchQuery.toLowerCase())
                    )
                    .map((organ, i) => (
                      <tr key={i}>
                        <td>
                          <span style={{ fontWeight: 700, color: '#0F172A', fontSize: '12.5px', fontFamily: "'Space Mono', monospace" }}>
                            {organ.assetId}
                          </span>
                        </td>
                        <td>
                          <div className="im-organ-type-cell">
                            <div
                              className="im-organ-emoji-wrap"
                              style={{ background: organ.organIconBg }}
                            >
                              {organ.organIcon}
                            </div>
                            <span className="im-organ-name">{organ.organType}</span>
                          </div>
                        </td>
                        <td style={{ color: '#64748B', fontFamily: "'Space Mono', monospace", fontSize: '11.5px' }}>
                          {organ.donorId}
                        </td>
                        <td>{organ.preservationStart}</td>
                        <td>
                          <div className="im-viability-cell">
                            <div className="im-viability-row">
                              <span style={{ color: organ.viabilityColor }}>{organ.viability}%</span>
                              <span className="im-viability-time">{organ.timeLeft}</span>
                            </div>
                            <div className="im-viability-bar">
                              <div
                                className="im-viability-fill"
                                style={{
                                  width: `${organ.viability}%`,
                                  background: organ.viabilityColor
                                }}
                              />
                            </div>
                          </div>
                        </td>
                        <td>{organ.hospitalUnit}</td>
                        <td>
                          <span
                            className="im-org-status"
                            style={{ background: organ.statusBg, color: organ.statusColor }}
                          >
                            {organ.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </div>

          </div>
        </div>
      </div>
    </>
  );
};

export default InventoryManagement;