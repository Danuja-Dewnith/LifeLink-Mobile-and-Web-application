import React, { useState } from 'react';
import '../style/EmergencyRequest.css';

const EmergencyRequest = () => {
  const [formData, setFormData] = useState({
    bloodOrganType: '',
    unitsRequired: '',
    hospitalFacility: '',
    emergencyNote: null
  });
  const [confirmChecked, setConfirmChecked] = useState(false);
  const [dragActive, setDragActive] = useState(false);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleDrag = (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === "dragenter" || e.type === "dragover") {
      setDragActive(true);
    } else if (e.type === "dragleave") {
      setDragActive(false);
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFiles(e.dataTransfer.files);
    }
  };

  const handleFileChange = (e) => {
    if (e.target.files && e.target.files[0]) {
      handleFiles(e.target.files);
    }
  };

  const handleFiles = (files) => {
    const file = files[0];
    setFormData(prev => ({
      ...prev,
      emergencyNote: file
    }));
    console.log('File uploaded:', file);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!confirmChecked) {
      alert('Please confirm that this is a critical life-saving emergency.');
      return;
    }
    console.log('Emergency Alert Sent:', formData);
    // Handle emergency alert submission
  };

  // Mock data for real-time tracking
  const alertTime = new Date().toLocaleTimeString('en-US', { 
    hour12: false,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  });

  const latestActivity = [
    {
      id: 1,
      type: 'success',
      text: 'Donor #882 has accepted the request from City Hospital.',
      icon: '●'
    },
    {
      id: 2,
      type: 'info',
      text: 'Broadcast expanded to 50km radius.',
      icon: '●'
    }
  ];

  return (
    <div className="emergency-request-container">
      {/* Sidebar */}
      <aside className="sidebar">
       

        <nav className="nav">
          <a href="/dashboard/patient" className="nav-item">
            <span className="nav-icon">📊</span>
            <span>Dashboard</span>
          </a>
          <a href="/myrequests" className="nav-item">
            <span className="nav-icon">📄</span>
            <span>My Requests</span>
          </a>
          <a href="/patient/medical-reports" className="nav-item">
            <span className="nav-icon">📋</span>
            <span>Medical Reports</span>
          </a>
          <a href="#" className="nav-item">
            <span className="nav-icon">👨‍⚕️</span>
            <span>Doctor Instructions</span>
          </a>
          <a href="/patient/emergency-request" className="nav-item emergency-active">
            <span className="nav-icon">🚨</span>
            <span>Emergency Request</span>
          </a>
          <a href="/patient/messages" className="nav-item">
            <span className="nav-icon">💬</span>
            <span>Messages</span>
            <span className="badge">3</span>
          </a>
        </nav>

        <div className="user-profile-sidebar">
          <div className="user-avatar">
            <img src="https://i.pravatar.cc/150?img=5" alt="Dr. Sarah Chen" />
          </div>
          <div className="user-info-sidebar">
            <div className="user-name-sidebar">Dr. Sarah Chen</div>
            <div className="user-role-sidebar">Surgical Resident</div>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="main-content-emergency">
        {/* Critical Alert Banner */}
        <div className="critical-banner">
          <div className="banner-icon">
            <span>🚨</span>
          </div>
          <div className="banner-content">
            <h2 className="banner-title">CRITICAL: Emergency Broadcast System Active</h2>
            <p className="banner-text">
              Emergency alerts notify nearby donors immediately via mobile notification and SMS. 
              Please use only for life-threatening cases.
            </p>
          </div>
        </div>

        <div className="emergency-layout">
          {/* Left Column - Emergency Request Form */}
          <div className="request-column">
            <div className="request-card">
              <div className="card-header-emergency">
                <span className="emergency-icon">🚨</span>
                <h2 className="card-title-emergency">New Emergency Request</h2>
              </div>

              <form onSubmit={handleSubmit} className="emergency-form">
                {/* Blood/Organ Type and Units */}
                <div className="form-row-emergency">
                  <div className="form-group-emergency">
                    <label className="form-label-emergency">Blood / Organ Type</label>
                    <select
                      name="bloodOrganType"
                      value={formData.bloodOrganType}
                      onChange={handleInputChange}
                      className="form-select-emergency"
                      required
                    >
                      <option value="">Select Type</option>
                      <option value="A+">A Positive (A+)</option>
                      <option value="A-">A Negative (A-)</option>
                      <option value="B+">B Positive (B+)</option>
                      <option value="B-">B Negative (B-)</option>
                      <option value="AB+">AB Positive (AB+)</option>
                      <option value="AB-">AB Negative (AB-)</option>
                      <option value="O+">O Positive (O+)</option>
                      <option value="O-">O Negative (O-)</option>
                      <option value="kidney">Kidney</option>
                      <option value="liver">Liver</option>
                      <option value="heart">Heart</option>
                      <option value="lung">Lung</option>
                    </select>
                  </div>

                  <div className="form-group-emergency">
                    <label className="form-label-emergency">Units Required</label>
                    <input
                      type="text"
                      name="unitsRequired"
                      value={formData.unitsRequired}
                      onChange={handleInputChange}
                      className="form-input-emergency"
                      placeholder="e.g. 2"
                      required
                    />
                  </div>
                </div>

                {/* Hospital Facility */}
                <div className="form-group-emergency">
                  <label className="form-label-emergency">Hospital Facility</label>
                  <div className="hospital-search">
                    <span className="search-icon-emergency">🔍</span>
                    <input
                      type="text"
                      name="hospitalFacility"
                      value={formData.hospitalFacility}
                      onChange={handleInputChange}
                      className="form-input-hospital"
                      placeholder="Search Hospital Name"
                      required
                    />
                  </div>
                </div>

                {/* Upload Emergency Note */}
                <div className="form-group-emergency">
                  <label className="form-label-emergency">Upload Emergency Note / Medical Record</label>
                  <div 
                    className={`dropzone-emergency ${dragActive ? 'active' : ''}`}
                    onDragEnter={handleDrag}
                    onDragLeave={handleDrag}
                    onDragOver={handleDrag}
                    onDrop={handleDrop}
                  >
                    <div className="dropzone-icon-emergency">
                      <span>☁️</span>
                    </div>
                    <p className="dropzone-text-emergency">
                      Drag and drop file here, or browse files
                    </p>
                    <p className="dropzone-subtext-emergency">
                      PDF, JPG, or PNG (Max 5MB)
                    </p>
                    <input
                      type="file"
                      className="file-input-emergency"
                      onChange={handleFileChange}
                      accept=".pdf,.jpg,.jpeg,.png"
                    />
                  </div>
                </div>

                {/* Confirmation Checkbox */}
                <div className="confirmation-box">
                  <label className="checkbox-container">
                    <input
                      type="checkbox"
                      checked={confirmChecked}
                      onChange={(e) => setConfirmChecked(e.target.checked)}
                      className="checkbox-input"
                    />
                    <span className="checkbox-checkmark"></span>
                    <span className="checkbox-label">
                      I confirm that this is a <strong>critical life-saving emergency</strong>. 
                      I understand that misusing the emergency system can lead to account suspension.
                    </span>
                  </label>
                </div>

                {/* Submit Button */}
                <button 
                  type="submit" 
                  className="btn-emergency-submit"
                  disabled={!confirmChecked}
                >
                  <span className="submit-icon">▶</span>
                  SEND EMERGENCY ALERT
                </button>
              </form>
            </div>
          </div>

          {/* Right Column - Real-time Tracking */}
          <div className="tracking-column">
            <div className="tracking-card">
              <div className="tracking-header">
                <span className="tracking-icon">📊</span>
                <h3 className="tracking-title">Real-time Alert Tracking</h3>
              </div>

              {/* Alert Sent Time */}
              <div className="stat-box alert-time">
                <div className="stat-icon-box red">
                  <span>⏱️</span>
                </div>
                <div className="stat-content">
                  <div className="stat-label-small">Alert Sent Time</div>
                  <div className="stat-value-time">{alertTime}</div>
                  <div className="stat-badge">TODAY</div>
                </div>
              </div>

              {/* Donors Notified */}
              <div className="stat-box donors-notified">
                <div className="stat-icon-box red">
                  <span>🔔</span>
                </div>
                <div className="stat-content">
                  <div className="stat-label-small">Donors Notified</div>
                  <div className="stat-value-large">1,248</div>
                  <div className="stat-badge-green">BROADCASTING</div>
                </div>
              </div>

              {/* Responses Received */}
              <div className="stat-box responses">
                <div className="stat-icon-box red">
                  <span>💬</span>
                </div>
                <div className="stat-content">
                  <div className="stat-label-small">Responses Received</div>
                  <div className="stat-value-large">42</div>
                  <div className="stat-info">
                    <span className="response-rate">3.4%</span>
                    <span className="rate-label">RATE</span>
                  </div>
                  <div className="response-bar">
                    <div className="response-bar-fill" style={{width: '3.4%'}}></div>
                  </div>
                </div>
              </div>

              {/* Latest Activity */}
              <div className="activity-section">
                <h4 className="activity-title">LATEST ACTIVITY</h4>
                <div className="activity-list">
                  {latestActivity.map((activity) => (
                    <div key={activity.id} className={`activity-item ${activity.type}`}>
                      <span className="activity-icon">{activity.icon}</span>
                      <span className="activity-text">{activity.text}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Hospital Location Map */}
            <div className="map-card">
              <div className="map-placeholder">
                <img 
                  src="https://images.unsplash.com/photo-1524661135-423995f22d0b?w=600&h=400&fit=crop" 
                  alt="World Map" 
                  className="map-image"
                />
                <div className="map-overlay">
                  <div className="location-badge">
                    <span className="location-label">HOSPITAL LOCATION</span>
                    <span className="location-name">Central Medical Center, NY</span>
                  </div>
                  <button className="location-btn">
                    <span>📍</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

export default EmergencyRequest;