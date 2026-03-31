import React, { useState, useEffect } from 'react';

const NotificationBell = () => {
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [showDropdown, setShowDropdown] = useState(false);

  // Fetch real urgent/critical requests
  const fetchNotifications = async () => {
    try {
      const res = await fetch('http://localhost:8083/api/admin/emergency-requests');
      if (!res.ok) throw new Error('Failed');

      const data = await res.json();

      const urgentOnly = data
        .filter(req => req.urgencyLevel === 'Urgent' || req.urgencyLevel === 'Critical')
        .map(req => ({
          id: req._id,
          title: `🚨 ${req.urgencyLevel} Blood Request`,
          message: `${req.patientName} needs ${req.bloodGroup} — ${req.unitsNeeded} units at ${req.hospitalName}`,
          time: new Date(req.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          isRead: false
        }));

      setNotifications(urgentOnly);
      setUnreadCount(urgentOnly.length);
    } catch (err) {
      console.error(err);
      setNotifications([]);
      setUnreadCount(0);
    }
  };

  useEffect(() => {
    fetchNotifications();
    const interval = setInterval(fetchNotifications, 30000);
    return () => clearInterval(interval);
  }, []);

  // Click one notification → Turn white + Reduce bell count (NO navigation)
  const handleNotificationClick = (id) => {
    // Reduce bell count immediately
    setUnreadCount(prev => Math.max(0, prev - 1));

    // Turn this notification white (mark as read)
    setNotifications(prev =>
      prev.map(notif => 
        notif.id === id ? { ...notif, isRead: true } : notif
      )
    );
  };

  const markAllAsRead = () => {
    setUnreadCount(0);
    setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
    setShowDropdown(false);
  };

  return (
    <div style={{ position: 'relative' }}>
      {/* Bell Icon */}
      <button
        onClick={() => setShowDropdown(!showDropdown)}
        style={{
          background: 'none',
          border: 'none',
          fontSize: '1.65rem',
          cursor: 'pointer',
          padding: '8px',
          position: 'relative'
        }}
      >
        🛎️
        {unreadCount > 0 && (
          <span style={{
            position: 'absolute',
            top: '4px',
            right: '4px',
            background: '#EF4444',
            color: 'white',
            fontSize: '0.75rem',
            width: '19px',
            height: '19px',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontWeight: 'bold',
            border: '2px solid white'
          }}>
            {unreadCount}
          </span>
        )}
      </button>

      {/* Dropdown */}
      {showDropdown && (
        <div style={{
          position: 'absolute',
          top: '55px',
          right: '0',
          width: '380px',
          background: 'white',
          borderRadius: '14px',
          boxShadow: '0 15px 40px rgba(0,0,0,0.18)',
          zIndex: 2000,
          overflow: 'hidden'
        }}>
          <div style={{ 
            padding: '1rem 1.25rem', 
            borderBottom: '1px solid #eee', 
            fontWeight: '600',
            display: 'flex',
            justifyContent: 'space-between'
          }}>
            Notifications ({unreadCount})
            <button 
              onClick={markAllAsRead}
              style={{ fontSize: '0.85rem', color: '#2563EB', background: 'none', border: 'none', cursor: 'pointer' }}
            >
              Mark all read
            </button>
          </div>

          <div style={{ maxHeight: '420px', overflowY: 'auto' }}>
            {notifications.length === 0 ? (
              <div style={{ padding: '3rem', textAlign: 'center', color: '#888' }}>
                No urgent alerts right now
              </div>
            ) : (
              notifications.map((notif) => (
                <div 
                  key={notif.id}
                  onClick={() => handleNotificationClick(notif.id)}
                  style={{
                    padding: '1rem 1.25rem',
                    borderBottom: '1px solid #f1f1f1',
                    background: notif.isRead ? 'white' : '#FEF2F2',
                    cursor: 'pointer'
                  }}
                >
                  <div style={{ fontWeight: '600', marginBottom: '4px' }}>{notif.title}</div>
                  <div style={{ fontSize: '0.95rem', color: '#555', marginBottom: '6px' }}>
                    {notif.message}
                  </div>
                  <div style={{ fontSize: '0.8rem', color: '#888' }}>{notif.time}</div>
                </div>
              ))
            )}
          </div>

          <div style={{ padding: '1rem', textAlign: 'center', borderTop: '1px solid #eee' }}>
            <a href="/admin/alerts" style={{ color: '#2563EB', textDecoration: 'none', fontWeight: '500' }}>
              View all notifications →
            </a>
          </div>
        </div>
      )}
    </div>
  );
};

export default NotificationBell;