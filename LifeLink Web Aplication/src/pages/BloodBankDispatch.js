import React, { useState } from 'react';
import { Link, useLocation } from "react-router-dom";

const DispatchManagement = () => {
  const [activeNav, setActiveNav] = useState('dispatch');
  const [activeDispatchTab, setActiveDispatchTab] = useState('live');
  const [searchQuery, setSearchQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
   const location = useLocation();

  const navItems = [
     { key: 'dashboard', icon: '⊞', label: 'Dashboard', path: '/bloodbank/dashboard' },
  { key: 'inventory', icon: '📦', label: 'Inventory', path: '/bloodbank/inventory' },
  { key: 'dispatch', icon: '🚚', label: 'Dispatch', path: '/bloodbank/dispatch' },
  { key: 'reports', icon: '📊', label: 'Reports', path: '/bloodbank/reports' },
  { key: 'settings', icon: '⚙️', label: 'Settings', path: '/bloodbank/setting' },
  ];

  const dispatches = [
    {
      id: '#LL-9021',
      assetIcon: '❤️',
      assetIconBg: '#FFF1F2',
      assetName: 'Human Heart',
      assetType: 'EMERGENCY TRANSPLANT',
      destination: 'St. Jude General',
      destinationSub: 'ER Bay 4',
      estArrival: '08:14',
      arrivalNote: 'Minutes left',
      arrivalColor: '#EF4444',
      status: 'URGENT PRIORITY',
      statusColor: '#EF4444',
      statusBg: '#FEE2E2',
      courier: 'Marcus R.',
      courierRole: 'Rapid Responder',
    },
    {
      id: '#LL-8842',
      assetIcon: '🩸',
      assetIconBg: '#EFF6FF',
      assetName: '4x Units O- Blood',
      assetType: 'ROUTINE SUPPLY',
      destination: "Mercy Children's",
      destinationSub: 'Blood Bank',
      estArrival: '14:45',
      arrivalNote: '',
      arrivalColor: '#0F172A',
      status: 'IN TRANSIT',
      statusColor: '#2563EB',
      statusBg: '#DBEAFE',
      courier: 'Jane M.',
      courierRole: 'Courier Van',
    },
    {
      id: '#LL-8711',
      assetIcon: '💉',
      assetIconBg: '#F0FDF4',
      assetName: 'Plasma Pkgs (10)',
      assetType: 'SCHEDULED REFILL',
      destination: 'Westside Surgical',
      destinationSub: 'Loading Dock B',
      estArrival: '22:10',
      arrivalNote: '(Delayed)',
      arrivalColor: '#F59E0B',
      status: 'TRAFFIC DELAY',
      statusColor: '#D97706',
      statusBg: '#FEF3C7',
      courier: 'S. Wilson',
      courierRole: 'Moto-courier',
    },
    {
      id: '#LL-8690',
      assetIcon: '🩸',
      assetIconBg: '#EFF6FF',
      assetName: '2x Units AB+ Blood',
      assetType: 'URGENT RESTOCK',
      destination: 'City Oncology',
      destinationSub: 'Lab Annex',
      estArrival: '06:30',
      arrivalNote: '',
      arrivalColor: '#0F172A',
      status: 'IN TRANSIT',
      statusColor: '#2563EB',
      statusBg: '#DBEAFE',
      courier: 'Alex B.',
      courierRole: 'Courier',
    },
  ];

  const mapCouriers = [
    { id: 'LL-9021', x: '30%', y: '38%', type: 'truck', critical: false, label: 'LL-9021 · 8 min' },
    { id: 'heart', x: '60%', y: '56%', type: 'heart', critical: true, label: 'CRITICAL · Heart' },
    { id: 'c2', x: '52%', y: '72%', type: 'truck', critical: false, label: '' },
  ];

  const filtered = dispatches.filter(d =>
    !searchQuery ||
    d.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
    d.assetName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    d.destination.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&family=Space+Mono:wght@400;700&display=swap');

        * { margin: 0; padding: 0; box-sizing: border-box; }

        .dm-app {
          display: flex;
          min-height: 100vh;
          background: #F8FAFC;
          font-family: 'DM Sans', -apple-system, sans-serif;
        }

        /* ── SIDEBAR ── */
        .dm-sidebar {
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

        .dm-logo {
          padding: 0 20px;
          height: 60px;
          border-bottom: 1px solid #F1F5F9;
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .dm-logo-icon {
          width: 36px; height: 36px;
          background: linear-gradient(135deg, #3B82F6, #2563EB);
          border-radius: 9px;
          display: flex; align-items: center; justify-content: center;
          font-size: 17px;
        }

        .dm-logo-name {
          font-size: 16px;
          font-weight: 800;
          color: #0F172A;
          letter-spacing: -0.3px;
        }

        .dm-nav {
          padding: 16px 12px;
          flex: 1;
          display: flex;
          flex-direction: column;
          gap: 2px;
        }

        .dm-nav-item {
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

        .dm-nav-item:hover { background: #F8FAFC; color: #0F172A; }
        .dm-nav-item.active { background: #EFF6FF; color: #2563EB; font-weight: 600; }
        .dm-nav-icon { font-size: 15px; width: 20px; text-align: center; }

        .dm-sys-status {
          padding: 14px 18px;
          border-top: 1px solid #F1F5F9;
          font-size: 11px;
        }

        .dm-sys-label {
          font-weight: 700;
          color: #10B981;
          text-transform: uppercase;
          letter-spacing: 0.06em;
          margin-bottom: 4px;
        }

        .dm-sys-sub {
          display: flex;
          align-items: center;
          gap: 6px;
          color: #64748B;
          font-size: 12px;
        }

        .dm-online-dot {
          width: 7px; height: 7px;
          background: #10B981;
          border-radius: 50%;
          animation: dmPulse 2s infinite;
        }

        @keyframes dmPulse {
          0%,100% { opacity: 1; }
          50% { opacity: 0.3; }
        }

        /* ── TOPBAR ── */
        .dm-topbar {
          position: fixed;
          top: 0; left: 0; right: 0;
          height: 60px;
          background: white;
          border-bottom: 1px solid #E2E8F0;
          display: flex;
          align-items: center;
          padding: 0 20px 0 260px;
          gap: 14px;
          z-index: 200;
        }

        .dm-search-wrap {
          position: relative;
          flex: 1;
          max-width: 320px;
        }

        .dm-search-icon {
          position: absolute;
          left: 10px;
          top: 50%;
          transform: translateY(-50%);
          font-size: 13px;
          color: #94A3B8;
        }

        .dm-search-input {
          width: 100%;
          background: #F8FAFC;
          border: 1px solid #E2E8F0;
          border-radius: 20px;
          padding: 7px 14px 7px 32px;
          font-family: 'DM Sans', sans-serif;
          font-size: 13px;
          color: #0F172A;
          outline: none;
          transition: border-color 0.15s;
        }

        .dm-search-input:focus { border-color: #2563EB; background: white; }
        .dm-search-input::placeholder { color: #94A3B8; }

        .dm-topbar-right {
          margin-left: auto;
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .dm-icon-btn {
          width: 36px; height: 36px;
          border-radius: 50%;
          background: white;
          border: 1px solid #E2E8F0;
          display: flex; align-items: center; justify-content: center;
          font-size: 16px;
          cursor: pointer;
          transition: background 0.12s;
          position: relative;
        }

        .dm-icon-btn:hover { background: #F8FAFC; }

        .dm-notif-dot {
          position: absolute;
          top: 5px; right: 5px;
          width: 8px; height: 8px;
          background: #EF4444;
          border: 2px solid white;
          border-radius: 50%;
        }

        .dm-user-info {
          text-align: right;
        }

        .dm-user-name {
          font-size: 13px;
          font-weight: 700;
          color: #0F172A;
          line-height: 1.2;
        }

        .dm-user-role {
          font-size: 10.5px;
          color: #94A3B8;
          text-transform: uppercase;
          letter-spacing: 0.04em;
          font-weight: 600;
        }

        .dm-avatar {
          width: 36px; height: 36px;
          background: linear-gradient(135deg, #FB923C, #F97316);
          color: white;
          border-radius: 50%;
          display: flex; align-items: center; justify-content: center;
          font-size: 15px;
          cursor: pointer;
        }

        /* ── MAIN ── */
        .dm-main {
          margin-left: 238px;
          margin-top: 60px;
          flex: 1;
          padding: 24px 24px;
          display: flex;
          flex-direction: column;
          gap: 18px;
        }

        /* ── PAGE HEADER ── */
        .dm-page-header {
          display: flex;
          align-items: flex-start;
          justify-content: space-between;
        }

        .dm-page-title {
          font-size: 22px;
          font-weight: 800;
          color: #0F172A;
          letter-spacing: -0.3px;
        }

        .dm-page-sub {
          font-size: 13px;
          color: #94A3B8;
          margin-top: 3px;
        }

        .dm-new-dispatch-btn {
          background: #2563EB;
          color: white;
          border: none;
          border-radius: 10px;
          padding: 11px 22px;
          font-size: 14px;
          font-weight: 700;
          cursor: pointer;
          font-family: 'DM Sans', sans-serif;
          display: flex;
          align-items: center;
          gap: 7px;
          transition: background 0.15s;
          box-shadow: 0 4px 14px rgba(37, 99, 235, 0.3);
        }

        .dm-new-dispatch-btn:hover { background: #1D4ED8; }

        /* ── STAT CARDS ── */
        .dm-stat-row {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 14px;
        }

        .dm-stat-card {
          background: white;
          border: 1px solid #E2E8F0;
          border-radius: 12px;
          padding: 20px 22px;
          display: flex;
          align-items: flex-start;
          justify-content: space-between;
          transition: box-shadow 0.15s;
          position: relative;
          overflow: hidden;
          animation: dmFadeUp 0.3s ease both;
        }

        .dm-stat-card:nth-child(1) { animation-delay: 0.05s; }
        .dm-stat-card:nth-child(2) { animation-delay: 0.10s; }
        .dm-stat-card:nth-child(3) { animation-delay: 0.15s; }

        @keyframes dmFadeUp {
          from { opacity: 0; transform: translateY(10px); }
          to   { opacity: 1; transform: translateY(0); }
        }

        .dm-stat-card:hover { box-shadow: 0 4px 16px rgba(0,0,0,0.07); }

        .dm-stat-label {
          font-size: 12px;
          color: #94A3B8;
          font-weight: 600;
          margin-bottom: 10px;
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }

        .dm-stat-value {
          font-family: 'Space Mono', monospace;
          font-size: 32px;
          font-weight: 700;
          color: #0F172A;
          line-height: 1;
          display: flex;
          align-items: baseline;
          gap: 8px;
        }

        .dm-stat-delta {
          font-size: 12px;
          font-weight: 700;
          display: flex;
          align-items: center;
          gap: 2px;
        }

        .dm-stat-delta.up { color: #10B981; }
        .dm-stat-delta.down { color: #F59E0B; }

        .dm-stat-sub {
          font-size: 12px;
          color: #94A3B8;
          margin-top: 6px;
        }

        .dm-stat-icon-wrap {
          width: 40px; height: 40px;
          border-radius: 10px;
          display: flex; align-items: center; justify-content: center;
          font-size: 18px;
          flex-shrink: 0;
        }

        .dm-critical-corner {
          position: absolute;
          top: 0; right: 0;
          background: #EF4444;
          color: white;
          font-size: 9px;
          font-weight: 800;
          padding: 3px 8px;
          letter-spacing: 0.06em;
          border-bottom-left-radius: 8px;
        }

        .dm-action-req {
          display: inline-flex;
          align-items: center;
          gap: 4px;
          font-size: 11px;
          font-weight: 700;
          color: #EF4444;
          margin-top: 4px;
        }

        /* ── BOTTOM GRID ── */
        .dm-bottom-grid {
          display: grid;
          grid-template-columns: 310px 1fr;
          gap: 16px;
          align-items: start;
        }

        /* ── MAP PANEL ── */
        .dm-map-panel {
          background: white;
          border: 1px solid #E2E8F0;
          border-radius: 12px;
          overflow: hidden;
        }

        .dm-map-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 14px 16px;
          border-bottom: 1px solid #F1F5F9;
        }

        .dm-map-title {
          font-size: 13.5px;
          font-weight: 700;
          color: #0F172A;
          display: flex;
          align-items: center;
          gap: 7px;
        }

        .dm-fullscreen-btn {
          font-size: 12px;
          color: #2563EB;
          font-weight: 600;
          background: none;
          border: none;
          cursor: pointer;
          font-family: 'DM Sans', sans-serif;
        }

        /* ── SVG MAP ── */
        .dm-map-container {
          position: relative;
          background: #EEF2F7;
          height: 340px;
          overflow: hidden;
        }

        .dm-map-svg {
          width: 100%;
          height: 100%;
        }

        .dm-map-marker {
          position: absolute;
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 4px;
          transform: translate(-50%, -50%);
          cursor: pointer;
          transition: transform 0.15s;
        }

        .dm-map-marker:hover { transform: translate(-50%, -50%) scale(1.1); }

        .dm-marker-bubble {
          background: #2563EB;
          color: white;
          border-radius: 50%;
          width: 34px; height: 34px;
          display: flex; align-items: center; justify-content: center;
          font-size: 14px;
          box-shadow: 0 2px 10px rgba(37,99,235,0.4);
          border: 2px solid white;
        }

        .dm-marker-bubble.critical {
          background: #EF4444;
          box-shadow: 0 2px 10px rgba(239,68,68,0.5);
        }

        .dm-marker-label {
          background: white;
          border: 1px solid #E2E8F0;
          border-radius: 6px;
          padding: 3px 8px;
          font-size: 10.5px;
          font-weight: 700;
          color: #0F172A;
          white-space: nowrap;
          box-shadow: 0 1px 4px rgba(0,0,0,0.1);
        }

        .dm-marker-label.critical { border-color: #FECACA; color: #EF4444; }

        .dm-map-zoom {
          position: absolute;
          bottom: 12px;
          right: 12px;
          display: flex;
          flex-direction: column;
          gap: 2px;
        }

        .dm-zoom-btn {
          width: 28px; height: 28px;
          background: white;
          border: 1px solid #E2E8F0;
          border-radius: 6px;
          display: flex; align-items: center; justify-content: center;
          font-size: 14px;
          cursor: pointer;
          font-weight: 700;
          color: #374151;
          transition: background 0.12s;
          font-family: monospace;
        }

        .dm-zoom-btn:hover { background: #F1F5F9; }

        /* ── COURIER CAPACITY ── */
        .dm-capacity-section {
          padding: 14px 16px;
          border-top: 1px solid #F1F5F9;
        }

        .dm-capacity-label {
          font-size: 10.5px;
          font-weight: 700;
          color: #94A3B8;
          text-transform: uppercase;
          letter-spacing: 0.07em;
          margin-bottom: 12px;
        }

        .dm-capacity-row {
          display: flex;
          align-items: center;
          justify-content: space-between;
          margin-bottom: 8px;
        }

        .dm-capacity-name {
          font-size: 13px;
          color: #374151;
          font-weight: 500;
        }

        .dm-capacity-count {
          font-size: 12px;
          font-weight: 700;
          color: #0F172A;
        }

        .dm-capacity-bar {
          height: 5px;
          background: #F1F5F9;
          border-radius: 3px;
          margin-top: 5px;
          overflow: hidden;
        }

        .dm-capacity-fill {
          height: 100%;
          border-radius: 3px;
          background: #2563EB;
        }

        /* ── DISPATCH PANEL ── */
        .dm-dispatch-panel {
          background: white;
          border: 1px solid #E2E8F0;
          border-radius: 12px;
          overflow: hidden;
        }

        .dm-dispatch-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 16px 20px;
          border-bottom: 1px solid #F1F5F9;
        }

        .dm-dispatch-title-row {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .dm-dispatch-title {
          font-size: 15px;
          font-weight: 700;
          color: #0F172A;
        }

        .dm-dispatch-tabs {
          display: flex;
          gap: 2px;
        }

        .dm-dtab {
          padding: 4px 12px;
          border-radius: 6px;
          font-size: 12.5px;
          font-weight: 600;
          cursor: pointer;
          border: none;
          background: none;
          color: #94A3B8;
          font-family: 'DM Sans', sans-serif;
          transition: all 0.15s;
        }

        .dm-dtab.active { background: #EFF6FF; color: #2563EB; }
        .dm-dtab:hover:not(.active) { color: #374151; }

        .dm-dispatch-actions {
          display: flex;
          gap: 6px;
        }

        .dm-action-icon-btn {
          width: 32px; height: 32px;
          background: #F8FAFC;
          border: 1px solid #E2E8F0;
          border-radius: 7px;
          display: flex; align-items: center; justify-content: center;
          font-size: 13px;
          cursor: pointer;
          color: #64748B;
          transition: all 0.12s;
        }

        .dm-action-icon-btn:hover { border-color: #2563EB; color: #2563EB; }

        /* ── TABLE ── */
        .dm-table { width: 100%; border-collapse: collapse; }

        .dm-table th {
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

        .dm-table tbody tr {
          transition: background 0.12s;
          cursor: pointer;
        }

        .dm-table tbody tr:hover { background: #F8FAFC; }

        .dm-table td {
          padding: 14px 16px;
          font-size: 13px;
          color: #374151;
          border-bottom: 1px solid #F8FAFC;
          vertical-align: middle;
        }

        .dm-table tbody tr:last-child td { border-bottom: none; }

        .dm-dispatch-id {
          font-family: 'Space Mono', monospace;
          font-size: 12px;
          color: #2563EB;
          font-weight: 700;
        }

        .dm-asset-cell {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .dm-asset-icon {
          width: 34px; height: 34px;
          border-radius: 8px;
          display: flex; align-items: center; justify-content: center;
          font-size: 15px;
          flex-shrink: 0;
        }

        .dm-asset-name {
          font-weight: 700;
          color: #0F172A;
          font-size: 13px;
        }

        .dm-asset-type {
          font-size: 10px;
          font-weight: 700;
          color: #94A3B8;
          text-transform: uppercase;
          letter-spacing: 0.05em;
          margin-top: 2px;
        }

        .dm-dest-name {
          font-weight: 600;
          color: #0F172A;
        }

        .dm-dest-sub {
          font-size: 11px;
          color: #94A3B8;
          margin-top: 2px;
        }

        .dm-arrival-time {
          font-family: 'Space Mono', monospace;
          font-size: 14px;
          font-weight: 700;
        }

        .dm-arrival-note {
          font-size: 11px;
          color: #94A3B8;
          margin-top: 2px;
        }

        .dm-status-chip {
          display: inline-block;
          padding: 3px 9px;
          border-radius: 5px;
          font-size: 10.5px;
          font-weight: 800;
          text-transform: uppercase;
          letter-spacing: 0.04em;
          font-family: 'Space Mono', monospace;
          line-height: 1.4;
          text-align: center;
        }

        .dm-courier-name {
          font-weight: 600;
          color: #0F172A;
          font-size: 12.5px;
        }

        .dm-courier-role {
          font-size: 11px;
          color: #94A3B8;
          margin-top: 2px;
        }

        /* ── PAGINATION ── */
        .dm-pagination {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 14px 20px;
          border-top: 1px solid #F1F5F9;
        }

        .dm-pagination-info {
          font-size: 12.5px;
          color: #94A3B8;
        }

        .dm-pagination-btns {
          display: flex;
          gap: 6px;
        }

        .dm-page-btn {
          padding: 6px 14px;
          border-radius: 7px;
          font-size: 12.5px;
          font-weight: 600;
          cursor: pointer;
          border: 1px solid #E2E8F0;
          background: white;
          color: #374151;
          font-family: 'DM Sans', sans-serif;
          transition: all 0.12s;
        }

        .dm-page-btn:hover { background: #F1F5F9; }
        .dm-page-btn.active { background: #2563EB; color: white; border-color: #2563EB; }

        @media (max-width: 1100px) {
          .dm-bottom-grid { grid-template-columns: 1fr; }
        }
        @media (max-width: 768px) {
          .dm-sidebar { display: none; }
          .dm-main { margin-left: 0; }
          .dm-topbar { padding-left: 20px; }
          .dm-stat-row { grid-template-columns: 1fr; }
        }
      `}</style>

      <div className="dm-app">

        {/* ── SIDEBAR ── */}
        <aside className="dm-sidebar">
          <div className="dm-logo">
            <div className="dm-logo-icon">➕</div>
            <div className="dm-logo-name">LifeLink</div>
          </div>

          <nav className="dm-nav">
                     {navItems.map(item => (
                       <Link
                         key={item.key}
                         to={item.path}
                         className={`dm-nav-item${location.pathname === item.path ? ' active' : ''}`}
                       >
                         <span className="dm-nav-icon">{item.icon}</span>
                         {item.label}
                       </Link>
                     ))}
                   </nav>
        

          <div className="dm-sys-status">
            <div className="dm-sys-label">System Status</div>
            <div className="dm-sys-sub">
              <div className="dm-online-dot"></div>
              All couriers connected
            </div>
          </div>
        </aside>

        {/* ── TOPBAR ── */}
        <header className="dm-topbar">
          <div className="dm-search-wrap">
            <span className="dm-search-icon">🔍</span>
            <input
              type="text"
              className="dm-search-input"
              placeholder="Search dispatches, assets, or hospitals"
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
            />
          </div>

          <div className="dm-topbar-right">
            <button className="dm-icon-btn">
              🔔
              <span className="dm-notif-dot"></span>
            </button>
            <button className="dm-icon-btn">❓</button>
            <div className="dm-user-info">
              <div className="dm-user-name">Dr. Sarah Chen</div>
              <div className="dm-user-role">Logistics Officer</div>
            </div>
            <div className="dm-avatar">👩</div>
          </div>
        </header>

        {/* ── MAIN ── */}
        <div className="dm-main">

          {/* PAGE HEADER */}
          <div className="dm-page-header">
            <div>
              <div className="dm-page-title">Dispatch Management</div>
              <div className="dm-page-sub">Monitor and manage critical life-saving logistics in real-time.</div>
            </div>
            <button className="dm-new-dispatch-btn">
              ＋ Initiate New Dispatch
            </button>
          </div>

          {/* STAT CARDS */}
          <div className="dm-stat-row">
            <div className="dm-stat-card">
              <div>
                <div className="dm-stat-label">Active Dispatches</div>
                <div className="dm-stat-value">
                  12
                  <span className="dm-stat-delta up">↗ 2%</span>
                </div>
                <div className="dm-stat-sub">Total assets currently moving</div>
              </div>
              <div className="dm-stat-icon-wrap" style={{ background: '#EFF6FF' }}>🔀</div>
            </div>

            <div className="dm-stat-card">
              <div>
                <div className="dm-stat-label">Avg. Delivery Time</div>
                <div className="dm-stat-value">
                  24m
                  <span className="dm-stat-delta down">↘ 5%</span>
                </div>
                <div className="dm-stat-sub">Optimization goal: 20 mins</div>
              </div>
              <div className="dm-stat-icon-wrap" style={{ background: '#EFF6FF' }}>⏱</div>
            </div>

            <div className="dm-stat-card">
              <div className="dm-critical-corner">CRITICAL</div>
              <div>
                <div className="dm-stat-label">Critical Requests</div>
                <div className="dm-stat-value" style={{ color: '#EF4444' }}>03</div>
                <div className="dm-action-req">⚠ Action Req.</div>
                <div className="dm-stat-sub" style={{ marginTop: 4 }}>High-priority organ transplants</div>
              </div>
              <div className="dm-stat-icon-wrap" style={{ background: '#FEE2E2' }}>✳</div>
            </div>
          </div>

          {/* BOTTOM GRID */}
          <div className="dm-bottom-grid">

            {/* MAP PANEL */}
            <div className="dm-map-panel">
              <div className="dm-map-header">
                <div className="dm-map-title">📋 Live Courier Tracking</div>
                <button className="dm-fullscreen-btn">Full Screen</button>
              </div>

              <div className="dm-map-container">
                {/* SVG city map */}
                <svg className="dm-map-svg" viewBox="0 0 310 340" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect width="310" height="340" fill="#E8EFF6"/>
                  {/* Roads */}
                  <rect x="0" y="80" width="310" height="18" fill="#D1D9E6" rx="1"/>
                  <rect x="0" y="160" width="310" height="14" fill="#D1D9E6" rx="1"/>
                  <rect x="0" y="240" width="310" height="18" fill="#D1D9E6" rx="1"/>
                  <rect x="60" y="0" width="16" height="340" fill="#D1D9E6" rx="1"/>
                  <rect x="150" y="0" width="14" height="340" fill="#D1D9E6" rx="1"/>
                  <rect x="240" y="0" width="16" height="340" fill="#D1D9E6" rx="1"/>
                  {/* Blocks */}
                  <rect x="76" y="0" width="64" height="74" fill="#D6E4F0" rx="4"/>
                  <rect x="164" y="0" width="66" height="74" fill="#D6E4F0" rx="4"/>
                  <rect x="76" y="98" width="64" height="56" fill="#D6E4F0" rx="4"/>
                  <rect x="164" y="98" width="66" height="56" fill="#D6E4F0" rx="4"/>
                  <rect x="0" y="98" width="52" height="56" fill="#D6E4F0" rx="4"/>
                  <rect x="256" y="98" width="54" height="56" fill="#D6E4F0" rx="4"/>
                  <rect x="76" y="178" width="64" height="56" fill="#CBD5E1" rx="4"/>
                  <rect x="164" y="178" width="66" height="56" fill="#D6E4F0" rx="4"/>
                  <rect x="0" y="178" width="52" height="56" fill="#D6E4F0" rx="4"/>
                  <rect x="76" y="258" width="64" height="82" fill="#D6E4F0" rx="4"/>
                  <rect x="164" y="258" width="66" height="82" fill="#D6E4F0" rx="4"/>
                  <rect x="0" y="258" width="52" height="82" fill="#CBD5E1" rx="4"/>
                  <rect x="256" y="178" width="54" height="56" fill="#D6E4F0" rx="4"/>
                  <rect x="256" y="258" width="54" height="82" fill="#D6E4F0" rx="4"/>
                  {/* Diagonal road accent */}
                  <line x1="76" y1="0" x2="0" y2="80" stroke="#C8D6E5" strokeWidth="8"/>
                  <line x1="310" y1="100" x2="240" y2="160" stroke="#C8D6E5" strokeWidth="6"/>
                </svg>

                {/* Courier markers */}
                <div className="dm-map-marker" style={{ left: '30%', top: '35%' }}>
                  <div className="dm-marker-label">LL-9021 · 8 min</div>
                  <div className="dm-marker-bubble">🚚</div>
                </div>

                <div className="dm-map-marker" style={{ left: '62%', top: '57%' }}>
                  <div className="dm-marker-label critical">CRITICAL · Heart</div>
                  <div className="dm-marker-bubble critical">🏥</div>
                </div>

                <div className="dm-map-marker" style={{ left: '52%', top: '74%' }}>
                  <div className="dm-marker-bubble">🚚</div>
                </div>

                <div className="dm-map-zoom">
                  <button className="dm-zoom-btn">+</button>
                  <button className="dm-zoom-btn">−</button>
                </div>
              </div>

              {/* Courier Capacity */}
              <div className="dm-capacity-section">
                <div className="dm-capacity-label">Courier Capacity</div>

                <div>
                  <div className="dm-capacity-row">
                    <span className="dm-capacity-name">Road Couriers</span>
                    <span className="dm-capacity-count">8/10 Active</span>
                  </div>
                  <div className="dm-capacity-bar">
                    <div className="dm-capacity-fill" style={{ width: '80%' }}></div>
                  </div>
                </div>

                <div style={{ marginTop: 10 }}>
                  <div className="dm-capacity-row">
                    <span className="dm-capacity-name">Air Transport (Organ)</span>
                    <span className="dm-capacity-count">2/5 Active</span>
                  </div>
                  <div className="dm-capacity-bar">
                    <div className="dm-capacity-fill" style={{ width: '40%' }}></div>
                  </div>
                </div>
              </div>
            </div>

            {/* DISPATCH TABLE PANEL */}
            <div className="dm-dispatch-panel">
              <div className="dm-dispatch-header">
                <div className="dm-dispatch-title-row">
                  <span className="dm-dispatch-title">Active Dispatches</span>
                  <div className="dm-dispatch-tabs">
                    <button
                      className={`dm-dtab${activeDispatchTab === 'live' ? ' active' : ''}`}
                      onClick={() => setActiveDispatchTab('live')}
                    >Live</button>
                    <button
                      className={`dm-dtab${activeDispatchTab === 'history' ? ' active' : ''}`}
                      onClick={() => setActiveDispatchTab('history')}
                    >History</button>
                  </div>
                </div>
                <div className="dm-dispatch-actions">
                  <button className="dm-action-icon-btn">≡</button>
                  <button className="dm-action-icon-btn">⬆</button>
                </div>
              </div>

              <table className="dm-table">
                <thead>
                  <tr>
                    <th>Dispatch ID</th>
                    <th>Asset Detail</th>
                    <th>Destination</th>
                    <th>Est. Arrival</th>
                    <th>Status</th>
                    <th>Courier</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((row, i) => (
                    <tr key={i}>
                      <td>
                        <span className="dm-dispatch-id">{row.id}</span>
                      </td>
                      <td>
                        <div className="dm-asset-cell">
                          <div
                            className="dm-asset-icon"
                            style={{ background: row.assetIconBg }}
                          >
                            {row.assetIcon}
                          </div>
                          <div>
                            <div className="dm-asset-name">{row.assetName}</div>
                            <div className="dm-asset-type">{row.assetType}</div>
                          </div>
                        </div>
                      </td>
                      <td>
                        <div className="dm-dest-name">{row.destination}</div>
                        <div className="dm-dest-sub">{row.destinationSub}</div>
                      </td>
                      <td>
                        <div
                          className="dm-arrival-time"
                          style={{ color: row.arrivalColor }}
                        >
                          {row.estArrival}
                        </div>
                        {row.arrivalNote && (
                          <div className="dm-arrival-note" style={{ color: row.arrivalColor }}>
                            {row.arrivalNote}
                          </div>
                        )}
                      </td>
                      <td>
                        <span
                          className="dm-status-chip"
                          style={{ background: row.statusBg, color: row.statusColor }}
                        >
                          {row.status}
                        </span>
                      </td>
                      <td>
                        <div className="dm-courier-name">{row.courier}</div>
                        <div className="dm-courier-role">{row.courierRole}</div>
                      </td>
                    </tr>
                  ))}
                  {filtered.length === 0 && (
                    <tr>
                      <td colSpan={6} style={{ textAlign: 'center', color: '#94A3B8', padding: '28px' }}>
                        No dispatches found
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>

              <div className="dm-pagination">
                <div className="dm-pagination-info">Showing 4 of 12 active dispatches</div>
                <div className="dm-pagination-btns">
                  <button
                    className="dm-page-btn"
                    onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                  >Previous</button>
                  <button
                    className="dm-page-btn"
                    onClick={() => setCurrentPage(p => p + 1)}
                  >Next</button>
                </div>
              </div>
            </div>

          </div>
        </div>
      </div>
    </>
  );
};

export default DispatchManagement;