import React, { useState, useEffect } from 'react';
import AdminSidebar from "../components/AdminSidebar";
import { useNavigate } from 'react-router-dom';

const EmergencyAlerts = () => {
  const navigate = useNavigate();

  const [requests, setRequests] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [showModal, setShowModal] = useState(false);

  const fetchRequests = async () => {
    try {
      setIsLoading(true);
      setError('');

      const res = await fetch('http://localhost:8083/api/admin/emergency-requests');
      if (!res.ok) throw new Error(`HTTP error: ${res.status}`);

      const data = await res.json();

      // Filter only Urgent and Critical alerts
      const urgentCriticalOnly = (Array.isArray(data) ? data : []).filter(req => 
        req.urgencyLevel === 'Urgent' || req.urgencyLevel === 'Critical'
      );

      setRequests(urgentCriticalOnly);
    } catch (err) {
      console.error(err);
      setError("Failed to load emergency alerts.");
      setRequests([]);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchRequests();
  }, []);

  const handleAccept = async (id) => {
    if (!window.confirm("Accept this request and broadcast to donors?")) return;
    try {
      const res = await fetch(`http://localhost:8083/api/admin/emergency-requests/${id}/accept`, { 
        method: 'PUT' 
      });
      if (res.ok) {
        alert("✅ Request Accepted & Broadcasted!");
        fetchRequests();
        setShowModal(false);
      }
    } catch (err) {
      alert("Failed to accept request");
    }
  };

  const handleReject = async (id) => {
    if (!window.confirm("Reject this request?")) return;
    try {
      const res = await fetch(`http://localhost:8083/api/admin/emergency-requests/${id}/reject`, { 
        method: 'PUT' 
      });
      if (res.ok) {
        alert("Request Rejected");
        fetchRequests();
        setShowModal(false);
      }
    } catch (err) {
      alert("Failed to reject request");
    }
  };

  const openDetails = (req) => {
    setSelectedRequest(req);
    setShowModal(true);
  };

  return (
    <>
      <style>{`
        .emergency-alerts { 
          display: flex; 
          min-height: 100vh; 
          background: #F8F9FA; 
          font-family: 'Inter', system-ui, sans-serif; 
        }
        .main-content { flex: 1; overflow-y: auto; }
        .content-area { padding: 2rem; }

        .page-title { 
          font-size: 2rem; 
          font-weight: 800; 
          color: #1F2937; 
          margin-bottom: 0.5rem; 
        }
        .page-subtitle { 
          color: #6B7280; 
          margin-bottom: 2rem; 
        }

        .request-card {
          background: white;
          border-radius: 16px;
          padding: 1.5rem;
          margin-bottom: 1.2rem;
          box-shadow: 0 4px 15px rgba(0,0,0,0.07);
          border-left: 6px solid #EF4444;
          transition: all 0.2s;
        }
        .request-card:hover {
          transform: translateY(-3px);
          box-shadow: 0 8px 25px rgba(0,0,0,0.1);
        }

        .request-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          margin-bottom: 1rem;
        }

        .urgency {
          padding: 6px 16px;
          border-radius: 9999px;
          font-size: 0.85rem;
          font-weight: 700;
        }

        .actions { 
          display: flex; 
          gap: 10px; 
          margin-top: 1.2rem; 
        }

        .btn {
          padding: 10px 20px;
          border: none;
          border-radius: 10px;
          font-weight: 600;
          cursor: pointer;
          font-size: 0.95rem;
        }
        .btn-view { background: #3B82F6; color: white; }
        .btn-accept { background: #10B981; color: white; }
        .btn-reject { background: #EF4444; color: white; }

        /* Centered Clean Modal */
        .modal-overlay {
          position: fixed;
          inset: 0;
          background: rgba(0,0,0,0.65);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 1000;
        }

        .modal {
          background: white;
          border-radius: 20px;
          width: 90%;
          max-width: 520px;
          box-shadow: 0 20px 50px rgba(0,0,0,0.25);
          overflow: hidden;
        }

        .modal-header {
          padding: 1.8rem 2rem;
          border-bottom: 1px solid #E5E7EB;
          font-size: 1.5rem;
          font-weight: 700;
        }

        .modal-body {
          padding: 2rem;
          line-height: 1.75;
          font-size: 1.02rem;
        }

        .modal-body p {
          margin: 14px 0;
        }

        .modal-footer {
          padding: 1.5rem 2rem;
          background: #F8F9FA;
          display: flex;
          gap: 12px;
        }

        .modal-btn {
          flex: 1;
          padding: 14px;
          border: none;
          border-radius: 10px;
          font-weight: 700;
          font-size: 1rem;
          cursor: pointer;
        }

        .modal-btn-accept { background: #10B981; color: white; }
        .modal-btn-reject { background: #EF4444; color: white; }
        .modal-btn-close { background: #6B7280; color: white; }
      `}</style>

      <div className="emergency-alerts">
        <AdminSidebar 
          user={{ initials: "SJ", name: "Sarah Jenkins", role: "System Director" }}
          onLogout={() => { localStorage.clear(); navigate('/login'); }}
        />

        <main className="main-content">
          <div className="content-area">
            <h1 className="page-title">Emergency Alerts</h1>
            <p className="page-subtitle">Urgent and Critical patient blood/organ requests</p>

            {isLoading && <div style={{textAlign:'center', padding:'100px', color:'#6B7280'}}>Loading urgent alerts...</div>}
            {error && <div style={{textAlign:'center', padding:'60px', color:'#EF4444'}}>{error}</div>}

            {!isLoading && !error && requests.length === 0 && (
              <div style={{textAlign:'center', padding:'120px', color:'#9CA3AF', fontSize:'1.1rem'}}>
                No Urgent or Critical emergency requests at the moment.
              </div>
            )}

            {requests.map((req) => (
              <div key={req._id} className="request-card">
                <div className="request-header">
                  <div>
                    <h3>{req.patientName}</h3>
                    <p style={{color: '#6B7280', marginTop: '4px'}}>
                      {req.hospitalName} • {req.requestType}
                    </p>
                  </div>
                  <span className="urgency" style={{ 
                    background: req.urgencyLevel === 'Urgent' || req.urgencyLevel === 'Critical' 
                      ? '#FEE2E2' 
                      : '#FEF3C7',
                    color: req.urgencyLevel === 'Urgent' || req.urgencyLevel === 'Critical' 
                      ? '#EF4444' 
                      : '#D97706'
                  }}>
                    {req.urgencyLevel}
                  </span>
                </div>

                <p><strong>Requirement:</strong> {req.bloodGroup || req.organType} — {req.unitsNeeded} units</p>
                <p><strong>Status:</strong> <span style={{fontWeight: '600'}}>{req.status}</span></p>

                <div className="actions">
                  <button className="btn btn-view" onClick={() => openDetails(req)}>
                    View Details
                  </button>
                  {req.status === 'Pending' && (
                    <>
                      <button className="btn btn-accept" onClick={() => handleAccept(req._id)}>
                        Accept & Broadcast
                      </button>
                      <button className="btn btn-reject" onClick={() => handleReject(req._id)}>
                        Reject
                      </button>
                    </>
                  )}
                </div>
              </div>
            ))}
          </div>
        </main>
      </div>

      {/* Clean Centered Modal */}
      {showModal && selectedRequest && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              Request Details
            </div>

            <div className="modal-body">
              <p><strong>Patient:</strong> {selectedRequest.patientName}</p>
              <p><strong>Hospital:</strong> {selectedRequest.hospitalName}</p>
              <p><strong>Request Type:</strong> {selectedRequest.requestType}</p>
              <p><strong>Blood Group:</strong> {selectedRequest.bloodGroup}</p>
              <p><strong>Units Needed:</strong> {selectedRequest.unitsNeeded}</p>
              <p><strong>Urgency:</strong> {selectedRequest.urgencyLevel}</p>
              <p><strong>Notes:</strong> {selectedRequest.additionalNotes || "No additional notes"}</p>
              <p><strong>Status:</strong> {selectedRequest.status}</p>
            </div>

            <div className="modal-footer">
              {selectedRequest.status === 'Pending' && (
                <>
                  <button 
                    className="modal-btn modal-btn-accept" 
                    onClick={() => handleAccept(selectedRequest._id)}
                  >
                    Accept & Broadcast
                  </button>
                  <button 
                    className="modal-btn modal-btn-reject" 
                    onClick={() => handleReject(selectedRequest._id)}
                  >
                    Reject Request
                  </button>
                </>
              )}
              <button 
                className="modal-btn modal-btn-close" 
                onClick={() => setShowModal(false)}
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default EmergencyAlerts;