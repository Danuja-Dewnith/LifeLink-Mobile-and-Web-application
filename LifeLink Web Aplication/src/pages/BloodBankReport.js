import React, { useState } from 'react';
import { Link, useLocation } from "react-router-dom";

const ReportsAnalytics = () => {
  const [activeNav, setActiveNav] = useState('reports');
  const [reportType, setReportType] = useState('Inventory Summary');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [status, setStatus] = useState('Completed');
  const [bloodProducts, setBloodProducts] = useState(true);
  const [organAssets, setOrganAssets] = useState(true);
  const [searchHistory, setSearchHistory] = useState('');
  const [generated, setGenerated] = useState(false);
   const location = useLocation();

  const navItems = [
     { key: 'dashboard', icon: '⊞', label: 'Dashboard', path: '/bloodbank/dashboard' },
  { key: 'inventory', icon: '📦', label: 'Inventory', path: '/bloodbank/inventory' },
  { key: 'dispatch', icon: '🚚', label: 'Dispatch', path: '/bloodbank/dispatch' },
  { key: 'reports', icon: '📊', label: 'Reports', path: '/bloodbank/reports' },
  { key: 'settings', icon: '⚙️', label: 'Settings', path: '/bloodbank/setting' },
  ];

  const donationTrends = [
    { month: 'JAN', value: 42, highlight: false },
    { month: 'FEB', value: 61, highlight: false },
    { month: 'MAR', value: 53, highlight: false },
    { month: 'APR', value: 75, highlight: false },
    { month: 'MAY', value: 68, highlight: false },
    { month: 'JUN', value: 88, highlight: true },
  ];

  const maxVal = Math.max(...donationTrends.map(d => d.value));

  const recentReports = [
    { name: 'Monthly Inventory Summary', type: 'Inventory', date: 'Oct 26, 2023', format: 'PDF', status: 'Completed', statusColor: '#10B981', statusBg: '#D1FAE5' },
    { name: 'Organ Dispatch Log – Q3', type: 'Dispatch', date: 'Oct 25, 2023', format: 'CSV', status: 'Completed', statusColor: '#10B981', statusBg: '#D1FAE5' },
    { name: 'Emergency Alert Summary', type: 'Alerts', date: 'Oct 24, 2023', format: 'PDF', status: 'Processing', statusColor: '#F59E0B', statusBg: '#FEF3C7' },
    { name: 'Blood Supply Efficiency Report', type: 'Inventory', date: 'Oct 22, 2023', format: 'XLSX', status: 'Completed', statusColor: '#10B981', statusBg: '#D1FAE5' },
    { name: 'Donor Registration Stats', type: 'Donors', date: 'Oct 20, 2023', format: 'PDF', status: 'Failed', statusColor: '#EF4444', statusBg: '#FEE2E2' },
  ];

  const filtered = recentReports.filter(r =>
    !searchHistory ||
    r.name.toLowerCase().includes(searchHistory.toLowerCase()) ||
    r.type.toLowerCase().includes(searchHistory.toLowerCase())
  );

  // Donut chart SVG params
  const bloodPct = 70;
  const organPct = 30;
  const r = 70;
  const cx = 110, cy = 110;
  const circ = 2 * Math.PI * r;
  const bloodDash = (bloodPct / 100) * circ;
  const organDash = (organPct / 100) * circ;

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&family=Space+Mono:wght@400;700&display=swap');

        * { margin: 0; padding: 0; box-sizing: border-box; }

        .ra-app {
          display: flex;
          min-height: 100vh;
          background: #F8FAFC;
          font-family: 'DM Sans', -apple-system, sans-serif;
        }

        /* ── SIDEBAR ── */
        .ra-sidebar {
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

        .ra-logo {
          padding: 0 20px;
          height: 60px;
          border-bottom: 1px solid #F1F5F9;
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .ra-logo-icon {
          width: 36px; height: 36px;
          background: linear-gradient(135deg, #3B82F6, #2563EB);
          border-radius: 9px;
          display: flex; align-items: center; justify-content: center;
          font-size: 17px;
        }

        .ra-logo-name {
          font-size: 16px;
          font-weight: 800;
          color: #0F172A;
          letter-spacing: -0.3px;
        }

        .ra-nav {
          padding: 16px 12px;
          flex: 1;
          display: flex;
          flex-direction: column;
          gap: 2px;
        }

        .ra-nav-item {
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

        .ra-nav-item:hover { background: #F8FAFC; color: #0F172A; }
        .ra-nav-item.active { background: #EFF6FF; color: #2563EB; font-weight: 600; }
        .ra-nav-icon { font-size: 15px; width: 20px; text-align: center; }

        .ra-user-card {
          margin: 14px;
          background: #EFF6FF;
          border-radius: 10px;
          padding: 12px 14px;
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .ra-user-avatar {
          width: 36px; height: 36px;
          background: #2563EB;
          border-radius: 10px;
          display: flex; align-items: center; justify-content: center;
          font-size: 17px;
          flex-shrink: 0;
        }

        .ra-user-name {
          font-size: 13px;
          font-weight: 700;
          color: #0F172A;
        }

        .ra-user-id {
          font-size: 11px;
          color: #64748B;
        }

        /* ── TOPBAR ── */
        .ra-topbar {
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

        .ra-breadcrumb {
          font-size: 13px;
          color: #94A3B8;
          display: flex;
          align-items: center;
          gap: 6px;
        }

        .ra-breadcrumb-sep { color: #CBD5E1; }
        .ra-breadcrumb-active { color: #2563EB; font-weight: 600; }

        .ra-topbar-right {
          margin-left: auto;
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .ra-icon-btn {
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

        .ra-icon-btn:hover { background: #F8FAFC; }

        .ra-notif-dot {
          position: absolute;
          top: 5px; right: 5px;
          width: 8px; height: 8px;
          background: #EF4444;
          border: 2px solid white;
          border-radius: 50%;
        }

        .ra-topbar-divider {
          width: 1px; height: 28px;
          background: #E2E8F0;
        }

        .ra-user-info { text-align: right; }
        .ra-tb-name { font-size: 13px; font-weight: 700; color: #0F172A; }
        .ra-tb-role { font-size: 10.5px; color: #94A3B8; text-transform: uppercase; letter-spacing: 0.04em; font-weight: 600; }

        .ra-tb-avatar {
          width: 36px; height: 36px;
          border-radius: 50%;
          border: 2px solid #E2E8F0;
          overflow: hidden;
          background: linear-gradient(135deg, #6EE7B7, #3B82F6);
          display: flex; align-items: center; justify-content: center;
          font-size: 16px;
          cursor: pointer;
        }

        /* ── MAIN ── */
        .ra-main {
          margin-left: 238px;
          margin-top: 60px;
          flex: 1;
          padding: 28px;
          display: flex;
          flex-direction: column;
          gap: 20px;
        }

        /* ── PAGE HEADER ── */
        .ra-page-title {
          font-size: 26px;
          font-weight: 800;
          color: #0F172A;
          letter-spacing: -0.4px;
        }

        .ra-page-sub {
          font-size: 13.5px;
          color: #94A3B8;
          margin-top: 4px;
        }

        /* ── REPORT GENERATION PANEL ── */
        .ra-panel {
          background: white;
          border: 1px solid #E2E8F0;
          border-radius: 14px;
          overflow: hidden;
        }

        .ra-panel-label {
          display: flex;
          align-items: center;
          gap: 8px;
          padding: 14px 22px;
          border-bottom: 1px solid #F1F5F9;
          font-size: 11px;
          font-weight: 800;
          color: #94A3B8;
          text-transform: uppercase;
          letter-spacing: 0.08em;
        }

        .ra-form-grid {
          display: grid;
          grid-template-columns: 1fr 1fr 1fr 1fr;
          gap: 20px;
          padding: 20px 22px 0;
        }

        .ra-form-group {
          display: flex;
          flex-direction: column;
          gap: 6px;
        }

        .ra-label {
          font-size: 13px;
          font-weight: 600;
          color: #374151;
        }

        .ra-select, .ra-date-input {
          padding: 9px 12px;
          border: 1.5px solid #E2E8F0;
          border-radius: 8px;
          font-size: 13.5px;
          color: #0F172A;
          background: white;
          font-family: 'DM Sans', sans-serif;
          outline: none;
          transition: border-color 0.15s;
          appearance: none;
          -webkit-appearance: none;
          width: 100%;
          cursor: pointer;
        }

        .ra-select {
          background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 12 12'%3E%3Cpath fill='%2394A3B8' d='M6 8L1 3h10z'/%3E%3C/svg%3E");
          background-repeat: no-repeat;
          background-position: right 12px center;
          padding-right: 32px;
        }

        .ra-select:focus, .ra-date-input:focus {
          border-color: #2563EB;
          box-shadow: 0 0 0 3px rgba(37,99,235,0.08);
        }

        .ra-form-bottom {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 16px 22px 20px;
        }

        .ra-asset-type-label {
          font-size: 13px;
          font-weight: 600;
          color: #374151;
          margin-bottom: 10px;
        }

        .ra-checkbox-group {
          display: flex;
          gap: 20px;
        }

        .ra-checkbox-item {
          display: flex;
          align-items: center;
          gap: 8px;
          cursor: pointer;
          font-size: 13.5px;
          color: #374151;
          font-weight: 500;
          user-select: none;
        }

        .ra-checkbox {
          width: 18px; height: 18px;
          border-radius: 5px;
          border: 2px solid #2563EB;
          background: #2563EB;
          display: flex; align-items: center; justify-content: center;
          font-size: 11px;
          color: white;
          flex-shrink: 0;
          transition: all 0.15s;
          cursor: pointer;
        }

        .ra-checkbox.unchecked {
          background: white;
          border-color: #CBD5E1;
        }

        .ra-generate-btn {
          background: #2563EB;
          color: white;
          border: none;
          border-radius: 10px;
          padding: 12px 26px;
          font-size: 14px;
          font-weight: 700;
          cursor: pointer;
          font-family: 'DM Sans', sans-serif;
          display: flex;
          align-items: center;
          gap: 8px;
          transition: all 0.15s;
          box-shadow: 0 4px 14px rgba(37,99,235,0.25);
        }

        .ra-generate-btn:hover { background: #1D4ED8; transform: translateY(-1px); }
        .ra-generate-btn:active { transform: translateY(0); }

        .ra-generate-btn.success {
          background: #10B981;
          box-shadow: 0 4px 14px rgba(16,185,129,0.25);
        }

        /* ── CHARTS ROW ── */
        .ra-charts-row {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 16px;
        }

        .ra-chart-panel {
          background: white;
          border: 1px solid #E2E8F0;
          border-radius: 14px;
          padding: 22px;
        }

        .ra-chart-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          margin-bottom: 20px;
        }

        .ra-chart-title {
          font-size: 15px;
          font-weight: 700;
          color: #0F172A;
        }

        .ra-chart-badge {
          font-size: 10.5px;
          font-weight: 700;
          color: #94A3B8;
          background: #F1F5F9;
          padding: 3px 10px;
          border-radius: 20px;
          letter-spacing: 0.04em;
        }

        /* ── BAR CHART ── */
        .ra-bar-chart {
          display: flex;
          align-items: flex-end;
          gap: 10px;
          height: 200px;
          padding-bottom: 28px;
          position: relative;
        }

        .ra-bar-col {
          flex: 1;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: flex-end;
          gap: 6px;
          height: 100%;
        }

        .ra-bar {
          width: 100%;
          border-radius: 6px 6px 0 0;
          transition: all 0.3s ease;
          cursor: pointer;
          position: relative;
        }

        .ra-bar:hover { filter: brightness(1.08); }

        .ra-bar-tooltip {
          display: none;
          position: absolute;
          top: -28px;
          left: 50%;
          transform: translateX(-50%);
          background: #0F172A;
          color: white;
          font-size: 11px;
          font-weight: 700;
          padding: 3px 7px;
          border-radius: 5px;
          white-space: nowrap;
        }

        .ra-bar:hover .ra-bar-tooltip { display: block; }

        .ra-bar-label {
          font-size: 10.5px;
          font-weight: 600;
          color: #94A3B8;
          text-transform: uppercase;
          letter-spacing: 0.04em;
        }

        /* ── DONUT CHART ── */
        .ra-donut-wrap {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 16px;
        }

        .ra-donut-svg {
          filter: drop-shadow(0 4px 12px rgba(37,99,235,0.15));
        }

        .ra-donut-legend {
          display: flex;
          gap: 20px;
        }

        .ra-legend-item {
          display: flex;
          align-items: center;
          gap: 7px;
          font-size: 13px;
          font-weight: 600;
          color: #374151;
        }

        .ra-legend-dot {
          width: 10px; height: 10px;
          border-radius: 50%;
        }

        .ra-info-btn {
          width: 28px; height: 28px;
          border-radius: 50%;
          background: #F1F5F9;
          border: none;
          display: flex; align-items: center; justify-content: center;
          font-size: 13px;
          cursor: pointer;
          color: #94A3B8;
        }

        /* ── RECENT REPORTS ── */
        .ra-reports-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 18px 22px;
          border-bottom: 1px solid #F1F5F9;
        }

        .ra-reports-title {
          font-size: 15px;
          font-weight: 700;
          color: #0F172A;
        }

        .ra-search-wrap {
          position: relative;
        }

        .ra-search-icon-pos {
          position: absolute;
          left: 10px;
          top: 50%;
          transform: translateY(-50%);
          font-size: 12px;
          color: #94A3B8;
        }

        .ra-search-input {
          background: #F8FAFC;
          border: 1.5px solid #E2E8F0;
          border-radius: 8px;
          padding: 7px 12px 7px 30px;
          font-family: 'DM Sans', sans-serif;
          font-size: 12.5px;
          color: #0F172A;
          outline: none;
          width: 200px;
          transition: border-color 0.15s;
        }

        .ra-search-input:focus { border-color: #2563EB; background: white; }
        .ra-search-input::placeholder { color: #94A3B8; }

        .ra-table { width: 100%; border-collapse: collapse; }

        .ra-table th {
          text-align: left;
          padding: 10px 22px;
          font-size: 10.5px;
          color: #94A3B8;
          text-transform: uppercase;
          letter-spacing: 0.07em;
          font-weight: 700;
          background: #FAFBFC;
          border-bottom: 1px solid #F1F5F9;
        }

        .ra-table tbody tr {
          transition: background 0.12s;
          cursor: pointer;
        }

        .ra-table tbody tr:hover { background: #F8FAFC; }

        .ra-table td {
          padding: 14px 22px;
          font-size: 13px;
          color: #374151;
          border-bottom: 1px solid #F8FAFC;
          vertical-align: middle;
        }

        .ra-table tbody tr:last-child td { border-bottom: none; }

        .ra-report-name { font-weight: 600; color: #0F172A; }

        .ra-type-chip {
          display: inline-block;
          padding: 2px 9px;
          border-radius: 5px;
          font-size: 11px;
          font-weight: 700;
          background: #F1F5F9;
          color: #374151;
        }

        .ra-format-chip {
          display: inline-block;
          padding: 2px 9px;
          border-radius: 5px;
          font-size: 11px;
          font-weight: 700;
          background: #EFF6FF;
          color: #2563EB;
          font-family: 'Space Mono', monospace;
        }

        .ra-status-chip {
          display: inline-flex;
          align-items: center;
          gap: 5px;
          padding: 3px 10px;
          border-radius: 20px;
          font-size: 11.5px;
          font-weight: 600;
        }

        .ra-status-dot {
          width: 6px; height: 6px;
          border-radius: 50%;
        }

        .ra-action-row {
          display: flex;
          gap: 6px;
        }

        .ra-action-btn {
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
        }

        .ra-action-btn:hover { border-color: #2563EB; color: #2563EB; }

        @media (max-width: 1100px) {
          .ra-charts-row { grid-template-columns: 1fr; }
          .ra-form-grid { grid-template-columns: 1fr 1fr; }
        }
        @media (max-width: 768px) {
          .ra-sidebar { display: none; }
          .ra-main { margin-left: 0; }
          .ra-topbar { left: 0; }
        }
      `}</style>

      <div className="ra-app">

        {/* ── SIDEBAR ── */}
        <aside className="ra-sidebar">
          <div className="ra-logo">
            <div className="ra-logo-icon">📈</div>
            <div className="ra-logo-name">LifeLink</div>
          </div>

          <nav className="ra-nav">
                              {navItems.map(item => (
                                <Link
                                  key={item.key}
                                  to={item.path}
                                  className={`ra-nav-item${location.pathname === item.path ? ' active' : ''}`}
                                >
                                  <span className="ra-nav-icon">{item.icon}</span>
                                  {item.label}
                                </Link>
                              ))}
          </nav>

          <div className="ra-user-card">
            <div className="ra-user-avatar">🏥</div>
            <div>
              <div className="ra-user-name">Medical Staff</div>
              <div className="ra-user-id">Staff #8821</div>
            </div>
          </div>
        </aside>

        {/* ── TOPBAR ── */}
        <header className="ra-topbar">
          <div className="ra-breadcrumb">
            <span>Reports & Analytics</span>
            <span className="ra-breadcrumb-sep">›</span>
            <span className="ra-breadcrumb-active">Generator</span>
          </div>

          <div className="ra-topbar-right">
            <button className="ra-icon-btn">
              🔔
              <span className="ra-notif-dot"></span>
            </button>
            <button className="ra-icon-btn">❓</button>
            <div className="ra-topbar-divider"></div>
            <div className="ra-user-info">
              <div className="ra-tb-name">Sarah Jenkins</div>
              <div className="ra-tb-role">Administrator</div>
            </div>
            <div className="ra-tb-avatar">👩‍⚕️</div>
          </div>
        </header>

        {/* ── MAIN ── */}
        <div className="ra-main">

          {/* PAGE HEADER */}
          <div>
            <div className="ra-page-title">Reports & Analytics</div>
            <div className="ra-page-sub">Generate medical asset summaries and operational efficiency logs.</div>
          </div>

          {/* ── REPORT GENERATION FORM ── */}
          <div className="ra-panel">
            <div className="ra-panel-label">
              ≡ Report Generation
            </div>

            <div className="ra-form-grid">
              <div className="ra-form-group">
                <label className="ra-label">Report Type</label>
                <select
                  className="ra-select"
                  value={reportType}
                  onChange={e => setReportType(e.target.value)}
                >
                  <option>Inventory Summary</option>
                  <option>Dispatch Log</option>
                  <option>Donor Statistics</option>
                  <option>Emergency Alerts</option>
                  <option>Organ Viability Report</option>
                </select>
              </div>

              <div className="ra-form-group">
                <label className="ra-label">Start Date</label>
                <input
                  type="date"
                  className="ra-date-input"
                  value={startDate}
                  onChange={e => setStartDate(e.target.value)}
                />
              </div>

              <div className="ra-form-group">
                <label className="ra-label">End Date</label>
                <input
                  type="date"
                  className="ra-date-input"
                  value={endDate}
                  onChange={e => setEndDate(e.target.value)}
                />
              </div>

              <div className="ra-form-group">
                <label className="ra-label">Status</label>
                <select
                  className="ra-select"
                  value={status}
                  onChange={e => setStatus(e.target.value)}
                >
                  <option>Completed</option>
                  <option>Processing</option>
                  <option>Failed</option>
                  <option>All</option>
                </select>
              </div>
            </div>

            <div className="ra-form-bottom">
              <div>
                <div className="ra-asset-type-label">Asset Type</div>
                <div className="ra-checkbox-group">
                  <label className="ra-checkbox-item" onClick={() => setBloodProducts(v => !v)}>
                    <div className={`ra-checkbox${bloodProducts ? '' : ' unchecked'}`}>
                      {bloodProducts && '✓'}
                    </div>
                    Blood Products
                  </label>
                  <label className="ra-checkbox-item" onClick={() => setOrganAssets(v => !v)}>
                    <div className={`ra-checkbox${organAssets ? '' : ' unchecked'}`}>
                      {organAssets && '✓'}
                    </div>
                    Organ Assets
                  </label>
                </div>
              </div>

              <button
                className={`ra-generate-btn${generated ? ' success' : ''}`}
                onClick={() => { setGenerated(true); setTimeout(() => setGenerated(false), 2500); }}
              >
                {generated ? '✓ Report Generated!' : '📊 Generate Report'}
              </button>
            </div>
          </div>

          {/* ── CHARTS ROW ── */}
          <div className="ra-charts-row">

            {/* Bar Chart */}
            <div className="ra-chart-panel">
              <div className="ra-chart-header">
                <div className="ra-chart-title">Donation Trends</div>
                <div className="ra-chart-badge">LAST 6 MONTHS</div>
              </div>
              <div className="ra-bar-chart">
                {donationTrends.map((d, i) => (
                  <div className="ra-bar-col" key={i}>
                    <div
                      className="ra-bar"
                      style={{
                        height: `${(d.value / maxVal) * 100}%`,
                        background: d.highlight ? '#1D4ED8' : '#93C5FD',
                        minHeight: 8,
                      }}
                    >
                      <div className="ra-bar-tooltip">{d.value}</div>
                    </div>
                    <div className="ra-bar-label">{d.month}</div>
                  </div>
                ))}
              </div>
            </div>

            {/* Donut Chart */}
            <div className="ra-chart-panel">
              <div className="ra-chart-header">
                <div className="ra-chart-title">Asset Distribution</div>
                <button className="ra-info-btn">ℹ</button>
              </div>
              <div className="ra-donut-wrap">
                <svg width="220" height="220" className="ra-donut-svg">
                  {/* Background circle */}
                  <circle
                    cx={cx} cy={cy} r={r}
                    fill="none"
                    stroke="#E2E8F0"
                    strokeWidth="28"
                  />
                  {/* Blood segment (70%) */}
                  <circle
                    cx={cx} cy={cy} r={r}
                    fill="none"
                    stroke="#2563EB"
                    strokeWidth="28"
                    strokeDasharray={`${bloodDash} ${circ - bloodDash}`}
                    strokeDashoffset={circ * 0.25}
                    strokeLinecap="round"
                    style={{ transition: 'stroke-dasharray 0.6s ease' }}
                  />
                  {/* Organs segment (30%) */}
                  <circle
                    cx={cx} cy={cy} r={r}
                    fill="none"
                    stroke="#CBD5E1"
                    strokeWidth="28"
                    strokeDasharray={`${organDash} ${circ - organDash}`}
                    strokeDashoffset={circ * 0.25 - bloodDash}
                    strokeLinecap="round"
                  />
                  {/* Center text */}
                  <text x={cx} y={cy - 8} textAnchor="middle" fill="#0F172A" fontSize="22" fontWeight="800" fontFamily="Space Mono, monospace">
                    70/30
                  </text>
                  <text x={cx} y={cy + 12} textAnchor="middle" fill="#94A3B8" fontSize="11" fontWeight="600" fontFamily="DM Sans, sans-serif" letterSpacing="0.05em">
                    RATIO %
                  </text>
                </svg>
                <div className="ra-donut-legend">
                  <div className="ra-legend-item">
                    <div className="ra-legend-dot" style={{ background: '#2563EB' }}></div>
                    Blood
                  </div>
                  <div className="ra-legend-item">
                    <div className="ra-legend-dot" style={{ background: '#CBD5E1' }}></div>
                    Organs
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* ── RECENTLY GENERATED REPORTS ── */}
          <div className="ra-panel">
            <div className="ra-reports-header">
              <div className="ra-reports-title">Recently Generated Reports</div>
              <div className="ra-search-wrap">
                <span className="ra-search-icon-pos">🔍</span>
                <input
                  type="text"
                  className="ra-search-input"
                  placeholder="Search history..."
                  value={searchHistory}
                  onChange={e => setSearchHistory(e.target.value)}
                />
              </div>
            </div>

            <table className="ra-table">
              <thead>
                <tr>
                  <th>Report Name</th>
                  <th>Type</th>
                  <th>Generated Date</th>
                  <th>Format</th>
                  <th>Status</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((r, i) => (
                  <tr key={i}>
                    <td><span className="ra-report-name">{r.name}</span></td>
                    <td><span className="ra-type-chip">{r.type}</span></td>
                    <td>{r.date}</td>
                    <td><span className="ra-format-chip">{r.format}</span></td>
                    <td>
                      <span
                        className="ra-status-chip"
                        style={{ background: r.statusBg, color: r.statusColor }}
                      >
                        <span className="ra-status-dot" style={{ background: r.statusColor }}></span>
                        {r.status}
                      </span>
                    </td>
                    <td>
                      <div className="ra-action-row">
                        <button className="ra-action-btn">⬇ Download</button>
                        <button className="ra-action-btn">👁 View</button>
                      </div>
                    </td>
                  </tr>
                ))}
                {filtered.length === 0 && (
                  <tr>
                    <td colSpan={6} style={{ textAlign: 'center', color: '#94A3B8', padding: '28px' }}>
                      No reports found
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

        </div>
      </div>
    </>
  );
};

export default ReportsAnalytics;