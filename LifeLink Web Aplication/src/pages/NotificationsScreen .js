import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

const NotificationsScreen = () => {
  const navigate = useNavigate();
  const [selectedTab, setSelectedTab] = useState(0); // 0: All, 1: Unread, 2: Important
  const [selectedBottomTab, setSelectedBottomTab] = useState(3);
  const [notifications, setNotifications] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [token, setToken] = useState(null);

  // Tab options
  const tabs = ['All', 'Unread', 'Important'];

  useEffect(() => {
    loadTokenAndNotifications();
  }, []);

  const loadTokenAndNotifications = async () => {
    const storedToken = localStorage.getItem('jwt_token');
    
    if (!storedToken) {
      console.log("❌ No token found in localStorage");
      setIsLoading(false);
      return;
    }

    setToken(storedToken);
    await loadNotifications(storedToken);
  };

  const loadNotifications = async (authToken) => {
    setIsLoading(true);

    try {
      const response = await fetch('http://localhost:8083/api/hospitals/notifications', {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json',
        },
      });

      console.log("📡 Status Code:", response.status);
      console.log("📦 Response:", response);

      if (response.status === 401) {
        navigate('/login');
        return;
      }

      if (response.ok) {
        const data = await response.json();
        const notifs = data.notifications || [];
        
        setNotifications(notifs.map(n => ({
          id: n.id || Math.random().toString(),
          title: n.title || 'Notification',
          subtitle: n.subtitle || '',
          body: n.body || '',
          icon: n.icon || 'notifications',
          iconBgColor: n.iconBgColor || '#EEF2F7',
          iconColor: n.iconColor || '#6B7280',
          timeAgo: n.timeAgo || 'Just now',
          isUnread: n.isUnread || false,
          isHighlighted: n.isHighlighted || false,
        })));
      } else {
        // Load demo data if API fails
        loadDemoNotifications();
      }
    } catch (error) {
      console.error('❌ Load notifications error:', error);
      loadDemoNotifications();
    } finally {
      setIsLoading(false);
    }
  };

  const loadDemoNotifications = () => {
    setNotifications([
      {
        id: '1',
        title: 'Urgent Blood Request',
        subtitle: 'Critical Need',
        body: 'Patient in ICU requires O- blood immediately. 3 units needed.',
        icon: 'notifications',
        iconBgColor: '#FFE5E5',
        iconColor: '#E53935',
        timeAgo: '2 mins ago',
        isUnread: true,
        isHighlighted: true,
      },
      {
        id: '2',
        title: 'Donor Matched',
        subtitle: 'Sarah Johnson',
        body: 'A donor has been matched for patient Michael Chen. Please coordinate collection.',
        icon: 'check_circle',
        iconBgColor: '#E8F5E9',
        iconColor: '#43A047',
        timeAgo: '15 mins ago',
        isUnread: true,
        isHighlighted: false,
      },
      {
        id: '3',
        title: 'Blood Stock Alert',
        subtitle: 'Low Inventory',
        body: 'A- blood stock is critically low (only 2 units remaining). Please restock.',
        icon: 'inventory',
        iconBgColor: '#FFF3E0',
        iconColor: '#FB8C00',
        timeAgo: '1 hour ago',
        isUnread: false,
        isHighlighted: false,
      },
      {
        id: '4',
        title: 'Donation Scheduled',
        subtitle: 'John Doe',
        body: 'Blood donation scheduled for tomorrow at 10:00 AM. Donor confirmed.',
        icon: 'add',
        iconBgColor: '#E8F0FE',
        iconColor: '#2979FF',
        timeAgo: '3 hours ago',
        isUnread: false,
        isHighlighted: false,
      },
      {
        id: '5',
        title: 'Donor Nearby',
        subtitle: 'Available Donor',
        body: 'O+ donor available within 2km radius. Ready for immediate donation.',
        icon: 'location_on',
        iconBgColor: '#E8F0FE',
        iconColor: '#2979FF',
        timeAgo: '5 hours ago',
        isUnread: false,
        isHighlighted: false,
      },
    ]);
  };

  const markAllAsRead = async () => {
    if (!token) return;

    try {
      const response = await fetch('http://localhost:8083/api/hospitals/notifications/mark-all-read', {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (response.ok) {
        await loadNotifications(token);
        alert('All notifications marked as read');
      }
    } catch (error) {
      console.error('Mark as read error:', error);
      // Demo mode: mark all as read
      setNotifications(notifications.map(n => ({ ...n, isUnread: false })));
      alert('All notifications marked as read (Demo Mode)');
    }
  };

  const getFilteredNotifications = () => {
    if (selectedTab === 1) { // Unread
      return notifications.filter(n => n.isUnread);
    } else if (selectedTab === 2) { // Important
      return notifications.filter(n => n.isHighlighted);
    }
    return notifications; // All
  };

  const getIconComponent = (iconName, color, bgColor) => {
    const iconStyle = { color: color, fontSize: '24px' };
    
    switch (iconName.toLowerCase()) {
      case 'add':
        return <span style={iconStyle}>➕</span>;
      case 'location_on':
        return <span style={iconStyle}>📍</span>;
      case 'inventory':
        return <span style={iconStyle}>📦</span>;
      case 'check_circle':
        return <span style={iconStyle}>✅</span>;
      default:
        return <span style={iconStyle}>🔔</span>;
    }
  };

  const handleNavigation = (index) => {
    setSelectedBottomTab(index);
    
    switch(index) {
      case 0:
        navigate('/hospital/dashboard');
        break;
      case 1:
        navigate('/hospital/requests');
        break;
      case 2:
        navigate('/hospital/donors');
        break;
      case 3:
        // Already on notifications
        break;
      case 4:
        navigate('/hospital/profile');
        break;
      default:
        break;
    }
  };

  const filteredNotifications = getFilteredNotifications();

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap');

        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        .notifications-page {
          background: white;
          min-height: 100vh;
          font-family: 'Inter', -apple-system, sans-serif;
        }

        /* Top Bar */
        .top-bar {
          padding: 16px 20px 8px;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .page-title {
          font-size: 22px;
          font-weight: 800;
          color: #1A2340;
        }

        .mark-all-btn {
          color: #2979FF;
          font-size: 14px;
          font-weight: 600;
          cursor: pointer;
          transition: opacity 0.2s;
          background: none;
          border: none;
        }

        .mark-all-btn:hover {
          opacity: 0.8;
        }

        /* Tab Bar */
        .tab-bar {
          border-bottom: 1px solid #E2E8F0;
          margin-top: 8px;
        }

        .tabs-container {
          display: flex;
          gap: 8px;
          padding: 0 20px;
        }

        .tab {
          padding: 12px 0;
          font-size: 14px;
          font-weight: 600;
          cursor: pointer;
          border-bottom: 3px solid transparent;
          transition: all 0.2s;
        }

        .tab.active {
          color: #2979FF;
          border-bottom-color: #2979FF;
        }

        .tab:not(.active) {
          color: #9E9E9E;
        }

        /* Notifications List */
        .notifications-list {
          padding: 8px 0 100px;
        }

        /* Notification Card */
        .notification-card {
          padding: 16px 20px;
          transition: background 0.2s;
          cursor: pointer;
        }

        .notification-card:hover {
          background: #F8FAFE;
        }

        .notification-card.highlighted {
          background: #F0F5FF;
        }

        .notification-content {
          display: flex;
          gap: 14px;
        }

        .notification-icon {
          width: 52px;
          height: 52px;
          border-radius: 14px;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
        }

        .notification-details {
          flex: 1;
        }

        .notification-title {
          font-size: 15px;
          font-weight: 700;
          color: #1A2340;
          margin-bottom: 2px;
        }

        .notification-subtitle {
          font-size: 13px;
          font-weight: 600;
          color: #6B7280;
          margin-bottom: 4px;
        }

        .notification-body {
          font-size: 13px;
          color: #6B7280;
          line-height: 1.4;
        }

        .notification-meta {
          display: flex;
          flex-direction: column;
          align-items: flex-end;
          gap: 6px;
        }

        .time-ago {
          font-size: 11px;
          color: #9E9E9E;
        }

        .unread-dot {
          width: 8px;
          height: 8px;
          border-radius: 50%;
          background: #2979FF;
        }

        /* Loading & Empty States */
        .loading-container {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          padding: 60px 20px;
        }

        .spinner {
          width: 40px;
          height: 40px;
          border: 3px solid #E2E8F0;
          border-top-color: #2979FF;
          border-radius: 50%;
          animation: spin 1s linear infinite;
        }

        .empty-container {
          text-align: center;
          padding: 60px 20px;
          color: #9E9E9E;
        }

        /* Bottom Navigation */
        .bottom-nav {
          position: fixed;
          bottom: 0;
          left: 0;
          right: 0;
          background: white;
          box-shadow: 0 -2px 12px rgba(0, 0, 0, 0.06);
          padding: 8px 0;
          z-index: 100;
        }

        .nav-items {
          display: flex;
          justify-content: space-around;
          align-items: center;
        }

        .nav-item {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 4px;
          cursor: pointer;
          padding: 4px 12px;
          transition: all 0.2s;
          background: none;
          border: none;
        }

        .nav-item:hover {
          transform: translateY(-2px);
        }

        .nav-icon {
          font-size: 22px;
        }

        .nav-label {
          font-size: 10px;
          font-weight: 500;
        }

        @keyframes spin {
          to { transform: rotate(360deg); }
        }

        /* Mobile Responsive */
        @media (max-width: 768px) {
          .top-bar {
            padding: 12px 16px 8px;
          }
          
          .page-title {
            font-size: 20px;
          }
          
          .tabs-container {
            padding: 0 16px;
          }
          
          .notification-card {
            padding: 12px 16px;
          }
          
          .notification-icon {
            width: 48px;
            height: 48px;
          }
        }
      `}</style>

      <div className="notifications-page">
        {/* Top Bar */}
        <div className="top-bar">
          <div className="page-title">Notifications</div>
          <button className="mark-all-btn" onClick={markAllAsRead}>
            Mark all as read
          </button>
        </div>

        {/* Tab Bar */}
        <div className="tab-bar">
          <div className="tabs-container">
            {tabs.map((tab, index) => (
              <div
                key={index}
                className={`tab ${selectedTab === index ? 'active' : ''}`}
                onClick={() => setSelectedTab(index)}
              >
                {tab}
              </div>
            ))}
          </div>
        </div>

        {/* Notifications List */}
        {isLoading ? (
          <div className="loading-container">
            <div className="spinner"></div>
            <p style={{ marginTop: '16px', color: '#6B7280' }}>Loading notifications...</p>
          </div>
        ) : filteredNotifications.length === 0 ? (
          <div className="empty-container">
            <span style={{ fontSize: '56px' }}>🔔</span>
            <p style={{ marginTop: '12px', fontSize: '15px', fontWeight: '600' }}>
              No notifications yet
            </p>
            <p style={{ marginTop: '4px', fontSize: '13px' }}>
              {selectedTab === 1 ? 'All notifications are read' : 'Check back later for updates'}
            </p>
          </div>
        ) : (
          <div className="notifications-list">
            {filteredNotifications.map((notif) => (
              <div
                key={notif.id}
                className={`notification-card ${notif.isHighlighted ? 'highlighted' : ''}`}
              >
                <div className="notification-content">
                  <div
                    className="notification-icon"
                    style={{
                      background: notif.iconBgColor,
                    }}
                  >
                    {getIconComponent(notif.icon, notif.iconColor, notif.iconBgColor)}
                  </div>
                  <div className="notification-details">
                    <div className="notification-title">{notif.title}</div>
                    {notif.subtitle && (
                      <div className="notification-subtitle">{notif.subtitle}</div>
                    )}
                    <div className="notification-body">{notif.body}</div>
                  </div>
                  <div className="notification-meta">
                    <div className="time-ago">{notif.timeAgo}</div>
                    {notif.isUnread && <div className="unread-dot"></div>}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Bottom Navigation */}
        <div className="bottom-nav">
          <div className="nav-items">
            {[
              { icon: '⊞', label: 'Dashboard', path: '/hospital/dashboard' },
              { icon: '💧', label: 'Requests', path: '/hospital/requests' },
              { icon: '👥', label: 'Donors', path: '/hospital/donors' },
              { icon: '🔔', label: 'Notifications', path: '/hospital/alerts' },
              { icon: '👤', label: 'Profile', path: '/hospital/profile' }
            ].map((item, index) => (
              <button
                key={index}
                className="nav-item"
                onClick={() => handleNavigation(index)}
                style={{
                  color: selectedBottomTab === index ? '#2979FF' : '#B0BEC5'
                }}
              >
                <div className="nav-icon">{item.icon}</div>
                <div className="nav-label">{item.label}</div>
              </button>
            ))}
          </div>
        </div>
      </div>
    </>
  );
};

export default NotificationsScreen;