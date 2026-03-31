import React, { useState, useEffect } from 'react';
import AdminSidebar from "../components/AdminSidebar";
import { useNavigate } from 'react-router-dom';

const UserManagement = () => {
  const navigate = useNavigate();

  const [users, setUsers] = useState([]);
  const [stats, setStats] = useState({
    totalUsers: 0,
    activeUsers: 0,
    pendingApprovals: 0,
    deactivated: 0
  });
  const [searchQuery, setSearchQuery] = useState("");
  const [roleFilter, setRoleFilter] = useState("All Roles");
  const [statusFilter, setStatusFilter] = useState("All Status");
  const [isLoading, setIsLoading] = useState(true);

  const fetchUsers = async () => {
    try {
      setIsLoading(true);
      const res = await fetch('http://localhost:8083/api/admin/users');
      
      if (!res.ok) throw new Error('Failed to fetch');

      const data = await res.json();

      // Filter out Admin users from the list
      const filteredUsers = (data.users || []).filter(user => 
        user.role !== 'Admin'
      );

      setUsers(filteredUsers);
      setStats({
        totalUsers: data.stats.totalUsers || 0,
        activeUsers: data.stats.activeUsers || 0,
        pendingApprovals: data.stats.pendingApprovals || 0,
        deactivated: data.stats.deactivated || 0
      });
    } catch (err) {
      console.error("Failed to fetch users:", err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  // Filter users (Donor + Patient only)
  const filteredUsers = users.filter(user => {
    const matchSearch = !searchQuery || 
      user.fullName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      user.email?.toLowerCase().includes(searchQuery.toLowerCase());

    const matchRole = roleFilter === "All Roles" || user.role === roleFilter;
    const matchStatus = statusFilter === "All Status" || 
      (statusFilter === "Active" && user.isVerified) ||
      (statusFilter === "Inactive" && !user.isVerified);

    return matchSearch && matchRole && matchStatus;
  });

  const refreshData = () => fetchUsers();

  const handleDeactivate = async (id) => {
    if (!window.confirm("Deactivate this user?")) return;
    try {
      const res = await fetch(`http://localhost:8083/api/admin/users/${id}/status`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isVerified: false })
      });
      if (res.ok) {
        alert("User deactivated successfully");
        refreshData();
      }
    } catch (err) {
      alert("Failed to deactivate");
    }
  };

  const handleActivate = async (id) => {
    try {
      const res = await fetch(`http://localhost:8083/api/admin/users/${id}/status`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isVerified: true })
      });
      if (res.ok) {
        alert("User activated successfully");
        refreshData();
      }
    } catch (err) {
      alert("Failed to activate");
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Delete this user permanently?")) return;
    try {
      const res = await fetch(`http://localhost:8083/api/admin/users/${id}`, { method: 'DELETE' });
      if (res.ok) {
        alert("User deleted successfully");
        refreshData();
      }
    } catch (err) {
      alert("Failed to delete");
    }
  };

  const formatDate = (date) => {
    return new Date(date).toLocaleDateString('en-US', { 
      month: 'short', day: 'numeric', year: 'numeric' 
    });
  };

  const handleLogout = () => {
    localStorage.clear();
    navigate('/login');
  };

  return (
    <>
      <style>{`
        .user-management {
          display: flex;
          min-height: 100vh;
          background: #F8F9FA;
          font-family: 'Inter', system-ui, sans-serif;
        }
        .main-content { flex: 1; overflow-y: auto; }
        .content-area { padding: 2rem; }

        .page-title { font-size: 2rem; font-weight: 800; color: #1F2937; }

        .stats-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
          gap: 1.5rem;
          margin-bottom: 2.5rem;
        }
        .stat-card {
          background: white;
          padding: 1.75rem;
          border-radius: 16px;
          box-shadow: 0 4px 12px rgba(0,0,0,0.06);
        }
        .stat-value {
          font-size: 2.6rem;
          font-weight: 800;
          margin: 0.5rem 0;
        }

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
          padding: 14px 20px 14px 50px;
          border: 1px solid #E5E7EB;
          border-radius: 12px;
          font-size: 1rem;
        }
        .search-icon {
          position: absolute;
          left: 18px;
          top: 50%;
          transform: translateY(-50%);
          color: #9CA3AF;
          font-size: 1.3rem;
        }

        .filter-select {
          padding: 12px 16px;
          border: 1px solid #E5E7EB;
          border-radius: 10px;
          background: white;
          min-width: 160px;
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
          padding: 1.1rem 1.5rem;
          text-align: left;
          font-weight: 600;
          color: #6B7280;
          font-size: 0.82rem;
          text-transform: uppercase;
        }
        td {
          padding: 1.2rem 1.5rem;
          border-bottom: 1px solid #E5E7EB;
        }

        .user-cell {
          display: flex;
          align-items: center;
          gap: 12px;
        }
        .role-chip {
          padding: 5px 14px;
          border-radius: 9999px;
          font-size: 0.82rem;
          font-weight: 600;
        }
        .status-dot {
          width: 9px;
          height: 9px;
          border-radius: 50%;
          display: inline-block;
          margin-right: 8px;
        }

        .actions-cell {
          display: flex;
          gap: 6px;
          flex-wrap: nowrap;
        }
        .action-btn {
          padding: 6px 14px;
          border: none;
          border-radius: 7px;
          font-weight: 600;
          font-size: 0.82rem;
          cursor: pointer;
          transition: all 0.2s;
        }
        .action-btn:hover {
          transform: translateY(-1px);
          box-shadow: 0 4px 10px rgba(0,0,0,0.12);
        }
        .edit-btn { background: #EFF6FF; color: #2563EB; }
        .deactivate-btn { background: #FEF2F2; color: #EF4444; }
        .delete-btn { background: #FEE2E2; color: #EF4444; }
      `}</style>

      <div className="user-management">
        <AdminSidebar 
          user={{ initials: "SJ", name: "Sarah Jenkins", role: "System Director" }}
          onLogout={handleLogout}
        />

        <main className="main-content">
          <div className="content-area">
            <div>
              <h1 className="page-title">User Management</h1>
              <p style={{ color: '#6B7280' }}>Configure user roles and system permissions</p>
            </div>

            {/* Stats Cards */}
            <div className="stats-grid">
              <div className="stat-card">
                <div style={{ fontSize: '0.95rem', color: '#6B7280' }}>TOTAL USERS</div>
                <div className="stat-value" style={{ color: '#1F2937' }}>{stats.totalUsers}</div>
              </div>
              <div className="stat-card">
                <div style={{ fontSize: '0.95rem', color: '#6B7280' }}>ACTIVE USERS</div>
                <div className="stat-value" style={{ color: '#10B981' }}>{stats.activeUsers}</div>
              </div>
              <div className="stat-card">
                <div style={{ fontSize: '0.95rem', color: '#6B7280' }}>PENDING APPROVALS</div>
                <div className="stat-value" style={{ color: '#F59E0B' }}>{stats.pendingApprovals}</div>
              </div>
              <div className="stat-card">
                <div style={{ fontSize: '0.95rem', color: '#6B7280' }}>DEACTIVATED</div>
                <div className="stat-value">{stats.deactivated}</div>
              </div>
            </div>

            {/* Search & Filters */}
            <div className="controls">
              <div className="search-bar">
                <span className="search-icon">🔍</span>
                <input
                  type="text"
                  placeholder="Search by name or email..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>

              <select className="filter-select" value={roleFilter} onChange={(e) => setRoleFilter(e.target.value)}>
                <option>All Roles</option>
                <option>Donor</option>
                <option>Patient</option>
              </select>

              <select className="filter-select" value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
                <option>All Status</option>
                <option>Active</option>
                <option>Inactive</option>
              </select>
            </div>

            {/* Table */}
            <div className="table-container">
              {isLoading ? (
                <div style={{ padding: '60px', textAlign: 'center', color: '#6B7280' }}>Loading users...</div>
              ) : (
                <table>
                  <thead>
                    <tr>
                      <th>USER</th>
                      <th>EMAIL</th>
                      <th>ROLE</th>
                      <th>JOINED</th>
                      <th>STATUS</th>
                      <th>ACTIONS</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredUsers.map(user => (
                      <tr key={user._id}>
                        <td>
                          <div className="user-cell">
                            <img 
                              src={user.avatarUrl || 'https://via.placeholder.com/46?text=U'} 
                              alt={user.fullName}
                              style={{ width: '46px', height: '46px', borderRadius: '50%', objectFit: 'cover' }}
                            />
                            <div>
                              <div style={{ fontWeight: '600' }}>{user.fullName}</div>
                              <div style={{ fontSize: '0.85rem', color: '#6B7280' }}>{user.city || '—'}</div>
                            </div>
                          </div>
                        </td>
                        <td>{user.email}</td>
                        <td>
                          <span className="role-chip" style={{
                            background: user.role === 'Donor' ? '#DBEAFE' : '#F3E8FF',
                            color: user.role === 'Donor' ? '#2563EB' : '#7C3AED'
                          }}>
                            {user.role}
                          </span>
                        </td>
                        <td>{formatDate(user.createdAt)}</td>
                        <td>
                          <span style={{ color: user.isVerified ? '#10B981' : '#EF4444', fontWeight: '500' }}>
                            <span className="status-dot" style={{ background: user.isVerified ? '#10B981' : '#EF4444' }}></span>
                            {user.isVerified ? 'Active' : 'Inactive'}
                          </span>
                        </td>
                        <td>
                          <div className="actions-cell">
                            <button className="action-btn edit-btn" title="Edit">✏️</button>
                            {user.isVerified ? (
                              <button className="action-btn deactivate-btn" onClick={() => handleDeactivate(user._id)} title="Deactivate">🚫</button>
                            ) : (
                              <button className="action-btn" style={{background:'#ECFDF5', color:'#10B981'}} onClick={() => handleActivate(user._id)} title="Activate">✅</button>
                            )}
                            <button className="action-btn delete-btn" onClick={() => handleDelete(user._id)} title="Delete">🗑</button>
                          </div>
                        </td>
                      </tr>
                    ))}

                    {filteredUsers.length === 0 && (
                      <tr>
                        <td colSpan="6" style={{ textAlign: 'center', padding: '80px', color: '#9CA3AF' }}>
                          No donors or patients found
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
    </>
  );
};

export default UserManagement;