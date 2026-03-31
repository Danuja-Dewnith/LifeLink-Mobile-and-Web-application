import React from 'react';
import { Link } from 'react-router-dom';
import DonorNavbar from '../components/DonorNavbar';

const DonorEligibility = () => {
  return (
    <>
      <style>{`
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        .eligibility-layout {
          display: flex;
          flex-direction: column;
          min-height: 100vh;
          background-color: #F8F9FA;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        }

        .eligibility-content-wrapper {
          display: flex;
          flex: 1;
        }

        /* Reuse sidebar styles */
        .sidebar {
          width: 240px;
          background-color: white;
          padding: 2rem 0;
          border-right: 1px solid #E5E7EB;
          height: calc(100vh - 65px);
          overflow-y: auto;
        }

        .user-profile {
          padding: 0 1.5rem;
          margin-bottom: 2rem;
          display: flex;
          align-items: center;
          gap: 1rem;
        }

        .user-avatar {
          width: 48px;
          height: 48px;
          border-radius: 50%;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }

        .user-avatar img {
          width: 100%;
          height: 100%;
          border-radius: 50%;
          object-fit: cover;
        }

        .user-info h3 {
          font-weight: 700;
          font-size: 0.9375rem;
          color: #1F2937;
        }

        .user-status {
          font-size: 0.75rem;
          color: #10B981;
          display: flex;
          align-items: center;
          gap: 0.25rem;
        }

        .sidebar-menu {
          display: flex;
          flex-direction: column;
          gap: 0.25rem;
          padding: 0 1rem;
        }

        .menu-item {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          padding: 0.75rem 1rem;
          color: #6B7280;
          text-decoration: none;
          border-radius: 8px;
          font-weight: 500;
          font-size: 0.9375rem;
          transition: all 0.2s;
        }

        .menu-item:hover {
          background-color: #F3F4F6;
          color: #1F2937;
        }

        .menu-item.active {
          background-color: #DBEAFE;
          color: #2563EB;
        }

        .menu-item svg {
          width: 20px;
          height: 20px;
        }

        .settings-menu {
          position: absolute;
          bottom: 2rem;
          left: 1rem;
          right: 1rem;
        }

        /* Main Content */
        .main-content {
          flex: 1;
        }

        /* Content Area */
        .content-area {
          padding: 2rem;
        }

        .breadcrumb {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          font-size: 0.875rem;
          color: #6B7280;
          margin-bottom: 1rem;
        }

        .breadcrumb a {
          color: #6B7280;
          text-decoration: none;
        }

        .breadcrumb a:hover {
          color: #1F2937;
        }

        .page-title {
          font-size: 2rem;
          font-weight: 800;
          color: #1F2937;
          margin-bottom: 2rem;
        }

        /* Main Grid */
        .eligibility-grid {
          display: grid;
          grid-template-columns: 1fr 400px;
          gap: 2rem;
        }

        /* Status Card */
        .status-card {
          background: white;
          border-radius: 16px;
          padding: 2.5rem;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
          text-align: center;
          margin-bottom: 2rem;
        }

        .status-icon {
          width: 80px;
          height: 80px;
          background: #D1FAE5;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          margin: 0 auto 1.5rem;
        }

        .checkmark {
          width: 40px;
          height: 40px;
          background: #10B981;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
        }

        .status-badge {
          display: inline-block;
          padding: 0.5rem 1rem;
          background: #D1FAE5;
          color: #10B981;
          border-radius: 20px;
          font-size: 0.875rem;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          margin-bottom: 1rem;
        }

        .status-title {
          font-size: 1.75rem;
          font-weight: 800;
          color: #10B981;
          margin-bottom: 0.5rem;
        }

        .last-donation {
          font-size: 0.875rem;
          color: #6B7280;
          margin-bottom: 2rem;
        }

        .status-heading {
          font-size: 1.5rem;
          font-weight: 700;
          color: #1F2937;
          margin-bottom: 1rem;
        }

        .status-description {
          color: #6B7280;
          line-height: 1.6;
          margin-bottom: 2rem;
        }

        .action-buttons {
          display: flex;
          gap: 1rem;
          justify-content: center;
        }

        .btn-primary {
          padding: 0.875rem 2rem;
          background: #2196F3;
          color: white;
          border: none;
          border-radius: 8px;
          font-weight: 600;
          font-size: 0.9375rem;
          cursor: pointer;
          display: flex;
          align-items: center;
          gap: 0.5rem;
          transition: all 0.3s;
        }

        .btn-primary:hover {
          background: #1976D2;
          transform: translateY(-2px);
        }

        .btn-secondary {
          padding: 0.875rem 2rem;
          background: white;
          color: #2196F3;
          border: 2px solid #2196F3;
          border-radius: 8px;
          font-weight: 600;
          font-size: 0.9375rem;
          cursor: pointer;
          transition: all 0.3s;
        }

        .btn-secondary:hover {
          background: #F0F9FF;
        }

        /* Requirements Section */
        .requirements-section {
          background: white;
          border-radius: 16px;
          padding: 2rem;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .section-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 2rem;
        }

        .section-title {
          font-size: 1.25rem;
          font-weight: 700;
          color: #1F2937;
        }

        .updated-badge {
          font-size: 0.75rem;
          color: #9CA3AF;
          background: #F3F4F6;
          padding: 0.25rem 0.75rem;
          border-radius: 12px;
        }

        .requirements-grid {
          display: grid;
          grid-template-columns: repeat(2, 1fr);
          gap: 1.5rem;
        }

        .requirement-card {
          padding: 1.5rem;
          border-radius: 12px;
          background: #F9FAFB;
          display: flex;
          gap: 1rem;
        }

        .req-icon {
          width: 48px;
          height: 48px;
          border-radius: 12px;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
        }

        .req-icon.green { background: #D1FAE5; }
        .req-icon.orange { background: #FED7AA; }

        .req-content h4 {
          font-weight: 700;
          color: #1F2937;
          margin-bottom: 0.5rem;
          display: flex;
          align-items: center;
          gap: 0.5rem;
        }

        .check-icon {
          color: #10B981;
        }

        .warning-icon {
          color: #F59E0B;
        }

        .req-content p {
          font-size: 0.875rem;
          color: #6B7280;
          line-height: 1.5;
        }

        .req-detail {
          font-size: 0.75rem;
          color: #9CA3AF;
          margin-top: 0.25rem;
        }

        /* Sidebar Content */
        .sidebar-section {
          background: white;
          border-radius: 16px;
          padding: 1.5rem;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
          margin-bottom: 1.5rem;
        }

        .sidebar-title {
          font-size: 1rem;
          font-weight: 700;
          color: #1F2937;
          margin-bottom: 1rem;
        }

        .report-item {
          display: flex;
          align-items: center;
          gap: 1rem;
          padding: 1rem 0;
          border-bottom: 1px solid #F3F4F6;
        }

        .report-item:last-child {
          border-bottom: none;
        }

        .report-date {
          font-size: 0.75rem;
          color: #2196F3;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .report-title {
          font-weight: 600;
          color: #1F2937;
          font-size: 0.9375rem;
          margin-bottom: 0.25rem;
        }

        .report-description {
          font-size: 0.875rem;
          color: #6B7280;
          line-height: 1.5;
        }

        .view-link {
          color: #2196F3;
          text-decoration: none;
          font-weight: 600;
          font-size: 0.875rem;
          display: flex;
          align-items: center;
          gap: 0.25rem;
        }

        /* Questions List */
        .questions-list {
          list-style: none;
        }

        .question-item {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 1rem 0;
          border-bottom: 1px solid #F3F4F6;
          cursor: pointer;
          transition: color 0.2s;
        }

        .question-item:hover {
          color: #2196F3;
        }

        .question-item:last-child {
          border-bottom: none;
        }

        .help-center-link {
          display: block;
          text-align: center;
          padding: 1rem;
          color: #6B7280;
          text-decoration: none;
          font-weight: 600;
          font-size: 0.875rem;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          transition: color 0.2s;
        }

        .help-center-link:hover {
          color: #2196F3;
        }

        .disclaimer {
          margin-top: 2rem;
          padding: 1.5rem;
          background: #F9FAFB;
          border-radius: 12px;
          font-size: 0.75rem;
          color: #9CA3AF;
          line-height: 1.6;
          text-align: center;
        }

        @media (max-width: 1200px) {
          .eligibility-grid {
            grid-template-columns: 1fr;
          }

          .requirements-grid {
            grid-template-columns: 1fr;
          }
        }

        @media (max-width: 768px) {
          .sidebar {
            display: none;
          }

          .main-content {
            margin-left: 0;
          }
        }
      `}</style>

      <div className="eligibility-layout">
        {/* Top Navbar */}
        

        <div className="eligibility-content-wrapper">
          {/* Sidebar */}
          <aside className="sidebar">
                    
          
                    <nav className="sidebar-menu">
                      <Link to="/dashboard/donor" className="menu-item ">
                        <svg fill="currentColor" viewBox="0 0 20 20">
                          <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
                        </svg>
                        Dashboard
                      </Link>
          
                      <Link to="/donations" className="menu-item">
                        <svg fill="currentColor" viewBox="0 0 20 20">
                          <path d="M4 3a2 2 0 100 4h12a2 2 0 100-4H4z"/>
                          <path fillRule="evenodd" d="M3 8h14v7a2 2 0 01-2 2H5a2 2 0 01-2-2V8zm5 3a1 1 0 011-1h2a1 1 0 110 2H9a1 1 0 01-1-1z" clipRule="evenodd"/>
                        </svg>
                        My Donations
                      </Link>
          
                      <Link to="/eligibility" className="menu-item active">
                        <svg fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M6.267 3.455a3.066 3.066 0 001.745-.723 3.066 3.066 0 013.976 0 3.066 3.066 0 001.745.723 3.066 3.066 0 012.812 2.812c.051.643.304 1.254.723 1.745a3.066 3.066 0 010 3.976 3.066 3.066 0 00-.723 1.745 3.066 3.066 0 01-2.812 2.812 3.066 3.066 0 00-1.745.723 3.066 3.066 0 01-3.976 0 3.066 3.066 0 00-1.745-.723 3.066 3.066 0 01-2.812-2.812 3.066 3.066 0 00-.723-1.745 3.066 3.066 0 010-3.976 3.066 3.066 0 00.723-1.745 3.066 3.066 0 012.812-2.812zm7.44 5.252a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/>
                        </svg>
                        Eligibility
                      </Link>
          
                      <Link to="/centers" className="menu-item">
                        <svg fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clipRule="evenodd"/>
                        </svg>
                        Find Centers
                      </Link>
          
                      <Link to="/settings" className="menu-item">
                        <svg fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z" clipRule="evenodd"/>
                        </svg>
                        Settings
                      </Link>
                    </nav>
          
                    
                  </aside>

        {/* Main Content */}
        <main className="main-content">
          {/* Content Area */}
          <div className="content-area" style={{paddingTop: '1rem'}}>
            <div className="breadcrumb">
              <a href="/dashboard">Dashboard</a>
              <span>›</span>
              <span>Donation Eligibility</span>
            </div>

            <h1 className="page-title">Donation Eligibility</h1>

            <div className="eligibility-grid">
              <div>
                {/* Status Card */}
                <div className="status-card">
                  <div className="status-icon">
                    <div className="checkmark">
                      <svg width="24" height="24" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd"/>
                      </svg>
                    </div>
                  </div>

                  <span className="status-badge">STATUS: ELIGIBLE</span>
                  <div className="last-donation">Last Donation: Aug 12, 2023</div>

                  <h2 className="status-title">Ready to Donate</h2>
                  <p className="status-description">
                    You have met all medical requirements and recovery periods.
                  </p>

                  <h3 className="status-heading">Great news, James!</h3>
                  <p className="status-description">
                    Based on your medical profile and recent health reports, you are currently cleared for blood donation. Regular donations help save lives in your community.
                  </p>

                  <div className="action-buttons">
                    <button className="btn-primary">
                      <svg width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clipRule="evenodd"/>
                      </svg>
                      Schedule Now
                    </button>
                    <button className="btn-secondary">View Centers Near Me</button>
                  </div>
                </div>

                {/* Requirements */}
                <div className="requirements-section">
                  <div className="section-header">
                    <h3 className="section-title">Eligibility Requirements</h3>
                    <span className="updated-badge">Updated 2 days ago</span>
                  </div>

                  <div className="requirements-grid">
                    <div className="requirement-card">
                      <div className="req-icon green">
                        <svg width="24" height="24" fill="#10B981" viewBox="0 0 20 20">
                          <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z"/>
                          <path fillRule="evenodd" d="M4 5a2 2 0 012-2 3 3 0 003 3h2a3 3 0 003-3 2 2 0 012 2v11a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm3 4a1 1 0 000 2h.01a1 1 0 100-2H7zm3 0a1 1 0 000 2h3a1 1 0 100-2h-3zm-3 4a1 1 0 100 2h.01a1 1 0 100-2H7zm3 0a1 1 0 100 2h3a1 1 0 100-2h-3z" clipRule="evenodd"/>
                        </svg>
                      </div>
                      <div className="req-content">
                        <h4>
                          Body Weight <span className="check-icon">✓</span>
                        </h4>
                        <p>Minimum 110 lbs (50kg) required.</p>
                        <p className="req-detail">Latest: 178 lbs.</p>
                      </div>
                    </div>

                    <div className="requirement-card">
                      <div className="req-icon green">
                        <svg width="24" height="24" fill="#10B981" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clipRule="evenodd"/>
                        </svg>
                      </div>
                      <div className="req-content">
                        <h4>
                          Waiting Period <span className="check-icon">✓</span>
                        </h4>
                        <p>8 weeks since last whole blood donation.</p>
                        <p className="req-detail">Elapsed: 9 weeks.</p>
                      </div>
                    </div>

                    <div className="requirement-card">
                      <div className="req-icon green">
                        <svg width="24" height="24" fill="#10B981" viewBox="0 0 20 20">
                          <path d="M9 2a2 2 0 00-2 2v8a2 2 0 002 2h6a2 2 0 002-2V6.414A2 2 0 0016.414 5L14 2.586A2 2 0 0012.586 2H9z"/>
                          <path d="M3 8a2 2 0 012-2v10h8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"/>
                        </svg>
                      </div>
                      <div className="req-content">
                        <h4>
                          Iron Levels <span className="check-icon">✓</span>
                        </h4>
                        <p>Hemoglobin levels are within safe donation range.</p>
                      </div>
                    </div>

                    <div className="requirement-card">
                      <div className="req-icon green">
                        <svg width="24" height="24" fill="#10B981" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd"/>
                        </svg>
                      </div>
                      <div className="req-content">
                        <h4>
                          Recent Travel <span className="check-icon">✓</span>
                        </h4>
                        <p>No recent travel to malaria-endemic areas reported.</p>
                      </div>
                    </div>

                    <div className="requirement-card">
                      <div className="req-icon orange">
                        <svg width="24" height="24" fill="#F59E0B" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd"/>
                        </svg>
                      </div>
                      <div className="req-content">
                        <h4>
                          Medications <span className="warning-icon">⚠</span>
                        </h4>
                        <p>Please inform the nurse of any aspirin intake within 48 hours.</p>
                      </div>
                    </div>

                    <div className="requirement-card">
                      <div className="req-icon green">
                        <svg width="24" height="24" fill="#10B981" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clipRule="evenodd"/>
                        </svg>
                      </div>
                      <div className="req-content">
                        <h4>
                          Age Group <span className="check-icon">✓</span>
                        </h4>
                        <p>You meet the age requirement (17-70 years).</p>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="disclaimer">
                  <strong>Disclaimer:</strong> Eligibility status is determined based on the information provided in your profile and medical reports. A final health screening will be performed at the donation center by qualified medical personnel before each donation.
                </div>
              </div>

              {/* Sidebar */}
              <div>
                {/* Latest Medical Report */}
                <div className="sidebar-section">
                  <h3 className="sidebar-title">Latest Medical Report</h3>
                  <div className="report-item">
                    <div>
                      <div className="report-date">REPORT ANALYZED</div>
                      <div className="report-date" style={{color: '#6B7280', marginTop: '0.25rem'}}>Oct 12, 2023</div>
                    </div>
                  </div>
                  <div style={{marginTop: '1rem'}}>
                    <div className="report-title">Blood Profile Review</div>
                    <p className="report-description">
                      Your recent lab results confirm high iron availability and no active contraindications.
                    </p>
                    <a href="#" className="view-link" style={{marginTop: '0.5rem', display: 'inline-flex'}}>
                      Full Medical History
                      <svg width="16" height="16" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M10.293 3.293a1 1 0 011.414 0l6 6a1 1 0 010 1.414l-6 6a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-4.293-4.293a1 1 0 010-1.414z" clipRule="evenodd"/>
                      </svg>
                    </a>
                  </div>
                </div>

                {/* Common Questions */}
                <div className="sidebar-section">
                  <h3 className="sidebar-title">Common Questions</h3>
                  <ul className="questions-list">
                    <li className="question-item">
                      <span>Travel deferral rules</span>
                      <svg width="16" height="16" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clipRule="evenodd"/>
                      </svg>
                    </li>
                    <li className="question-item">
                      <span>Weight & height charts</span>
                      <svg width="16" height="16" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clipRule="evenodd"/>
                      </svg>
                    </li>
                    <li className="question-item">
                      <span>Tattoos and piercings</span>
                      <svg width="16" height="16" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clipRule="evenodd"/>
                      </svg>
                    </li>
                    <li className="question-item">
                      <span>Medication list lookup</span>
                      <svg width="16" height="16" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clipRule="evenodd"/>
                      </svg>
                    </li>
                  </ul>
                  <a href="#" className="help-center-link">VISIT HELP CENTER</a>
                </div>
              </div>
            </div>
          </div>
        </main>
        </div>
      </div>
    </>
  );
};

export default DonorEligibility;