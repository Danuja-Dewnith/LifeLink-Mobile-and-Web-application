import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import NotificationBell from '../components/NotificationBell';

import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  Legend, 
  ResponsiveContainer 
} from 'recharts';

const AdminDashboard = () => {
  const navigate = useNavigate();
  
  const [adminName, setAdminName] = useState("Director");
  const [stats, setStats] = useState({
    totalDonors: 0,
    totalPatients: 0,
    totalHospitals: 0,
    pendingHospitals: 0
  });

  // New states for Verification Queue
  const [verificationQueue, setVerificationQueue] = useState([]);
  const [isLoadingQueue, setIsLoadingQueue] = useState(true);
  const [isLoadingStats, setIsLoadingStats] = useState(true);
  const [error, setError] = useState('');

  const [monthlyData, setMonthlyData] = useState([]);
const [isLoadingTrends, setIsLoadingTrends] = useState(true);

// Fetch Monthly Donation Trends
useEffect(() => {
  const fetchTrends = async () => {
    try {
      setIsLoadingTrends(true);
      const res = await fetch('http://localhost:8083/api/admin/stats/donations-monthly');
      
      if (!res.ok) throw new Error('Failed to fetch trends');
      
      const data = await res.json();
      setMonthlyData(data);
    } catch (err) {
      console.error("Failed to fetch donation trends:", err);
      setMonthlyData([]); // fallback
    } finally {
      setIsLoadingTrends(false);
    }
  };

  fetchTrends();
}, []);

  // Load admin name from localStorage
  useEffect(() => {
    const storedName = localStorage.getItem("name") || "Director";
    setAdminName(storedName.split(" ")[0] || "Director");
  }, []);

  // Fetch real statistics from backend
  useEffect(() => {
    const fetchStats = async () => {
      try {
        setIsLoadingStats(true);
        setError('');

        const [donorsRes, patientsRes, hospitalsRes, pendingRes] = await Promise.all([
          fetch('http://localhost:8083/api/admin/stats/donors'),
          fetch('http://localhost:8083/api/admin/stats/patients'),
          fetch('http://localhost:8083/api/admin/stats/hospitals'),
          fetch('http://localhost:8083/api/admin/stats/pending-hospitals')
        ]);

        const donorsData = await donorsRes.json();
        const patientsData = await patientsRes.json();
        const hospitalsData = await hospitalsRes.json();
        const pendingData = await pendingRes.json();

        setStats({
          totalDonors: donorsData.count || 12450,
          totalPatients: patientsData.count || 86,
          totalHospitals: hospitalsData.count || 3240,
          pendingHospitals: pendingData.count || 12
        });
      } catch (err) {
        console.error("Failed to fetch stats:", err);
        setError("Could not load real statistics. Showing demo numbers.");
        
        // Fallback demo numbers matching your image
        setStats({
          totalDonors: 12450,
          totalPatients: 86,
          totalHospitals: 3240,
          pendingHospitals: 12
        });
      } finally {
        setIsLoadingStats(false);
      }
    };

    fetchStats();
  }, []);

  // Fetch real pending hospitals for Verification Queue (Latest 4 only)
  useEffect(() => {
    const fetchVerificationQueue = async () => {
      try {
        setIsLoadingQueue(true);
        const res = await fetch('http://localhost:8083/api/admin/hospitals');
        
        if (!res.ok) throw new Error('Failed to fetch hospitals');

        const data = await res.json();

        // Filter pending hospitals, sort by newest first, limit to 4
        const pendingHospitals = data
          .filter(h => !h.isVerified)
          .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
          .slice(0, 4);

        setVerificationQueue(pendingHospitals);
      } catch (err) {
        console.error("Failed to fetch verification queue:", err);
        setVerificationQueue([]); // fallback to empty
      } finally {
        setIsLoadingQueue(false);
      }
    };

    fetchVerificationQueue();
  }, []);

  const handleLogout = () => {
    localStorage.clear();
    navigate('/login');
  };

  // Handle Review button - navigates to Hospital Management page
  const handleReview = (hospital) => {
    navigate('/admin/hospitalmanage');
  };

  const formatDate = (date) => {
    return new Date(date).toLocaleDateString('en-US', { 
      year: 'numeric', month: 'short', day: 'numeric' 
    });
  };

  const getTypeBadge = (hospital) => {
    const name = hospital.name?.toLowerCase() || '';
    if (name.includes('blood') || name.includes('bank')) {
      return { label: 'Blood Bank', className: 'hospital' }; // using hospital style for now
    }
    return { label: 'Hospital', className: 'hospital' };
  };

  // Static system activity (kept as is)
  const systemActivity = [
    {
      icon: '🚨',
      iconBg: '#FEE2E2',
      iconColor: '#EF4444',
      title: 'Emergency Alert',
      description: 'dispatched to Zone A-12. O- Negative blood required.',
      time: '2 minutes ago'
    },
    {
      icon: '🤝',
      iconBg: '#D1FAE5',
      iconColor: '#10B981',
      title: 'Match Found!',
      description: 'Kidney donor identified for Patient ID: #88219.',
      time: '15 minutes ago'
    },
    {
      icon: '🎉',
      iconBg: '#DBEAFE',
      iconColor: '#2196F3',
      title: 'Donation Success:',
      description: 'Heart transplant completed at Central Hospital.',
      time: '1 hour ago'
    },
    {
      icon: '👤',
      iconBg: '#F3F4F6',
      iconColor: '#6B7280',
      title: 'New Donor:',
      description: 'Mark Stevenson registered as a Bone Marrow donor.',
      time: '2 hours ago'
    }
  ];

  return (
    <>
      <style>{`
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        .admin-dashboard {
          display: flex;
          min-height: 100vh;
          background: #F8F9FA;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        }

        /* Sidebar */
        .sidebar {
          width: 240px;
          background: white;
          border-right: 1px solid #E5E7EB;
          padding: 1.5rem 0;
          display: flex;
          flex-direction: column;
        }

        .logo-section {
          padding: 0 1.5rem;
          margin-bottom: 2rem;
          display: flex;
          align-items: center;
          gap: 0.75rem;
        }

        .logo-icon {
          width: 40px;
          height: 40px;
          background: #2196F3;
          border-radius: 10px;
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
          font-size: 1.25rem;
        }

        .logo-text h2 {
          font-size: 1.125rem;
          font-weight: 700;
          color: #1F2937;
          margin: 0;
        }

        .logo-text span {
          font-size: 0.875rem;
          color: #9CA3AF;
          font-weight: 400;
        }

        .menu-section {
          margin-bottom: 2rem;
        }

        .menu-label {
          padding: 0 1.5rem;
          font-size: 0.75rem;
          font-weight: 600;
          color: #9CA3AF;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          margin-bottom: 0.75rem;
        }

        .menu-items {
          display: flex;
          flex-direction: column;
          gap: 0.25rem;
          padding: 0 0.75rem;
        }

        .menu-item {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          padding: 0.75rem;
          color: #6B7280;
          text-decoration: none;
          border-radius: 8px;
          font-weight: 500;
          transition: all 0.2s;
          font-size: 0.9375rem;
        }

        .menu-item:hover {
          background: #F3F4F6;
          color: #1F2937;
        }

        .menu-item.active {
          background: #DBEAFE;
          color: #2563EB;
        }

        .menu-item svg {
          width: 20px;
          height: 20px;
        }

        .user-profile {
          margin-top: auto;
          padding: 1rem 1.5rem;
          border-top: 1px solid #E5E7EB;
          display: flex;
          align-items: center;
          gap: 0.75rem;
        }

        .user-avatar {
          width: 40px;
          height: 40px;
          border-radius: 50%;
          background: linear-gradient(135deg, #10B981 0%, #059669 100%);
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
          font-weight: 600;
        }

        .user-info h4 {
          font-size: 0.875rem;
          font-weight: 600;
          color: #1F2937;
          margin: 0;
        }

        .user-info p {
          font-size: 0.75rem;
          color: #9CA3AF;
          margin: 0;
        }

        .logout-btn {
          margin-left: auto;
          color: #9CA3AF;
          cursor: pointer;
          transition: color 0.2s;
        }

        .logout-btn:hover {
          color: #EF4444;
        }

        /* Main Content */
        .main-content {
          flex: 1;
          overflow-y: auto;
        }

        .top-header {
          background: white;
          border-bottom: 1px solid #E5E7EB;
          padding: 1.25rem 2rem;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .search-bar {
          position: relative;
          flex: 1;
          max-width: 500px;
        }

        .search-icon {
          position: absolute;
          left: 1rem;
          top: 50%;
          transform: translateY(-50%);
          color: #9CA3AF;
        }

        .search-input {
          width: 100%;
          padding: 0.75rem 1rem 0.75rem 2.75rem;
          border: 1px solid #E5E7EB;
          border-radius: 8px;
          font-size: 0.875rem;
          background: #F9FAFB;
        }

        .search-input:focus {
          outline: none;
          border-color: #2196F3;
          background: white;
        }

        .header-actions {
          display: flex;
          align-items: center;
          gap: 1rem;
        }

        .notification-btn {
          position: relative;
          width: 40px;
          height: 40px;
          border-radius: 8px;
          background: white;
          border: 1px solid #E5E7EB;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: all 0.2s;
        }

        .notification-btn:hover {
          background: #F3F4F6;
        }

        .notification-dot {
          position: absolute;
          top: 8px;
          right: 8px;
          width: 8px;
          height: 8px;
          background: #EF4444;
          border-radius: 50%;
          border: 2px solid white;
        }

        .help-btn {
          width: 40px;
          height: 40px;
          border-radius: 50%;
          background: #F3F4F6;
          border: none;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          color: #6B7280;
          transition: all 0.2s;
        }

        .help-btn:hover {
          background: #E5E7EB;
        }

        .content-area {
          padding: 2rem;
        }

        .welcome-section {
          margin-bottom: 2rem;
        }

        .welcome-title {
          font-size: 2rem;
          font-weight: 800;
          color: #1F2937;
          margin-bottom: 0.5rem;
        }

        .welcome-subtitle {
          color: #6B7280;
          font-size: 1rem;
        }

        /* Stats Grid */
        .stats-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 1.5rem;
          margin-bottom: 2rem;
        }

        .stat-card {
          background: white;
          padding: 1.5rem;
          border-radius: 12px;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .stat-label {
          font-size: 0.875rem;
          color: #6B7280;
          margin-bottom: 0.5rem;
        }

        .stat-value {
          font-size: 2.25rem;
          font-weight: 800;
          color: #1F2937;
          margin-bottom: 0.75rem;
        }

        .stat-meta {
          font-size: 0.875rem;
          display: flex;
          align-items: center;
          gap: 0.5rem;
        }

        .stat-meta.green { color: #10B981; }
        .stat-meta.orange { color: #F59E0B; }
        .stat-meta.red { color: #EF4444; }
        .stat-meta.blue { color: #2196F3; }

        /* Content Grid */
        .content-grid {
          display: grid;
          grid-template-columns: 2fr 1fr;
          gap: 1.5rem;
          margin-bottom: 2rem;
        }

        /* Verification Queue */
        .verification-section {
          background: white;
          border-radius: 12px;
          padding: 1.5rem;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .section-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 1.5rem;
        }

        .section-title {
          font-size: 1.25rem;
          font-weight: 700;
          color: #1F2937;
        }

        .section-subtitle {
          font-size: 0.875rem;
          color: #9CA3AF;
        }

        .view-all-link {
          color: #2196F3;
          text-decoration: none;
          font-weight: 600;
          font-size: 0.875rem;
        }

        .verification-table {
          width: 100%;
          border-collapse: collapse;
        }

        .verification-table th {
          text-align: left;
          font-size: 0.75rem;
          font-weight: 600;
          color: #9CA3AF;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          padding-bottom: 1rem;
          border-bottom: 1px solid #E5E7EB;
        }

        .verification-table td {
          padding: 1.25rem 0;
          border-bottom: 1px solid #F3F4F6;
        }

        .name-cell {
          font-weight: 600;
          color: #1F2937;
        }

        .type-badge {
          display: inline-block;
          padding: 0.25rem 0.75rem;
          border-radius: 12px;
          font-size: 0.75rem;
          font-weight: 600;
        }

        .type-badge.hospital {
          background: #DBEAFE;
          color: #2563EB;
        }

        .type-badge.donor {
          background: #DDD6FE;
          color: #7C3AED;
        }

        .status-badge {
          display: inline-flex;
          align-items: center;
          gap: 0.375rem;
          font-size: 0.8125rem;
          font-weight: 500;
        }

        .status-dot {
          width: 8px;
          height: 8px;
          border-radius: 50%;
        }

        .status-badge.pending .status-dot {
          background: #F59E0B;
        }

        .status-badge.under-review .status-dot {
          background: #3B82F6;
        }

        .status-badge.pending {
          color: #D97706;
        }

        .status-badge.under-review {
          color: #2563EB;
        }

        .review-btn {
          padding: 0.5rem 1.25rem;
          background: #2196F3;
          color: white;
          border: none;
          border-radius: 6px;
          font-weight: 600;
          font-size: 0.875rem;
          cursor: pointer;
          transition: all 0.3s;
        }

        .review-btn:hover {
          background: #1976D2;
        }

        /* System Activity */
        .activity-section {
          background: white;
          border-radius: 12px;
          padding: 1.5rem;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .activity-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 1.5rem;
        }

        .rss-icon {
          color: #9CA3AF;
          cursor: pointer;
        }

        .activity-list {
          display: flex;
          flex-direction: column;
          gap: 1.25rem;
        }

        .activity-item {
          display: flex;
          gap: 1rem;
        }

        .activity-icon {
          width: 40px;
          height: 40px;
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 1.25rem;
          flex-shrink: 0;
        }

        .activity-content {
          flex: 1;
        }

        .activity-title {
          font-weight: 600;
          color: #1F2937;
          margin-bottom: 0.25rem;
          font-size: 0.9375rem;
        }

        .activity-description {
          color: #6B7280;
          font-size: 0.875rem;
          line-height: 1.5;
          margin-bottom: 0.25rem;
        }

        .activity-time {
          font-size: 0.8125rem;
          color: #9CA3AF;
        }

        /* Bottom Grid */
        .bottom-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 1.5rem;
        }

        .chart-section {
          background: white;
          border-radius: 12px;
          padding: 1.5rem;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .chart-legend {
          display: flex;
          gap: 1.5rem;
          margin-bottom: 1rem;
          font-size: 0.8125rem;
        }

        .legend-item {
          display: flex;
          align-items: center;
          gap: 0.5rem;
        }

        .legend-dot {
          width: 10px;
          height: 10px;
          border-radius: 50%;
        }

        .legend-dot.blood { background: #2196F3; }
        .legend-dot.organs { background: #E5E7EB; }

        .chart-placeholder {
          height: 200px;
          background: #F9FAFB;
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          color: #9CA3AF;
          font-size: 0.875rem;
        }

        .map-section {
          background: white;
          border-radius: 12px;
          padding: 1.5rem;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
          position: relative;
        }

        .live-badge {
          position: absolute;
          top: 1.5rem;
          right: 1.5rem;
          padding: 0.375rem 0.75rem;
          background: #FEE2E2;
          color: #EF4444;
          border-radius: 12px;
          font-size: 0.75rem;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .map-placeholder {
          height: 200px;
          background: linear-gradient(135deg, #E0F2FE 0%, #F0F9FF 100%);
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          position: relative;
          overflow: hidden;
        }

        .map-marker {
          position: absolute;
          width: 24px;
          height: 24px;
          background: #EF4444;
          border-radius: 50% 50% 50% 0;
          transform: rotate(-45deg);
          box-shadow: 0 4px 12px rgba(239, 68, 68, 0.4);
        }

        .map-marker::before {
          content: '';
          position: absolute;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%) rotate(45deg);
          width: 10px;
          height: 10px;
          background: white;
          border-radius: 50%;
        }

        .map-marker:nth-child(1) { top: 30%; left: 40%; }
        .map-marker:nth-child(2) { top: 50%; left: 60%; }
        .map-marker:nth-child(3) { top: 70%; left: 35%; }
        .map-marker:nth-child(4) { top: 40%; left: 70%; }

        @media (max-width: 1400px) {
          .stats-grid {
            grid-template-columns: repeat(2, 1fr);
          }
        }

        @media (max-width: 1024px) {
          .content-grid,
          .bottom-grid {
            grid-template-columns: 1fr;
          }

          .stats-grid {
            grid-template-columns: 1fr;
          }
        }

        @media (max-width: 768px) {
          .sidebar {
            display: none;
          }

          .content-area {
            padding: 1rem;
          }
        }
      `}</style>

      <div className="admin-dashboard">
        {/* Sidebar - unchanged */}
        <aside className="sidebar">
          <div className="logo-section">
            <div className="logo-icon">📊</div>
            <div className="logo-text">
              <h2>LifeLink <span>Admin</span></h2>
            </div>
          </div>

          <div className="menu-section">
            <div className="menu-label">Main Menu</div>
            <nav className="menu-items">
              <Link to="/admin/dashboard" className="menu-item active">
                <svg fill="currentColor" viewBox="0 0 20 20">
                  <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
                </svg>
                Dashboard
              </Link>

              <Link to="/admin/usermanage" className="menu-item">
                <svg fill="currentColor" viewBox="0 0 20 20">
                  <path d="M9 6a3 3 0 11-6 0 3 3 0 016 0zM17 6a3 3 0 11-6 0 3 3 0 016 0zM12.93 17c.046-.327.07-.66.07-1a6.97 6.97 0 00-1.5-4.33A5 5 0 0119 16v1h-6.07zM6 11a5 5 0 015 5v1H1v-1a5 5 0 015-5z"/>
                </svg>
                User Management
              </Link>

              <Link to="/admin/hospitalmanage" className="menu-item">
                <svg fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M4 4a2 2 0 012-2h8a2 2 0 012 2v12a1 1 0 110 2h-3a1 1 0 01-1-1v-2a1 1 0 00-1-1H9a1 1 0 00-1 1v2a1 1 0 01-1 1H4a1 1 0 110-2V4zm3 1h2v2H7V5zm2 4H7v2h2V9zm2-4h2v2h-2V5zm2 4h-2v2h2V9z" clipRule="evenodd"/>
                </svg>
                Hospital Management
              </Link>

              <Link to="/admin/alerts" className="menu-item">
                <svg fill="currentColor" viewBox="0 0 20 20">
                  <path d="M10 2a6 6 0 00-6 6v3.586l-.707.707A1 1 0 004 14h12a1 1 0 00.707-1.707L16 11.586V8a6 6 0 00-6-6zM10 18a3 3 0 01-3-3h6a3 3 0 01-3 3z"/>
                </svg>
                Emergency Alerts
              </Link>
            </nav>
          </div>

          <div className="menu-section">
            <div className="menu-label">Analytics & Support</div>
            <nav className="menu-items">
              <Link to="/admin/reports" className="menu-item">
                <svg fill="currentColor" viewBox="0 0 20 20">
                  <path d="M2 11a1 1 0 011-1h2a1 1 0 011 1v5a1 1 0 01-1 1H3a1 1 0 01-1-1v-5zM8 7a1 1 0 011-1h2a1 1 0 011 1v9a1 1 0 01-1 1H9a1 1 0 01-1-1V7zM14 4a1 1 0 011-1h2a1 1 0 011 1v12a1 1 0 01-1 1h-2a1 1 0 01-1-1V4z"/>
                </svg>
                Reports
              </Link>
            </nav>
          </div>

          <div className="user-profile">
            <div className="user-avatar">LA</div>
            <div className="user-info">
              <h4>Director {adminName}</h4>
              <p>System Director</p>
            </div>
            <svg onClick={handleLogout} className="logout-btn" width="20" height="20" fill="currentColor" viewBox="0 0 20 20" style={{ cursor: 'pointer' }}>
              <path fillRule="evenodd" d="M3 3a1 1 0 011 1v12a1 1 0 11-2 0V4a1 1 0 011-1zm7.707 3.293a1 1 0 010 1.414L9.414 9H17a1 1 0 110 2H9.414l1.293 1.293a1 1 0 01-1.414 1.414l-3-3a1 1 0 010-1.414l3-3a1 1 0 011.414 0z" clipRule="evenodd"/>
            </svg>
          </div>
        </aside>

        {/* Main Content */}
        <main className="main-content">
          {/* Top Header */}
          <header className="top-header">
            <div className="search-bar">
              <svg className="search-icon" width="16" height="16" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
              </svg>
              <input 
                type="text" 
                className="search-input" 
                placeholder="Search donors, hospitals, or alerts..."
              />
            </div>

            <div className="header-actions">
            <NotificationBell />
            <button className="help-btn">
              <svg width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-8-3a1 1 0 00-.867.5 1 1 0 11-1.731-1A3 3 0 0113 8a3.001 3.001 0 01-2 2.83V11a1 1 0 11-2 0v-1a1 1 0 011-1 1 1 0 100-2zm0 8a1 1 0 100-2 1 1 0 000 2z" clipRule="evenodd"/>
              </svg>
            </button>
          </div>
          </header>

          {/* Content Area */}
          <div className="content-area">
            {/* Welcome Section */}
            <div className="welcome-section">
              <h1 className="welcome-title">Good morning, Director {adminName}</h1>
              <p className="welcome-subtitle">Here's what's happening across the donation network today.</p>
            </div>

            {/* Dynamic Stats Grid */}
            <div className="stats-grid">
              <div className="stat-card">
                <div className="stat-label">Total Registered Donors</div>
                <div className="stat-value">{isLoadingStats ? '...' : stats.totalDonors.toLocaleString()}</div>
                <div className="stat-meta green">📈 +5.2% from last month</div>
              </div>

              <div className="stat-card">
                <div className="stat-label">Pending Patient Requests</div>
                <div className="stat-value">{isLoadingStats ? '...' : stats.totalPatients}</div>
                <div className="stat-meta orange">⚠️ Requires urgent review</div>
              </div>

              <div className="stat-card">
                <div className="stat-label">Registered Hospitals</div>
                <div className="stat-value">{isLoadingStats ? '...' : stats.totalHospitals}</div>
                <div className="stat-meta blue">✅ Active in network</div>
              </div>

              <div className="stat-card">
                <div className="stat-label">New Hospital Requests</div>
                <div className="stat-value">{isLoadingStats ? '...' : stats.pendingHospitals}</div>
                <div className="stat-meta red">📍 Pending verification</div>
              </div>
            </div>

            {/* Content Grid */}
            <div className="content-grid">
              {/* Verification Queue - NOW WITH REAL DATA */}
              <div className="verification-section">
                <div className="section-header">
                  <div>
                    <h3 className="section-title">Verification Queue</h3>
                    <p className="section-subtitle">Awaiting document validation</p>
                  </div>
                  <Link to="/admin/hospitalmanage" className="view-all-link">View all</Link>
                </div>

                {isLoadingQueue ? (
                  <div style={{ padding: '60px', textAlign: 'center', color: '#6B7280' }}>
                    Loading pending verifications...
                  </div>
                ) : verificationQueue.length === 0 ? (
                  <div style={{ padding: '60px', textAlign: 'center', color: '#9CA3AF' }}>
                    No pending verifications at the moment ✓
                  </div>
                ) : (
                  <table className="verification-table">
                    <thead>
                      <tr>
                        <th>NAME</th>
                        <th>TYPE</th>
                        <th>SUBMISSION DATE</th>
                        <th>STATUS</th>
                        <th>ACTION</th>
                      </tr>
                    </thead>
                    <tbody>
                      {verificationQueue.map((hospital) => {
                        const typeInfo = getTypeBadge(hospital);
                        return (
                          <tr key={hospital._id}>
                            <td className="name-cell">{hospital.name}</td>
                            <td>
                              <span className={`type-badge ${typeInfo.className}`}>
                                {typeInfo.label}
                              </span>
                            </td>
                            <td>{formatDate(hospital.createdAt)}</td>
                            <td>
                              <span className="status-badge pending">
                                <span className="status-dot"></span>
                                Pending Review
                              </span>
                            </td>
                            <td>
                              <button 
                                className="review-btn"
                                onClick={() => handleReview(hospital)}
                              >
                                Review
                              </button>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                )}
              </div>

              {/* System Activity - unchanged */}
              <div className="activity-section">
                <div className="activity-header">
                  <h3 className="section-title">System Activity</h3>
                  <svg className="rss-icon" width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M5 3a1 1 0 000 2c5.523 0 10 4.477 10 10a1 1 0 102 0C17 8.373 11.627 3 5 3z"/>
                    <path d="M4 9a1 1 0 011-1 7 7 0 017 7 1 1 0 11-2 0 5 5 0 00-5-5 1 1 0 01-1-1zM3 15a2 2 0 114 0 2 2 0 01-4 0z"/>
                  </svg>
                </div>

                <div className="activity-list">
                  {systemActivity.map((activity, index) => (
                    <div className="activity-item" key={index}>
                      <div 
                        className="activity-icon" 
                        style={{
                          background: activity.iconBg,
                          color: activity.iconColor
                        }}
                      >
                        {activity.icon}
                      </div>
                      <div className="activity-content">
                        <div className="activity-title">{activity.title}</div>
                        <div className="activity-description">{activity.description}</div>
                        <div className="activity-time">{activity.time}</div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Bottom Grid - unchanged */}
            <div className="bottom-grid">
              {/* Monthly Donation Trends */}
              {/* Monthly Donation Trends - REAL CHART */}
{/* Monthly Donation Trends - MULTIPLE TYPES */}
<div className="chart-section">
  <div className="section-header">
    <div>
      <h3 className="section-title">Monthly Donation Trends</h3>
      <p className="section-subtitle">Comparison of donation types</p>
    </div>
  </div>

  <div className="chart-legend" style={{ marginBottom: '1rem', display: 'flex', flexWrap: 'wrap', gap: '1rem' }}>
    <div className="legend-item"><span className="legend-dot" style={{background: '#2196F3'}}></span> Whole Blood</div>
    <div className="legend-item"><span className="legend-dot" style={{background: '#00BCD4'}}></span> Plasma</div>
    <div className="legend-item"><span className="legend-dot" style={{background: '#FF9800'}}></span> Platelets</div>
    <div className="legend-item"><span className="legend-dot" style={{background: '#F44336'}}></span> Red Cells</div>
    <div className="legend-item"><span className="legend-dot" style={{background: '#9E9E9E'}}></span> Others</div>
  </div>

  {isLoadingTrends ? (
    <div className="chart-placeholder" style={{ height: '260px' }}>
      Loading chart...
    </div>
  ) : monthlyData.length === 0 ? (
    <div className="chart-placeholder" style={{ height: '260px', color: '#9CA3AF' }}>
      No donation data available yet
    </div>
  ) : (
    <ResponsiveContainer width="100%" height={260}>
      <BarChart data={monthlyData}>
        <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
        <XAxis dataKey="month" tick={{ fill: '#6B7280', fontSize: 12 }} />
        <YAxis tick={{ fill: '#6B7280', fontSize: 12 }} />
        <Tooltip />
        <Legend />
        
        <Bar dataKey="wholeBlood" fill="#2196F3" name="Whole Blood" radius={[4, 4, 0, 0]} />
        <Bar dataKey="plasma" fill="#00BCD4" name="Plasma" radius={[4, 4, 0, 0]} />
        <Bar dataKey="platelets" fill="#FF9800" name="Platelets" radius={[4, 4, 0, 0]} />
        <Bar dataKey="redCells" fill="#F44336" name="Red Cells" radius={[4, 4, 0, 0]} />
        <Bar dataKey="others" fill="#9E9E9E" name="Others" radius={[4, 4, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  )}
</div>

              {/* Emergency Map */}
              <div className="map-section">
                <span className="live-badge">LIVE</span>
                <div className="section-header" style={{marginBottom: '1rem'}}>
                  <div>
                    <h3 className="section-title">Emergency Map</h3>
                    <p className="section-subtitle">Real-time alert distribution</p>
                  </div>
                </div>
                <div className="map-placeholder">
                  <span className="map-marker"></span>
                  <span className="map-marker"></span>
                  <span className="map-marker"></span>
                  <span className="map-marker"></span>
                </div>
              </div>
            </div>
          </div>
        </main>
      </div>
    </>
  );
};

export default AdminDashboard;