import React from "react";
import AdminSidebar from "../components/AdminSidebar";
import "./AdminLayout.css";

const AdminLayout = ({ children }) => {
  return (
    <div className="al-shell">
      <AdminSidebar />
      <div className="al-page">{children}</div>
    </div>
  );
};

export default AdminLayout;