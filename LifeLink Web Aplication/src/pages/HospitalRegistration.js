import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

const HospitalRegistration = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    name: '',
    regNumber: '',
    address: '',
    contact: '',
    email: '',
    password: '',
    confirmPassword: '',
    storageCapacity: '',
    confirmed: false,
    govtCertificate: null,
    medicalLicense: null,
    authorizedId: null
  });

  const [bloodTypes, setBloodTypes] = useState({
    'A+': { enabled: true, amount: '' },
    'A-': { enabled: false, amount: '' },
    'B+': { enabled: true, amount: '' },
    'B-': { enabled: false, amount: '' },
    'O+': { enabled: true, amount: '' },
    'O-': { enabled: false, amount: '' },
    'AB+': { enabled: false, amount: '' },
    'AB-': { enabled: false, amount: '' }
  });

  const [obscurePassword, setObscurePassword] = useState(true);
  const [obscureConfirm, setObscureConfirm] = useState(true);
  const [isLoading, setIsLoading] = useState(false);
  const [errors, setErrors] = useState({});

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const handleFileChange = (e, docType) => {
    const file = e.target.files && e.target.files[0];
    if (!file) return;

    if (file.size > 10 * 1024 * 1024) {
      alert('File size must be less than 10MB');
      return;
    }

    const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png'];
    if (!allowedTypes.includes(file.type)) {
      alert('Only PDF, JPG, and PNG files are allowed');
      return;
    }

    setFormData(prev => ({
      ...prev,
      [docType]: file
    }));
  };

  const handleBloodTypeToggle = (type) => {
    setBloodTypes(prev => ({
      ...prev,
      [type]: { ...prev[type], enabled: !prev[type].enabled }
    }));
  };

  const handleBloodAmountChange = (type, amount) => {
    setBloodTypes(prev => ({
      ...prev,
      [type]: { ...prev[type], amount }
    }));
  };

  const validateForm = () => {
    const newErrors = {};

    if (!formData.name.trim()) newErrors.name = 'Hospital name is required';
    if (!formData.regNumber.trim() || formData.regNumber.trim().length < 5)
      newErrors.regNumber = 'Valid registration number required';
    if (!formData.address.trim()) newErrors.address = 'Address is required';
    if (!formData.contact.trim() || !/^(?:0|94|\+94)?[0-9]{9,10}$/.test(formData.contact.replace(/[\s\-]/g, '')))
      newErrors.contact = 'Valid contact number required';
    if (!formData.email.trim() || !/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(formData.email))
      newErrors.email = 'Valid email address required';

    // Check documents
    if (!formData.govtCertificate) newErrors.govtCertificate = 'Government Registration Certificate is required';
    if (!formData.medicalLicense) newErrors.medicalLicense = 'Medical License is required';
    if (!formData.authorizedId) newErrors.authorizedId = 'Authorized Person ID is required';

    const enabledTypes = Object.entries(bloodTypes).filter(([_, data]) => data.enabled);
    if (enabledTypes.length === 0) {
      newErrors.bloodTypes = 'Select at least one blood type';
    } else {
      for (const [type, data] of enabledTypes) {
        if (!data.amount || parseInt(data.amount) <= 0) {
          newErrors[`blood_${type}`] = `Enter valid amount for ${type}`;
        }
      }
    }

    if (!formData.storageCapacity || parseInt(formData.storageCapacity) <= 0)
      newErrors.storageCapacity = 'Valid storage capacity required';
    if (!formData.password || formData.password.length < 8)
      newErrors.password = 'Password must be at least 8 characters';
    if (formData.password !== formData.confirmPassword)
      newErrors.confirmPassword = 'Passwords do not match';
    if (!formData.confirmed) newErrors.confirmed = 'Please confirm details are valid';

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e) => {
  e.preventDefault();
  if (!validateForm()) return;

  setIsLoading(true);

  const formDataToSend = new FormData();

  // Text fields
  formDataToSend.append('name', formData.name);
  formDataToSend.append('regNumber', formData.regNumber);
  formDataToSend.append('address', formData.address);
  formDataToSend.append('contact', formData.contact);
  formDataToSend.append('email', formData.email);
  formDataToSend.append('password', formData.password);
  formDataToSend.append('storageCapacity', formData.storageCapacity);

  // Blood inventory as JSON strings
  const bloodInventory = {};
  const selectedBloodTypes = [];
  Object.entries(bloodTypes).forEach(([type, data]) => {
    if (data.enabled && data.amount) {
      bloodInventory[type] = parseInt(data.amount);
      selectedBloodTypes.push(type);
    }
  });

  formDataToSend.append('bloodInventory', JSON.stringify(bloodInventory));
  formDataToSend.append('selectedBloodTypes', JSON.stringify(selectedBloodTypes));

  // Files
  if (formData.govtCertificate) formDataToSend.append('govtCertificate', formData.govtCertificate);
  if (formData.medicalLicense) formDataToSend.append('medicalLicense', formData.medicalLicense);
  if (formData.authorizedId) formDataToSend.append('authorizedId', formData.authorizedId);

  try {
    const response = await fetch('http://localhost:8083/api/hospitals/register', {
      method: 'POST',
      body: formDataToSend
      // Do NOT add Content-Type header
    });

    const data = await response.json();

    if (response.ok && data.success) {
      alert('✅ Hospital / Blood Bank registered successfully!');
      navigate('/login');
    } else {
      setErrors({ submit: data.message || 'Registration failed' });
    }
  } catch (error) {
    setErrors({ submit: 'Connection error. Please try again.' });
  } finally {
    setIsLoading(false);
  }
};
  const getBloodTypeColor = (type) => {
    if (type.startsWith('A')) return '#E53935';
    if (type.startsWith('B')) return '#8E24AA';
    if (type.startsWith('O')) return '#1E88E5';
    return '#00897B';
  };

  return (
    <>
      <style>{`
        .hospital-reg-page {
          min-height: 100vh;
          background: linear-gradient(135deg, #E3F2FD 0%, #F5F5F5 100%);
          padding: 2rem;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
        }

        .hospital-reg-container {
          max-width: 1200px;
          margin: 0 auto;
          background: white;
          border-radius: 20px;
          overflow: hidden;
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
          display: grid;
          grid-template-columns: 1fr 380px;
        }

        .hospital-reg-form-wrapper {
          padding: 3rem;
        }

        .hospital-reg-header {
          text-align: center;
          margin-bottom: 2rem;
        }

        .hospital-reg-logo {
          width: 72px;
          height: 72px;
          margin: 0 auto 1rem;
          background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%);
          border-radius: 20px;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .hospital-reg-title {
          font-size: 2rem;
          font-weight: 800;
          color: #1a1a1a;
          margin-bottom: 0.5rem;
        }

        .hospital-reg-subtitle {
          font-size: 1rem;
          color: #666;
        }

        .form-section {
          background: #F8F9FA;
          border-radius: 16px;
          padding: 1.5rem;
          margin-bottom: 1.5rem;
          border: 1px solid #E0E0E0;
        }

        .section-title {
          font-size: 1.25rem;
          font-weight: 700;
          color: #2196F3;
          margin-bottom: 1.5rem;
          display: flex;
          align-items: center;
          gap: 0.5rem;
        }

        .form-row {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 1rem;
          margin-bottom: 1rem;
        }

        .form-group {
          margin-bottom: 1rem;
        }

        .form-group.full-width {
          grid-column: span 2;
        }

        .form-group label {
          display: block;
          font-size: 0.875rem;
          font-weight: 600;
          color: #333;
          margin-bottom: 0.5rem;
        }

        .form-group input,
        .form-group select,
        .form-group textarea {
          width: 100%;
          padding: 0.75rem 1rem;
          border: 2px solid #E0E0E0;
          border-radius: 10px;
          font-size: 0.95rem;
          transition: all 0.3s;
          font-family: inherit;
        }

        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
          outline: none;
          border-color: #2196F3;
          box-shadow: 0 0 0 3px rgba(33, 150, 243, 0.1);
        }

        .password-container {
          position: relative;
        }

        .password-toggle {
          position: absolute;
          right: 12px;
          top: 50%;
          transform: translateY(-50%);
          background: none;
          border: none;
          cursor: pointer;
          font-size: 18px;
          padding: 0;
        }

        .doc-card {
          background: #F8F9FA;
          border-radius: 16px;
          padding: 1.5rem;
          margin-bottom: 1.5rem;
          border: 1px solid #2196F3;
          border-left: 4px solid #2196F3;
        }

        .doc-header {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          margin-bottom: 0.5rem;
        }

        .doc-icon {
          font-size: 1.25rem;
          color: #2196F3;
        }

        .doc-title {
          font-size: 1.1rem;
          font-weight: 700;
          color: #2196F3;
          margin: 0;
        }

        .doc-subtitle {
          font-size: 0.85rem;
          color: #666;
          margin-bottom: 1rem;
        }

        .doc-row {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 0.75rem 0;
        }

        .doc-label {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          font-size: 0.9rem;
          font-weight: 500;
          color: #333;
        }

        .upload-btn {
          background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%);
          color: white;
          border: none;
          padding: 0.5rem 1rem;
          border-radius: 8px;
          font-size: 0.85rem;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.3s;
        }

        .upload-btn:hover {
          transform: translateY(-1px);
          box-shadow: 0 2px 8px rgba(33, 150, 243, 0.3);
        }

        .file-name {
          font-size: 0.8rem;
          color: #4CAF50;
          margin-left: 0.5rem;
        }

        .divider {
          height: 1px;
          background: #E0E0E0;
          margin: 0.5rem 0;
        }

        .blood-inventory-grid {
          display: grid;
          grid-template-columns: repeat(2, 1fr);
          gap: 1rem;
          margin-bottom: 1rem;
        }

        .blood-type-item {
          display: flex;
          align-items: center;
          gap: 0.75rem;
        }

        .blood-type-toggle {
          padding: 0.5rem 1rem;
          border-radius: 8px;
          border: none;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s;
          min-width: 60px;
        }

        .blood-type-input {
          flex: 1;
          padding: 0.5rem;
          border: 1px solid #E0E0E0;
          border-radius: 8px;
          text-align: center;
        }

        .blood-type-input:focus {
          outline: none;
          border-color: #2196F3;
        }

        .checkbox-row {
          display: flex;
          align-items: flex-start;
          gap: 0.75rem;
          margin: 1.5rem 0;
        }

        .checkbox-row input[type="checkbox"] {
          width: 18px;
          height: 18px;
          margin-top: 2px;
          cursor: pointer;
        }

        .error-text {
          color: #C62828;
          font-size: 0.75rem;
          margin-top: 0.25rem;
        }

        .submit-error {
          background: #FFEBEE;
          color: #C62828;
          padding: 0.75rem;
          border-radius: 10px;
          margin-bottom: 1rem;
          text-align: center;
        }

        .submit-btn {
          width: 100%;
          padding: 1rem;
          background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%);
          color: white;
          border: none;
          border-radius: 12px;
          font-size: 1rem;
          font-weight: 700;
          cursor: pointer;
          transition: all 0.3s;
          margin-top: 1rem;
        }

        .submit-btn:hover:not(:disabled) {
          transform: translateY(-2px);
          box-shadow: 0 8px 20px rgba(33, 150, 243, 0.4);
        }

        .submit-btn:disabled {
          opacity: 0.7;
          cursor: not-allowed;
        }

        .login-footer {
          text-align: center;
          margin-top: 2rem;
          padding-top: 1.5rem;
          border-top: 1px solid #E0E0E0;
        }

        .register-link {
          color: #2196F3;
          font-weight: 600;
          text-decoration: none;
        }

        .register-link:hover {
          text-decoration: underline;
        }

        .hospital-reg-sidebar {
          background: linear-gradient(135deg, #2196F3 0%, #1565C0 100%);
          padding: 3rem;
          color: white;
        }

        .sidebar-content h2 {
          font-size: 1.75rem;
          font-weight: 800;
          margin-bottom: 1rem;
        }

        .sidebar-content p {
          font-size: 0.95rem;
          line-height: 1.6;
          opacity: 0.95;
          margin-bottom: 2rem;
        }

        .stats-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 1rem;
        }

        .stat {
          background: rgba(255, 255, 255, 0.15);
          backdrop-filter: blur(10px);
          padding: 1rem;
          border-radius: 12px;
          text-align: center;
        }

        .stat-number {
          font-size: 1.25rem;
          font-weight: 800;
          margin-bottom: 0.25rem;
        }

        .stat-label {
          font-size: 0.7rem;
          opacity: 0.9;
          text-transform: uppercase;
        }

        @media (max-width: 968px) {
          .hospital-reg-container {
            grid-template-columns: 1fr;
          }
          .hospital-reg-sidebar {
            order: -1;
            padding: 2rem;
          }
          .form-row {
            grid-template-columns: 1fr;
          }
          .form-group.full-width {
            grid-column: span 1;
          }
          .blood-inventory-grid {
            grid-template-columns: 1fr;
          }
        }

        @media (max-width: 768px) {
          .hospital-reg-page {
            padding: 1rem;
          }
          .hospital-reg-form-wrapper {
            padding: 1.5rem;
          }
          .hospital-reg-title {
            font-size: 1.5rem;
          }
        }
      `}</style>

      <div className="hospital-reg-page">
        <div className="hospital-reg-container">
          <div className="hospital-reg-form-wrapper">
            <div className="hospital-reg-header">
              <div className="hospital-reg-logo">
                <svg width="40" height="40" viewBox="0 0 48 48" fill="none">
                  <circle cx="24" cy="24" r="24" fill="white" />
                  <path d="M24 34l-2-1.8C15.6 26.6 12 23.2 12 19c0-3.08 2.42-5.5 5.5-5.5 1.74 0 3.41.81 4.5 2.09C23.09 14.31 24.76 13.5 26.5 13.5 29.58 13.5 32 15.92 32 19c0 4.2-3.6 7.6-10 12.2L24 34z" fill="#2196F3" />
                </svg>
              </div>
              <h1 className="hospital-reg-title">Hospital Registration</h1>
              <p className="hospital-reg-subtitle">Join our network of life-saving institutions</p>
            </div>

            <form onSubmit={handleSubmit}>
              {/* Organization Details */}
              <div className="form-section">
                <h3 className="section-title">🏢 Organization Details</h3>
                
                <div className="form-group">
                  <label>Hospital / Blood Bank Name *</label>
                  <input
                    type="text"
                    name="name"
                    value={formData.name}
                    onChange={handleInputChange}
                    placeholder="Enter official name"
                  />
                  {errors.name && <div className="error-text">{errors.name}</div>}
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Registration Number *</label>
                    <input
                      type="text"
                      name="regNumber"
                      value={formData.regNumber}
                      onChange={handleInputChange}
                      placeholder="Govt. Issued Reg No."
                    />
                    {errors.regNumber && <div className="error-text">{errors.regNumber}</div>}
                  </div>

                  <div className="form-group">
                    <label>Contact Number *</label>
                    <input
                      type="tel"
                      name="contact"
                      value={formData.contact}
                      onChange={handleInputChange}
                      placeholder="+94 77 123 4567"
                    />
                    {errors.contact && <div className="error-text">{errors.contact}</div>}
                  </div>
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Official Email *</label>
                    <input
                      type="email"
                      name="email"
                      value={formData.email}
                      onChange={handleInputChange}
                      placeholder="admin@org.com"
                    />
                    {errors.email && <div className="error-text">{errors.email}</div>}
                  </div>
                </div>

                <div className="form-group">
                  <label>Complete Address *</label>
                  <textarea
                    name="address"
                    value={formData.address}
                    onChange={handleInputChange}
                    placeholder="Street, City, State, Zip"
                    rows="3"
                  />
                  {errors.address && <div className="error-text">{errors.address}</div>}
                </div>
              </div>

              {/* Blood Type Inventory */}
              <div className="form-section">
                <h3 className="section-title">💧 Blood Type Inventory</h3>
                <p style={{ fontSize: '0.85rem', color: '#666', marginBottom: '1rem' }}>
                  Toggle blood types and enter available units
                </p>
                
                <div className="blood-inventory-grid">
                  {Object.entries(bloodTypes).map(([type, data]) => (
                    <div key={type} className="blood-type-item">
                      <button
                        type="button"
                        onClick={() => handleBloodTypeToggle(type)}
                        className="blood-type-toggle"
                        style={{
                          backgroundColor: data.enabled ? getBloodTypeColor(type) : '#E0E0E0',
                          color: data.enabled ? 'white' : '#666'
                        }}
                      >
                        {type}
                      </button>
                      <input
                        type="number"
                        value={data.amount}
                        onChange={(e) => handleBloodAmountChange(type, e.target.value)}
                        disabled={!data.enabled}
                        placeholder="Units"
                        className="blood-type-input"
                        style={{
                          backgroundColor: data.enabled ? 'white' : '#F5F5F5',
                          opacity: data.enabled ? 1 : 0.6
                        }}
                      />
                    </div>
                  ))}
                </div>
                {errors.bloodTypes && <div className="error-text">{errors.bloodTypes}</div>}
                
                <div className="form-group" style={{ marginTop: '1rem' }}>
                  <label>Total Storage Capacity (Units) *</label>
                  <input
                    type="number"
                    name="storageCapacity"
                    value={formData.storageCapacity}
                    onChange={handleInputChange}
                    placeholder="e.g., 500"
                  />
                  {errors.storageCapacity && <div className="error-text">{errors.storageCapacity}</div>}
                </div>
              </div>

              {/* Verification Documents Section */}
              <div className="doc-card">
                <div className="doc-header">
                  <span className="doc-icon">✓</span>
                  <h3 className="doc-title">Verification Documents</h3>
                </div>
                <p className="doc-subtitle">
                  These documents will be reviewed and verified by LifeLink Admin before approval.
                </p>
                
                <div className="doc-row">
                  <span className="doc-label">📄 Govt. Reg Certificate *</span>
                  <div>
                    <input
                      type="file"
                      id="govtCertificate"
                      accept=".pdf,.jpg,.jpeg,.png"
                      style={{ display: 'none' }}
                      onChange={(e) => handleFileChange(e, 'govtCertificate')}
                    />
                    <button
                      type="button"
                      onClick={() => document.getElementById('govtCertificate').click()}
                      className="upload-btn"
                    >
                      Upload
                    </button>
                    {formData.govtCertificate && (
                      <span className="file-name">{formData.govtCertificate.name}</span>
                    )}
                  </div>
                </div>
                {errors.govtCertificate && <div className="error-text">{errors.govtCertificate}</div>}
                
                <div className="divider" />
                
                <div className="doc-row">
                  <span className="doc-label">🏥 Medical License *</span>
                  <div>
                    <input
                      type="file"
                      id="medicalLicense"
                      accept=".pdf,.jpg,.jpeg,.png"
                      style={{ display: 'none' }}
                      onChange={(e) => handleFileChange(e, 'medicalLicense')}
                    />
                    <button
                      type="button"
                      onClick={() => document.getElementById('medicalLicense').click()}
                      className="upload-btn"
                    >
                      Upload
                    </button>
                    {formData.medicalLicense && (
                      <span className="file-name">{formData.medicalLicense.name}</span>
                    )}
                  </div>
                </div>
                {errors.medicalLicense && <div className="error-text">{errors.medicalLicense}</div>}
                
                <div className="divider" />
                
                <div className="doc-row">
                  <span className="doc-label">🆔 Authorized Person ID *</span>
                  <div>
                    <input
                      type="file"
                      id="authorizedId"
                      accept=".pdf,.jpg,.jpeg,.png"
                      style={{ display: 'none' }}
                      onChange={(e) => handleFileChange(e, 'authorizedId')}
                    />
                    <button
                      type="button"
                      onClick={() => document.getElementById('authorizedId').click()}
                      className="upload-btn"
                    >
                      Upload
                    </button>
                    {formData.authorizedId && (
                      <span className="file-name">{formData.authorizedId.name}</span>
                    )}
                  </div>
                </div>
                {errors.authorizedId && <div className="error-text">{errors.authorizedId}</div>}
              </div>

              {/* Account Security */}
              <div className="form-section">
                <h3 className="section-title">🔒 Account Security</h3>
                
                <div className="form-row">
                  <div className="form-group">
                    <label>Password * (min 8 characters)</label>
                    <div className="password-container">
                      <input
                        type={obscurePassword ? 'password' : 'text'}
                        name="password"
                        value={formData.password}
                        onChange={handleInputChange}
                        placeholder="Enter password"
                      />
                      <button
                        type="button"
                        onClick={() => setObscurePassword(!obscurePassword)}
                        className="password-toggle"
                      >
                        {obscurePassword ? '👁️' : '👁️‍🗨️'}
                      </button>
                    </div>
                    {errors.password && <div className="error-text">{errors.password}</div>}
                  </div>

                  <div className="form-group">
                    <label>Confirm Password *</label>
                    <div className="password-container">
                      <input
                        type={obscureConfirm ? 'password' : 'text'}
                        name="confirmPassword"
                        value={formData.confirmPassword}
                        onChange={handleInputChange}
                        placeholder="Re-enter password"
                      />
                      <button
                        type="button"
                        onClick={() => setObscureConfirm(!obscureConfirm)}
                        className="password-toggle"
                      >
                        {obscureConfirm ? '👁️' : '👁️‍🗨️'}
                      </button>
                    </div>
                    {errors.confirmPassword && <div className="error-text">{errors.confirmPassword}</div>}
                  </div>
                </div>
              </div>

              {/* Confirmation */}
              <div className="checkbox-row">
                <input
                  type="checkbox"
                  name="confirmed"
                  checked={formData.confirmed}
                  onChange={handleInputChange}
                />
                <label>
                  I confirm all details provided are valid and represent the official status of the organization.
                </label>
              </div>
              {errors.confirmed && <div className="error-text">{errors.confirmed}</div>}

              {errors.submit && <div className="submit-error">{errors.submit}</div>}

              <button type="submit" className="submit-btn" disabled={isLoading}>
                {isLoading ? 'Submitting...' : 'Register Institution →'}
              </button>

              <div className="login-footer">
                <p>
                  Already have an account?{' '}
                  <Link to="/login" className="register-link">Login here</Link>
                </p>
              </div>
            </form>
          </div>

          <div className="hospital-reg-sidebar">
            <div className="sidebar-content">
              <h2>Save Lives with LifeLink</h2>
              <p>Join thousands of donors, patients, and hospitals in our mission to make blood and organ donation more accessible.</p>
              <div className="stats-grid">
                <div className="stat">
                  <div className="stat-number">12K+</div>
                  <div className="stat-label">Donors</div>
                </div>
                <div className="stat">
                  <div className="stat-number">500+</div>
                  <div className="stat-label">Hospitals</div>
                </div>
                <div className="stat">
                  <div className="stat-number">8K+</div>
                  <div className="stat-label">Lives Saved</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default HospitalRegistration;