import React from 'react';
import { Link } from 'react-router-dom';

const RoleSelection = () => {
  return (
    <>
      <style>{`
        .role-selection-page {
          min-height: calc(100vh - 80px);
          background: linear-gradient(135deg, #E3F2FD 0%, #F5F5F5 100%);
          padding: 3rem 2rem;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
        }

        .role-container {
          max-width: 1400px;
          margin: 0 auto;
        }

        .role-header {
          text-align: center;
          margin-bottom: 3rem;
        }

        .role-title {
          font-size: 3rem;
          font-weight: 800;
          color: #1a1a1a;
          margin-bottom: 0.5rem;
        }

        .role-subtitle {
          font-size: 1.25rem;
          color: #666;
        }

        .role-cards {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
          gap: 2rem;
          margin-bottom: 3rem;
        }

        .role-card {
          background: white;
          border-radius: 20px;
          overflow: hidden;
          box-shadow: 0 10px 40px rgba(0, 0, 0, 0.08);
          transition: transform 0.3s, box-shadow 0.3s;
        }

        .role-card:hover {
          transform: translateY(-8px);
          box-shadow: 0 15px 50px rgba(0, 0, 0, 0.12);
        }

        .role-image {
          width: 100%;
          height: 250px;
          display: flex;
          align-items: center;
          justify-content: center;
          overflow: hidden;
        }

        .role-image svg {
          width: 100%;
          height: 100%;
        }

        .role-content {
          padding: 2rem;
          text-align: center;
        }

        .role-icon {
          width: 64px;
          height: 64px;
          margin: 0 auto 1.5rem;
          border-radius: 16px;
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
        }

        .donor-card .role-icon {
          background: linear-gradient(135deg, #F44336 0%, #D32F2F 100%);
        }

        .patient-card .role-icon {
          background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%);
        }

        .hospital-card .role-icon {
          background: linear-gradient(135deg, #4CAF50 0%, #388E3C 100%);
        }

        .role-card-title {
          font-size: 1.75rem;
          font-weight: 700;
          color: #1a1a1a;
          margin-bottom: 1rem;
        }

        .role-card-description {
          font-size: 1rem;
          color: #666;
          line-height: 1.6;
          margin-bottom: 2rem;
        }

        .role-btn {
          display: inline-flex;
          align-items: center;
          gap: 0.5rem;
          padding: 1rem 2rem;
          border: none;
          border-radius: 12px;
          font-weight: 600;
          font-size: 1rem;
          text-decoration: none;
          transition: all 0.3s;
          cursor: pointer;
        }

        .donor-btn {
          background-color: #F44336;
          color: white;
        }

        .donor-btn:hover {
          background-color: #D32F2F;
          transform: scale(1.05);
          box-shadow: 0 4px 12px rgba(244, 67, 54, 0.3);
        }

        .patient-btn {
          background-color: #2196F3;
          color: white;
        }

        .patient-btn:hover {
          background-color: #1976D2;
          transform: scale(1.05);
          box-shadow: 0 4px 12px rgba(33, 150, 243, 0.3);
        }

        .hospital-btn {
          background-color: #4CAF50;
          color: white;
        }

        .hospital-btn:hover {
          background-color: #388E3C;
          transform: scale(1.05);
          box-shadow: 0 4px 12px rgba(76, 175, 80, 0.3);
        }

        .role-footer {
          text-align: center;
          margin-top: 2rem;
        }

        .role-footer p {
          font-size: 1.125rem;
          color: #666;
          font-style: italic;
        }

        @media (max-width: 1200px) {
          .role-cards {
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
          }
        }

        @media (max-width: 768px) {
          .role-title {
            font-size: 2rem;
          }

          .role-subtitle {
            font-size: 1rem;
          }

          .role-cards {
            grid-template-columns: 1fr;
          }

          .role-image {
            height: 200px;
          }

          .role-card-title {
            font-size: 1.5rem;
          }
        }
      `}</style>

      <div className="role-selection-page">
      <div className="role-container">
        <div className="role-header">
          <h1 className="role-title">Join LifeLink</h1>
          <p className="role-subtitle">Select your role to continue</p>
        </div>

        <div className="role-cards">
          {/* Donor Card */}
          <div className="role-card donor-card">
            <div className="role-image">
              <svg viewBox="0 0 400 300" fill="none">
                <rect width="400" height="300" fill="#FFF3E0" rx="15"/>
                <g transform="translate(120, 80)">
                  <circle cx="80" cy="50" r="30" fill="#FFB74D"/>
                  <rect x="55" y="80" width="50" height="70" fill="#FFB74D" rx="10"/>
                  <circle cx="60" cy="95" r="15" fill="#F44336"/>
                  <line x1="55" y1="95" x2="65" y2="95" stroke="white" strokeWidth="2"/>
                  <line x1="60" y1="90" x2="60" y2="100" stroke="white" strokeWidth="2"/>
                  <rect x="40" y="110" width="15" height="25" fill="#FF9800" rx="3"/>
                </g>
              </svg>
            </div>
            <div className="role-content">
              <div className="role-icon">
                <svg width="32" height="32" viewBox="0 0 32 32" fill="currentColor">
                  <path d="M16 4l-2 4h-4l3 3-1 4 4-2 4 2-1-4 3-3h-4z"/>
                  <path d="M16 28c-6.627 0-12-5.373-12-12h2c0 5.523 4.477 10 10 10s10-4.477 10-10h2c0 6.627-5.373 12-12 12z"/>
                </svg>
              </div>
              <h2 className="role-card-title">I am a Donor</h2>
              <p className="role-card-description">
                Donate blood or organs and save lives. Join our community of life-savers.
              </p>
              <Link to="/register/donor" className="role-btn donor-btn">
                Continue as Donor
                <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M10 4l-1.5 1.5L13 10l-4.5 4.5L10 16l6-6z"/>
                </svg>
              </Link>
            </div>
          </div>

          {/* Patient Card */}
          <div className="role-card patient-card">
            <div className="role-image">
              <svg viewBox="0 0 400 300" fill="none">
                <rect width="400" height="300" fill="#E3F2FD" rx="15"/>
                <g transform="translate(100, 80)">
                  <rect x="40" y="60" width="120" height="80" fill="white" rx="8"/>
                  <rect x="50" y="40" width="100" height="15" fill="#90CAF9" rx="5"/>
                  <circle cx="100" cy="100" r="20" fill="#2196F3"/>
                  <rect x="75" y="120" width="50" height="15" fill="#64B5F6" rx="3"/>
                  <rect x="160" y="80" width="20" height="50" fill="#90CAF9" rx="3"/>
                  <circle cx="170" cy="70" r="8" fill="#2196F3"/>
                </g>
              </svg>
            </div>
            <div className="role-content">
              <div className="role-icon">
                <svg width="32" height="32" viewBox="0 0 32 32" fill="currentColor">
                  <path d="M16 2C8.268 2 2 8.268 2 16s6.268 14 14 14 14-6.268 14-14S23.732 2 16 2zm0 26c-6.617 0-12-5.383-12-12S9.383 4 16 4s12 5.383 12 12-5.383 12-12 12z"/>
                  <path d="M16 8v8l6 6"/>
                  <circle cx="16" cy="16" r="2"/>
                </svg>
              </div>
              <h2 className="role-card-title">I am a Patient</h2>
              <p className="role-card-description">
                Request blood or organ support for medical emergencies and planned surgeries.
              </p>
              <Link to="/register/patient" className="role-btn patient-btn">
                Continue as Patient
                <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M10 4l-1.5 1.5L13 10l-4.5 4.5L10 16l6-6z"/>
                </svg>
              </Link>
            </div>
          </div>

          {/* Hospital Card */}
          <div className="role-card hospital-card">
            <div className="role-image">
              <svg viewBox="0 0 400 300" fill="none">
                <rect width="400" height="300" fill="#E8F5E9" rx="15"/>
                <g transform="translate(100, 60)">
                  <rect x="20" y="40" width="160" height="140" fill="white" rx="8"/>
                  <rect x="80" y="20" width="40" height="30" fill="#4CAF50" rx="4"/>
                  <rect x="40" y="70" width="30" height="35" fill="#81C784" rx="3"/>
                  <rect x="85" y="70" width="30" height="35" fill="#81C784" rx="3"/>
                  <rect x="130" y="70" width="30" height="35" fill="#81C784" rx="3"/>
                  <rect x="40" y="115" width="30" height="35" fill="#81C784" rx="3"/>
                  <rect x="85" y="115" width="30" height="35" fill="#81C784" rx="3"/>
                  <rect x="130" y="115" width="30" height="35" fill="#81C784" rx="3"/>
                  <line x1="95" y1="30" x2="105" y2="30" stroke="white" strokeWidth="3"/>
                  <line x1="100" y1="25" x2="100" y2="35" stroke="white" strokeWidth="3"/>
                </g>
              </svg>
            </div>
            <div className="role-content">
              <div className="role-icon">
                <svg width="32" height="32" viewBox="0 0 32 32" fill="currentColor">
                  <path d="M16 2L4 8v8c0 7.5 5 13 12 14 7-1 12-6.5 12-14V8L16 2z"/>
                  <path d="M16 9v6m0 0v6m0-6h6m-6 0H10" stroke="white" strokeWidth="2"/>
                </svg>
              </div>
              <h2 className="role-card-title">Blood Bank / Hospital</h2>
              <p className="role-card-description">
                Manage blood storage, incoming requests, and donor databases efficiently.
              </p>
              <Link to="/register/hospital" className="role-btn hospital-btn">
                Continue as Hospital
                <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M10 4l-1.5 1.5L13 10l-4.5 4.5L10 16l6-6z"/>
                </svg>
              </Link>
            </div>
          </div>
        </div>

        <div className="role-footer">
          <p>"LifeLink connects donors, patients, and hospitals in real-time."</p>
        </div>
      </div>
      </div>
    </>
  );
};

export default RoleSelection;