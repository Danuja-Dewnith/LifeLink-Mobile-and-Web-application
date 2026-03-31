import React, { useState, useEffect } from 'react';
import AdminSidebar from "../components/AdminSidebar";
import { useNavigate } from 'react-router-dom';

const HospitalManagement = () => {
  const navigate = useNavigate();

  const [hospitals, setHospitals] = useState([]);
  const [filteredHospitals, setFilteredHospitals] = useState([]);
  const [activeTab, setActiveTab] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedHospital, setSelectedHospital] = useState(null);
  const [showModal, setShowModal] = useState(false);

  // Fetch hospitals
  useEffect(() => {
    const fetchHospitals = async () => {
      try {
        setIsLoading(true);
        const res = await fetch('http://localhost:8083/api/admin/hospitals');
        if (!res.ok) throw new Error('Failed to fetch');
        const data = await res.json();
        setHospitals(data);
      } catch (err) {
        console.error(err);
        setError("Could not load hospitals from server.");
      } finally {
        setIsLoading(false);
      }
    };

    fetchHospitals();
  }, []);

  // Filter logic
  useEffect(() => {
    let result = [...hospitals];

    if (activeTab === 'verified') {
      result = result.filter(h => h.isVerified === true);
    } else if (activeTab === 'pending') {
      result = result.filter(h => h.isVerified === false);
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      result = result.filter(h =>
        h.name?.toLowerCase().includes(q) ||
        h.email?.toLowerCase().includes(q) ||
        h.regNumber?.toLowerCase().includes(q)
      );
    }

    setFilteredHospitals(result);
  }, [hospitals, activeTab, searchQuery]);

  const handleVerify = async (id) => {
    if (!window.confirm("Mark this hospital as verified?")) return;
    try {
      const res = await fetch(`http://localhost:8083/api/admin/hospitals/${id}/verify`, { method: 'PUT' });
      if (res.ok) {
        setHospitals(prev => prev.map(h => h._id === id ? { ...h, isVerified: true } : h));
        alert("✅ Hospital verified successfully!");
      }
    } catch (err) {
      alert("Failed to verify hospital");
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Delete this hospital permanently?")) return;
    try {
      const res = await fetch(`http://localhost:8083/api/admin/hospitals/${id}`, { method: 'DELETE' });
      if (res.ok) {
        setHospitals(prev => prev.filter(h => h._id !== id));
        alert("Hospital deleted");
      }
    } catch (err) {
      alert("Failed to delete");
    }
  };

  const openDetails = (hospital) => {
    setSelectedHospital(hospital);
    setShowModal(true);
  };

  const formatDate = (date) => new Date(date).toLocaleDateString('en-US', { 
    year: 'numeric', month: 'short', day: 'numeric' 
  });

  const handleLogout = () => {
    localStorage.clear();
    navigate('/login');
  };

  return (
    <>
      <style>{`
        .hospital-management {
          display: flex;
          min-height: 100vh;
          background: #F8F9FA;
          font-family: 'Inter', system-ui, sans-serif;
        }
        .main-content { flex: 1; overflow-y: auto; }
        .content-area { padding: 2rem; }

        .page-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 2rem;
        }
        .page-title { font-size: 2rem; font-weight: 800; color: #1F2937; }
        .page-subtitle { color: #6B7280; font-size: 1.05rem; }

        .stats-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
          gap: 1.5rem;
          margin-bottom: 2.5rem;
        }
        .stat-card {
          background: white;
          padding: 1.75rem;
          border-radius: 16px;
          box-shadow: 0 4px 12px rgba(0,0,0,0.06);
          text-align: center;
        }
        .stat-number { font-size: 3rem; font-weight: 800; margin: 0.5rem 0; }
        .stat-label { color: #6B7280; font-size: 0.95rem; font-weight: 500; }

        .controls {
          display: flex;
          gap: 1rem;
          margin-bottom: 1.5rem;
          flex-wrap: wrap;
          align-items: center;
        }
        .search-bar {
          flex: 1;
          min-width: 320px;
          position: relative;
        }
        .search-bar input {
          width: 100%;
          padding: 14px 20px 14px 48px;
          border: 1px solid #E5E7EB;
          border-radius: 12px;
          font-size: 1rem;
          background: white;
        }
        .search-icon {
          position: absolute;
          left: 18px;
          top: 50%;
          transform: translateY(-50%);
          color: #9CA3AF;
          font-size: 1.2rem;
        }

        .tabs {
          display: flex;
          background: white;
          border-radius: 12px;
          padding: 6px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }
        .tab-btn {
          padding: 10px 24px;
          border: none;
          background: transparent;
          border-radius: 10px;
          font-weight: 600;
          font-size: 0.95rem;
          cursor: pointer;
        }
        .tab-btn.active {
          background: #2563EB;
          color: white;
        }

        .table-container {
          background: white;
          border-radius: 16px;
          overflow: hidden;
          box-shadow: 0 4px 15px rgba(0,0,0,0.07);
        }
        table { width: 100%; border-collapse: collapse; }
        th {
          background: #F8F9FA;
          padding: 1rem 1.5rem;
          text-align: left;
          font-weight: 600;
          color: #6B7280;
          font-size: 0.78rem;
          text-transform: uppercase;
        }
        td {
          padding: 1.1rem 1.5rem;
          border-bottom: 1px solid #E5E7EB;
          vertical-align: middle;
        }

        .hospital-cell {
          display: flex;
          align-items: center;
          gap: 12px;
        }

        /* Small & Clean Status Badges */
        .status-badge {
          padding: 4px 14px;
          border-radius: 9999px;
          font-size: 0.78rem;
          font-weight: 600;
          display: inline-flex;
          align-items: center;
          gap: 5px;
        }
        .verified { background: #D1FAE5; color: #059669; }
        .pending { background: #FEF3C7; color: #D97706; }

        /* Compact Single-Line Action Buttons */
        .actions-cell {
          display: flex;
          gap: 6px;
          flex-wrap: nowrap;
          white-space: nowrap;
        }
        .action-btn {
          padding: 5px 14px;
          border: none;
          border-radius: 7px;
          font-weight: 600;
          font-size: 0.8rem;
          cursor: pointer;
          transition: all 0.2s;
        }
        .action-btn:hover {
          transform: translateY(-1px);
          box-shadow: 0 3px 8px rgba(0,0,0,0.1);
        }
        .view-btn { background: #3B82F6; color: white; }
        .verify-btn { background: #10B981; color: white; }
        .delete-btn { background: #EF4444; color: white; }
      `}</style>

      <div className="hospital-management">
        <AdminSidebar 
          user={{ initials: "LA", name: "Director", role: "System Director" }}
          onLogout={() => {
            localStorage.clear();
            navigate('/login');
          }}
        />

        <main className="main-content">
          <div className="content-area">
            <div className="page-header">
              <div>
                <h1 className="page-title">Hospital Management</h1>
                <p className="page-subtitle">Manage and verify all registered hospitals & blood banks</p>
              </div>
            </div>

            {/* Stats */}
            <div className="stats-grid">
              <div className="stat-card">
                <div className="stat-label">Total Hospitals</div>
                <div className="stat-number" style={{color: '#1F2937'}}>{hospitals.length}</div>
              </div>
              <div className="stat-card">
                <div className="stat-label">Verified</div>
                <div className="stat-number" style={{color: '#10B981'}}>
                  {hospitals.filter(h => h.isVerified).length}
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-label">Pending Verification</div>
                <div className="stat-number" style={{color: '#F59E0B'}}>
                  {hospitals.filter(h => !h.isVerified).length}
                </div>
              </div>
            </div>

            {/* Controls */}
            <div className="controls">
              <div className="search-bar">
                <span className="search-icon">🔍</span>
                <input
                  type="text"
                  placeholder="Search by name, email, or reg number..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>

              <div className="tabs">
                <button className={`tab-btn ${activeTab === 'all' ? 'active' : ''}`} onClick={() => setActiveTab('all')}>All</button>
                <button className={`tab-btn ${activeTab === 'verified' ? 'active' : ''}`} onClick={() => setActiveTab('verified')}>Verified</button>
                <button className={`tab-btn ${activeTab === 'pending' ? 'active' : ''}`} onClick={() => setActiveTab('pending')}>Pending</button>
              </div>
            </div>

            {/* Table */}
            <div className="table-container">
              {isLoading ? (
                <div style={{padding: '80px', textAlign: 'center', color: '#6B7280'}}>Loading hospitals...</div>
              ) : error ? (
                <div style={{padding: '80px', textAlign: 'center', color: '#EF4444'}}>{error}</div>
              ) : (
                <table>
                  <thead>
                    <tr>
                      <th>HOSPITAL NAME</th>
                      <th>REG NUMBER</th>
                      <th>EMAIL</th>
                      <th>CONTACT</th>
                      <th>JOINED</th>
                      <th>STATUS</th>
                      <th>ACTIONS</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredHospitals.map(hospital => (
                      <tr key={hospital._id}>
                        <td>
                          <div className="hospital-cell">
                            <img 
                              src={hospital.avatarUrl || 'https://via.placeholder.com/48?text=H'} 
                              alt={hospital.name}
                              style={{width: '46px', height: '46px', borderRadius: '10px', objectFit: 'cover'}}
                              onError={(e) => e.target.src = 'https://via.placeholder.com/46?text=H'}
                            />
                            <div>
                              <div style={{fontWeight: 600, color: '#1F2937'}}>{hospital.name}</div>
                            </div>
                          </div>
                        </td>
                        <td style={{fontFamily: 'monospace'}}>{hospital.regNumber}</td>
                        <td>{hospital.email}</td>
                        <td>{hospital.contact}</td>
                        <td>{formatDate(hospital.createdAt)}</td>
                        <td>
                          <span className={`status-badge ${hospital.isVerified ? 'verified' : 'pending'}`}>
                            {hospital.isVerified ? 'Verified' : 'Pending'}
                          </span>
                        </td>
                        <td>
                          <div className="actions-cell">
                            <button className="action-btn view-btn" onClick={() => openDetails(hospital)}>View</button>
                            
                            {!hospital.isVerified && (
                              <button className="action-btn verify-btn" onClick={() => handleVerify(hospital._id)}>
                                Verify
                              </button>
                            )}
                            
                            <button className="action-btn delete-btn" onClick={() => handleDelete(hospital._id)}>
                              Delete
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}

                    {filteredHospitals.length === 0 && (
                      <tr>
                        <td colSpan="7" style={{textAlign: 'center', padding: '60px', color: '#9CA3AF'}}>
                          No hospitals found
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        </main>
      </div>

      {/* Modal */}
      {showModal && selectedHospital && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h2 style={{margin: 0}}>{selectedHospital.name}</h2>
              <button onClick={() => setShowModal(false)} style={{fontSize: '1.8rem', background: 'none', border: 'none', cursor: 'pointer'}}>×</button>
            </div>
            <div style={{padding: '2rem', lineHeight: '1.7'}}>
              <p><strong>Registration Number:</strong> {selectedHospital.regNumber}</p>
              <p><strong>Email:</strong> {selectedHospital.email}</p>
              <p><strong>Contact:</strong> {selectedHospital.contact}</p>
              <p><strong>Address:</strong> {selectedHospital.address}</p>
              <p><strong>Storage Capacity:</strong> {selectedHospital.storageCapacity} units</p>
              <p><strong>Status:</strong> {selectedHospital.isVerified ? 'Verified' : 'Pending Verification'}</p>
              <p><strong>Joined Date:</strong> {formatDate(selectedHospital.createdAt)}</p>

              {selectedHospital.documents && Object.keys(selectedHospital.documents).length > 0 && (
                <div style={{marginTop: '2rem'}}>
                  <h3>Documents</h3>
                  <ul style={{listStyle: 'none', padding: 0}}>
                    {Object.entries(selectedHospital.documents).map(([key, path]) => 
                      path && (
                        <li key={key} style={{marginBottom: '8px'}}>
                          {key.replace(/([A-Z])/g, ' $1').trim()} → 
                          <a href={`http://localhost:8083/${path}`} target="_blank" rel="noopener noreferrer" style={{color: '#2563EB', marginLeft: '8px'}}>
                            View File
                          </a>
                        </li>
                      )
                    )}
                  </ul>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default HospitalManagement;