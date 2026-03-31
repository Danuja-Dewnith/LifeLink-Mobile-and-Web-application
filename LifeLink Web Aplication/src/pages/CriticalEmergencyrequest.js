import React, { useState } from 'react';
import { Link } from 'react-router-dom';

const EmergencyRequest = () => {
  const [formData, setFormData] = useState({
    patientName: '',
    hospitalId: '',
    contactNumber: '',
    currentLocation: '',
    bloodGroupOrOrgan: '',
    unitsRequired: '',
    urgencyLevel: 'CRITICAL',
    hospitalName: '',
    medicalProof: null,
    confirmEmergency: false
  });

  const handleInputChange = (e) => {
    const { name, value, type, checked, files } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : type === 'file' ? files[0] : value
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    console.log('Emergency request submitted:', formData);
    // Handle form submission
  };

  return (
    <>
      <style>{`
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        .emergency-page {
          min-height: 100vh;
          background: #F8F9FA;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        }

        .emergency-header {
          background: white;
          padding: 1.25rem 2rem;
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .logo {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          font-size: 1.5rem;
          font-weight: 700;
          color: #DC2626;
        }

        .logo-icon {
          width: 32px;
          height: 32px;
        }

        .back-btn {
          padding: 0.625rem 1.25rem;
          background: #F3F4F6;
          border: 1px solid #E5E7EB;
          border-radius: 8px;
          font-size: 0.875rem;
          font-weight: 600;
          color: #374151;
          cursor: pointer;
          transition: all 0.2s;
          text-decoration: none;
          display: inline-block;
        }

        .back-btn:hover {
          background: #E5E7EB;
        }

        .emergency-content {
          max-width: 1400px;
          margin: 0 auto;
          padding: 3rem 2rem;
        }

        .page-title {
          text-align: center;
          margin-bottom: 1rem;
        }

        .page-title h1 {
          font-size: 2.5rem;
          font-weight: 800;
          color: #DC2626;
          margin-bottom: 0.5rem;
        }

        .page-subtitle {
          font-size: 1rem;
          color: #6B7280;
          text-align: center;
          margin-bottom: 3rem;
        }

        .emergency-grid {
          display: grid;
          grid-template-columns: 1fr 400px;
          gap: 2rem;
          align-items: start;
        }

        .form-section {
          background: white;
          border-radius: 16px;
          padding: 2rem;
          box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
        }

        .section-header {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          margin-bottom: 1.5rem;
        }

        .section-icon {
          color: #DC2626;
        }

        .section-header h2 {
          font-size: 1.25rem;
          font-weight: 700;
          color: #1F2937;
        }

        .form-grid {
          display: grid;
          grid-template-columns: repeat(2, 1fr);
          gap: 1.25rem;
          margin-bottom: 2rem;
        }

        .form-group {
          display: flex;
          flex-direction: column;
        }

        .form-group.full-width {
          grid-column: span 2;
        }

        .form-group label {
          font-size: 0.875rem;
          font-weight: 600;
          color: #374151;
          margin-bottom: 0.5rem;
        }

        .form-group input,
        .form-group select {
          padding: 0.75rem 1rem;
          border: 2px solid #E5E7EB;
          border-radius: 10px;
          font-size: 0.875rem;
          color: #1F2937;
          transition: all 0.2s;
          font-family: inherit;
        }

        .form-group input:focus,
        .form-group select:focus {
          outline: none;
          border-color: #DC2626;
          box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.1);
        }

        .form-group input::placeholder {
          color: #9CA3AF;
        }

        .location-input {
          position: relative;
        }

        .location-icon {
          position: absolute;
          right: 1rem;
          top: 50%;
          transform: translateY(-50%);
          color: #9CA3AF;
          pointer-events: none;
        }

        .emergency-requirement {
          border: 2px solid #DC2626;
          border-radius: 12px;
          padding: 1.5rem;
          margin-bottom: 2rem;
        }

        .urgency-level {
          margin-bottom: 1.25rem;
        }

        .urgency-btn {
          width: 100%;
          padding: 1rem;
          background: #DC2626;
          color: white;
          border: none;
          border-radius: 10px;
          font-size: 0.875rem;
          font-weight: 700;
          cursor: pointer;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 0.5rem;
        }

        .urgency-indicator {
          width: 8px;
          height: 8px;
          background: white;
          border-radius: 50%;
        }

        .upload-section {
          margin-bottom: 2rem;
        }

        .upload-area {
          border: 2px dashed #D1D5DB;
          border-radius: 12px;
          padding: 3rem 2rem;
          text-align: center;
          cursor: pointer;
          transition: all 0.3s;
          background: #F9FAFB;
        }

        .upload-area:hover {
          border-color: #DC2626;
          background: #FEF2F2;
        }

        .upload-icon {
          width: 48px;
          height: 48px;
          margin: 0 auto 1rem;
          color: #9CA3AF;
        }

        .upload-area p {
          font-size: 0.875rem;
          color: #6B7280;
          margin-bottom: 0.5rem;
        }

        .upload-area .file-types {
          font-size: 0.75rem;
          color: #9CA3AF;
        }

        .upload-note {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          margin-top: 1rem;
          color: #DC2626;
          font-size: 0.75rem;
        }

        .upload-note svg {
          width: 16px;
          height: 16px;
          flex-shrink: 0;
        }

        .checkbox-group {
          display: flex;
          align-items: center;
          gap: 0.75rem;
          padding: 1rem;
          border: 2px solid #E5E7EB;
          border-radius: 10px;
          margin-bottom: 2rem;
          cursor: pointer;
          transition: all 0.2s;
        }

        .checkbox-group:hover {
          border-color: #D1D5DB;
          background: #F9FAFB;
        }

        .checkbox-group input[type="checkbox"] {
          width: 20px;
          height: 20px;
          cursor: pointer;
          accent-color: #DC2626;
        }

        .checkbox-group label {
          font-size: 0.875rem;
          font-weight: 600;
          color: #1F2937;
          cursor: pointer;
          user-select: none;
        }

        .submit-btn {
          width: 100%;
          padding: 1.25rem;
          background: #DC2626;
          color: white;
          border: none;
          border-radius: 12px;
          font-size: 1rem;
          font-weight: 700;
          cursor: pointer;
          transition: all 0.3s;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 0.75rem;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .submit-btn:hover {
          background: #B91C1C;
          transform: translateY(-2px);
          box-shadow: 0 8px 20px rgba(220, 38, 38, 0.3);
        }

        .submit-btn svg {
          width: 20px;
          height: 20px;
        }

        .info-box {
          display: flex;
          align-items: start;
          gap: 0.75rem;
          padding: 1rem;
          background: #EFF6FF;
          border-left: 4px solid #3B82F6;
          border-radius: 8px;
          margin-top: 1.5rem;
        }

        .info-box svg {
          width: 20px;
          height: 20px;
          color: #3B82F6;
          flex-shrink: 0;
          margin-top: 0.125rem;
        }

        .info-box p {
          font-size: 0.875rem;
          color: #1E40AF;
          line-height: 1.5;
        }

        .info-box strong {
          font-weight: 700;
        }

        .sidebar {
          position: sticky;
          top: 2rem;
        }

        .status-card {
          background: linear-gradient(135deg, #F97316 0%, #EA580C 100%);
          border-radius: 16px;
          padding: 2.5rem 2rem;
          color: white;
          text-align: center;
          box-shadow: 0 8px 24px rgba(249, 115, 22, 0.3);
          margin-bottom: 1.5rem;
        }

        .status-icon {
          width: 80px;
          height: 80px;
          margin: 0 auto 1.5rem;
          animation: pulse 2s ease-in-out infinite;
        }

        @keyframes pulse {
          0%, 100% {
            transform: scale(1);
          }
          50% {
            transform: scale(1.05);
          }
        }

        .status-info {
          background: rgba(255, 255, 255, 0.2);
          backdrop-filter: blur(10px);
          border-radius: 12px;
          padding: 1.5rem;
          border: 1px solid rgba(255, 255, 255, 0.3);
        }

        .status-label {
          font-size: 0.75rem;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 1px;
          opacity: 0.9;
          margin-bottom: 0.5rem;
        }

        .status-value {
          font-size: 2rem;
          font-weight: 800;
          margin-bottom: 0.25rem;
        }

        .status-text {
          font-size: 0.875rem;
          opacity: 0.95;
        }

        .stats-grid {
          display: grid;
          grid-template-columns: repeat(2, 1fr);
          gap: 1rem;
        }

        .stat-card {
          background: white;
          border-radius: 12px;
          padding: 1.5rem;
          text-align: center;
          box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
        }

        .stat-value {
          font-size: 2rem;
          font-weight: 800;
          color: #DC2626;
          margin-bottom: 0.25rem;
        }

        .stat-label {
          font-size: 0.75rem;
          font-weight: 600;
          color: #6B7280;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .footer {
          text-align: center;
          padding: 3rem 2rem;
          color: #6B7280;
        }

        .footer-brand {
          font-size: 1.125rem;
          font-weight: 700;
          color: #DC2626;
          margin-bottom: 0.5rem;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 0.5rem;
        }

        .footer-text {
          font-size: 0.875rem;
        }

        @media (max-width: 1024px) {
          .emergency-grid {
            grid-template-columns: 1fr;
          }

          .sidebar {
            position: static;
          }

          .stats-grid {
            grid-template-columns: repeat(2, 1fr);
          }
        }

        @media (max-width: 768px) {
          .emergency-header {
            padding: 1rem;
          }

          .logo {
            font-size: 1.25rem;
          }

          .emergency-content {
            padding: 2rem 1rem;
          }

          .page-title h1 {
            font-size: 1.75rem;
          }

          .form-grid {
            grid-template-columns: 1fr;
            gap: 1rem;
          }

          .form-group.full-width {
            grid-column: span 1;
          }

          .form-section {
            padding: 1.5rem;
          }

          .emergency-requirement {
            padding: 1rem;
          }

          .status-card {
            padding: 2rem 1.5rem;
          }

          .status-icon {
            width: 60px;
            height: 60px;
          }

          .status-value {
            font-size: 1.5rem;
          }

          .stats-grid {
            grid-template-columns: repeat(2, 1fr);
            gap: 0.75rem;
          }

          .stat-card {
            padding: 1rem;
          }

          .stat-value {
            font-size: 1.5rem;
          }
        }
      `}</style>

      <div className="emergency-page">
        {/* Header */}
        <header className="emergency-header">
          <div className="logo">
            <svg className="logo-icon" viewBox="0 0 32 32" fill="none">
              <path d="M16 2L4 8v8c0 7.5 5.2 14.5 12 16 6.8-1.5 12-8.5 12-16V8L16 2z" fill="currentColor"/>
              <path d="M16 26l-1.33-1.2C9.07 20.27 6 17.52 6 14.13c0-2.05 1.61-3.67 3.67-3.67 1.16 0 2.27.54 3 1.39.73-.85 1.84-1.39 3-1.39 2.06 0 3.67 1.62 3.67 3.67 0 3.39-3.07 6.14-8.67 10.67L16 26z" fill="white"/>
            </svg>
            LifeLink
          </div>
          <Link to="/" className="back-btn">Back to Home</Link>
        </header>

        {/* Main Content */}
        <div className="emergency-content">
          <div className="page-title">
            <h1>Emergency Blood / Organ Request</h1>
          </div>
          <p className="page-subtitle">Submit urgent request to notify nearby donors and hospitals immediately</p>

          <div className="emergency-grid">
            {/* Left Column - Form */}
            <div>
              {/* Patient Basic Info */}
              <div className="form-section">
                <div className="section-header">
                  <svg className="section-icon" width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
                  </svg>
                  <h2>Patient Basic Info</h2>
                </div>

                <div className="form-grid">
                  <div className="form-group">
                    <label>Patient Name</label>
                    <input
                      type="text"
                      name="patientName"
                      placeholder="Enter full name"
                      value={formData.patientName}
                      onChange={handleInputChange}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label>NIC / Hospital ID</label>
                    <input
                      type="text"
                      name="hospitalId"
                      placeholder="Enter ID number"
                      value={formData.hospitalId}
                      onChange={handleInputChange}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label>Contact Number</label>
                    <input
                      type="tel"
                      name="contactNumber"
                      placeholder="+1 (555) 000-0000"
                      value={formData.contactNumber}
                      onChange={handleInputChange}
                      required
                    />
                  </div>

                  <div className="form-group">
                    <label>Current Location</label>
                    <div className="location-input">
                      <input
                        type="text"
                        name="currentLocation"
                        placeholder="City or Zip code"
                        value={formData.currentLocation}
                        onChange={handleInputChange}
                        required
                      />
                      <svg className="location-icon" width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                        <path d="M10 2c-2.76 0-5 2.24-5 5 0 3.75 5 11 5 11s5-7.25 5-11c0-2.76-2.24-5-5-5zm0 7c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2z"/>
                      </svg>
                    </div>
                  </div>
                </div>
              </div>

              {/* Emergency Requirement */}
              <div className="form-section" style={{ marginTop: '2rem' }}>
                <div className="emergency-requirement">
                  <div className="section-header" style={{ marginBottom: '1rem' }}>
                    <svg className="section-icon" width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M12 2L2 7v10c0 5.5 3.8 10.7 10 12 6.2-1.3 10-6.5 10-12V7l-10-5zm0 18c-3.9 0-7-3.1-7-7s3.1-7 7-7 7 3.1 7 7-3.1 7-7 7zm-1-11h2v6h-2zm0 8h2v2h-2z"/>
                    </svg>
                    <h2>Emergency Requirement</h2>
                  </div>

                  <div className="form-grid">
                    <div className="form-group">
                      <label>Blood Group or Organ</label>
                      <select
                        name="bloodGroupOrOrgan"
                        value={formData.bloodGroupOrOrgan}
                        onChange={handleInputChange}
                        required
                      >
                        <option value="">Select Requirement</option>
                        <option value="A+">A+</option>
                        <option value="A-">A-</option>
                        <option value="B+">B+</option>
                        <option value="B-">B-</option>
                        <option value="AB+">AB+</option>
                        <option value="AB-">AB-</option>
                        <option value="O+">O+</option>
                        <option value="O-">O-</option>
                        <option value="Kidney">Kidney</option>
                        <option value="Liver">Liver</option>
                        <option value="Heart">Heart</option>
                        <option value="Lung">Lung</option>
                      </select>
                    </div>

                    <div className="form-group">
                      <label>Units Required</label>
                      <input
                        type="number"
                        name="unitsRequired"
                        placeholder="Number of units"
                        value={formData.unitsRequired}
                        onChange={handleInputChange}
                        required
                      />
                    </div>

                    <div className="form-group">
                      <label>Urgency Level</label>
                      <button type="button" className="urgency-btn">
                        <span className="urgency-indicator"></span>
                        CRITICAL (Pre-selected)
                      </button>
                    </div>

                    <div className="form-group">
                      <label>Hospital Name</label>
                      <input
                        type="text"
                        name="hospitalName"
                        placeholder="Enter hospital name"
                        value={formData.hospitalName}
                        onChange={handleInputChange}
                        required
                      />
                    </div>
                  </div>
                </div>
              </div>

              {/* Medical Proof Upload */}
              <div className="form-section upload-section" style={{ marginTop: '2rem' }}>
                <h2 style={{ fontSize: '1rem', fontWeight: '700', marginBottom: '1rem' }}>Medical Proof Upload</h2>
                <label htmlFor="medicalProof" className="upload-area">
                  <svg className="upload-icon" viewBox="0 0 48 48" fill="currentColor">
                    <path d="M38 18h-8V6H18v12h-8l14 14 14-14zM10 36v4h28v-4H10z"/>
                  </svg>
                  <p><strong>Click to upload or drag and drop</strong></p>
                  <p className="file-types">PDF, JPG or PNG (Max 5MB)</p>
                  <input
                    type="file"
                    id="medicalProof"
                    name="medicalProof"
                    accept=".pdf,.jpg,.jpeg,.png"
                    onChange={handleInputChange}
                    style={{ display: 'none' }}
                  />
                </label>
                <div className="upload-note">
                  <svg viewBox="0 0 16 16" fill="currentColor">
                    <path d="M8 0C3.6 0 0 3.6 0 8s3.6 8 8 8 8-3.6 8-8-3.6-8-8-8zm1 12H7V7h2v5zm0-6H7V4h2v2z"/>
                  </svg>
                  <span>This will be quickly reviewed by admin for fast approval</span>
                </div>
              </div>

              {/* Confirmation Checkbox */}
              <div className="checkbox-group">
                <input
                  type="checkbox"
                  id="confirmEmergency"
                  name="confirmEmergency"
                  checked={formData.confirmEmergency}
                  onChange={handleInputChange}
                  required
                />
                <label htmlFor="confirmEmergency">THIS IS A REAL EMERGENCY CASE</label>
              </div>

              {/* Submit Button */}
              <button type="submit" className="submit-btn" onClick={handleSubmit}>
                <svg viewBox="0 0 20 20" fill="currentColor">
                  <path d="M2.003 5.884L10 9.882l7.997-3.998A2 2 0 0016 4H4a2 2 0 00-1.997 1.884z"/>
                  <path d="M18 8.118l-8 4-8-4V14a2 2 0 002 2h12a2 2 0 002-2V8.118z"/>
                </svg>
                Send Emergency Alert
              </button>

              {/* Info Box */}
              <div className="info-box">
                <svg viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd"/>
                </svg>
                <p>
                  <strong>Instant Activation:</strong> When submitted, LifeLink will instantly notify nearby eligible donors and hospitals via push notification and SMS.
                </p>
              </div>
            </div>

            {/* Right Column - Status & Stats */}
            <div className="sidebar">
              {/* Network Status Card */}
              <div className="status-card">
                <svg className="status-icon" viewBox="0 0 80 80" fill="none">
                  <circle cx="40" cy="40" r="38" stroke="white" strokeWidth="4" opacity="0.3"/>
                  <path d="M40 8L32 24H48L40 8Z" fill="white"/>
                  <path d="M40 72L32 56H48L40 72Z" fill="white"/>
                  <path d="M8 40L24 32V48L8 40Z" fill="white"/>
                  <path d="M72 40L56 32V48L72 40Z" fill="white"/>
                  <circle cx="40" cy="40" r="12" fill="white"/>
                  <path d="M40 30v20M30 40h20" stroke="#F97316" strokeWidth="3" strokeLinecap="round"/>
                </svg>
                <div className="status-info">
                  <div className="status-label">Network Status</div>
                  <div className="status-value">Active Responders:</div>
                  <div className="status-value">2,490</div>
                  <div className="status-text">Ready to help</div>
                </div>
              </div>

              {/* Stats Grid */}
              <div className="stats-grid">
                <div className="stat-card">
                  <div className="stat-value">12s</div>
                  <div className="stat-label">Avg Notification Speed</div>
                </div>
                <div className="stat-card">
                  <div className="stat-value">100%</div>
                  <div className="stat-label">Verified Donors</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <footer className="footer">
          <div className="footer-brand">
            <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
              <path d="M10 18l-1.33-1.2C3.07 12.27 0 9.52 0 6.13c0-2.05 1.61-3.67 3.67-3.67 1.16 0 2.27.54 3 1.39.73-.85 1.84-1.39 3-1.39 2.06 0 3.67 1.62 3.67 3.67 0 3.39-3.07 6.14-8.67 10.67L10 18z"/>
            </svg>
            LifeLink Emergency Network
          </div>
          <p className="footer-text">Saving lives in critical moments © 2024</p>
        </footer>
      </div>
    </>
  );
};

export default EmergencyRequest;