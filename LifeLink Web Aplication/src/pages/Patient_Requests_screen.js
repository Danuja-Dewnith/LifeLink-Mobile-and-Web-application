import React, { useState, useEffect, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';

const PatientRequestsScreen = () => {
  const navigate = useNavigate();

  const [activeFilterTab, setActiveFilterTab] = useState(0); // 0=All,1=Active,2=Emergency,3=Completed
  const [selectedBloodType, setSelectedBloodType] = useState('All');
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [activeSection, setActiveSection] = useState("requests");

  const filterTabs = ['All Requests', 'Active', 'Emergency', 'Completed'];
  const bloodTypes = ['All', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  const API_BASE = 'http://localhost:8083/api';

  // ── Auth headers ──────────────────────────────────────────────────────────
  const getAuthHeaders = useCallback(() => ({
    Authorization: `Bearer ${localStorage.getItem("jwt_token")}`,
    "Content-Type": "application/json",
    "Hospital-Id": localStorage.getItem("hospitalId"),
  }), []);

  // ── Fetch Requests ─────────────────────────────────────────────────────────────────
  const fetchRequests = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const token = localStorage.getItem('jwt_token');
      const hospitalId = localStorage.getItem('hospitalId');

      if (!token || !hospitalId) {
        setError('Please login again. Authentication missing.');
        setLoading(false);
        return;
      }

      const params = new URLSearchParams();
      if (activeFilterTab === 1) params.append('status', 'active');
      if (activeFilterTab === 3) params.append('status', 'completed');
      if (activeFilterTab === 2) params.append('urgency', 'Urgent');
      if (selectedBloodType !== 'All') params.append('bloodType', selectedBloodType);

      const url = `${API_BASE}/hospitals/patient-requests${params.toString() ? '?' + params.toString() : ''}`;

      const res = await fetch(url, {
        headers: getAuthHeaders()
      });

      if (res.status === 401) {
        setError('Session expired. Please login again.');
        setLoading(false);
        return;
      }

      const data = await res.json();

      if (data.success) {
        setRequests(data.requests || []);
      } else {
        setError(data.message || 'Failed to load requests');
      }
    } catch (err) {
      console.error('Fetch error:', err);
      setError('Cannot connect to server. Make sure backend is running on port 8083.');
    } finally {
      setLoading(false);
    }
  }, [activeFilterTab, selectedBloodType, getAuthHeaders]);

  useEffect(() => { fetchRequests(); }, [fetchRequests]);

  // ── Actions ───────────────────────────────────────────────────────────────
  const handleComplete = async (requestId, e) => {
    e.stopPropagation();
    try {
      const res = await fetch(`${API_BASE}/hospitals/requests/${requestId}/complete`, {
        method: 'POST',
        headers: getAuthHeaders()
      });
      if (res.ok) { 
        alert('Request marked as completed'); 
        fetchRequests(); 
      } else { 
        const d = await res.json(); 
        alert(d.message || 'Failed'); 
      }
    } catch (err) { 
      alert(`Error: ${err.message}`); 
    }
  };

  const handleCancel = async (requestId, e) => {
    e.stopPropagation();
    if (!window.confirm('Cancel this request?')) return;
    try {
      const res = await fetch(`${API_BASE}/hospitals/requests/${requestId}/cancel`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify({ reason: 'Cancelled by hospital' })
      });
      if (res.ok) { 
        alert('Request cancelled'); 
        fetchRequests(); 
      } else { 
        const d = await res.json(); 
        alert(d.message || 'Failed'); 
      }
    } catch (err) { 
      alert(`Error: ${err.message}`); 
    }
  };

  const handleLogout = useCallback(() => {
    [
      "jwt_token",
      "userType",
      "hospitalId",
      "name",
      "email",
      "regNumber",
      "contact",
      "storageCapacity",
      "isVerified",
    ].forEach((k) => localStorage.removeItem(k));
    navigate("/login");
  }, [navigate]);

  const getStatusStyle = (status) => {
    switch(status) {
      case 'Matched':
        return { color: "#15803D", bg: "#F0FDF4", icon: "✅" };
      case 'Active':
        return { color: "#1976D2", bg: "#E3F2FD", icon: "🔄" };
      case 'Pending':
        return { color: "#FB8C00", bg: "#FFF8F0", icon: "⏳" };
      case 'Completed':
        return { color: "#43A047", bg: "#F1F8F1", icon: "✔️" };
      default:
        return { color: "#6B7280", bg: "#F3F4F6", icon: "📋" };
    }
  };

  // ── Render ────────────────────────────────────────────────────────────────
  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap');
        * { margin:0; padding:0; box-sizing:border-box; }
        .ll-app { display:flex; min-height:100vh; background:#F1F5F9; font-family:'DM Sans',-apple-system,sans-serif; }
        
        /* Sidebar */
        .ll-sidebar { width:230px; background:white; border-right:1px solid #E2E8F0; display:flex; flex-direction:column; position:fixed; top:0; left:0; height:100vh; z-index:100; }
        .ll-logo { padding:20px 20px 18px; border-bottom:1px solid #E2E8F0; display:flex; align-items:center; gap:10px; }
        .ll-logo-icon { width:38px; height:38px; background:#2563EB; border-radius:10px; display:flex; align-items:center; justify-content:center; font-size:18px; }
        .ll-logo-name { font-size:14px; font-weight:700; color:#0F172A; line-height:1.2; }
        .ll-logo-sub  { font-size:11px; color:#94A3B8; }
        .ll-nav { padding:14px 10px; flex:1; display:flex; flex-direction:column; gap:2px; }
        .ll-nav-item { display:flex; align-items:center; gap:10px; padding:10px 12px; border-radius:8px; font-size:13.5px; font-weight:500; color:#64748B; cursor:pointer; transition:all 0.15s; border:none; background:none; width:100%; text-align:left; font-family:'DM Sans',sans-serif; text-decoration:none; }
        .ll-nav-item:hover  { background:#F8FAFC; color:#0F172A; }
        .ll-nav-item.active { background:#EFF6FF; color:#2563EB; font-weight:600; }
        .ll-nav-icon { font-size:16px; width:20px; text-align:center; }
        .ll-sys-health { padding:14px 20px; border-top:1px solid #E2E8F0; font-size:11px; color:#94A3B8; text-transform:uppercase; letter-spacing:0.06em; font-weight:600; display:flex; align-items:center; gap:6px; }
        .ll-pulse-dot { width:7px; height:7px; background:#10B981; border-radius:50%; animation:llPulse 2s infinite; }
        @keyframes llPulse { 0%,100%{opacity:1} 50%{opacity:0.3} }
        
        /* Main */
        .ll-main { margin-left:230px; flex:1; display:flex; flex-direction:column; min-height:100vh; }
        .ll-topbar { background:white; border-bottom:1px solid #E2E8F0; padding:0 28px; height:64px; display:flex; align-items:center; justify-content:space-between; position:sticky; top:0; z-index:50; }
        .ll-topbar-left h1 { font-size:16px; font-weight:700; color:#0F172A; }
        .ll-topbar-left p  { font-size:12px; color:#94A3B8; margin-top:2px; }
        .ll-topbar-right   { display:flex; align-items:center; gap:10px; }
        .ll-btn { padding:7px 16px; border-radius:8px; font-size:13px; font-weight:600; cursor:pointer; border:none; transition:all 0.15s; font-family:'DM Sans',sans-serif; }
        .ll-btn-outline { background:white; color:#374151; border:1px solid #D1D5DB; }
        .ll-btn-outline:hover { background:#F9FAFB; }
        .ll-btn-primary { background:#2563EB; color:white; }
        .ll-btn-primary:hover { background:#1D4ED8; }
        .ll-avatar { width:36px; height:36px; background:#F1F5F9; border:1px solid #E2E8F0; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:14px; cursor:pointer; }
        .ll-content { padding:24px 28px; display:flex; flex-direction:column; gap:20px; }
        
        /* Stats Cards */
        .stats-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 16px;
        }
        .stat-card {
          background: white;
          border-radius: 16px;
          padding: 20px;
          text-align: center;
          border: 1px solid #E2E8F0;
          transition: all 0.2s ease;
        }
        .stat-card:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .stat-value {
          font-size: 32px;
          font-weight: 800;
          color: #2563EB;
        }
        .stat-label {
          font-size: 13px;
          color: #6B7280;
          margin-top: 8px;
          font-weight: 500;
        }
        
        /* Tab Bar */
        .tab-bar {
          background: white;
          border-radius: 16px;
          padding: 8px;
          border: 1px solid #E2E8F0;
          display: inline-flex;
          gap: 8px;
          margin-bottom: 20px;
        }
        .tab {
          padding: 10px 24px;
          border-radius: 12px;
          font-size: 14px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s;
          background: transparent;
          color: #64748B;
        }
        .tab:hover {
          background: #F8FAFC;
          color: #0F172A;
        }
        .tab.active {
          background: #2563EB;
          color: white;
        }
        
        /* Filter Row */
        .filter-row {
          background: white;
          border-radius: 16px;
          padding: 20px;
          border: 1px solid #E2E8F0;
          display: flex;
          align-items: center;
          gap: 16px;
          flex-wrap: wrap;
        }
        .filter-label {
          font-size: 13px;
          font-weight: 600;
          color: #374151;
        }
        .blood-chips {
          display: flex;
          gap: 8px;
          flex-wrap: wrap;
        }
        .blood-chip {
          padding: 6px 16px;
          border-radius: 20px;
          font-size: 13px;
          font-weight: 600;
          cursor: pointer;
          border: 1.5px solid #E2E8F0;
          background: white;
          color: #374151;
          transition: all 0.2s;
        }
        .blood-chip.active {
          background: #2563EB;
          color: white;
          border-color: #2563EB;
        }
        .blood-chip:hover:not(.active) {
          border-color: #2563EB;
          color: #2563EB;
        }
        
        /* Request Cards */
        .request-card {
          background: white;
          border-radius: 16px;
          padding: 20px;
          border: 1px solid #E2E8F0;
          transition: all 0.2s ease;
          cursor: pointer;
          margin-bottom: 16px;
        }
        .request-card:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .request-header {
          display: flex;
          align-items: center;
          gap: 16px;
          margin-bottom: 16px;
        }
        .avatar {
          width: 56px;
          height: 56px;
          border-radius: 14px;
          object-fit: cover;
          background: #EFF6FF;
        }
        .patient-info {
          flex: 1;
        }
        .patient-name {
          font-size: 16px;
          font-weight: 700;
          color: #0F172A;
          margin-bottom: 4px;
        }
        .hospital-name {
          font-size: 13px;
          color: #6B7280;
          display: flex;
          align-items: center;
          gap: 4px;
        }
        .priority-badge {
          padding: 6px 14px;
          border-radius: 20px;
          font-size: 12px;
          font-weight: 700;
        }
        .request-details {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 16px;
          margin-bottom: 16px;
          padding: 16px 0;
          border-top: 1px solid #F1F5F9;
          border-bottom: 1px solid #F1F5F9;
        }
        .detail-item {
          text-align: center;
        }
        .detail-label {
          font-size: 11px;
          text-transform: uppercase;
          letter-spacing: 0.06em;
          color: #94A3B8;
          font-weight: 600;
          margin-bottom: 4px;
        }
        .detail-value {
          font-size: 16px;
          font-weight: 700;
          color: #0F172A;
        }
        .detail-value.critical {
          color: #E53935;
        }
        .detail-value.urgent {
          color: #FB8C00;
        }
        .request-notes {
          background: #F8FAFC;
          padding: 12px;
          border-radius: 12px;
          font-size: 13px;
          color: #6B7280;
          margin-bottom: 16px;
          border-left: 3px solid #E2E8F0;
        }
        .donor-matched-banner {
          background: #F0FDF4;
          border: 1px solid #BBF7D0;
          border-radius: 12px;
          padding: 10px 12px;
          margin-bottom: 16px;
          font-size: 13px;
          font-weight: 600;
          color: #15803D;
          display: flex;
          align-items: center;
          gap: 8px;
        }
        .request-footer {
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .status-indicator {
          display: flex;
          align-items: center;
          gap: 8px;
        }
        .status-dot {
          width: 8px;
          height: 8px;
          border-radius: 50%;
        }
        .status-text {
          font-size: 13px;
          font-weight: 600;
          color: #374151;
        }
        .time-text {
          font-size: 11px;
          color: #94A3B8;
          margin-top: 2px;
        }
        .action-buttons {
          display: flex;
          gap: 12px;
        }
        .view-btn {
          padding: 8px 20px;
          background: #2563EB;
          color: white;
          border: none;
          border-radius: 8px;
          font-size: 13px;
          font-weight: 600;
          cursor: pointer;
          font-family: 'DM Sans', sans-serif;
          transition: all 0.2s;
        }
        .view-btn:hover {
          background: #1D4ED8;
          transform: translateY(-1px);
        }
        .complete-btn {
          padding: 8px 20px;
          background: #F0FDF4;
          color: #15803D;
          border: 1px solid #BBF7D0;
          border-radius: 8px;
          font-size: 13px;
          font-weight: 600;
          cursor: pointer;
          font-family: 'DM Sans', sans-serif;
          transition: all 0.2s;
        }
        .complete-btn:hover {
          background: #DCFCE7;
          transform: translateY(-1px);
        }
        .cancel-btn {
          padding: 8px 20px;
          background: #FFF5F5;
          color: #E53935;
          border: 1px solid #FFCDD2;
          border-radius: 8px;
          font-size: 13px;
          font-weight: 600;
          cursor: pointer;
          font-family: 'DM Sans', sans-serif;
          transition: all 0.2s;
        }
        .cancel-btn:hover {
          background: #FFEBEE;
          transform: translateY(-1px);
        }
        
        /* FAB Button */
        .fab {
          position: fixed;
          bottom: 30px;
          right: 30px;
          width: 56px;
          height: 56px;
          background: #2563EB;
          color: white;
          border: none;
          border-radius: 50%;
          font-size: 28px;
          cursor: pointer;
          box-shadow: 0 4px 16px rgba(37, 99, 235, 0.4);
          display: flex;
          align-items: center;
          justify-content: center;
          transition: all 0.2s;
          z-index: 40;
        }
        .fab:hover {
          transform: scale(1.08);
          background: #1D4ED8;
        }
        
        /* State Boxes */
        .state-box {
          text-align: center;
          padding: 60px 20px;
          background: white;
          border-radius: 16px;
          border: 1px solid #E2E8F0;
        }
        .state-icon {
          font-size: 48px;
          margin-bottom: 16px;
        }
        .state-text {
          font-size: 16px;
          font-weight: 600;
          color: #374151;
          margin-bottom: 8px;
        }
        .state-sub {
          font-size: 13px;
          color: #94A3B8;
        }
        .retry-btn {
          margin-top: 20px;
          padding: 10px 24px;
          background: #2563EB;
          color: white;
          border: none;
          border-radius: 8px;
          font-size: 14px;
          font-weight: 600;
          cursor: pointer;
          font-family: 'DM Sans', sans-serif;
        }
        .spin {
          width: 40px;
          height: 40px;
          border: 3px solid #E2E8F0;
          border-top-color: #2563EB;
          border-radius: 50%;
          animation: spin 0.8s linear infinite;
          margin: 0 auto 16px;
        }
        @keyframes spin {
          to { transform: rotate(360deg); }
        }
        
        @media (max-width:768px) {
          .ll-sidebar { display: none; }
          .ll-main { margin-left: 0; }
          .stats-grid { grid-template-columns: repeat(2, 1fr); }
          .request-details { grid-template-columns: repeat(2, 1fr); }
          .filter-row { flex-direction: column; align-items: flex-start; }
        }
      `}</style>

      <div className="ll-app">
        {/* Sidebar */}
        <aside className="ll-sidebar">
          <div className="ll-logo">
            <div className="ll-logo-icon">🏥</div>
            <div>
              <div className="ll-logo-name">LifeLink</div>
              <div className="ll-logo-sub">Hospital Portal</div>
            </div>
          </div>
          <nav className="ll-nav">
            <Link to="/bloodbank/dashboard" className="ll-nav-item">
              <span className="ll-nav-icon">⊞</span> Dashboard
            </Link>
            <Link to="bloodbank/dashboard" className="ll-nav-item">
              <span className="ll-nav-icon">🩸</span> Blood Inventory
            </Link>
            <Link to="/bloodbank/requests" className="ll-nav-item active">
              <span className="ll-nav-icon">📋</span> Requests
            </Link>
            
            <Link to="/bloodbank/dashboard" className="ll-nav-item">
              <span className="ll-nav-icon">🔔</span> Alerts  
            </Link>
            <Link to="/bloodbank/profile" className="ll-nav-item">
              <span className="ll-nav-icon">👤</span> Profile
            </Link>
          </nav>
          <div className="ll-sys-health">
            <div className="ll-pulse-dot" />
            System Health · Cloud Synced
          </div>
        </aside>

        {/* Main Content */}
        <div className="ll-main">
          <header className="ll-topbar">
            <div className="ll-topbar-left">
              <h1>Patient Requests</h1>
              <p>Manage and track all blood donation requests</p>
            </div>
            <div className="ll-topbar-right">
              <button className="ll-btn ll-btn-outline" onClick={handleLogout}>
                Logout
              </button>
              <Link to="/bloodbank/profile" className="ll-btn ll-btn-primary">
                Profile
              </Link>
              <div className="ll-avatar" onClick={() => navigate('/bloodbank/profile')}>
                👤
              </div>
            </div>
          </header>

          <div className="ll-content">
            {/* Stats Cards */}
            {!loading && !error && (
              <div className="stats-grid">
                {[
                  { label: 'Total Requests', count: requests.length, color: '#2563EB', icon: '📋' },
                  { label: 'Active', count: requests.filter(r => ['Active', 'Pending'].includes(r.rawStatus)).length, color: '#FB8C00', icon: '🔄' },
                  { label: 'Matched', count: requests.filter(r => r.rawStatus === 'Matched').length, color: '#15803D', icon: '✅' },
                  { label: 'Critical', count: requests.filter(r => r.urgency === 'Critical' || r.urgency === 'Urgent').length, color: '#E53935', icon: '🚨' },
                ].map(({ label, count, color, icon }) => (
                  <div key={label} className="stat-card">
                    <div className="stat-value" style={{ color }}>{count}</div>
                    <div className="stat-label">{icon} {label}</div>
                  </div>
                ))}
              </div>
            )}

            {/* Tabs */}
            <div className="tab-bar">
              {filterTabs.map((tab, i) => (
                <div
                  key={i}
                  className={`tab${activeFilterTab === i ? ' active' : ''}`}
                  onClick={() => setActiveFilterTab(i)}
                >
                  {tab}
                </div>
              ))}
            </div>

            {/* Blood Type Filter */}
            <div className="filter-row">
              <span className="filter-label">🩸 Blood Type Filter:</span>
              <div className="blood-chips">
                {bloodTypes.map(type => (
                  <div
                    key={type}
                    className={`blood-chip${selectedBloodType === type ? ' active' : ''}`}
                    onClick={() => setSelectedBloodType(type)}
                  >
                    {type}
                  </div>
                ))}
              </div>
            </div>

            {/* Requests List */}
            {loading && (
              <div className="state-box">
                <div className="spin" />
                <div className="state-text">Loading patient requests...</div>
                <div className="state-sub">Please wait while we fetch the data</div>
              </div>
            )}

            {!loading && error && (
              <div className="state-box">
                <div className="state-icon">⚠️</div>
                <div className="state-text">Something went wrong</div>
                <div className="state-sub">{error}</div>
                <button className="retry-btn" onClick={fetchRequests}>Try Again</button>
              </div>
            )}

            {!loading && !error && requests.length === 0 && (
              <div className="state-box">
                <div className="state-icon">📋</div>
                <div className="state-text">No requests found</div>
                <div className="state-sub">
                  {activeFilterTab === 0 ? 'No patient requests for your hospital yet.' :
                   activeFilterTab === 1 ? 'No active requests at the moment.' :
                   activeFilterTab === 2 ? 'No emergency requests right now.' :
                   'No completed requests yet.'}
                </div>
              </div>
            )}

            {!loading && !error && requests.map(request => {
              const statusStyle = getStatusStyle(request.rawStatus);
              const urgencyColor = request.urgency === 'Critical' ? '#E53935' : request.urgency === 'Urgent' ? '#FB8C00' : '#43A047';
              
              return (
                <div
                  key={request.id}
                  className="request-card"
                  onClick={() => navigate(`/hospital/request/${request.id}`)}
                >
                  <div className="request-header">
                    <img
                      src={request.avatarUrl}
                      alt={request.name}
                      className="avatar"
                      onError={e => {
                        e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(request.name)}&background=EFF6FF&color=2563EB&size=80`;
                      }}
                    />
                    <div className="patient-info">
                      <div className="patient-name">{request.name}</div>
                      <div className="hospital-name">
                        <span>🏥</span> {request.hospital}
                      </div>
                    </div>
                    <div
                      className="priority-badge"
                      style={{
                        background: urgencyColor + '20',
                        color: urgencyColor,
                        border: `1px solid ${urgencyColor}40`
                      }}
                    >
                      {request.priority === 'CRITICAL' ? '🚨' : '⚠️'} {request.priority}
                    </div>
                  </div>

                  <div className="request-details">
                    <div className="detail-item">
                      <div className="detail-label">Required</div>
                      <div className="detail-value critical">{request.required}</div>
                    </div>
                    <div className="detail-item">
                      <div className="detail-label">Units</div>
                      <div className="detail-value">{request.units}</div>
                    </div>
                    <div className="detail-item">
                      <div className="detail-label">Urgency</div>
                      <div className={`detail-value ${request.urgency === 'Critical' ? 'critical' : request.urgency === 'Urgent' ? 'urgent' : ''}`}>
                        {request.urgency}
                      </div>
                    </div>
                    <div className="detail-item">
                      <div className="detail-label">Status</div>
                      <div className="detail-value" style={{ color: statusStyle.color }}>
                        {statusStyle.icon} {request.status}
                      </div>
                    </div>
                  </div>

                  {request.donorFound && (
                    <div className="donor-matched-banner">
                      ✅ Donor has been matched for this request
                    </div>
                  )}

                  {request.notes && (
                    <div className="request-notes">
                      📝 {request.notes}
                    </div>
                  )}

                  <div className="request-footer">
                    <div>
                      <div className="status-indicator">
                        <div className="status-dot" style={{ background: statusStyle.color }} />
                        <div className="status-text">{request.status}</div>
                      </div>
                      <div className="time-text">{request.timeAgo}</div>
                    </div>

                    <div className="action-buttons">
                      {request.rawStatus === 'Matched' && (
                        <button className="complete-btn" onClick={e => handleComplete(request.id, e)}>
                          ✔ Complete
                        </button>
                      )}
                      {(request.rawStatus === 'Active' || request.rawStatus === 'Pending') && (
                        <button className="cancel-btn" onClick={e => handleCancel(request.id, e)}>
                          ✕ Cancel
                        </button>
                      )}
                      <button
                        className="view-btn"
                        onClick={e => {
                          e.stopPropagation();
                          navigate(`/hospital/request/${request.id}`);
                        }}
                      >
                        View Details →
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* FAB Button */}
        <button className="fab" onClick={() => navigate('/bloodbank/requests/new')}>
          +
        </button>
      </div>
    </>
  );
};

export default PatientRequestsScreen;