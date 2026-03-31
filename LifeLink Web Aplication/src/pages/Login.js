import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

const Login = () => {
  const navigate = useNavigate();
  const [userType, setUserType] = useState('hospital'); // 'hospital' or 'admin'
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    rememberMe: false
  });
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
    if (error) setError('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    const endpoint = userType === 'admin'
      ? 'http://localhost:8083/api/admin/login'
      : 'http://localhost:8083/api/hospitals/login';

    try {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: formData.email,
          password: formData.password,
        }),
      });

      const data = await response.json();

      if (response.ok && data.success) {
        // ✅ Always save common fields
        localStorage.setItem("userType", userType);
        localStorage.setItem("email", data.email);

        if (userType === 'admin') {
          localStorage.setItem("adminId", data.adminId);
          localStorage.setItem("name", data.fullName);
          localStorage.setItem("role", data.role);
          localStorage.setItem("jwt_token", data.token); 
          alert(`✅ Welcome back, ${data.fullName}!`);
          navigate("/admin/dashboard");
        } else {
          // FIXED: Make sure hospitalId and token are always saved
          localStorage.setItem("hospitalId", data.hospitalId || data._id || data.id);
          localStorage.setItem("name", data.hospitalName || data.name || data.fullName);
          localStorage.setItem("role", "hospital");
          localStorage.setItem("jwt_token", data.token); 

          // ✅ Also save extra hospital info for profile use
          localStorage.setItem("regNumber", data.regNumber || '');
          localStorage.setItem("contact", data.contact || '');
          localStorage.setItem("storageCapacity", data.storageCapacity || '');
          localStorage.setItem("isVerified", data.isVerified || false);

          alert(`✅ Welcome back, ${data.hospitalName || data.name || 'Hospital'}!`);
          navigate("/bloodbank/dashboard");
        }
      } else {
        setError(data.message || "Invalid email or password");
      }
    } catch (err) {
      console.error(err);
      setError("Cannot connect to server. Make sure backend is running on port 8083.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      <style>{`
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        .login-page {
          min-height: calc(100vh - 80px);
          background: linear-gradient(135deg, #E3F2FD 0%, #F5F5F5 100%);
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 2rem;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', sans-serif;
        }
        .login-container {
          max-width: 1000px;
          width: 100%;
          display: grid;
          grid-template-columns: 1fr 1fr;
          background: white;
          border-radius: 20px;
          overflow: hidden;
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
        }
        .login-card {
          padding: 3rem;
          display: flex;
          flex-direction: column;
          justify-content: center;
        }
        .login-header {
          text-align: center;
          margin-bottom: 2.5rem;
        }
        .login-logo {
          width: 72px;
          height: 72px;
          margin: 0 auto 1.5rem;
          animation: pulse 2s ease-in-out infinite;
        }
        @keyframes pulse {
          0%, 100% { transform: scale(1); }
          50% { transform: scale(1.05); }
        }
        .login-title {
          font-size: 2rem;
          font-weight: 800;
          color: #1a1a1a;
          margin-bottom: 0.5rem;
        }
        .login-subtitle {
          font-size: 1rem;
          color: #666;
        }
        .error-message {
          background: #FFEBEE;
          color: #C62828;
          padding: 0.875rem 1rem;
          border-radius: 10px;
          font-size: 0.875rem;
          font-weight: 600;
          border-left: 4px solid #C62828;
          animation: shake 0.3s;
          margin-bottom: 1rem;
        }
        @keyframes shake {
          0%, 100% { transform: translateX(0); }
          25% { transform: translateX(-5px); }
          75% { transform: translateX(5px); }
        }
        .login-form {
          display: flex;
          flex-direction: column;
          gap: 1.5rem;
        }
        .login-form .form-group {
          display: flex;
          flex-direction: column;
        }
        .login-form .form-group label {
          font-size: 0.875rem;
          font-weight: 600;
          color: #333;
          margin-bottom: 0.5rem;
        }
        .login-form .form-group input {
          padding: 0.875rem 1rem;
          border: 2px solid #E0E0E0;
          border-radius: 10px;
          font-size: 1rem;
          color: #333;
          transition: all 0.3s;
          font-family: inherit;
        }
        .login-form .form-group input:focus {
          outline: none;
          border-color: #2196F3;
          box-shadow: 0 0 0 3px rgba(33, 150, 243, 0.1);
        }
        .form-options {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin: -0.5rem 0;
        }
        .remember-label {
          display: flex;
          align-items: center;
          gap: 0.5rem;
          cursor: pointer;
          font-size: 0.875rem;
          color: #666;
        }
        .remember-label input[type="checkbox"] {
          width: 18px;
          height: 18px;
          cursor: pointer;
          accent-color: #2196F3;
        }
        .forgot-link {
          font-size: 0.875rem;
          color: #2196F3;
          text-decoration: none;
          font-weight: 600;
        }
        .forgot-link:hover {
          color: #1976D2;
          text-decoration: underline;
        }
        .login-btn {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 0.75rem;
          padding: 1rem;
          background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%);
          color: white;
          border: none;
          border-radius: 12px;
          font-weight: 700;
          font-size: 1.125rem;
          cursor: pointer;
          transition: all 0.3s;
          margin-top: 1rem;
        }
        .login-btn:hover:not(:disabled) {
          transform: translateY(-2px);
          box-shadow: 0 8px 20px rgba(33, 150, 243, 0.4);
        }
        .login-btn:disabled {
          opacity: 0.7;
          cursor: not-allowed;
        }
        .login-footer {
          text-align: center;
          margin-top: 2rem;
          padding-top: 2rem;
          border-top: 1px solid #E0E0E0;
        }
        .login-footer p {
          font-size: 0.875rem;
          color: #666;
        }
        .register-link {
          color: #2196F3;
          font-weight: 600;
          text-decoration: none;
          cursor: pointer;
        }
        .register-link:hover {
          color: #1976D2;
          text-decoration: underline;
        }
        .login-sidebar {
          background: linear-gradient(135deg, #2196F3 0%, #1565C0 100%);
          padding: 3rem;
          display: flex;
          align-items: center;
          color: white;
        }
        .sidebar-content h2 {
          font-size: 2rem;
          font-weight: 800;
          margin-bottom: 1rem;
          line-height: 1.3;
        }
        .sidebar-content p {
          font-size: 1rem;
          line-height: 1.6;
          opacity: 0.95;
          margin-bottom: 2.5rem;
        }
        .stats-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 1.5rem;
        }
        .stat {
          background: rgba(255, 255, 255, 0.15);
          backdrop-filter: blur(10px);
          padding: 1.5rem 1rem;
          border-radius: 12px;
          text-align: center;
          border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .stat-number {
          font-size: 1.5rem;
          font-weight: 800;
          margin-bottom: 0.25rem;
        }
        .stat-label {
          font-size: 0.75rem;
          opacity: 0.9;
          font-weight: 600;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }
        @media (max-width: 968px) {
          .login-container { grid-template-columns: 1fr; }
          .login-sidebar { order: -1; padding: 2rem; }
          .sidebar-content h2 { font-size: 1.5rem; }
          .stats-grid { grid-template-columns: repeat(3, 1fr); gap: 1rem; }
          .stat { padding: 1rem 0.5rem; }
          .stat-number { font-size: 1.25rem; }
          .stat-label { font-size: 0.65rem; }
        }
        @media (max-width: 768px) {
          .login-page { padding: 1rem; }
          .login-card { padding: 2rem 1.5rem; }
          .login-title { font-size: 1.5rem; }
          .login-btn { font-size: 1rem; }
          .stats-grid { gap: 0.75rem; }
        }
      `}</style>
      <div className="login-page">
        <div className="login-container">
          <div className="login-card">
            <div className="login-header">
              <div className="login-logo">
                <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
                  <circle cx="24" cy="24" r="24" fill="#2196F3" />
                  <path d="M24 34l-2-1.8C15.6 26.6 12 23.2 12 19c0-3.08 2.42-5.5 5.5-5.5 1.74 0 3.41.81 4.5 2.09C23.09 14.31 24.76 13.5 26.5 13.5 29.58 13.5 32 15.92 32 19c0 4.2-3.6 7.6-10 12.2L24 34z" fill="white" />
                </svg>
              </div>
              <h1 className="login-title">
                {userType === 'admin' ? 'Admin Login' : 'Hospital Login'}
              </h1>
              <p className="login-subtitle">
                {userType === 'admin'
                  ? 'Access the LifeLink administration panel'
                  : 'Login to manage your hospital account'}
              </p>
            </div>
            {/* Toggle: Hospital / Admin */}
            <div style={{
              display: 'flex',
              marginBottom: '2rem',
              borderRadius: '12px',
              overflow: 'hidden',
              border: '2px solid #E0E0E0'
            }}>
              <button
                type="button"
                onClick={() => { setUserType('hospital'); setError(''); }}
                style={{
                  flex: 1,
                  padding: '12px',
                  fontWeight: '600',
                  background: userType === 'hospital' ? '#2196F3' : 'white',
                  color: userType === 'hospital' ? 'white' : '#333',
                  border: 'none',
                  cursor: 'pointer',
                  transition: 'all 0.3s'
                }}
              >
                Hospital
              </button>
              <button
                type="button"
                onClick={() => { setUserType('admin'); setError(''); }}
                style={{
                  flex: 1,
                  padding: '12px',
                  fontWeight: '600',
                  background: userType === 'admin' ? '#2196F3' : 'white',
                  color: userType === 'admin' ? 'white' : '#333',
                  border: 'none',
                  cursor: 'pointer',
                  transition: 'all 0.3s'
                }}
              >
                Admin
              </button>
            </div>
            <form onSubmit={handleSubmit} className="login-form">
              {error && <div className="error-message">{error}</div>}
              <div className="form-group">
                <label htmlFor="email">Email Address *</label>
                <input
                  type="email"
                  id="email"
                  name="email"
                  placeholder="Enter your email"
                  value={formData.email}
                  onChange={handleInputChange}
                  required
                  disabled={isLoading}
                />
              </div>
              <div className="form-group">
                <label htmlFor="password">Password *</label>
                <input
                  type="password"
                  id="password"
                  name="password"
                  placeholder="Enter your password"
                  value={formData.password}
                  onChange={handleInputChange}
                  required
                  disabled={isLoading}
                />
              </div>
              <div className="form-options">
                <label className="remember-label">
                  <input
                    type="checkbox"
                    name="rememberMe"
                    checked={formData.rememberMe}
                    onChange={handleInputChange}
                    disabled={isLoading}
                  />
                  <span>Remember me</span>
                </label>
                <Link to="/forgot-password" className="forgot-link">
                  Forgot Password?
                </Link>
              </div>
              <button
                type="submit"
                className="login-btn"
                disabled={isLoading}
              >
                <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                  <path d="M10 0C4.477 0 0 4.477 0 10s4.477 10 10 10 10-4.477 10-10S15.523 0 10 0zm-1 15l-5-5 1.41-1.41L9 12.17l7.59-7.59L18 6l-9 9z" />
                </svg>
                {isLoading ? 'Logging in...' : `Login as ${userType === 'admin' ? 'Admin' : 'Hospital'}`}
              </button>
            </form>
            <div className="login-footer">
              <p>
                Don't have an account?{" "}
                <Link to="/register/hospital" className="register-link">
                  Register Hospital
                </Link>
              </p>
            </div>
          </div>
          <div className="login-sidebar">
            <div className="sidebar-content">
              <h2>Save Lives with LifeLink</h2>
              <p>Join thousands of donors, patients, and hospitals in our mission to make blood and organ donation more accessible.</p>
              <div className="stats-grid">
                <div className="stat">
                  <div className="stat-number">12K+</div>
                  <div className="stat-label">DONORS</div>
                </div>
                <div className="stat">
                  <div className="stat-number">500+</div>
                  <div className="stat-label">HOSPITALS</div>
                </div>
                <div className="stat">
                  <div className="stat-number">8K+</div>
                  <div className="stat-label">LIVES SAVED</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Login;