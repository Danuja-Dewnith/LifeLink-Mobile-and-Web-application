import React from "react";
import { NavLink } from "react-router-dom";
import "./AdminSidebar.css";

/**
 * Reusable Admin Sidebar (matches AdminDashboard sidebar UI)
 *
 * Props:
 * - activePath (optional): if you want manual active control (usually not needed)
 * - user: { initials, name, role }
 * - onLogout: function
 */
const AdminSidebar = ({
  user = { initials: "SJ", name: "Sarah Jenkins", role: "System Director" },
  onLogout,
}) => {
  const navMain = [
    {
      to: "/admin/dashboard",
      label: "Dashboard",
      icon: (
        <svg fill="currentColor" viewBox="0 0 20 20">
          <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z" />
        </svg>
      ),
    },
    {
      to: "/admin/usermanage",
      label: "User Management",
      icon: (
        <svg fill="currentColor" viewBox="0 0 20 20">
          <path d="M9 6a3 3 0 11-6 0 3 3 0 016 0zM17 6a3 3 0 11-6 0 3 3 0 016 0zM12.93 17c.046-.327.07-.66.07-1a6.97 6.97 0 00-1.5-4.33A5 5 0 0119 16v1h-6.07zM6 11a5 5 0 015 5v1H1v-1a5 5 0 015-5z" />
        </svg>
      ),
    },
    {
      to: "/admin/hospitalmanage",
      label: "Hospital Management",
      icon: (
        <svg fill="currentColor" viewBox="0 0 20 20">
          <path
            fillRule="evenodd"
            d="M4 4a2 2 0 012-2h8a2 2 0 012 2v12a1 1 0 110 2h-3a1 1 0 01-1-1v-2a1 1 0 00-1-1H9a1 1 0 00-1 1v2a1 1 0 01-1 1H4a1 1 0 110-2V4zm3 1h2v2H7V5zm2 4H7v2h2V9zm2-4h2v2h-2V5zm2 4h-2v2h2V9z"
            clipRule="evenodd"
          />
        </svg>
      ),
    },
    {
      to: "/admin/alerts",
      label: "Emergency Alerts",
      icon: (
        <svg fill="currentColor" viewBox="0 0 20 20">
          <path d="M10 2a6 6 0 00-6 6v3.586l-.707.707A1 1 0 004 14h12a1 1 0 00.707-1.707L16 11.586V8a6 6 0 00-6-6zM10 18a3 3 0 01-3-3h6a3 3 0 01-3 3z" />
        </svg>
      ),
    },
  ];

  const navAnalytics = [
    {
      to: "/admin/reports",
      label: "Reports",
      icon: (
        <svg fill="currentColor" viewBox="0 0 20 20">
          <path d="M2 11a1 1 0 011-1h2a1 1 0 011 1v5a1 1 0 01-1 1H3a1 1 0 01-1-1v-5zM8 7a1 1 0 011-1h2a1 1 0 011 1v9a1 1 0 01-1 1H9a1 1 0 01-1-1V7zM14 4a1 1 0 011-1h2a1 1 0 011 1v12a1 1 0 01-1 1h-2a1 1 0 01-1-1V4z" />
        </svg>
      ),
    }
  ];

  return (
    <aside className="ll-sidebar">
      <div className="ll-logo-section">
        <div className="ll-logo-icon">📊</div>
        <div className="ll-logo-text">
          <h2>
            LifeLink <span>Admin</span>
          </h2>
        </div>
      </div>

      <div className="ll-menu-section">
        <div className="ll-menu-label">Main Menu</div>
        <nav className="ll-menu-items">
          {navMain.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end
              className={({ isActive }) =>
                `ll-menu-item${isActive ? " active" : ""}`
              }
            >
              {item.icon}
              {item.label}
            </NavLink>
          ))}
        </nav>
      </div>

      <div className="ll-menu-section">
        <div className="ll-menu-label">Analytics & Support</div>
        <nav className="ll-menu-items">
          {navAnalytics.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `ll-menu-item${isActive ? " active" : ""}`
              }
            >
              {item.icon}
              {item.label}
            </NavLink>
          ))}
        </nav>
      </div>

      <div className="ll-user-profile">
        <div className="ll-user-avatar">{user.initials}</div>
        <div className="ll-user-info">
          <h4>{user.name}</h4>
          <p>{user.role}</p>
        </div>

        <button
          type="button"
          className="ll-logout-btn"
          onClick={onLogout}
          title="Logout"
          aria-label="Logout"
        >
          <svg width="20" height="20" fill="currentColor" viewBox="0 0 20 20">
            <path
              fillRule="evenodd"
              d="M3 3a1 1 0 011 1v12a1 1 0 11-2 0V4a1 1 0 011-1zm7.707 3.293a1 1 0 010 1.414L9.414 9H17a1 1 0 110 2H9.414l1.293 1.293a1 1 0 01-1.414 1.414l-3-3a1 1 0 010-1.414l3-3a1 1 0 011.414 0z"
              clipRule="evenodd"
            />
          </svg>
        </button>
      </div>
    </aside>
  );
};

export default AdminSidebar;