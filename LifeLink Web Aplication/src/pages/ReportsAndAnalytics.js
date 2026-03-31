import React, { useState, useEffect } from 'react';
import AdminSidebar from "../components/AdminSidebar";
import { useNavigate } from 'react-router-dom';

const ReportsAndAnalytics = () => {
  const navigate = useNavigate();

  const [kpis, setKpis] = useState({
    totalDonations: 0,
    avgResponseTime: "0m 0s",
    alertSuccessRate: "0",
    activeDonors: 0,
    donationTrend: "+0",
    responseTrend: "-0",
    successTrend: "+0",
    donorsTrend: "+0"
  });

  const [isLoading, setIsLoading] = useState(true);

  // Fetch real analytics from backend
  const fetchAnalytics = async () => {
    try {
      setIsLoading(true);
      const res = await fetch('http://localhost:8083/api/admin/analytics/summary');
      
      if (res.ok) {
        const data = await res.json();
        setKpis({
          totalDonations: data.totalDonations || 0,
          avgResponseTime: data.avgResponseTime || "0m 0s",
          alertSuccessRate: data.alertSuccessRate || "0",
          activeDonors: data.activeDonors || 0,
          donationTrend: data.donationTrend || "+0",
          responseTrend: data.responseTrend || "-0",
          successTrend: data.successTrend || "+0",
          donorsTrend: data.donorsTrend || "+0"
        });
      }
    } catch (err) {
      console.error("Failed to fetch analytics:", err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchAnalytics();
    const interval = setInterval(fetchAnalytics, 30000); // Auto refresh every 30 seconds
    return () => clearInterval(interval);
  }, []);

  const handleLogout = () => {
    localStorage.clear();
    navigate('/login');
  };

  return (
    <>
      <style>{`
        .reports-page {
          display: flex;
          min-height: 100vh;
          background: #F8F9FA;
          font-family: 'Inter', system-ui, sans-serif;
        }
        .main-content { flex: 1; overflow-y: auto; }
        .content-area { padding: 2rem; }

        .page-header {
          margin-bottom: 2rem;
        }
        .page-title { 
          font-size: 1.8rem; 
          font-weight: 700; 
          color: #1F2937; 
        }
        .page-subtitle { 
          color: #6B7280; 
          font-size: 0.95rem; 
        }

        .kpi-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
          gap: 1.5rem;
          margin-bottom: 2.5rem;
        }
        .kpi-card {
          background: white;
          padding: 1.5rem;
          border-radius: 16px;
          box-shadow: 0 4px 12px rgba(0,0,0,0.06);
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
        }
        .kpi-value {
          font-size: 2rem;
          font-weight: 800;
          color: #1F2937;
          line-height: 1;
        }
        .kpi-label { 
          color: #6B7280; 
          font-size: 0.92rem; 
          margin-top: 6px; 
        }
        .kpi-icon {
          font-size: 1.8rem;
          opacity: 0.9;
        }
        .kpi-delta {
          font-size: 0.82rem;
          font-weight: 600;
          padding: 3px 10px;
          border-radius: 9999px;
          margin-top: 6px;
        }
        .delta-up { background: #D1FAE5; color: #059669; }
        .delta-down { background: #FEE2E2; color: #EF4444; }
      `}</style>

      <div className="reports-page">
        <AdminSidebar 
          user={{ initials: "SJ", name: "Sarah Jenkins", role: "System Director" }}
          onLogout={handleLogout}
        />

        <main className="main-content">
          <div className="content-area">
            <div className="page-header">
              <div>
                <h1 className="page-title">Operational Insights</h1>
                <p className="page-subtitle">
                  Holistic view of regional blood and organ distribution performance.
                </p>
              </div>
            </div>

            {/* KPI Cards */}
            <div className="kpi-grid">
              <div className="kpi-card">
                <div>
                  <div className="kpi-value">{kpis.totalDonations.toLocaleString()}</div>
                  <div className="kpi-label">Total Donations</div>
                </div>
                <div className="kpi-icon">💧</div>
                <div className="kpi-delta delta-up">↗ {kpis.donationTrend}</div>
              </div>

              <div className="kpi-card">
                <div>
                  <div className="kpi-value">{kpis.avgResponseTime}</div>
                  <div className="kpi-label">Avg. Response Time</div>
                </div>
                <div className="kpi-icon">⏱️</div>
                <div className="kpi-delta delta-down">↘ {kpis.responseTrend}</div>
              </div>

              <div className="kpi-card">
                <div>
                  <div className="kpi-value">{kpis.alertSuccessRate}%</div>
                  <div className="kpi-label">Alert Success Rate</div>
                </div>
                <div className="kpi-icon">✅</div>
                <div className="kpi-delta delta-up">↗ {kpis.successTrend}</div>
              </div>

              <div className="kpi-card">
                <div>
                  <div className="kpi-value">{kpis.activeDonors.toLocaleString()}</div>
                  <div className="kpi-label">Active Donors</div>
                </div>
                <div className="kpi-icon">👥</div>
                <div className="kpi-delta delta-up">↗ {kpis.donorsTrend}</div>
              </div>
            </div>

            {/* Chart Placeholders */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.5rem' }}>
              <div style={{
                background: 'white',
                borderRadius: '16px',
                padding: '2rem',
                minHeight: '280px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#9CA3AF',
                border: '1px dashed #E5E7EB'
              }}>
                Monthly Donation Trends (Chart Area - Coming Soon)
              </div>
              <div style={{
                background: 'white',
                borderRadius: '16px',
                padding: '2rem',
                minHeight: '280px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#9CA3AF',
                border: '1px dashed #E5E7EB'
              }}>
                Blood Group Distribution (Donut Chart - Coming Soon)
              </div>
            </div>
          </div>
        </main>
      </div>
    </>
  );
};

export default ReportsAndAnalytics;