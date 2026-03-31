import React from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';

import Navbar from './components/Navbar';


// Public Pages
import LandingPage from './pages/LandingPage';
import RoleSelection from './pages/RoleSelection';
import Login from './pages/Login';
import CriticalEmergencyrequest from './pages/CriticalEmergencyrequest';


import HospitalRegistration from './pages/HospitalRegistration';





// Blood Bank Pages
import BloodBankDashboard from './pages/BloodBankDashboard';
import BloodBankInventry from './pages/BloodBankInventry';
import BloodBankDispatch from './pages/BloodBankDispatch';
import BloodBankReport from './pages/BloodBankReport';
import AccountProfile from './pages/AccountProfile';
import NotificationsScreen from './pages/NotificationsScreen ';
import DornoreEligibility from './pages/Donoreligibility';
import PatientRequestsScreen from './pages/Patient_Requests_screen';



//Admin
import AdminDashboard from './pages/Admindashboard';
import AdminUserManage from './pages/AdminUserManage';
import Adminhospitalmanage from './pages/Adminhospitalmanage';
import Adminalerts from './pages/adminalerts';
import ReportsAndAnalytics from './pages/ReportsAndAnalytics';

import './App.css';


// Conditional Navbar Component
function ConditionalNavbar() {
  const location = useLocation();

  // Donor pages that use DonorNavbar
  const donorPages = [
    '/dashboard/donor',
    '/eligibility',
    '/donations',
    '/medical-reports'
  ];

  // Pages that don't show any navbar
 const noNavbarPages = [
  '/login',
  '/critical-emergency'
];


  if (noNavbarPages.includes(location.pathname)) {
    return null;
  }



  // Default Navbar (for patient + public)
  return <Navbar />;
}

function AppContent() {
  return (
    <div className="App">
      <ConditionalNavbar />

      <Routes>

        {/* Public Routes */}
        <Route path="/" element={<LandingPage />} />
        <Route path="/join" element={<RoleSelection />} />
        <Route path="/login" element={<Login />} />
        <Route path="/critical-emergency" element={<CriticalEmergencyrequest />} />

        {/* Registration Routes */}
        <Route path="/register/hospital" element={<HospitalRegistration />} />





        {/* ================= Admin Routes ================= */}
        <Route path="/admin/dashboard" element={<AdminDashboard />} />
        <Route path="/admin/usermanage" element={<AdminUserManage />} />
        <Route path="/admin/hospitalmanage" element={<Adminhospitalmanage />} />
        <Route path="/admin/alerts" element={<Adminalerts />} />
        <Route path="/admin/reports" element={<ReportsAndAnalytics />} />
    
        {/* ================= Blood Bank Routes ================= */}
       {/* ================= Blood Bank Routes ================= */}
        <Route path="/bloodbank/notifications" element={<NotificationsScreen />} />
        <Route path="/bloodbank/eligibility" element={<DornoreEligibility />} />
        <Route path="/bloodbank/requests" element={<PatientRequestsScreen />} />
        <Route path="/bloodbank/dashboard" element={<BloodBankDashboard />} />
        <Route path="/bloodbank/profile" element={<AccountProfile />} />
        



      </Routes>
    </div>
  );
}

function App() {
  return (
    <Router>
      <AppContent />
    </Router>
  );
}

export default App;
