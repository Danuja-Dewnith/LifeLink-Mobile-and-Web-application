import React, { useState, useEffect, useCallback } from "react";
import { Link, useNavigate } from "react-router-dom";

const BloodBankDashboard = () => {
  const navigate = useNavigate();

  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState("");
  const [hospitalName, setHospitalName] = useState("");
  const [bloodStocks, setBloodStocks] = useState([]);
  const [patientRequests, setPatientRequests] = useState([]);
  const [availableDonors, setAvailableDonors] = useState([]);
  
  // Hardcoded doctor instructions with various types
  const [instructions, setInstructions] = useState([
    {
      id: "inst_001",
      title: "⚠️ URGENT: Blood Transfusion Protocol for Emergency Ward",
      description: "Due to multiple trauma cases in the emergency ward, we require immediate blood transfusion for 3 patients. O Negative blood is critically needed. Please prioritize O Negative blood units for the following patients: Patient ID: EM-234 (Mr. Rajapakse), Patient ID: EM-235 (Mrs. Perera), Patient ID: EM-236 (Mr. Fernando). Coordinate with the emergency ward staff for immediate delivery.",
      meta: "Posted by Dr. N. Jayawardena • 2 hours ago • Critical",
      priority: "Critical",
      issuedBy: "Dr. N. Jayawardena",
      date: "2024-03-26",
      department: "Emergency Ward",
      additionalNotes: "Blood must be cross-matched before transfusion. Priority to O Negative donors. Contact emergency ward at ext. 1234 immediately.",
      instructionType: "emergency"
    },
    {
      id: "inst_002",
      title: "🩸 Weekly Blood Donation Camp Schedule",
      description: "This week's blood donation camp will be held at the hospital main hall from 9:00 AM to 5:00 PM on Friday, March 29th. All blood bank staff are requested to be present. We need to collect at least 50 units to replenish our stocks. Please arrange for refreshments and comfortable seating for donors. Setup should be completed by 8:00 AM.",
      meta: "Posted by Dr. S. Fernando • 1 day ago • High Priority",
      priority: "High",
      issuedBy: "Dr. S. Fernando",
      date: "2024-03-25",
      department: "Blood Bank",
      additionalNotes: "Ensure sufficient blood collection kits and storage boxes are available. Coordinate with canteen for refreshments.",
      instructionType: "scheduled"
    },
    {
      id: "inst_003",
      title: "📋 New SOP: Blood Component Separation",
      description: "All blood bank technicians must follow the updated Standard Operating Procedure for blood component separation. The new protocol requires centrifugation at 3000 RPM for 12 minutes for platelet separation, and 4000 RPM for 15 minutes for plasma separation. All staff must complete the training module by March 30th. Please sign the acknowledgment form.",
      meta: "Posted by Dr. M. Rathnayake • 3 days ago • Medium Priority",
      priority: "Medium",
      issuedBy: "Dr. M. Rathnayake",
      date: "2024-03-23",
      department: "Blood Bank Laboratory",
      additionalNotes: "Training materials are available in the shared drive. Contact lab supervisor for hands-on demonstration.",
      instructionType: "protocol"
    },
    {
      id: "inst_004",
      title: "🔴 Critical: A+ Blood Shortage Alert",
      description: "We are currently experiencing a critical shortage of A+ blood. Only 3 units remaining in stock. Please restrict A+ blood usage to only life-threatening emergencies. Contact nearby hospitals for possible transfer if needed. Urgently activate the donor notification system for A+ donors within 10km radius.",
      meta: "Posted by Dr. K. Weerasinghe • 4 hours ago • Critical",
      priority: "Critical",
      issuedBy: "Dr. K. Weerasinghe",
      date: "2024-03-26",
      department: "Blood Bank",
      additionalNotes: "Update inventory system immediately. Coordinate with communication team to send SMS alerts to registered A+ donors.",
      instructionType: "alert"
    },
    {
      id: "inst_005",
      title: "🧪 Quality Control: Blood Storage Temperature Check",
      description: "Conduct mandatory temperature checks for all blood storage refrigerators every 4 hours. Document readings in the temperature log sheet. Ensure backup generators are tested weekly. Last week's temperature logs show fluctuations in Refrigerator B - please investigate and report immediately.",
      meta: "Posted by Dr. P. Silva • 2 days ago • High Priority",
      priority: "High",
      issuedBy: "Dr. P. Silva",
      date: "2024-03-24",
      department: "Quality Assurance",
      additionalNotes: "Temperature log sheets must be submitted to QA department by end of shift. Calibration required for Refrigerator B sensors.",
      instructionType: "quality"
    },
    {
      id: "inst_006",
      title: "👥 Staff Training: Emergency Response Drill",
      description: "Mandatory emergency response drill for all blood bank staff on Monday, April 1st at 10:00 AM. This drill will simulate a massive transfusion scenario requiring coordination with multiple departments. Attendance is compulsory. Please arrive 15 minutes early in full uniform.",
      meta: "Posted by Dr. R. Perera • 5 days ago • Medium Priority",
      priority: "Medium",
      issuedBy: "Dr. R. Perera",
      date: "2024-03-21",
      department: "Training & Development",
      additionalNotes: "Bring your ID cards. Review the emergency protocol document before the drill. Sign-in sheet will be available at the blood bank counter.",
      instructionType: "training"
    },
    {
      id: "inst_007",
      title: "📝 Documentation: Daily Blood Usage Report",
      description: "All blood bank staff must submit daily blood usage reports by end of shift. Reports should include: blood type, units issued, patient details, and department requesting. Incomplete reports will not be accepted. Use the new digital form available on the hospital portal.",
      meta: "Posted by Admin • 6 days ago • Normal Priority",
      priority: "Normal",
      issuedBy: "Hospital Administration",
      date: "2024-03-20",
      department: "Administration",
      additionalNotes: "Digital form training available upon request. Previous month's reports are due by March 31st.",
      instructionType: "documentation"
    },
    {
      id: "inst_008",
      title: "🔄 Blood Stock Rotation: FIFO Implementation",
      description: "Implement First-In-First-Out (FIFO) system for all blood products. Check expiration dates daily and prioritize using units with earliest expiry. Any blood units expiring within 7 days must be flagged and reported to the medical team for priority usage.",
      meta: "Posted by Dr. L. Samarawickrama • 1 week ago • High Priority",
      priority: "High",
      issuedBy: "Dr. L. Samarawickrama",
      date: "2024-03-19",
      department: "Inventory Management",
      additionalNotes: "Create daily expiry report. Coordinate with wards for early usage of near-expiry units.",
      instructionType: "inventory"
    },
    {
      id: "inst_009",
      title: "🏥 COVID-19 Safety Protocol for Donors",
      description: "All blood donors must undergo temperature screening and provide a negative antigen test report (within 24 hours) before donation. Donation area must be sanitized after each donor. Mask-wearing is mandatory. Maintain social distancing in waiting areas.",
      meta: "Posted by Infection Control • 2 weeks ago • High Priority",
      priority: "High",
      issuedBy: "Infection Control Committee",
      date: "2024-03-12",
      department: "Infection Control",
      additionalNotes: "PPE kits available at the donation center entrance. Report any symptomatic donors immediately.",
      instructionType: "safety"
    },
    {
      id: "inst_010",
      title: "📊 Monthly Performance Review Meeting",
      description: "Monthly blood bank performance review meeting scheduled for April 5th at 2:00 PM in Conference Room B. Agenda includes: monthly collection targets, wastage analysis, donor retention metrics, and quality improvement initiatives. All team leads must prepare their department reports.",
      meta: "Posted by Dr. H. Jayasinghe • 1 week ago • Normal Priority",
      priority: "Normal",
      issuedBy: "Dr. H. Jayasinghe",
      date: "2024-03-18",
      department: "Blood Bank Management",
      additionalNotes: "Submit reports by April 3rd. Zoom link available for remote participants.",
      instructionType: "meeting"
    }
  ]);
  
  const [urgentRequests, setUrgentRequests] = useState([]);
  const [alerts, setAlerts] = useState([]);
  const [isLoadingUrgent, setIsLoadingUrgent] = useState(true);
  const [isLoadingAlerts, setIsLoadingAlerts] = useState(false);
  const [profileData, setProfileData] = useState(null);
  const [isLoadingProfile, setIsLoadingProfile] = useState(false);
  const [activeSection, setActiveSection] = useState("dashboard");
  
  // State for instruction popup modal
  const [selectedInstruction, setSelectedInstruction] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  
  // State for inventory management
  const [isInventoryModalOpen, setIsInventoryModalOpen] = useState(false);
  const [selectedBloodType, setSelectedBloodType] = useState(null);
  const [inventoryAction, setInventoryAction] = useState("add");
  const [inventoryQuantity, setInventoryQuantity] = useState(0);
  const [inventoryReason, setInventoryReason] = useState("");
  const [isUpdatingInventory, setIsUpdatingInventory] = useState(false);
  const [newBloodType, setNewBloodType] = useState("");
  const [showCustomBloodType, setShowCustomBloodType] = useState(false);
  const [availableBloodTypes] = useState([
    "A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"
  ]);

  // State for Hospital Requests
  const [hospitalRequests, setHospitalRequests] = useState([]);
  const [isLoadingRequests, setIsLoadingRequests] = useState(false);
  const [isRequestModalOpen, setIsRequestModalOpen] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [isRequestDetailModalOpen, setIsRequestDetailModalOpen] = useState(false);
  const [requestForm, setRequestForm] = useState({
    itemType: 'Blood',
    itemName: '',
    quantity: 1,
    urgency: 'Normal',
    reason: '',
    contactPerson: ''
  });
  const [isSubmittingRequest, setIsSubmittingRequest] = useState(false);
  const [requestStats, setRequestStats] = useState({
    total: 0,
    pending: 0,
    fulfilled: 0,
    cancelled: 0,
    critical: 0,
    urgent: 0
  });

  // State for Alert Detail Modal
  const [selectedAlert, setSelectedAlert] = useState(null);
  const [isAlertDetailModalOpen, setIsAlertDetailModalOpen] = useState(false);
  
  // State for Emergency Hospital Request Modal
  const [isEmergencyRequestModalOpen, setIsEmergencyRequestModalOpen] = useState(false);
  const [emergencyRequestForm, setEmergencyRequestForm] = useState({
    itemType: 'Blood',
    itemName: '',
    quantity: 1,
    urgency: 'Critical',
    reason: '',
    contactPerson: ''
  });
  const [isSubmittingEmergency, setIsSubmittingEmergency] = useState(false);

  // State for Profile Editing
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [editForm, setEditForm] = useState({
    contact: '',
    address: '',
    description: '',
    workingHours: '',
    emergencyContact: ''
  });
  const [isUpdatingProfile, setIsUpdatingProfile] = useState(false);

  const API_BASE_URL = "http://localhost:8083/api";

  // ── Auth headers ──────────────────────────────────────────────────────────
  const getAuthHeaders = useCallback(
    () => ({
      Authorization: `Bearer ${localStorage.getItem("jwt_token")}`,
      "Content-Type": "application/json",
      "Hospital-Id": localStorage.getItem("hospitalId"),
    }),
    [],
  );

  // Load Available Donors
  const loadAvailableDonors = useCallback(async () => {
    try {
      const res = await fetch(`${API_BASE_URL}/hospitals/available-donors`, {
        headers: getAuthHeaders(),
      });
      if (res.ok) {
        const data = await res.json();
        setAvailableDonors(data.availableDonors || []);
      }
    } catch (err) {
      console.error("Available donors fetch error:", err);
      setAvailableDonors([
        { id: "1", name: "Kasun Perera", bloodType: "O+", city: "Negombo", distance: "2.3 km", age: 28, avatarUrl: "" },
        { id: "2", name: "Nadeesha Silva", bloodType: "A-", city: "Colombo", distance: "4.1 km", age: 24, avatarUrl: "" },
        { id: "3", name: "Tharindu Fernando", bloodType: "B+", city: "Negombo", distance: "1.8 km", age: 31, avatarUrl: "" },
      ]);
    }
  }, [API_BASE_URL, getAuthHeaders]);

  // ── Logout ────────────────────────────────────────────────────────────────
  const handleLogout = useCallback(() => {
    [
      "jwt_token",
      "userType",
      "hospitalId",
      "name",
      "email",
      "regNumber",
      "contact",
      "storageCapacity",
      "isVerified",
    ].forEach((k) => localStorage.removeItem(k));
    navigate("/login");
  }, [navigate]);

  // ── Load urgent requests (background) ────────────────────────────────────
  const loadUrgentRequests = useCallback(async () => {
    setIsLoadingUrgent(true);
    try {
      const res = await fetch(`${API_BASE_URL}/hospitals/urgent-requests`, {
        headers: getAuthHeaders(),
      });
      if (res.ok) {
        const data = await res.json();
        setUrgentRequests(data.urgentRequests || []);
      }
    } catch (err) {
      console.error("Urgent requests error:", err);
    } finally {
      setIsLoadingUrgent(false);
    }
  }, [API_BASE_URL, getAuthHeaders]);

  // ── Load Alerts from Backend ─────────────────────────────────────────────
  const loadAlerts = useCallback(async () => {
    setIsLoadingAlerts(true);
    try {
      const res = await fetch(`${API_BASE_URL}/hospitals/alerts`, {
        headers: getAuthHeaders(),
      });
      if (res.ok) {
        const data = await res.json();
        setAlerts(data.alerts || []);
      } else {
        // Fallback to sample alerts if backend fails
        setAlerts([
          { id: 1, type: "urgent", message: "Blood stock for O- is critically low (2 units)", time: "2 min ago", read: false, category: "inventory" },
          { id: 2, type: "info", message: "New donor registration: Tharindu Fernando (B+)", time: "1 hour ago", read: true, category: "donor" },
          { id: 3, type: "success", message: "Emergency request #REQ7842 has been fulfilled", time: "Yesterday", read: true, category: "request" },
          { id: 4, type: "warning", message: "A+ blood stock running low (4 units remaining)", time: "3 hours ago", read: false, category: "inventory" },
          { id: 5, type: "urgent", message: "Urgent request from City Hospital for B- blood", time: "30 min ago", read: false, category: "request" },
        ]);
      }
    } catch (err) {
      console.error("Alerts load error:", err);
      // Fallback to sample alerts
      setAlerts([
        { id: 1, type: "urgent", message: "Blood stock for O- is critically low (2 units)", time: "2 min ago", read: false, category: "inventory" },
        { id: 2, type: "info", message: "New donor registration: Tharindu Fernando (B+)", time: "1 hour ago", read: true, category: "donor" },
        { id: 3, type: "success", message: "Emergency request #REQ7842 has been fulfilled", time: "Yesterday", read: true, category: "request" },
      ]);
    } finally {
      setIsLoadingAlerts(false);
    }
  }, [API_BASE_URL, getAuthHeaders]);

  // ── Load Hospital Requests ───────────────────────────────────────────────
  const loadHospitalRequests = useCallback(async () => {
    setIsLoadingRequests(true);
    try {
      const res = await fetch(`${API_BASE_URL}/hospitals/hospital-requests`, {
        headers: getAuthHeaders(),
      });
      if (res.ok) {
        const data = await res.json();
        setHospitalRequests(data.requests || []);
        
        // Calculate stats
        const requests = data.requests || [];
        setRequestStats({
          total: requests.length,
          pending: requests.filter(r => r.status === 'Pending').length,
          fulfilled: requests.filter(r => r.status === 'Fulfilled').length,
          cancelled: requests.filter(r => r.status === 'Cancelled').length,
          critical: requests.filter(r => r.urgency === 'Critical').length,
          urgent: requests.filter(r => r.urgency === 'Urgent').length
        });
      }
    } catch (err) {
      console.error("Load hospital requests error:", err);
    } finally {
      setIsLoadingRequests(false);
    }
  }, [API_BASE_URL, getAuthHeaders]);

  // ── Create Hospital Request ──────────────────────────────────────────────
  const createHospitalRequest = async (e) => {
    e.preventDefault();
    
    // Validate form
    if (!requestForm.itemName || !requestForm.reason || !requestForm.contactPerson) {
      alert('Please fill in all required fields');
      return;
    }
    
    setIsSubmittingRequest(true);
    try {
      const res = await fetch(`${API_BASE_URL}/hospitals/hospital-requests`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify(requestForm)
      });
      
      const data = await res.json();
      
      if (res.ok) {
        alert('✅ Request created successfully!');
        setIsRequestModalOpen(false);
        setRequestForm({
          itemType: 'Blood',
          itemName: '',
          quantity: 1,
          urgency: 'Normal',
          reason: '',
          contactPerson: ''
        });
        loadHospitalRequests();
        refreshData();
      } else {
        alert(data.message || 'Failed to create request');
      }
    } catch (err) {
      console.error('Create request error:', err);
      alert('Error creating request. Please try again.');
    } finally {
      setIsSubmittingRequest(false);
    }
  };

  // ── Submit Emergency Hospital Request ──────────────────────────────────────────────
  const submitEmergencyHospitalRequest = async (e) => {
    e.preventDefault();
    
    // Validate form
    if (!emergencyRequestForm.itemName || !emergencyRequestForm.reason || !emergencyRequestForm.contactPerson) {
      alert('Please fill in all required fields');
      return;
    }
    
    setIsSubmittingEmergency(true);
    try {
      const res = await fetch(`${API_BASE_URL}/hospitals/hospital-requests`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify(emergencyRequestForm)
      });
      
      const data = await res.json();
      
      if (res.ok) {
        alert('🚨 Emergency request sent successfully! Nearby hospitals have been notified.');
        setIsEmergencyRequestModalOpen(false);
        setEmergencyRequestForm({
          itemType: 'Blood',
          itemName: '',
          quantity: 1,
          urgency: 'Critical',
          reason: '',
          contactPerson: ''
        });
        loadHospitalRequests();
        refreshData();
      } else {
        alert(data.message || 'Failed to send emergency request');
      }
    } catch (err) {
      console.error('Emergency request error:', err);
      alert('Error sending emergency request. Please try again.');
    } finally {
      setIsSubmittingEmergency(false);
    }
  };

  // ── Update Request Fulfillment ───────────────────────────────────────────
  const updateFulfillment = async (requestId, quantity) => {
    if (!quantity || quantity <= 0) {
      alert('Please enter a valid quantity');
      return;
    }
    
    try {
      const res = await fetch(`${API_BASE_URL}/hospitals/hospital-requests/${requestId}/fulfill`, {
        method: 'PATCH',
        headers: getAuthHeaders(),
        body: JSON.stringify({ quantity })
      });
      
      const data = await res.json();
      
      if (res.ok) {
        alert(`✅ Successfully fulfilled ${quantity} units!`);
        loadHospitalRequests();
        refreshData();
      } else {
        alert(data.message || 'Failed to update fulfillment');
      }
    } catch (err) {
      console.error('Update fulfillment error:', err);
      alert('Error updating fulfillment');
    }
  };

  // ── Cancel Request ───────────────────────────────────────────────────────
  const cancelHospitalRequest = async (requestId) => {
    if (!window.confirm('Are you sure you want to cancel this request?')) return;
    
    try {
      const res = await fetch(`${API_BASE_URL}/hospitals/hospital-requests/${requestId}/cancel`, {
        method: 'PATCH',
        headers: getAuthHeaders()
      });
      
      if (res.ok) {
        alert('Request cancelled successfully');
        loadHospitalRequests();
        refreshData();
      } else {
        const data = await res.json();
        alert(data.message || 'Failed to cancel request');
      }
    } catch (err) {
      console.error('Cancel request error:', err);
      alert('Error cancelling request');
    }
  };

  // ── Add Response to Request ──────────────────────────────────────────────
  const addResponse = async (requestId, offeredQuantity, message) => {
    try {
      const res = await fetch(`${API_BASE_URL}/hospitals/hospital-requests/${requestId}/respond`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify({ offeredQuantity, message })
      });
      
      if (res.ok) {
        alert('Response added successfully');
        loadHospitalRequests();
      } else {
        alert('Failed to add response');
      }
    } catch (err) {
      console.error('Add response error:', err);
      alert('Error adding response');
    }
  };

  // ── Load dashboard data ───────────────────────────────────────────────────
  const loadDashboardData = useCallback(async () => {
    setIsLoading(true);
    setErrorMessage("");
    try {
      const res = await fetch(`${API_BASE_URL}/hospitals/dashboard`, {
        headers: getAuthHeaders(),
      });
      if (res.status === 401) {
        handleLogout();
        return;
      }
      if (!res.ok) throw new Error("Failed to load dashboard");

      const data = await res.json();

      setHospitalName(
        data.hospitalName || localStorage.getItem("name") || "Hospital",
      );
      setBloodStocks(data.bloodStocks || []);
      setPatientRequests(data.patientRequests || []);
      setAvailableDonors(data.availableDonors || []);
      
      if (data.urgentRequests) setUrgentRequests(data.urgentRequests);

      setIsLoading(false);
      loadUrgentRequests();
      loadAlerts();
      loadHospitalRequests();
    } catch (err) {
      console.error("Dashboard error:", err);
      setErrorMessage(
        "Unable to connect to server. Please check your connection.",
      );
      setIsLoading(false);
    }
  }, [API_BASE_URL, getAuthHeaders, handleLogout, loadUrgentRequests, loadAlerts, loadHospitalRequests]);

  // ── Update Blood Inventory ────────────────────────────────────────────────
  const updateBloodInventory = async () => {
    let bloodTypeToUpdate = selectedBloodType;
    
    // Handle new blood type
    if (selectedBloodType === "New Blood Type") {
      if (!newBloodType) {
        alert("Please select or enter a blood type");
        return;
      }
      bloodTypeToUpdate = newBloodType;
    }
    
    if (!bloodTypeToUpdate || inventoryQuantity <= 0) {
      alert("Please enter a valid quantity");
      return;
    }

    setIsUpdatingInventory(true);
    try {
      let updatedStock = [...bloodStocks];
      const stockIndex = updatedStock.findIndex(
        stock => stock.bloodType === bloodTypeToUpdate
      );

      let newQuantity = 0;
      if (inventoryAction === "add") {
        newQuantity = (updatedStock[stockIndex]?.units || 0) + inventoryQuantity;
      } else if (inventoryAction === "remove") {
        newQuantity = Math.max(0, (updatedStock[stockIndex]?.units || 0) - inventoryQuantity);
      } else if (inventoryAction === "set") {
        newQuantity = inventoryQuantity;
      }

      if (stockIndex >= 0) {
        updatedStock[stockIndex].units = newQuantity;
      } else {
        updatedStock.push({ bloodType: bloodTypeToUpdate, units: newQuantity });
      }

      // Remove blood types with 0 units
      updatedStock = updatedStock.filter(stock => stock.units > 0);

      // Send update to backend
      const response = await fetch(`${API_BASE_URL}/hospitals/inventory/update`, {
        method: "POST",
        headers: getAuthHeaders(),
        body: JSON.stringify({
          bloodInventory: updatedStock.reduce((acc, stock) => {
            acc[stock.bloodType] = stock.units;
            return acc;
          }, {}),
          updateReason: inventoryReason || `${inventoryAction} ${inventoryQuantity} units`,
          bloodType: bloodTypeToUpdate,
          action: inventoryAction,
          quantity: inventoryQuantity
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setBloodStocks(data.bloodStocks || updatedStock);
        alert(`Successfully ${inventoryAction === "add" ? "added" : inventoryAction === "remove" ? "removed" : "set"} ${inventoryQuantity} units of ${bloodTypeToUpdate} blood`);
        
        // Reload alerts after inventory update
        loadAlerts();
        
        closeInventoryModal();
        refreshData();
      } else {
        const error = await response.json();
        alert(error.message || "Failed to update inventory");
      }
    } catch (err) {
      console.error("Inventory update error:", err);
      alert("Error updating inventory. Please try again.");
    } finally {
      setIsUpdatingInventory(false);
    }
  };

  // ── Open inventory management modal ──────────────────────────────────────
  const openInventoryModal = (bloodType, action = "add") => {
    if (bloodType === "New Blood Type") {
      setNewBloodType("");
      setShowCustomBloodType(false);
      setSelectedBloodType(bloodType);
    } else {
      setSelectedBloodType(bloodType);
    }
    setInventoryAction(action);
    setInventoryQuantity(0);
    setInventoryReason("");
    setIsInventoryModalOpen(true);
  };

  const closeInventoryModal = () => {
    setIsInventoryModalOpen(false);
    setSelectedBloodType(null);
    setInventoryQuantity(0);
    setInventoryReason("");
    setNewBloodType("");
    setShowCustomBloodType(false);
  };

  // Add this function to handle blood type selection
  const handleBloodTypeSelect = (type) => {
    if (type === "custom") {
      setShowCustomBloodType(true);
      setSelectedBloodType("");
    } else {
      setShowCustomBloodType(false);
      setSelectedBloodType(type);
    }
  };

  // ── Bulk update inventory ─────────────────────────────────────────────────
  const bulkUpdateInventory = async () => {
    const updates = bloodStocks.map(stock => ({
      bloodType: stock.bloodType,
      units: stock.units
    }));
    
    try {
      const response = await fetch(`${API_BASE_URL}/hospitals/inventory/bulk-update`, {
        method: "POST",
        headers: getAuthHeaders(),
        body: JSON.stringify({ inventory: updates }),
      });
      
      if (response.ok) {
        alert("Inventory synchronized successfully");
        refreshData();
      }
    } catch (err) {
      console.error("Bulk update error:", err);
    }
  };

  // ── On mount: auth check ──────────────────────────────────────────────────
  useEffect(() => {
    const token = localStorage.getItem("jwt_token");
    const userType = localStorage.getItem("userType");
    const hospitalId = localStorage.getItem("hospitalId");
    if (!token || userType !== "hospital" || !hospitalId) {
      navigate("/login");
      return;
    }
    loadDashboardData();
  }, [navigate, loadDashboardData]);

  // Load requests when section changes
  useEffect(() => {
    if (activeSection === "requests") {
      loadHospitalRequests();
    }
  }, [activeSection, loadHospitalRequests]);

  // ── Load profile (lazy — only when tab clicked) ───────────────────────────
  const loadProfileData = async () => {
    if (profileData) return;
    setIsLoadingProfile(true);
    try {
      const res = await fetch(`${API_BASE_URL}/hospitals/profile`, {
        headers: getAuthHeaders(),
      });
      if (res.ok) {
        const data = await res.json();
        setProfileData(data.hospital);
      }
    } catch (err) {
      console.error("Profile error:", err);
    } finally {
      setIsLoadingProfile(false);
    }
  };

  const handleProfileClick = () => {
    setActiveSection("profile");
    loadProfileData();
  };

  const refreshData = () => {
    loadDashboardData();
    loadUrgentRequests();
    loadAlerts();
    loadHospitalRequests();
  };

  // ── Update Profile ─────────────────────────────────────────────────────────
  const updateProfile = async (e) => {
    e.preventDefault();
    setIsUpdatingProfile(true);
    
    try {
      const res = await fetch(`${API_BASE_URL}/hospitals/profile`, {
        method: 'PUT',
        headers: getAuthHeaders(),
        body: JSON.stringify({
          contact: editForm.contact,
          address: editForm.address,
          description: editForm.description,
          workingHours: editForm.workingHours,
          emergencyContact: editForm.emergencyContact
        })
      });
      
      const data = await res.json();
      
      if (res.ok) {
        alert('✅ Profile updated successfully!');
        setProfileData(data.hospital);
        setIsEditingProfile(false);
        refreshData();
      } else {
        alert(data.message || 'Failed to update profile');
      }
    } catch (err) {
      console.error('Profile update error:', err);
      alert('Error updating profile. Please try again.');
    } finally {
      setIsUpdatingProfile(false);
    }
  };

  // ── Request Field Change (for locked fields) ──────────────────────────────
  const requestFieldChange = (fieldName) => {
    const newValue = prompt(`Enter new ${fieldName}:`);
    if (newValue) {
      alert(`Change request for ${fieldName} has been submitted for admin approval.`);
      // Here you would call an API to create a change request
    }
  };

  // ── Accept urgent request ─────────────────────────────────────────────────
  const acceptUrgentRequest = async (requestId) => {
    try {
      const res = await fetch(
        `${API_BASE_URL}/hospitals/urgent-requests/${requestId}/accept`,
        {
          method: "POST",
          headers: getAuthHeaders(),
          body: JSON.stringify({
            messageToPatient: "Your urgent request has been accepted.",
          }),
        },
      );
      if (res.ok) {
        alert("Request accepted — notification sent");
        refreshData();
      } else {
        const e = await res.json();
        alert(e.message || "Failed");
      }
    } catch (err) {
      alert(`Error: ${err.message}`);
    }
  };

  // ── Complete a patient request ────────────────────────────────────────────
  const completeRequest = async (requestId) => {
    try {
      const res = await fetch(
        `${API_BASE_URL}/hospitals/requests/${requestId}/complete`,
        {
          method: "POST",
          headers: getAuthHeaders(),
        },
      );
      if (res.ok) {
        alert("Request marked as completed");
        refreshData();
      } else {
        const e = await res.json();
        alert(e.message || "Failed");
      }
    } catch (err) {
      alert(`Error: ${err.message}`);
    }
  };

  // ── Emergency alert - now opens modal for hospital request ─────────────────────────────────
  const triggerEmergencyAlert = () => {
    // Open the modal instead of directly sending alert
    setIsEmergencyRequestModalOpen(true);
  };

  // ── Mark alert as read ────────────────────────────────────────────────────
  const markAlertAsRead = async (alertId) => {
    try {
      // Try to update on backend
      await fetch(`${API_BASE_URL}/hospitals/alerts/${alertId}/read`, {
        method: "POST",
        headers: getAuthHeaders(),
      });
    } catch (err) {
      console.error("Error marking alert as read:", err);
    }
    
    // Update frontend state
    setAlerts(alerts.map(alert => 
      alert.id === alertId ? { ...alert, read: true } : alert
    ));
  };

  // ── Mark all alerts as read ───────────────────────────────────────────────
  const markAllAlertsAsRead = async () => {
    try {
      await fetch(`${API_BASE_URL}/hospitals/alerts/mark-all-read`, {
        method: "POST",
        headers: getAuthHeaders(),
      });
    } catch (err) {
      console.error("Error marking all alerts as read:", err);
    }
    
    setAlerts(alerts.map(alert => ({ ...alert, read: true })));
  };

  // ── Open alert detail modal ─────────────────────────────────────────────────
  const openAlertDetailModal = (alert) => {
    setSelectedAlert(alert);
    setIsAlertDetailModalOpen(true);
    // Mark as read when opened
    if (!alert.read) {
      markAlertAsRead(alert.id);
    }
  };

  // ── Handle alert click - now opens detail modal instead of just marking read ──
  const handleAlertClick = (alert) => {
    openAlertDetailModal(alert);
  };

  // ── Instruction modal handlers ────────────────────────────────────────────
  const openInstructionModal = (instruction) => {
    setSelectedInstruction(instruction);
    setIsModalOpen(true);
  };

  const closeInstructionModal = () => {
    setIsModalOpen(false);
    setSelectedInstruction(null);
  };

  // ── Helpers ───────────────────────────────────────────────────────────────
  const getBloodStockStatus = (units) => {
    if (units <= 5)
      return { color: "#E53935", bg: "#FFF5F5", label: "CRITICAL", icon: "🔴" };
    if (units <= 10) return { color: "#FB8C00", bg: "#FFF8F0", label: "LOW", icon: "⚠️" };
    return { color: "#43A047", bg: "#F1F8F1", label: "NORMAL", icon: "✅" };
  };

  // Maps DB status + urgency to badge colours
  const getStatusStyle = (status, urgency) => {
    if (status === "Active") {
      if (urgency === "Urgent") return { color: "#FB8C00", bg: "#FFF8F0" };
      if (urgency === "Critical") return { color: "#E53935", bg: "#FFEBEE" };
      return { color: "#1976D2", bg: "#E3F2FD" };
    }
    if (status === "Matched" || urgency === "Critical")
      return { color: "#E53935", bg: "#FFEBEE" };
    if (status === "Pending" && urgency === "Urgent")
      return { color: "#FB8C00", bg: "#FFF8F0" };
    if (status === "Pending") return { color: "#1976D2", bg: "#E3F2FD" };
    if (status === "Completed") return { color: "#43A047", bg: "#F1F8F1" };
    return { color: "#6B7280", bg: "#F3F4F6" };
  };

  // Get priority color for instruction cards
  const getPriorityColor = (priority) => {
    switch(priority) {
      case "Critical":
        return { color: "#E53935", bg: "#FFEBEE", border: "#FFCDD2" };
      case "High":
        return { color: "#FB8C00", bg: "#FFF8F0", border: "#FFE0B2" };
      case "Medium":
        return { color: "#1976D2", bg: "#E3F2FD", border: "#BBDEFB" };
      default:
        return { color: "#43A047", bg: "#F1F8F1", border: "#C8E6C9" };
    }
  };

  // Get alert type style
  const getAlertStyle = (type) => {
    switch(type) {
      case "urgent":
        return { bg: "#FFEBEE", color: "#E53935", icon: "🔴", label: "Critical" };
      case "warning":
        return { bg: "#FFF8F0", color: "#FB8C00", icon: "⚠️", label: "Warning" };
      case "success":
        return { bg: "#F1F8F1", color: "#43A047", icon: "✅", label: "Success" };
      default:
        return { bg: "#E3F2FD", color: "#1976D2", icon: "ℹ️", label: "Info" };
    }
  };

  // Get category icon
  const getCategoryIcon = (category) => {
    switch(category) {
      case "inventory":
        return "🩸";
      case "request":
        return "📋";
      case "donation":
        return "🤝";
      case "donor":
        return "👤";
      case "hospital_request":
        return "🏥";
      default:
        return "🔔";
    }
  };

  // Get time display
  const formatTime = (timeStr) => {
    if (!timeStr) return "Just now";
    if (timeStr.includes("min") || timeStr.includes("hour") || timeStr.includes("day")) {
      return timeStr;
    }
    return timeStr;
  };

  // ── Loading / error screens ───────────────────────────────────────────────
  if (isLoading) {
    return (
      <div style={styles.loadingContainer}>
        <div style={styles.loadingSpinner} />
        <p style={{ color: "#64748B", fontFamily: "DM Sans, sans-serif" }}>
          Loading dashboard...
        </p>
      </div>
    );
  }

  if (errorMessage) {
    return (
      <div style={styles.errorContainer}>
        <div style={{ fontSize: "64px" }}>⚠️</div>
        <p style={{ fontSize: "16px", color: "#E53935", textAlign: "center" }}>
          {errorMessage}
        </p>
        <button style={styles.retryButton} onClick={refreshData}>
          Try Again
        </button>
        <button
          style={{
            ...styles.retryButton,
            background: "#6B7280",
            marginTop: "10px",
          }}
          onClick={handleLogout}
        >
          Logout
        </button>
      </div>
    );
  }

  // Count unread alerts
  const unreadAlertsCount = alerts.filter(a => !a.read).length;

  // ── Render ────────────────────────────────────────────────────────────────
  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap');
        * { margin:0; padding:0; box-sizing:border-box; }
        .ll-app { display:flex; min-height:100vh; background:#F1F5F9; font-family:'DM Sans',-apple-system,sans-serif; }
        
        /* Sidebar */
        .ll-sidebar { width:230px; background:white; border-right:1px solid #E2E8F0; display:flex; flex-direction:column; position:fixed; top:0; left:0; height:100vh; z-index:100; }
        .ll-logo { padding:20px 20px 18px; border-bottom:1px solid #E2E8F0; display:flex; align-items:center; gap:10px; }
        .ll-logo-icon { width:38px; height:38px; background:#2563EB; border-radius:10px; display:flex; align-items:center; justify-content:center; font-size:18px; }
        .ll-logo-name { font-size:14px; font-weight:700; color:#0F172A; line-height:1.2; }
        .ll-logo-sub  { font-size:11px; color:#94A3B8; }
        .ll-nav { padding:14px 10px; flex:1; display:flex; flex-direction:column; gap:2px; }
        .ll-nav-item { display:flex; align-items:center; gap:10px; padding:10px 12px; border-radius:8px; font-size:13.5px; font-weight:500; color:#64748B; cursor:pointer; transition:all 0.15s; border:none; background:none; width:100%; text-align:left; font-family:'DM Sans',sans-serif; text-decoration:none; }
        .ll-nav-item:hover  { background:#F8FAFC; color:#0F172A; }
        .ll-nav-item.active { background:#EFF6FF; color:#2563EB; font-weight:600; }
        .ll-nav-icon { font-size:16px; width:20px; text-align:center; }
        .ll-sys-health { padding:14px 20px; border-top:1px solid #E2E8F0; font-size:11px; color:#94A3B8; text-transform:uppercase; letter-spacing:0.06em; font-weight:600; display:flex; align-items:center; gap:6px; }
        .ll-pulse-dot { width:7px; height:7px; background:#10B981; border-radius:50%; animation:llPulse 2s infinite; }
        @keyframes llPulse { 0%,100%{opacity:1} 50%{opacity:0.3} }
        
        /* Main */
        .ll-main { margin-left:230px; flex:1; display:flex; flex-direction:column; min-height:100vh; }
        .ll-topbar { background:white; border-bottom:1px solid #E2E8F0; padding:0 28px; height:64px; display:flex; align-items:center; justify-content:space-between; position:sticky; top:0; z-index:50; }
        .ll-topbar-left h1 { font-size:16px; font-weight:700; color:#0F172A; }
        .ll-topbar-left p  { font-size:12px; color:#94A3B8; margin-top:2px; }
        .ll-topbar-right   { display:flex; align-items:center; gap:10px; }
        .ll-btn { padding:7px 16px; border-radius:8px; font-size:13px; font-weight:600; cursor:pointer; border:none; transition:all 0.15s; font-family:'DM Sans',sans-serif; }
        .ll-btn-outline { background:white; color:#374151; border:1px solid #D1D5DB; }
        .ll-btn-outline:hover { background:#F9FAFB; }
        .ll-btn-primary { background:#2563EB; color:white; }
        .ll-btn-primary:hover { background:#1D4ED8; }
        .ll-avatar { width:36px; height:36px; background:#F1F5F9; border:1px solid #E2E8F0; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:14px; cursor:pointer; }
        .ll-content { padding:24px 28px; display:flex; flex-direction:column; gap:20px; }
        
        /* Cards */
        .blood-storage-card { background:white; border-radius:16px; padding:20px; border:1px solid #E2E8F0; }
        .card-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:16px; }
        .card-title  { font-size:15px; font-weight:700; color:#0F172A; }
        .update-link { color:#2563EB; font-size:13px; font-weight:600; cursor:pointer; }
        .blood-grid  { display:grid; grid-template-columns:repeat(4,1fr); gap:12px; }
        .blood-item  { padding:12px; border-radius:12px; text-align:center; border:1px solid rgba(0,0,0,0.1); cursor:pointer; transition:all 0.2s ease; }
        .blood-item:hover { transform:translateY(-2px); box-shadow:0 4px 12px rgba(0,0,0,0.1); }
        .blood-type  { font-size:14px; font-weight:800; margin-bottom:6px; }
        .blood-units { font-size:16px; font-weight:700; }
        .blood-units small { font-size:9px; font-weight:500; }
        
        .critical-alert { background:#FFF5F5; border:1px solid #FFCDD2; border-radius:16px; padding:20px; text-align:center; }
        .alert-icon  { width:44px; height:44px; background:#FFEBEE; border-radius:50%; display:flex; align-items:center; justify-content:center; margin:0 auto 10px; font-size:22px; }
        .alert-title { font-size:16px; font-weight:700; color:#E53935; margin-bottom:6px; }
        .alert-desc  { font-size:13px; color:#6B7280; margin-bottom:14px; }
        .emergency-btn { width:100%; padding:12px; background:#E53935; color:white; border:none; border-radius:12px; font-weight:700; cursor:pointer; font-family:'DM Sans',sans-serif; }
        
        .section-header { display:flex; align-items:center; gap:8px; margin-bottom:12px; }
        .section-header h3 { font-size:15px; font-weight:700; color:#0F172A; }
        
        .urgent-scroll { display:flex; gap:12px; overflow-x:auto; padding:4px; }
        .urgent-card   { min-width:265px; background:#1F2937; border-radius:16px; padding:16px; color:white; }
        .urgent-badge  { display:inline-block; background:#E53935; padding:5px 10px; border-radius:6px; font-size:12px; font-weight:bold; }
        
        /* Patient request cards */
        .request-card { background:white; border-radius:14px; padding:16px; margin-bottom:10px; box-shadow:0 2px 8px rgba(0,0,0,0.05); border:1px solid #F1F5F9; }
        .request-top  { display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:10px; }
        .request-name { font-weight:700; font-size:15px; color:#0F172A; }
        .request-time { font-size:11px; color:#9E9E9E; }
        .request-meta { display:flex; flex-wrap:wrap; gap:8px; margin-bottom:12px; }
        .meta-pill    { display:inline-flex; align-items:center; gap:4px; padding:4px 10px; border-radius:20px; font-size:12px; font-weight:600; }
        .request-notes { font-size:12px; color:#6B7280; margin-bottom:12px; padding:8px 10px; background:#F8FAFC; border-radius:8px; border-left:3px solid #E2E8F0; }
        .request-actions { display:flex; gap:8px; }
        
        .donor-row { display:flex; align-items:center; gap:12px; padding:12px 14px; border-bottom:1px solid #EEF2F7; }
        
        /* Instruction rows */
        .instruction-row { padding:12px 14px; border-bottom:1px solid #EEF2F7; cursor:pointer; transition:all 0.2s ease; }
        .instruction-row:hover { background:#F8FAFC; transform:translateX(2px); }
        
        /* Alert rows - Enhanced */
        .alert-row { 
          padding: 16px; 
          border-bottom: 1px solid #E2E8F0; 
          cursor: pointer; 
          transition: all 0.2s ease; 
          display: flex; 
          align-items: flex-start; 
          gap: 12px;
          background: white;
        }
        .alert-row:hover { 
          background: #F8FAFC; 
          transform: translateX(2px);
        }
        .alert-unread { 
          background: #FFF5F5;
          border-left: 4px solid #E53935;
        }
        .alert-read { 
          opacity: 0.75;
          background: white;
        }
        .alert-badge {
          display: inline-block;
          padding: 2px 8px;
          border-radius: 12px;
          font-size: 10px;
          font-weight: 600;
          margin-left: 8px;
        }
        .alert-category {
          font-size: 10px;
          padding: 2px 8px;
          border-radius: 12px;
          background: #F3F4F6;
          color: #6B7280;
        }
        
        /* Modal Styles */
        .modal-overlay {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.5);
          backdrop-filter: blur(4px);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 1000;
          animation: fadeIn 0.2s ease;
        }
        .modal-container {
          background: white;
          border-radius: 24px;
          width: 90%;
          max-width: 500px;
          max-height: 85vh;
          overflow-y: auto;
          box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
          animation: slideUp 0.3s ease;
        }
        .modal-header {
          padding: 20px 24px;
          border-bottom: 1px solid #E2E8F0;
          display: flex;
          justify-content: space-between;
          align-items: center;
          position: sticky;
          top: 0;
          background: white;
          border-radius: 24px 24px 0 0;
        }
        .modal-header h2 {
          font-size: 18px;
          font-weight: 700;
          color: #0F172A;
          margin: 0;
        }
        .modal-close {
          background: none;
          border: none;
          font-size: 24px;
          cursor: pointer;
          color: #94A3B8;
          transition: color 0.2s;
          line-height: 1;
          padding: 4px 8px;
          border-radius: 8px;
        }
        .modal-close:hover {
          color: #E53935;
          background: #FFF5F5;
        }
        .modal-body {
          padding: 24px;
        }
        .inventory-form {
          display: flex;
          flex-direction: column;
          gap: 20px;
        }
        .form-group {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }
        .form-label {
          font-size: 13px;
          font-weight: 600;
          color: #374151;
        }
        .form-input {
          padding: 10px 12px;
          border: 1px solid #E2E8F0;
          border-radius: 8px;
          font-size: 14px;
          font-family: 'DM Sans', sans-serif;
        }
        .form-input:focus {
          outline: none;
          border-color: #2563EB;
          ring: 2px solid rgba(37, 99, 235, 0.1);
        }
        .action-buttons {
          display: flex;
          gap: 10px;
          margin-top: 10px;
        }
        .action-btn {
          flex: 1;
          padding: 10px;
          border: none;
          border-radius: 8px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s;
          font-family: 'DM Sans', sans-serif;
        }
        .action-btn:hover {
          transform: translateY(-1px);
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .inventory-stats {
          background: #F8FAFC;
          padding: 12px;
          border-radius: 8px;
          margin: 10px 0;
        }
        .detail-section {
          display: flex;
          flex-direction: column;
          gap: 6px;
        }
        .detail-label {
          font-size: 11px;
          text-transform: uppercase;
          letter-spacing: 0.06em;
          color: #94A3B8;
          font-weight: 600;
        }
        .detail-value {
          font-size: 14px;
          color: #0F172A;
          font-weight: 500;
          line-height: 1.5;
        }
        .detail-value.large {
          font-size: 16px;
          font-weight: 700;
          color: #2563EB;
        }
        .divider {
          height: 1px;
          background: #E2E8F0;
          margin: 8px 0;
        }
        .priority-badge {
          display: inline-block;
          padding: 4px 12px;
          border-radius: 20px;
          font-size: 11px;
          font-weight: 700;
          text-transform: uppercase;
        }
        
        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }
        @keyframes slideUp {
          from {
            opacity: 0;
            transform: translateY(20px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
        
        /* Profile */
        .profile-section { background:white; border-radius:16px; border:1px solid #E2E8F0; overflow:hidden; }
        .profile-header  { background:linear-gradient(135deg,#2563EB 0%,#1D4ED8 100%); padding:32px 28px; color:white; display:flex; align-items:center; gap:20px; }
        .profile-avatar  { width:72px; height:72px; background:rgba(255,255,255,0.2); border-radius:16px; display:flex; align-items:center; justify-content:center; font-size:32px; border:2px solid rgba(255,255,255,0.3); }
        .profile-name    { font-size:20px; font-weight:700; margin-bottom:4px; }
        .profile-sub     { font-size:13px; opacity:0.85; }
        .profile-badge   { display:inline-flex; align-items:center; gap:4px; background:rgba(255,255,255,0.2); padding:4px 10px; border-radius:20px; font-size:11px; font-weight:600; margin-top:8px; }
        .profile-body    { padding:24px 28px; }
        .profile-grid    { display:grid; grid-template-columns:1fr 1fr; gap:16px; }
        .profile-field   { display:flex; flex-direction:column; gap:4px; }
        .field-label     { font-size:11px; text-transform:uppercase; letter-spacing:0.06em; color:#94A3B8; font-weight:600; }
        .field-value     { font-size:14px; color:#0F172A; font-weight:500; }
        .profile-divider { height:1px; background:#E2E8F0; margin:20px 0; }
        
        /* Inventory */
        .inventory-section { background:white; border-radius:16px; border:1px solid #E2E8F0; padding:24px; }
        .inventory-grid    { display:grid; grid-template-columns:repeat(4,1fr); gap:16px; margin-top:16px; }
        .inventory-item    { border-radius:14px; padding:18px 14px; text-align:center; border:1.5px solid; cursor:pointer; transition:all 0.2s ease; }
        .inventory-item:hover { transform:translateY(-2px); box-shadow:0 4px 12px rgba(0,0,0,0.1); }
        .inventory-type    { font-size:18px; font-weight:900; margin-bottom:8px; }
        .inventory-units   { font-size:22px; font-weight:700; margin-bottom:4px; }
        .inventory-label   { font-size:10px; font-weight:700; text-transform:uppercase; letter-spacing:0.06em; }
        .inventory-bar     { height:4px; border-radius:2px; margin-top:10px; background:#E2E8F0; }
        .inventory-fill    { height:4px; border-radius:2px; }
        
        select.form-input {
          cursor: pointer;
          background-color: white;
        }
        select.form-input:hover {
          border-color: #2563EB;
        }
        .inventory-stats button {
          transition: all 0.2s;
        }
        .inventory-stats button:hover {
          background: #E2E8F0;
        }
        
        /* Stats Cards */
        .stats-grid {
          display: grid;
          grid-template-columns: repeat(3, 1fr);
          gap: 16px;
          margin-bottom: 20px;
        }
        .stat-card {
          background: white;
          border-radius: 16px;
          padding: 20px;
          text-align: center;
          border: 1px solid #E2E8F0;
        }
        .stat-value {
          font-size: 32px;
          font-weight: 800;
          color: #2563EB;
        }
        .stat-label {
          font-size: 13px;
          color: #6B7280;
          margin-top: 8px;
        }
        
        @media (max-width:768px) {
          .ll-sidebar,.ll-main { margin-left:0; }
          .ll-sidebar { display:none; }
          .blood-grid,.inventory-grid { grid-template-columns:repeat(2,1fr); }
          .profile-grid { grid-template-columns:1fr; }
          .stats-grid { grid-template-columns: 1fr; }
        }
      `}</style>
      
      <div className="ll-app">
        {/* ── Sidebar ── */}
        <aside className="ll-sidebar">
          <div className="ll-logo">
            <div className="ll-logo-icon">🏥</div>
            <div>
              <div className="ll-logo-name">LifeLink</div>
              <div className="ll-logo-sub">Hospital Portal</div>
            </div>
          </div>
          <nav className="ll-nav">
            <button
              className={`ll-nav-item${activeSection === "dashboard" ? " active" : ""}`}
              onClick={() => setActiveSection("dashboard")}
            >
              <span className="ll-nav-icon">⊞</span> Dashboard
            </button>
            <button
              className={`ll-nav-item${activeSection === "inventory" ? " active" : ""}`}
              onClick={() => setActiveSection("inventory")}
            >
              <span className="ll-nav-icon">🩸</span> Blood Inventory
            </button>
            <button
              className={`ll-nav-item${activeSection === "alerts" ? " active" : ""}`}
              onClick={() => setActiveSection("alerts")}
            >
              <span className="ll-nav-icon">🔔</span> Alerts
              {unreadAlertsCount > 0 && (
                <span style={{
                  background: "#E53935",
                  color: "white",
                  fontSize: "10px",
                  borderRadius: "10px",
                  padding: "2px 6px",
                  marginLeft: "auto"
                }}>
                  {unreadAlertsCount}
                </span>
              )}
            </button>
            <button
              className={`ll-nav-item${activeSection === "requests" ? " active" : ""}`}
              onClick={() => setActiveSection("requests")}
            >
              <span className="ll-nav-icon">📋</span> Hospital Requests
              {requestStats.pending > 0 && (
                <span style={{
                  background: "#E53935",
                  color: "white",
                  fontSize: "10px",
                  borderRadius: "10px",
                  padding: "2px 6px",
                  marginLeft: "auto"
                }}>
                  {requestStats.pending}
                </span>
              )}
            </button>
            <Link to="/bloodbank/requests" className="ll-nav-item">
              <span className="ll-nav-icon">📋</span> Patient Requests
            </Link>
            
            <button
              className={`ll-nav-item${activeSection === "profile" ? " active" : ""}`}
              onClick={handleProfileClick}
            >
              <span className="ll-nav-icon">👤</span> Profile
            </button>
          </nav>
          <div className="ll-sys-health">
            <div className="ll-pulse-dot" />
            System Health · Cloud Synced
          </div>
        </aside>
        
        {/* ── Main ── */}
        <div className="ll-main">
          <header className="ll-topbar">
            <div className="ll-topbar-left">
              <h1>{hospitalName || "LifeLink Partner Hospital"}</h1>
              <p>LIFELINK PARTNER • Real-time monitoring</p>
            </div>
            <div className="ll-topbar-right">
              <button className="ll-btn ll-btn-outline" onClick={handleLogout}>
                Logout
              </button>
              <button
                className="ll-btn ll-btn-primary"
                onClick={handleProfileClick}
              >
                Profile
              </button>
              <div className="ll-avatar" onClick={handleProfileClick}>
                👤
              </div>
            </div>
          </header>
          
          {/* ═══════════════════ DASHBOARD ═══════════════════ */}
          {activeSection === "dashboard" && (
            <div className="ll-content">
              {/* Stats Overview */}
              <div className="stats-grid">
                <div className="stat-card">
                  <div className="stat-value">{bloodStocks.reduce((sum, s) => sum + s.units, 0)}</div>
                  <div className="stat-label">Total Blood Units</div>
                </div>
                <div className="stat-card">
                  <div className="stat-value">{patientRequests.length}</div>
                  <div className="stat-label">Active Requests</div>
                </div>
                <div className="stat-card">
                  <div className="stat-value">{unreadAlertsCount}</div>
                  <div className="stat-label">Unread Alerts</div>
                </div>
              </div>
              
              {/* Blood Storage Overview */}
              <div className="blood-storage-card">
                <div className="card-header">
                  <span className="card-title">Blood Storage Overview</span>
                  <span
                    className="update-link"
                    onClick={() => setActiveSection("inventory")}
                  >
                    View Full Inventory →
                  </span>
                </div>
                {bloodStocks.length === 0 ? (
                  <p style={{ textAlign: "center", padding: "24px", color: "#9E9E9E" }}>
                    No blood stock data available.
                  </p>
                ) : (
                  <div className="blood-grid">
                    {bloodStocks.map((stock, idx) => {
                      const s = getBloodStockStatus(stock.units);
                      return (
                        <div
                          key={idx}
                          className="blood-item"
                          style={{ background: s.bg, borderColor: s.color }}
                          onClick={() => openInventoryModal(stock.bloodType, "add")}
                        >
                          <div className="blood-type" style={{ color: s.color }}>
                            {stock.bloodType}
                          </div>
                          <div className="blood-units" style={{ color: s.color }}>
                            {stock.units} <small>units</small>
                          </div>
                          <div style={{ fontSize: "10px", marginTop: "6px", color: s.color }}>
                            {s.icon} {s.label}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
              
              {/* Critical Shortage Alert - Emergency Request Button */}
              <div className="critical-alert">
                <div className="alert-icon">🚨</div>
                <div className="alert-title">Emergency Request</div>
                <div className="alert-desc">
                  Need urgent blood, medical supplies, or equipment? Send an emergency request to all nearby hospitals.
                </div>
                <button 
                  className="emergency-btn" 
                  onClick={triggerEmergencyAlert}
                  style={{
                    background: '#E53935',
                    transition: 'all 0.2s',
                    cursor: 'pointer'
                  }}
                  onMouseEnter={(e) => e.target.style.background = '#C62828'}
                  onMouseLeave={(e) => e.target.style.background = '#E53935'}
                >
                  🚨 Trigger Emergency Request
                </button>
              </div>
              
              {/* Incoming Urgent Requests */}
              <div>
                <div className="section-header">
                  <span style={{ fontSize: "20px" }}>⚠️</span>
                  <h3>Incoming Urgent Requests</h3>
                </div>
                {isLoadingUrgent ? (
                  <p style={{ textAlign: "center", padding: "20px", color: "#94A3B8" }}>
                    Loading urgent requests...
                  </p>
                ) : urgentRequests.length === 0 ? (
                  <p style={{ textAlign: "center", padding: "20px", color: "#9E9E9E" }}>
                    No urgent requests at the moment
                  </p>
                ) : (
                  <div className="urgent-scroll">
                    {urgentRequests.map((req, idx) => (
                      <div key={idx} className="urgent-card">
                        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "14px" }}>
                          <span className="urgent-badge">IMMEDIATE ({req.timeLeft})</span>
                          <span style={{ fontSize: "11px", color: "#9CA3AF" }}>
                            #{String(req.id).slice(-6)}
                          </span>
                        </div>
                        <div style={{ fontSize: "16px", fontWeight: "700", marginBottom: "4px" }}>
                          {req.bloodGroup} Blood
                        </div>
                        <div style={{ fontSize: "13px", color: "#9CA3AF", marginBottom: "4px" }}>
                          {req.patientName}
                        </div>
                        <div style={{ fontSize: "12px", color: "#9CA3AF", marginBottom: "16px" }}>
                          {req.hospitalOrER} • {req.unitsNeeded} Units
                        </div>
                        <div style={{ display: "flex", gap: "10px" }}>
                          <button
                            onClick={() => acceptUrgentRequest(req.id)}
                            style={{
                              flex: 1,
                              padding: "8px",
                              background: "transparent",
                              border: "1px solid white",
                              borderRadius: "8px",
                              color: "white",
                              cursor: "pointer",
                              fontFamily: "DM Sans,sans-serif",
                            }}
                          >
                            Accept
                          </button>
                          <button
                            onClick={() => navigate(`/bloodbank/requests/${req.id}`)}
                            style={{
                              flex: 1,
                              padding: "8px",
                              background: "transparent",
                              border: "1px solid #6B7280",
                              borderRadius: "8px",
                              color: "#9CA3AF",
                              cursor: "pointer",
                              fontFamily: "DM Sans,sans-serif",
                            }}
                          >
                            View
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
              
              {/* Active Patient Requests */}
              <div>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "12px" }}>
                  <h3 style={{ fontSize: "15px", fontWeight: "700", color: "#0F172A" }}>
                    Active Patient Requests
                  </h3>
                  <span style={{
                    background: "#E8F0FE",
                    padding: "4px 10px",
                    borderRadius: "20px",
                    fontSize: "12px",
                    color: "#2563EB",
                    fontWeight: "600",
                  }}>
                    {patientRequests.length} Active
                  </span>
                </div>
                {patientRequests.length === 0 ? (
                  <div style={{ textAlign: "center", padding: "32px", background: "white", borderRadius: "16px", color: "#9E9E9E" }}>
                    <div style={{ fontSize: "36px", marginBottom: "8px" }}>📋</div>
                    <p style={{ fontWeight: "600" }}>No active patient requests</p>
                  </div>
                ) : (
                  patientRequests.map((req) => {
                    const ss = getStatusStyle(req.status, req.urgency);
                    return (
                      <div key={req.id} className="request-card">
                        <div className="request-top">
                          <div>
                            <div className="request-name">{req.name}</div>
                            <div style={{ fontSize: "12px", color: "#6B7280", marginTop: "2px" }}>
                              {req.hospitalName}
                            </div>
                          </div>
                          <div style={{ textAlign: "right" }}>
                            <div className="request-time">{req.timeAgo}</div>
                            <div style={{ fontSize: "10px", color: "#94A3B8", marginTop: "2px" }}>
                              #{String(req.id).slice(-6)}
                            </div>
                          </div>
                        </div>
                        <div className="request-meta">
                          <span className="meta-pill" style={{ background: "#FFF0F0", color: "#C62828" }}>
                            🩸 {req.bloodType}
                          </span>
                          <span className="meta-pill" style={{ background: "#F3F4F6", color: "#374151" }}>
                            💉 {req.units} unit{req.units !== 1 ? "s" : ""}
                          </span>
                          <span className="meta-pill" style={{ background: "#EFF6FF", color: "#1D4ED8" }}>
                            {req.requestType === "Blood" ? "🔴" : "🫀"} {req.requestType}
                          </span>
                          <span className="meta-pill" style={{ background: ss.bg, color: ss.color }}>
                            {req.urgency === "Critical" ? "🚨" : req.urgency === "Urgent" ? "⚡" : "📌"} {req.urgency}
                          </span>
                          <span className="meta-pill" style={{ background: ss.bg, color: ss.color }}>
                            {req.status === "Matched" ? "✅" : req.status === "Active" || req.status === "active" ? "🔄" : req.status === "Pending" ? "⏳" : "📋"} {req.status}
                          </span>
                          {req.donorFound && (
                            <span className="meta-pill" style={{ background: "#F0FDF4", color: "#15803D" }}>
                              👤 Donor Matched
                            </span>
                          )}
                        </div>
                        {req.notes && (
                          <div className="request-notes">📝 {req.notes}</div>
                        )}
                        <div className="request-actions">
                          <button
                            onClick={() => navigate(`/bloodbank/requests/${req.id}`)}
                            style={{
                              flex: 1,
                              padding: "9px",
                              border: "1px solid #2563EB",
                              borderRadius: "8px",
                              background: "white",
                              color: "#2563EB",
                              fontWeight: "600",
                              cursor: "pointer",
                              fontFamily: "DM Sans,sans-serif",
                              fontSize: "13px",
                            }}
                          >
                            {req.actionLabel}
                          </button>
                          {req.status === "Matched" && (
                            <button
                              onClick={() => completeRequest(req.id)}
                              style={{
                                padding: "9px 14px",
                                border: "none",
                                borderRadius: "8px",
                                background: "#F0FDF4",
                                color: "#15803D",
                                fontWeight: "600",
                                cursor: "pointer",
                                fontFamily: "DM Sans,sans-serif",
                                fontSize: "13px",
                              }}
                            >
                              ✔ Complete
                            </button>
                          )}
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
              
              {/* Available Donors Section */}
              <div>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "10px" }}>
                  <h3 style={{ fontSize: "15px", fontWeight: "700" }}>Available Donors</h3>
                  <span style={{ background: "#E8F0FE", padding: "4px 10px", borderRadius: "20px", fontSize: "12px", color: "#2563EB", fontWeight: "600" }}>
                    {availableDonors.length} Ready to Donate
                  </span>
                </div>
                <div style={{ background: "white", borderRadius: "16px", overflow: "hidden", border: "1px solid #E2E8F0" }}>
                  {availableDonors.length === 0 ? (
                    <p style={{ textAlign: "center", padding: "32px", color: "#9E9E9E" }}>No available donors at the moment</p>
                  ) : (
                    availableDonors.map((donor) => (
                      <div key={donor.id} className="donor-row">
                        <div style={{ width: "42px", height: "42px", borderRadius: "12px", background: "#EEF2F7", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "18px", fontWeight: "bold" }}>
                          {donor.bloodType}
                        </div>
                        <div style={{ flex: 1 }}>
                          <div style={{ fontWeight: "600", fontSize: "15px" }}>{donor.name}</div>
                          <div style={{ fontSize: "13px", color: "#6B7280" }}>
                            {donor.city} • Age {donor.age}
                          </div>
                        </div>
                        <div style={{ textAlign: "center", marginRight: "12px" }}>
                          <div style={{ fontSize: "18px", fontWeight: "800", color: "#E53935" }}>{donor.bloodType}</div>
                          <div style={{ fontSize: "10px", color: "#94A3B8" }}>{donor.distance}</div>
                        </div>
                        <button
                          onClick={() => navigate(`/bloodbank/donors/${donor.id}`)}
                          style={{
                            padding: "8px 18px",
                            background: "#2563EB",
                            color: "white",
                            border: "none",
                            borderRadius: "8px",
                            cursor: "pointer",
                            fontWeight: "600",
                            fontSize: "13px"
                          }}
                        >
                          Request
                        </button>
                      </div>
                    ))
                  )}
                </div>
              </div>
              
              {/* Doctor Instructions */}
              <div>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "10px" }}>
                  <h3 style={{ fontSize: "15px", fontWeight: "700" }}>
                    📋 Doctor Instructions ({instructions.length})
                  </h3>
                  <span
                    onClick={() => navigate("/bloodbank/instructions/new")}
                    style={{
                      color: "#2563EB",
                      fontSize: "13px",
                      fontWeight: "600",
                      cursor: "pointer",
                    }}
                  >
                    + Add New
                  </span>
                </div>
                <div style={{
                  background: "white",
                  borderRadius: "16px",
                  overflow: "hidden",
                  border: "1px solid #E2E8F0",
                }}>
                  {instructions.map((inst, idx) => {
                    const priorityStyle = getPriorityColor(inst.priority);
                    return (
                      <div
                        key={idx}
                        className="instruction-row"
                        onClick={() => openInstructionModal(inst)}
                        style={{
                          borderLeft: `4px solid ${priorityStyle.color}`,
                          background: idx % 2 === 0 ? "white" : "#FAFAFA"
                        }}
                      >
                        <div style={{ display: "flex", gap: "12px", alignItems: "flex-start" }}>
                          <div
                            style={{
                              width: "40px",
                              height: "40px",
                              background: priorityStyle.bg,
                              borderRadius: "10px",
                              display: "flex",
                              alignItems: "center",
                              justifyContent: "center",
                              fontSize: "20px",
                              flexShrink: 0,
                            }}
                          >
                            {inst.instructionType === "emergency" ? "🚨" :
                             inst.instructionType === "alert" ? "⚠️" :
                             inst.instructionType === "scheduled" ? "📅" :
                             inst.instructionType === "protocol" ? "📋" :
                             inst.instructionType === "quality" ? "🔬" :
                             inst.instructionType === "training" ? "🎓" :
                             inst.instructionType === "safety" ? "🛡️" : "📄"}
                          </div>
                          <div style={{ flex: 1 }}>
                            <div style={{ 
                              fontWeight: "700", 
                              fontSize: "14px",
                              marginBottom: "4px",
                              color: "#0F172A"
                            }}>
                              {inst.title}
                            </div>
                            <div style={{ 
                              fontSize: "12px", 
                              color: "#6B7280",
                              marginBottom: "6px",
                              lineHeight: "1.4"
                            }}>
                              {inst.description.length > 100 
                                ? inst.description.substring(0, 100) + "..." 
                                : inst.description}
                            </div>
                            <div style={{ 
                              display: "flex", 
                              gap: "12px", 
                              alignItems: "center",
                              flexWrap: "wrap"
                            }}>
                              <span style={{ 
                                fontSize: "11px", 
                                color: "#94A3B8",
                                display: "flex",
                                alignItems: "center",
                                gap: "4px"
                              }}>
                                👤 {inst.issuedBy}
                              </span>
                              <span style={{ 
                                fontSize: "11px", 
                                color: "#94A3B8",
                                display: "flex",
                                alignItems: "center",
                                gap: "4px"
                              }}>
                                📅 {inst.date}
                              </span>
                              <span 
                                className="priority-badge"
                                style={{
                                  background: priorityStyle.bg,
                                  color: priorityStyle.color,
                                  fontSize: "10px",
                                  padding: "2px 8px"
                                }}
                              >
                                {inst.priority}
                              </span>
                              <span style={{ 
                                fontSize: "10px", 
                                color: "#94A3B8",
                                background: "#F3F4F6",
                                padding: "2px 8px",
                                borderRadius: "12px"
                              }}>
                                {inst.department}
                              </span>
                            </div>
                          </div>
                          <div style={{ 
                            fontSize: "20px", 
                            color: "#94A3B8",
                            flexShrink: 0,
                            alignSelf: "center"
                          }}>
                            →
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          )}
          
          {/* ═══════════════════ BLOOD INVENTORY ═══════════════════ */}
          {activeSection === "inventory" && (
            <div className="ll-content">
              <div className="inventory-section">
                <div className="card-header">
                  <div>
                    <span className="card-title">🩸 Blood Inventory Management</span>
                    <p style={{ fontSize: "12px", color: "#6B7280", marginTop: "4px" }}>
                      Click on any blood type to update stock levels
                    </p>
                  </div>
                  <div style={{ display: "flex", gap: "10px" }}>
                    <button
                      onClick={refreshData}
                      style={{
                        padding: "7px 14px",
                        background: "#EFF6FF",
                        color: "#2563EB",
                        border: "none",
                        borderRadius: "8px",
                        fontWeight: "600",
                        cursor: "pointer",
                        fontSize: "13px",
                        fontFamily: "DM Sans,sans-serif",
                      }}
                    >
                      ↻ Refresh
                    </button>
                    <button
                      onClick={bulkUpdateInventory}
                      style={{
                        padding: "7px 14px",
                        background: "#43A047",
                        color: "white",
                        border: "none",
                        borderRadius: "8px",
                        fontWeight: "600",
                        cursor: "pointer",
                        fontSize: "13px",
                        fontFamily: "DM Sans,sans-serif",
                      }}
                    >
                      💾 Sync All
                    </button>
                  </div>
                </div>
                
                {bloodStocks.length === 0 ? (
                  <div style={{ textAlign: "center", padding: "48px 24px", color: "#9E9E9E" }}>
                    <div style={{ fontSize: "48px", marginBottom: "12px" }}>🩸</div>
                    <p style={{ fontWeight: "600", marginBottom: "6px" }}>No blood stock data available</p>
                    <p style={{ fontSize: "13px" }}>Click on "Add Blood Type" to initialize inventory.</p>
                    <button
                      onClick={() => openInventoryModal("New Blood Type", "add")}
                      style={{
                        marginTop: "16px",
                        padding: "10px 20px",
                        background: "#2563EB",
                        color: "white",
                        border: "none",
                        borderRadius: "8px",
                        cursor: "pointer",
                        fontWeight: "600"
                      }}
                    >
                      + Initialize Inventory
                    </button>
                  </div>
                ) : (
                  <>
                    <div className="inventory-grid">
                      {bloodStocks.map((stock, idx) => {
                        const s = getBloodStockStatus(stock.units);
                        const fillPct = Math.min(100, (stock.units / 50) * 100);
                        return (
                          <div
                            key={idx}
                            className="inventory-item"
                            style={{ background: s.bg, borderColor: s.color }}
                            onClick={() => openInventoryModal(stock.bloodType, "add")}
                          >
                            <div className="inventory-type" style={{ color: s.color }}>
                              {stock.bloodType}
                            </div>
                            <div className="inventory-units" style={{ color: s.color }}>
                              {stock.units}
                            </div>
                            <div style={{ fontSize: "10px", color: s.color, fontWeight: "600", marginBottom: "8px" }}>
                              units available
                            </div>
                            <div className="inventory-bar">
                              <div
                                className="inventory-fill"
                                style={{
                                  width: `${fillPct}%`,
                                  background: s.color,
                                }}
                              />
                            </div>
                            <div className="inventory-label" style={{ color: s.color, marginTop: "8px" }}>
                              {s.icon} {s.label}
                            </div>
                            <div style={{ marginTop: "12px", fontSize: "10px", color: "#94A3B8" }}>
                              Click to update
                            </div>
                          </div>
                        );
                      })}
                    </div>
                    
                    {/* Add new blood type */}
                    <div style={{ marginTop: "24px", textAlign: "center" }}>
                      <button
                        onClick={() => openInventoryModal("New Blood Type", "add")}
                        style={{
                          padding: "10px 20px",
                          background: "#F3F4F6",
                          color: "#374151",
                          border: "1px dashed #9CA3AF",
                          borderRadius: "12px",
                          cursor: "pointer",
                          fontWeight: "600",
                          fontSize: "13px",
                          display: "inline-flex",
                          alignItems: "center",
                          gap: "8px"
                        }}
                      >
                        + Add New Blood Type
                      </button>
                    </div>
                  </>
                )}
                
                <div style={{ display: "flex", gap: "20px", marginTop: "24px", padding: "16px", background: "#F8FAFC", borderRadius: "12px", fontSize: "12px" }}>
                  {[
                    ["#E53935", "Critical (≤ 5 units)", "Immediate action required"],
                    ["#FB8C00", "Low (6–10 units)", "Plan for replenishment"],
                    ["#43A047", "Normal (> 10 units)", "Adequate supply"],
                  ].map(([c, l, d]) => (
                    <div key={l} style={{ flex: 1 }}>
                      <div style={{ display: "flex", alignItems: "center", gap: "6px", marginBottom: "4px" }}>
                        <span style={{ width: "10px", height: "10px", background: c, borderRadius: "50%", display: "inline-block" }} />
                        <span style={{ color: "#374151", fontWeight: "600" }}>{l}</span>
                      </div>
                      <span style={{ fontSize: "10px", color: "#6B7280" }}>{d}</span>
                    </div>
                  ))}
                </div>
                
                {/* Quick Actions */}
                <div style={{ marginTop: "16px", display: "flex", gap: "12px", flexWrap: "wrap" }}>
                  <button
                    onClick={() => {
                      const criticalStocks = bloodStocks.filter(s => s.units <= 5);
                      if (criticalStocks.length > 0) {
                        alert(`Critical stocks: ${criticalStocks.map(s => `${s.bloodType} (${s.units} units)`).join(", ")}`);
                      } else {
                        alert("No critical stock levels detected.");
                      }
                    }}
                    style={{
                      padding: "8px 16px",
                      background: "#FFEBEE",
                      color: "#E53935",
                      border: "none",
                      borderRadius: "8px",
                      cursor: "pointer",
                      fontSize: "12px",
                      fontWeight: "600"
                    }}
                  >
                    Check Critical Stocks
                  </button>
                  <button
                    onClick={() => {
                      const totalUnits = bloodStocks.reduce((sum, s) => sum + s.units, 0);
                      alert(`Total Blood Units: ${totalUnits}\nAverage per type: ${Math.round(totalUnits / bloodStocks.length)}`);
                    }}
                    style={{
                      padding: "8px 16px",
                      background: "#E3F2FD",
                      color: "#1976D2",
                      border: "none",
                      borderRadius: "8px",
                      cursor: "pointer",
                      fontSize: "12px",
                      fontWeight: "600"
                    }}
                  >
                    View Statistics
                  </button>
                </div>
              </div>
            </div>
          )}
          
          {/* ═══════════════════ ALERTS SECTION ═══════════════════ */}
          {activeSection === "alerts" && (
            <div className="ll-content">
              <div className="inventory-section">
                <div className="card-header">
                  <div>
                    <span className="card-title">🔔 Notifications & Alerts</span>
                    <p style={{ fontSize: "12px", color: "#6B7280", marginTop: "4px" }}>
                      {unreadAlertsCount} unread • {alerts.length} total
                    </p>
                  </div>
                  <div style={{ display: "flex", gap: "10px" }}>
                    <button
                      onClick={refreshData}
                      style={{
                        padding: "7px 14px",
                        background: "#EFF6FF",
                        color: "#2563EB",
                        border: "none",
                        borderRadius: "8px",
                        fontWeight: "600",
                        cursor: "pointer",
                        fontSize: "13px",
                        fontFamily: "DM Sans,sans-serif",
                      }}
                    >
                      ↻ Refresh
                    </button>
                    <button
                      onClick={markAllAlertsAsRead}
                      style={{
                        padding: "7px 14px",
                        background: "#43A047",
                        color: "white",
                        border: "none",
                        borderRadius: "8px",
                        fontWeight: "600",
                        cursor: "pointer",
                        fontSize: "13px",
                        fontFamily: "DM Sans,sans-serif",
                      }}
                    >
                      Mark All as Read
                    </button>
                  </div>
                </div>
                <div style={{ marginTop: "16px" }}>
                  {isLoadingAlerts ? (
                    <div style={{ textAlign: "center", padding: "48px 24px", color: "#94A3B8" }}>
                      <div
                        style={{
                          width: "32px",
                          height: "32px",
                          border: "3px solid #E2E8F0",
                          borderTopColor: "#2563EB",
                          borderRadius: "50%",
                          animation: "spin 1s linear infinite",
                          margin: "0 auto 12px",
                        }}
                      />
                      <p>Loading alerts...</p>
                    </div>
                  ) : alerts.length === 0 ? (
                    <div style={{ textAlign: "center", padding: "48px 24px", color: "#9E9E9E" }}>
                      <div style={{ fontSize: "48px", marginBottom: "12px" }}>🔔</div>
                      <p style={{ fontWeight: "600", marginBottom: "6px" }}>No new alerts</p>
                      <p style={{ fontSize: "13px" }}>You're all caught up!</p>
                    </div>
                  ) : (
                    alerts.map((alert) => {
                      const alertStyle = getAlertStyle(alert.type);
                      return (
                        <div
                          key={alert.id}
                          className={`alert-row ${!alert.read ? 'alert-unread' : 'alert-read'}`}
                          onClick={() => handleAlertClick(alert)}
                          style={{ cursor: 'pointer' }}
                        >
                          <div style={{ fontSize: "28px", minWidth: "48px", textAlign: "center" }}>
                            {alertStyle.icon}
                          </div>
                          <div style={{ flex: 1 }}>
                            <div style={{ 
                              fontWeight: !alert.read ? "700" : "500", 
                              fontSize: "14px", 
                              color: "#0F172A",
                              marginBottom: "4px"
                            }}>
                              {alert.message}
                            </div>
                            <div style={{ 
                              display: "flex", 
                              gap: "8px", 
                              alignItems: "center",
                              flexWrap: "wrap"
                            }}>
                              <span style={{ 
                                fontSize: "11px", 
                                color: "#94A3B8",
                                display: "flex",
                                alignItems: "center",
                                gap: "4px"
                              }}>
                                ⏰ {formatTime(alert.time)}
                              </span>
                              <span className="alert-category">
                                {getCategoryIcon(alert.category)} {alert.category || "General"}
                              </span>
                              <span 
                                className="alert-badge"
                                style={{
                                  background: alertStyle.bg,
                                  color: alertStyle.color
                                }}
                              >
                                {alertStyle.label}
                              </span>
                            </div>
                          </div>
                          {!alert.read && (
                            <div style={{
                              width: "10px",
                              height: "10px",
                              background: "#E53935",
                              borderRadius: "50%",
                              animation: "pulse 1.5s infinite"
                            }} />
                          )}
                        </div>
                      );
                    })
                  )}
                </div>
              </div>
            </div>
          )}
          
          {/* ═══════════════════ HOSPITAL REQUESTS ═══════════════════ */}
          {activeSection === "requests" && (
            <div className="ll-content">
              <div className="inventory-section">
                <div className="card-header">
                  <div>
                    <span className="card-title">📋 Hospital Requests</span>
                    <p style={{ fontSize: "12px", color: "#6B7280", marginTop: "4px" }}>
                      Manage and track all your hospital resource requests
                    </p>
                  </div>
                  <div style={{ display: "flex", gap: "10px" }}>
                    <button
                      onClick={() => setIsRequestModalOpen(true)}
                      style={{
                        padding: "8px 20px",
                        background: "#2563EB",
                        color: "white",
                        border: "none",
                        borderRadius: "8px",
                        fontWeight: "600",
                        cursor: "pointer",
                        fontSize: "13px",
                        fontFamily: "DM Sans,sans-serif",
                      }}
                    >
                      + New Request
                    </button>
                    <button
                      onClick={loadHospitalRequests}
                      style={{
                        padding: "8px 16px",
                        background: "#EFF6FF",
                        color: "#2563EB",
                        border: "none",
                        borderRadius: "8px",
                        fontWeight: "600",
                        cursor: "pointer",
                        fontSize: "13px",
                        fontFamily: "DM Sans,sans-serif",
                      }}
                    >
                      ↻ Refresh
                    </button>
                  </div>
                </div>
                
                {/* Stats Cards */}
                <div className="stats-grid" style={{ marginBottom: "20px" }}>
                  <div className="stat-card">
                    <div className="stat-value">{requestStats.total}</div>
                    <div className="stat-label">Total Requests</div>
                  </div>
                  <div className="stat-card">
                    <div className="stat-value" style={{ color: "#FB8C00" }}>{requestStats.pending}</div>
                    <div className="stat-label">Pending</div>
                  </div>
                  <div className="stat-card">
                    <div className="stat-value" style={{ color: "#2E7D32" }}>{requestStats.fulfilled}</div>
                    <div className="stat-label">Fulfilled</div>
                  </div>
                </div>
                
                {/* Requests List */}
                {isLoadingRequests ? (
                  <div style={{ textAlign: "center", padding: "48px", color: "#94A3B8" }}>
                    <div style={{ width: "32px", height: "32px", border: "3px solid #E2E8F0", borderTopColor: "#2563EB", borderRadius: "50%", animation: "spin 1s linear infinite", margin: "0 auto 12px" }} />
                    <p>Loading requests...</p>
                  </div>
                ) : hospitalRequests.length === 0 ? (
                  <div style={{ textAlign: "center", padding: "48px", background: "#F8FAFC", borderRadius: "16px", color: "#9E9E9E" }}>
                    <div style={{ fontSize: "48px", marginBottom: "12px" }}>📋</div>
                    <p style={{ fontWeight: "600", marginBottom: "6px" }}>No requests yet</p>
                    <p style={{ fontSize: "13px" }}>Click "New Request" to create your first request</p>
                  </div>
                ) : (
                  hospitalRequests.map((req) => {
                    const urgencyColor = req.urgency === 'Critical' ? '#E53935' : req.urgency === 'Urgent' ? '#FB8C00' : '#1976D2';
                    const statusColor = req.status === 'Fulfilled' ? '#2E7D32' : req.status === 'Pending' ? '#FB8C00' : '#9E9E9E';
                    const remaining = (req.quantity - (req.fulfilledQuantity || 0));
                    
                    return (
                      <div
                        key={req.id}
                        className="request-card"
                        style={{ cursor: 'pointer' }}
                        onClick={() => {
                          setSelectedRequest(req);
                          setIsRequestDetailModalOpen(true);
                        }}
                      >
                        <div className="request-top">
                          <div>
                            <div className="request-name" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                              {req.itemType === 'Blood' ? '🩸' : req.itemType === 'Medical Supplies' ? '💊' : '🔧'}
                              {req.itemName}
                            </div>
                            <div style={{ fontSize: "12px", color: "#6B7280", marginTop: "2px" }}>
                              {req.contactPerson}
                            </div>
                          </div>
                          <div style={{ textAlign: "right" }}>
                            <div className="request-time">{req.timeElapsed || new Date(req.createdAt).toLocaleDateString()}</div>
                            <div style={{ fontSize: "10px", color: "#94A3B8", marginTop: "2px" }}>
                              #{String(req.id).slice(-6)}
                            </div>
                          </div>
                        </div>
                        
                        <div className="request-meta">
                          <span className="meta-pill" style={{ background: urgencyColor + '20', color: urgencyColor }}>
                            {req.urgency === 'Critical' ? '🚨' : req.urgency === 'Urgent' ? '⚡' : '📌'} {req.urgency}
                          </span>
                          <span className="meta-pill" style={{ background: statusColor + '20', color: statusColor }}>
                            {req.status === 'Fulfilled' ? '✅' : req.status === 'Pending' ? '⏳' : '❌'} {req.status}
                          </span>
                          <span className="meta-pill" style={{ background: "#F3F4F6", color: "#374151" }}>
                            📦 {req.quantity} {req.unitOfMeasure || 'units'}
                          </span>
                          {remaining > 0 && req.status !== 'Fulfilled' && (
                            <span className="meta-pill" style={{ background: "#FFEBEE", color: "#E53935" }}>
                              ⏰ {remaining} remaining
                            </span>
                          )}
                        </div>
                        
                        {req.reason && (
                          <div className="request-notes">📝 {req.reason.length > 100 ? req.reason.substring(0, 100) + '...' : req.reason}</div>
                        )}
                        
                        <div className="request-footer" style={{ marginTop: '12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <div className="status-indicator">
                            <div className="status-dot" style={{ background: statusColor }} />
                            <div className="status-text">{req.status}</div>
                          </div>
                          <div className="action-buttons">
                            {req.status === 'Pending' && (
                              <>
                                <button
                                  className="complete-btn"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    const quantity = prompt('Enter quantity to fulfill:', '1');
                                    if (quantity) updateFulfillment(req.id, parseInt(quantity));
                                  }}
                                  style={{
                                    padding: "8px 16px",
                                    background: "#F0FDF4",
                                    color: "#15803D",
                                    border: "1px solid #BBF7D0",
                                    borderRadius: "8px",
                                    cursor: "pointer",
                                    fontWeight: "600",
                                    fontSize: "12px"
                                  }}
                                >
                                  ✓ Fulfill
                                </button>
                                <button
                                  className="cancel-btn"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    cancelHospitalRequest(req.id);
                                  }}
                                  style={{
                                    padding: "8px 16px",
                                    background: "#FFF5F5",
                                    color: "#E53935",
                                    border: "1px solid #FFCDD2",
                                    borderRadius: "8px",
                                    cursor: "pointer",
                                    fontWeight: "600",
                                    fontSize: "12px"
                                  }}
                                >
                                  ✕ Cancel
                                </button>
                              </>
                            )}
                            <button
                              className="view-btn"
                              onClick={(e) => {
                                e.stopPropagation();
                                setSelectedRequest(req);
                                setIsRequestDetailModalOpen(true);
                              }}
                              style={{
                                padding: "8px 20px",
                                background: "#2563EB",
                                color: "white",
                                border: "none",
                                borderRadius: "8px",
                                cursor: "pointer",
                                fontWeight: "600",
                                fontSize: "12px"
                              }}
                            >
                              View Details →
                            </button>
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </div>
          )}
          
          {/* ═══════════════════ PROFILE SECTION WITH EDIT MODE ═══════════════════ */}
          {activeSection === "profile" && (
            <div className="ll-content">
              {isLoadingProfile ? (
                <div style={{ textAlign: "center", padding: "48px", color: "#94A3B8" }}>
                  <div
                    style={{
                      width: "32px",
                      height: "32px",
                      border: "3px solid #E2E8F0",
                      borderTopColor: "#2563EB",
                      borderRadius: "50%",
                      animation: "spin 1s linear infinite",
                      margin: "0 auto 12px",
                    }}
                  />
                  <p>Loading profile...</p>
                </div>
              ) : (
                <div className="profile-section">
                  <div className="profile-header">
                    <div className="profile-avatar">🏥</div>
                    <div style={{ flex: 1 }}>
                      <div className="profile-name">
                        {profileData?.name || localStorage.getItem("name") || "Hospital"}
                        <span style={{ 
                          fontSize: '12px', 
                          marginLeft: '10px',
                          padding: '2px 8px',
                          background: '#F3F4F6',
                          borderRadius: '20px',
                          color: '#6B7280'
                        }}>
                          ID: {profileData?.regNumber || localStorage.getItem("regNumber")}
                        </span>
                      </div>
                      <div className="profile-sub">
                        {profileData?.email || localStorage.getItem("email")}
                      </div>
                      <div className="profile-badge">
                        {(profileData?.isVerified ?? localStorage.getItem("isVerified") === "true")
                          ? "✅ Verified Hospital"
                          : "⏳ Pending Verification"}
                      </div>
                    </div>
                    <button 
                      onClick={() => {
                        if (!isEditingProfile) {
                          // Set edit form values from current profile
                          setEditForm({
                            contact: profileData?.contact || localStorage.getItem("contact") || '',
                            address: profileData?.address || '',
                            description: profileData?.description || '',
                            workingHours: profileData?.workingHours || '24/7',
                            emergencyContact: profileData?.emergencyContact || profileData?.contact || ''
                          });
                        }
                        setIsEditingProfile(!isEditingProfile);
                      }}
                      style={{
                        padding: '8px 20px',
                        background: isEditingProfile ? '#6B7280' : '#2563EB',
                        color: 'white',
                        border: 'none',
                        borderRadius: '8px',
                        cursor: 'pointer',
                        fontWeight: '600',
                        transition: 'all 0.2s'
                      }}
                      onMouseEnter={(e) => e.target.style.background = isEditingProfile ? '#4B5563' : '#1D4ED8'}
                      onMouseLeave={(e) => e.target.style.background = isEditingProfile ? '#6B7280' : '#2563EB'}
                    >
                      {isEditingProfile ? 'Cancel' : 'Edit Profile'}
                    </button>
                  </div>
                  
                  <div className="profile-body">
                    {isEditingProfile ? (
                      // Edit Mode Form
                      <form onSubmit={updateProfile} className="inventory-form">
                        <div style={{ marginBottom: '16px', padding: '12px', background: '#EFF6FF', borderRadius: '8px' }}>
                          <div style={{ fontWeight: '600', marginBottom: '8px', color: '#2563EB' }}>✏️ Editable Information</div>
                          <div style={{ fontSize: '12px', color: '#6B7280' }}>You can update these fields directly</div>
                        </div>
                        
                        <div className="profile-grid">
                          <div className="form-group">
                            <label className="form-label">Contact Number</label>
                            <input
                              type="tel"
                              className="form-input"
                              value={editForm.contact}
                              onChange={(e) => setEditForm({...editForm, contact: e.target.value})}
                              placeholder="Hospital contact number"
                            />
                          </div>
                          
                          <div className="form-group">
                            <label className="form-label">Emergency Contact</label>
                            <input
                              type="tel"
                              className="form-input"
                              value={editForm.emergencyContact}
                              onChange={(e) => setEditForm({...editForm, emergencyContact: e.target.value})}
                              placeholder="Emergency contact number"
                            />
                          </div>
                          
                          <div className="form-group">
                            <label className="form-label">Address</label>
                            <textarea
                              className="form-input"
                              value={editForm.address}
                              onChange={(e) => setEditForm({...editForm, address: e.target.value})}
                              rows="2"
                              placeholder="Hospital address"
                            />
                          </div>
                          
                          <div className="form-group">
                            <label className="form-label">Working Hours</label>
                            <input
                              type="text"
                              className="form-input"
                              value={editForm.workingHours}
                              onChange={(e) => setEditForm({...editForm, workingHours: e.target.value})}
                              placeholder="e.g., 24/7 or Mon-Fri 9AM-5PM"
                            />
                          </div>
                          
                          <div className="form-group" style={{ gridColumn: 'span 2' }}>
                            <label className="form-label">Hospital Description</label>
                            <textarea
                              className="form-input"
                              value={editForm.description}
                              onChange={(e) => setEditForm({...editForm, description: e.target.value})}
                              rows="3"
                              placeholder="Brief description of your hospital"
                            />
                          </div>
                        </div>
                        
                        <div className="profile-divider" />
                        
                        {/* Read-only Fields with Change Request Option */}
                        <div style={{ marginBottom: '16px', padding: '12px', background: '#FEF3C7', borderRadius: '8px' }}>
                          <div style={{ fontWeight: '600', marginBottom: '8px', color: '#F59E0B' }}>🔒 Locked Information</div>
                          <div style={{ fontSize: '12px', color: '#6B7280' }}>These fields require admin approval to change</div>
                        </div>
                        
                        <div className="profile-grid">
                          <div className="profile-field">
                            <span className="field-label">Hospital Name (Locked)</span>
                            <span className="field-value">{profileData?.name || localStorage.getItem("name")}</span>
                            <button 
                              type="button"
                              onClick={() => requestFieldChange('Hospital Name')}
                              style={{
                                fontSize: '11px',
                                color: '#F59E0B',
                                background: 'none',
                                border: 'none',
                                cursor: 'pointer',
                                marginTop: '4px',
                                textAlign: 'left',
                                padding: '0'
                              }}
                            >
                              Request Change →
                            </button>
                          </div>
                          
                          <div className="profile-field">
                            <span className="field-label">Email (Locked)</span>
                            <span className="field-value">{profileData?.email || localStorage.getItem("email")}</span>
                            <button 
                              type="button"
                              onClick={() => requestFieldChange('Email')}
                              style={{
                                fontSize: '11px',
                                color: '#F59E0B',
                                background: 'none',
                                border: 'none',
                                cursor: 'pointer',
                                marginTop: '4px',
                                textAlign: 'left',
                                padding: '0'
                              }}
                            >
                              Request Change →
                            </button>
                          </div>
                          
                          <div className="profile-field">
                            <span className="field-label">Registration Number</span>
                            <span className="field-value">{profileData?.regNumber || localStorage.getItem("regNumber")}</span>
                            <span style={{ fontSize: '10px', color: '#94A3B8' }}>Legal document - cannot be changed</span>
                          </div>
                          
                          <div className="profile-field">
                            <span className="field-label">Storage Capacity</span>
                            <span className="field-value">{profileData?.storageCapacity || localStorage.getItem("storageCapacity")} units</span>
                            <span style={{ fontSize: '10px', color: '#94A3B8' }}>Set during registration</span>
                          </div>
                          
                          <div className="profile-field">
                            <span className="field-label">Blood Types Supported</span>
                            <span className="field-value">{profileData?.selectedBloodTypes?.join(", ") || "All types"}</span>
                            <button 
                              type="button"
                              onClick={() => requestFieldChange('Blood Types')}
                              style={{
                                fontSize: '11px',
                                color: '#F59E0B',
                                background: 'none',
                                border: 'none',
                                cursor: 'pointer',
                                marginTop: '4px',
                                textAlign: 'left',
                                padding: '0'
                              }}
                            >
                              Request Change →
                            </button>
                          </div>
                        </div>
                        
                        <div style={{ display: "flex", gap: "12px", marginTop: "20px" }}>
                          <button
                            type="submit"
                            disabled={isUpdatingProfile}
                            style={{
                              flex: 1,
                              padding: "12px",
                              background: "#2563EB",
                              color: "white",
                              border: "none",
                              borderRadius: "8px",
                              fontWeight: "600",
                              cursor: isUpdatingProfile ? "not-allowed" : "pointer",
                              opacity: isUpdatingProfile ? 0.7 : 1,
                              fontFamily: "DM Sans,sans-serif",
                              transition: "all 0.2s"
                            }}
                            onMouseEnter={(e) => !isUpdatingProfile && (e.target.style.background = '#1D4ED8')}
                            onMouseLeave={(e) => !isUpdatingProfile && (e.target.style.background = '#2563EB')}
                          >
                            {isUpdatingProfile ? "Saving Changes..." : "Save Changes"}
                          </button>
                          <button
                            type="button"
                            onClick={() => setIsEditingProfile(false)}
                            style={{
                              flex: 1,
                              padding: "12px",
                              background: "#F3F4F6",
                              color: "#374151",
                              border: "none",
                              borderRadius: "8px",
                              fontWeight: "600",
                              cursor: "pointer",
                              fontFamily: "DM Sans,sans-serif"
                            }}
                          >
                            Cancel
                          </button>
                        </div>
                      </form>
                    ) : (
                      // View Mode - Display Current Profile
                      <>
                        <div className="profile-grid">
                          <div className="profile-field">
                            <span className="field-label">Contact</span>
                            <span className="field-value">{profileData?.contact || localStorage.getItem("contact") || "—"}</span>
                          </div>
                          
                          <div className="profile-field">
                            <span className="field-label">Emergency Contact</span>
                            <span className="field-value">{profileData?.emergencyContact || profileData?.contact || "—"}</span>
                          </div>
                          
                          <div className="profile-field">
                            <span className="field-label">Address</span>
                            <span className="field-value">{profileData?.address || "—"}</span>
                          </div>
                          
                          <div className="profile-field">
                            <span className="field-label">Working Hours</span>
                            <span className="field-value">{profileData?.workingHours || "24/7"}</span>
                          </div>
                          
                          <div className="profile-field">
                            <span className="field-label">Email</span>
                            <span className="field-value">{profileData?.email || localStorage.getItem("email") || "—"}</span>
                          </div>
                          
                          <div className="profile-field">
                            <span className="field-label">Registration Number</span>
                            <span className="field-value">{profileData?.regNumber || localStorage.getItem("regNumber") || "—"}</span>
                          </div>
                          
                          <div className="profile-field">
                            <span className="field-label">Storage Capacity</span>
                            <span className="field-value">{profileData?.storageCapacity || localStorage.getItem("storageCapacity") || "—"} units</span>
                          </div>
                          
                          <div className="profile-field">
                            <span className="field-label">Blood Types Supported</span>
                            <span className="field-value">{profileData?.selectedBloodTypes?.join(", ") || "All types"}</span>
                          </div>
                        </div>
                        
                        {profileData?.description && (
                          <>
                            <div className="profile-divider" />
                            <div className="profile-field">
                              <span className="field-label">About Hospital</span>
                              <span className="field-value">{profileData.description}</span>
                            </div>
                          </>
                        )}
                      </>
                    )}
                    
                    <div className="profile-divider" />
                    
                    <div style={{ marginBottom: "20px" }}>
                      <div style={{ fontSize: "14px", fontWeight: "700", color: "#0F172A", marginBottom: "12px" }}>
                        Current Blood Inventory
                      </div>
                      {bloodStocks.length === 0 ? (
                        <p style={{ fontSize: "13px", color: "#9E9E9E" }}>No inventory data available.</p>
                      ) : (
                        <div style={{ display: "flex", flexWrap: "wrap", gap: "8px" }}>
                          {bloodStocks.map((stock, idx) => {
                            const s = getBloodStockStatus(stock.units);
                            return (
                              <div
                                key={idx}
                                style={{
                                  display: "flex",
                                  alignItems: "center",
                                  gap: "6px",
                                  padding: "6px 12px",
                                  background: s.bg,
                                  borderRadius: "8px",
                                  border: `1px solid ${s.color}30`,
                                  cursor: "pointer"
                                }}
                                onClick={() => openInventoryModal(stock.bloodType, "add")}
                              >
                                <span style={{ fontWeight: "800", color: s.color, fontSize: "13px" }}>
                                  {stock.bloodType}
                                </span>
                                <span style={{ fontSize: "12px", color: s.color }}>
                                  {stock.units}u
                                </span>
                              </div>
                            );
                          })}
                        </div>
                      )}
                    </div>
                    
                    <div style={{ display: "flex", gap: "12px" }}>
                      <button
                        onClick={() => setActiveSection("inventory")}
                        style={{
                          flex: 1,
                          padding: "12px",
                          background: "#EFF6FF",
                          color: "#2563EB",
                          border: "none",
                          borderRadius: "10px",
                          fontWeight: "700",
                          cursor: "pointer",
                          fontFamily: "DM Sans,sans-serif",
                          transition: "all 0.2s"
                        }}
                        onMouseEnter={(e) => e.target.style.background = '#DBEAFE'}
                        onMouseLeave={(e) => e.target.style.background = '#EFF6FF'}
                      >
                        Manage Inventory
                      </button>
                      <button
                        onClick={handleLogout}
                        style={{
                          flex: 1,
                          padding: "12px",
                          background: "#FFF5F5",
                          color: "#E53935",
                          border: "none",
                          borderRadius: "10px",
                          fontWeight: "700",
                          cursor: "pointer",
                          fontFamily: "DM Sans,sans-serif",
                          transition: "all 0.2s"
                        }}
                        onMouseEnter={(e) => e.target.style.background = '#FFEBEE'}
                        onMouseLeave={(e) => e.target.style.background = '#FFF5F5'}
                      >
                        Logout
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
      
      {/* ── Inventory Management Modal ── */}
      {isInventoryModalOpen && (
        <div className="modal-overlay" onClick={closeInventoryModal}>
          <div className="modal-container" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>🩸 Manage Blood Inventory</h2>
              <button className="modal-close" onClick={closeInventoryModal}>
                ✕
              </button>
            </div>
            <div className="modal-body">
              <div className="inventory-form">
                <div className="form-group">
                  <label className="form-label">Blood Type</label>
                  
                  {selectedBloodType === "New Blood Type" ? (
                    <div>
                      <select 
                        className="form-input" 
                        value={newBloodType}
                        onChange={(e) => handleBloodTypeSelect(e.target.value)}
                        style={{ marginBottom: "10px" }}
                      >
                        <option value="">Select blood type</option>
                        {availableBloodTypes.map(type => (
                          <option key={type} value={type}>{type}</option>
                        ))}
                        <option value="custom">+ Add Custom Blood Type</option>
                      </select>
                      
                      {showCustomBloodType && (
                        <input
                          type="text"
                          className="form-input"
                          placeholder="Enter custom blood type (e.g., AB-, O+)"
                          value={selectedBloodType === "New Blood Type" ? newBloodType : selectedBloodType}
                          onChange={(e) => setNewBloodType(e.target.value.toUpperCase())}
                          style={{ marginTop: "10px" }}
                        />
                      )}
                      
                      {newBloodType && !showCustomBloodType && (
                        <div style={{ 
                          marginTop: "8px", 
                          fontSize: "12px", 
                          color: "#2563EB",
                          fontWeight: "500"
                        }}>
                          Selected: {newBloodType}
                        </div>
                      )}
                    </div>
                  ) : (
                    <div className="inventory-stats">
                      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                        <strong style={{ fontSize: "16px" }}>{selectedBloodType}</strong>
                        {bloodStocks.find(s => s.bloodType === selectedBloodType) && (
                          <span style={{ color: "#6B7280", fontSize: "13px" }}>
                            Current: {bloodStocks.find(s => s.bloodType === selectedBloodType)?.units || 0} units
                          </span>
                        )}
                      </div>
                      <button
                        onClick={() => openInventoryModal("New Blood Type", inventoryAction)}
                        style={{
                          marginTop: "8px",
                          padding: "4px 12px",
                          background: "#F3F4F6",
                          border: "none",
                          borderRadius: "6px",
                          fontSize: "11px",
                          cursor: "pointer",
                          color: "#374151"
                        }}
                      >
                        + Add New Blood Type
                      </button>
                    </div>
                  )}
                </div>
                
                {/* Only show action buttons if a blood type is selected */}
                {(selectedBloodType !== "New Blood Type" || (newBloodType && (selectedBloodType === "New Blood Type"))) && (
                  <>
                    <div className="form-group">
                      <label className="form-label">Action</label>
                      <div className="action-buttons">
                        <button
                          className={`action-btn ${inventoryAction === "add" ? "active" : ""}`}
                          onClick={() => setInventoryAction("add")}
                          style={{ 
                            background: inventoryAction === "add" ? "#43A047" : "#E8F5E9",
                            color: inventoryAction === "add" ? "white" : "#2E7D32",
                            border: inventoryAction === "add" ? "none" : "1px solid #C8E6C9"
                          }}
                        >
                          ➕ Add Units
                        </button>
                        <button
                          className={`action-btn ${inventoryAction === "remove" ? "active" : ""}`}
                          onClick={() => setInventoryAction("remove")}
                          style={{ 
                            background: inventoryAction === "remove" ? "#E53935" : "#FFEBEE",
                            color: inventoryAction === "remove" ? "white" : "#C62828",
                            border: inventoryAction === "remove" ? "none" : "1px solid #FFCDD2"
                          }}
                        >
                          ➖ Remove Units
                        </button>
                        <button
                          className={`action-btn ${inventoryAction === "set" ? "active" : ""}`}
                          onClick={() => setInventoryAction("set")}
                          style={{ 
                            background: inventoryAction === "set" ? "#FB8C00" : "#FFF8F0",
                            color: inventoryAction === "set" ? "white" : "#F57C00",
                            border: inventoryAction === "set" ? "none" : "1px solid #FFE0B2"
                          }}
                        >
                          🎯 Set Exact
                        </button>
                      </div>
                    </div>
                    
                    <div className="form-group">
                      <label className="form-label">Quantity (units)</label>
                      <input
                        type="number"
                        className="form-input"
                        value={inventoryQuantity}
                        onChange={(e) => setInventoryQuantity(Math.max(0, parseInt(e.target.value) || 0))}
                        min="0"
                        step="1"
                        placeholder="Enter number of units"
                        style={{ fontSize: "16px" }}
                      />
                    </div>
                    
                    <div className="form-group">
                      <label className="form-label">Reason / Notes (optional)</label>
                      <textarea
                        className="form-input"
                        value={inventoryReason}
                        onChange={(e) => setInventoryReason(e.target.value)}
                        rows="2"
                        placeholder="e.g., Blood donation camp, emergency usage, stock received, etc."
                        style={{ resize: "vertical" }}
                      />
                    </div>
                    
                    {inventoryAction === "remove" && inventoryQuantity > 0 && (
                      <div style={{ 
                        padding: "12px", 
                        background: "#FFF5F5", 
                        borderRadius: "8px", 
                        fontSize: "12px",
                        borderLeft: "3px solid #E53935"
                      }}>
                        ⚠️ <strong>Warning:</strong> Removing {inventoryQuantity} unit(s) of {selectedBloodType === "New Blood Type" ? newBloodType : selectedBloodType} blood will affect patient care capabilities. Please confirm this action.
                      </div>
                    )}
                    
                    {inventoryAction === "set" && inventoryQuantity === 0 && (
                      <div style={{ 
                        padding: "12px", 
                        background: "#FFF8F0", 
                        borderRadius: "8px", 
                        fontSize: "12px",
                        borderLeft: "3px solid #FB8C00"
                      }}>
                        ⚠️ <strong>Note:</strong> Setting to 0 units will remove this blood type from inventory.
                      </div>
                    )}
                    
                    {/* Current stock info for existing blood types */}
                    {selectedBloodType !== "New Blood Type" && bloodStocks.find(s => s.bloodType === selectedBloodType) && (
                      <div style={{ 
                        padding: "10px", 
                        background: "#F8FAFC", 
                        borderRadius: "8px", 
                        fontSize: "12px",
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "center"
                      }}>
                        <span>📊 Current Stock Level</span>
                        <span style={{ fontWeight: "bold" }}>
                          {bloodStocks.find(s => s.bloodType === selectedBloodType)?.units || 0} units
                        </span>
                      </div>
                    )}
                    
                    <div style={{ display: "flex", gap: "12px", marginTop: "20px" }}>
                      <button
                        onClick={updateBloodInventory}
                        disabled={isUpdatingInventory || !inventoryQuantity || (selectedBloodType === "New Blood Type" && !newBloodType)}
                        style={{
                          flex: 1,
                          padding: "12px",
                          background: "#2563EB",
                          color: "white",
                          border: "none",
                          borderRadius: "8px",
                          fontWeight: "600",
                          cursor: isUpdatingInventory || !inventoryQuantity || (selectedBloodType === "New Blood Type" && !newBloodType) ? "not-allowed" : "pointer",
                          opacity: isUpdatingInventory || !inventoryQuantity || (selectedBloodType === "New Blood Type" && !newBloodType) ? 0.5 : 1,
                          fontFamily: "DM Sans,sans-serif",
                          transition: "all 0.2s"
                        }}
                      >
                        {isUpdatingInventory ? "Updating..." : "Confirm Update"}
                      </button>
                      <button
                        onClick={closeInventoryModal}
                        style={{
                          flex: 1,
                          padding: "12px",
                          background: "#F3F4F6",
                          color: "#374151",
                          border: "none",
                          borderRadius: "8px",
                          fontWeight: "600",
                          cursor: "pointer",
                          fontFamily: "DM Sans,sans-serif",
                          transition: "all 0.2s"
                        }}
                      >
                        Cancel
                      </button>
                    </div>
                  </>
                )}
                
                {/* Show message when no blood type is selected */}
                {selectedBloodType === "New Blood Type" && !newBloodType && !showCustomBloodType && (
                  <div style={{ 
                    padding: "20px", 
                    textAlign: "center", 
                    color: "#94A3B8",
                    background: "#F8FAFC",
                    borderRadius: "8px",
                    marginTop: "10px"
                  }}>
                    <div style={{ fontSize: "32px", marginBottom: "8px" }}>🩸</div>
                    <p>Please select a blood type from the dropdown above</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
      
      {/* ── Create Hospital Request Modal ── */}
      {isRequestModalOpen && (
        <div className="modal-overlay" onClick={() => setIsRequestModalOpen(false)}>
          <div className="modal-container" style={{ maxWidth: '600px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>📋 Create New Request</h2>
              <button className="modal-close" onClick={() => setIsRequestModalOpen(false)}>
                ✕
              </button>
            </div>
            <div className="modal-body">
              <form onSubmit={createHospitalRequest} className="inventory-form">
                <div className="form-group">
                  <label className="form-label">Request Type *</label>
                  <select
                    className="form-input"
                    value={requestForm.itemType}
                    onChange={(e) => setRequestForm({...requestForm, itemType: e.target.value})}
                    required
                  >
                    <option value="Blood">Blood</option>
                    <option value="Medical Supplies">Medical Supplies</option>
                    <option value="Equipment">Equipment</option>
                  </select>
                </div>
                
                <div className="form-group">
                  <label className="form-label">Item Name *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={requestForm.itemName}
                    onChange={(e) => setRequestForm({...requestForm, itemName: e.target.value})}
                    placeholder={requestForm.itemType === 'Blood' ? 'e.g., O+ Blood' : 'e.g., Ventilator, Masks, etc.'}
                    required
                  />
                </div>
                
                <div className="form-group">
                  <label className="form-label">Quantity *</label>
                  <input
                    type="number"
                    className="form-input"
                    value={requestForm.quantity}
                    onChange={(e) => setRequestForm({...requestForm, quantity: parseInt(e.target.value) || 1})}
                    min="1"
                    max="100"
                    required
                  />
                </div>
                
                <div className="form-group">
                  <label className="form-label">Urgency Level *</label>
                  <select
                    className="form-input"
                    value={requestForm.urgency}
                    onChange={(e) => setRequestForm({...requestForm, urgency: e.target.value})}
                    required
                  >
                    <option value="Critical">🔴 Critical - Immediate (Within hours)</option>
                    <option value="Urgent">🟠 Urgent - Within 24 hours</option>
                    <option value="Normal">🔵 Normal - Within 3-5 days</option>
                  </select>
                </div>
                
                <div className="form-group">
                  <label className="form-label">Reason for Request *</label>
                  <textarea
                    className="form-input"
                    value={requestForm.reason}
                    onChange={(e) => setRequestForm({...requestForm, reason: e.target.value})}
                    rows="3"
                    placeholder="Explain why this is needed..."
                    required
                  />
                </div>
                
                <div className="form-group">
                  <label className="form-label">Contact Person *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={requestForm.contactPerson}
                    onChange={(e) => setRequestForm({...requestForm, contactPerson: e.target.value})}
                    placeholder="Doctor or staff name"
                    required
                  />
                </div>
                
                <div style={{ display: "flex", gap: "12px", marginTop: "20px" }}>
                  <button
                    type="submit"
                    disabled={isSubmittingRequest}
                    style={{
                      flex: 1,
                      padding: "12px",
                      background: "linear-gradient(135deg, #2563EB 0%, #1D4ED8 100%)",
                      color: "white",
                      border: "none",
                      borderRadius: "8px",
                      fontWeight: "600",
                      cursor: isSubmittingRequest ? "not-allowed" : "pointer",
                      opacity: isSubmittingRequest ? 0.7 : 1,
                      fontFamily: "DM Sans,sans-serif"
                    }}
                  >
                    {isSubmittingRequest ? "Creating..." : "Create Request"}
                  </button>
                  <button
                    type="button"
                    onClick={() => setIsRequestModalOpen(false)}
                    style={{
                      padding: "12px 24px",
                      background: "#F3F4F6",
                      color: "#374151",
                      border: "none",
                      borderRadius: "8px",
                      fontWeight: "600",
                      cursor: "pointer",
                      fontFamily: "DM Sans,sans-serif"
                    }}
                  >
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
      
      {/* ── Request Detail Modal ── */}
      {isRequestDetailModalOpen && selectedRequest && (
        <div className="modal-overlay" onClick={() => setIsRequestDetailModalOpen(false)}>
          <div className="modal-container" style={{ maxWidth: '700px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>📋 Request Details</h2>
              <button className="modal-close" onClick={() => setIsRequestDetailModalOpen(false)}>
                ✕
              </button>
            </div>
            <div className="modal-body">
              <div className="instruction-detail">
                <div className="detail-section">
                  <span className="detail-label">Request Type</span>
                  <span className="detail-value large">{selectedRequest.itemType}</span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Item</span>
                  <span className="detail-value large">{selectedRequest.itemName}</span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Quantity</span>
                  <span className="detail-value">{selectedRequest.quantity} {selectedRequest.unitOfMeasure || 'units'}</span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Fulfilled</span>
                  <span className="detail-value">{selectedRequest.fulfilledQuantity || 0} units</span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Remaining</span>
                  <span className="detail-value">{selectedRequest.remainingQuantity || selectedRequest.quantity} units</span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Urgency</span>
                  <span className="detail-value" style={{ color: selectedRequest.urgency === 'Critical' ? '#E53935' : selectedRequest.urgency === 'Urgent' ? '#FB8C00' : '#1976D2' }}>
                    {selectedRequest.urgency === 'Critical' ? '🔴 Critical' : selectedRequest.urgency === 'Urgent' ? '🟠 Urgent' : '🔵 Normal'}
                  </span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Status</span>
                  <span className="detail-value" style={{ color: selectedRequest.status === 'Fulfilled' ? '#2E7D32' : selectedRequest.status === 'Pending' ? '#FB8C00' : '#9E9E9E' }}>
                    {selectedRequest.status}
                  </span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Reason</span>
                  <span className="detail-value">{selectedRequest.reason}</span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Contact Person</span>
                  <span className="detail-value">{selectedRequest.contactPerson}</span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Created</span>
                  <span className="detail-value">{new Date(selectedRequest.createdAt).toLocaleString()}</span>
                </div>
                
                {selectedRequest.responses && selectedRequest.responses.length > 0 && (
                  <>
                    <div className="divider" />
                    <div className="detail-section">
                      <span className="detail-label">Responses ({selectedRequest.responses.length})</span>
                      {selectedRequest.responses.map((resp, idx) => (
                        <div key={idx} style={{ marginTop: '8px', padding: '8px', background: '#F8FAFC', borderRadius: '8px' }}>
                          <div><strong>{resp.hospitalName}</strong> offered {resp.offeredQuantity} units</div>
                          <div style={{ fontSize: '12px', color: '#6B7280' }}>{resp.message}</div>
                          <div style={{ fontSize: '11px', color: '#94A3B8' }}>{new Date(resp.respondedAt).toLocaleString()}</div>
                        </div>
                      ))}
                    </div>
                  </>
                )}
                
                <div style={{ display: "flex", gap: "12px", marginTop: "20px" }}>
                  {selectedRequest.status === 'Pending' && (
                    <>
                      <button
                        onClick={() => {
                          const quantity = prompt('Enter quantity to fulfill:', '1');
                          if (quantity) updateFulfillment(selectedRequest.id, parseInt(quantity));
                          setIsRequestDetailModalOpen(false);
                        }}
                        style={{
                          flex: 1,
                          padding: "12px",
                          background: "#43A047",
                          color: "white",
                          border: "none",
                          borderRadius: "8px",
                          fontWeight: "600",
                          cursor: "pointer",
                          fontFamily: "DM Sans,sans-serif"
                        }}
                      >
                        ✓ Mark Fulfilled
                      </button>
                      <button
                        onClick={() => cancelHospitalRequest(selectedRequest.id)}
                        style={{
                          flex: 1,
                          padding: "12px",
                          background: "#E53935",
                          color: "white",
                          border: "none",
                          borderRadius: "8px",
                          fontWeight: "600",
                          cursor: "pointer",
                          fontFamily: "DM Sans,sans-serif"
                        }}
                      >
                        ✕ Cancel Request
                      </button>
                    </>
                  )}
                  <button
                    onClick={() => setIsRequestDetailModalOpen(false)}
                    style={{
                      flex: 1,
                      padding: "12px",
                      background: "#F3F4F6",
                      color: "#374151",
                      border: "none",
                      borderRadius: "8px",
                      fontWeight: "600",
                      cursor: "pointer",
                      fontFamily: "DM Sans,sans-serif"
                    }}
                  >
                    Close
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
      
      {/* ── Emergency Hospital Request Modal ── */}
      {isEmergencyRequestModalOpen && (
        <div className="modal-overlay" onClick={() => setIsEmergencyRequestModalOpen(false)}>
          <div className="modal-container" style={{ maxWidth: '600px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header" style={{ background: 'linear-gradient(135deg, #E53935 0%, #C62828 100%)' }}>
              <h2 style={{ color: 'white', display: 'flex', alignItems: 'center', gap: '8px' }}>
                🚨 EMERGENCY REQUEST
              </h2>
              <button className="modal-close" onClick={() => setIsEmergencyRequestModalOpen(false)} style={{ color: 'white' }}>
                ✕
              </button>
            </div>
            <div className="modal-body">
              <div style={{ marginBottom: '16px', padding: '12px', background: '#FFEBEE', borderRadius: '8px', borderLeft: '4px solid #E53935' }}>
                <div style={{ fontWeight: '700', color: '#E53935', marginBottom: '4px' }}>⚠️ Critical Alert</div>
                <div style={{ fontSize: '13px', color: '#C62828' }}>
                  This is an EMERGENCY request. It will be broadcasted to all nearby hospitals immediately.
                </div>
              </div>
              
              <form onSubmit={submitEmergencyHospitalRequest} className="inventory-form">
                <div className="form-group">
                  <label className="form-label">Request Type *</label>
                  <select
                    className="form-input"
                    value={emergencyRequestForm.itemType}
                    onChange={(e) => setEmergencyRequestForm({...emergencyRequestForm, itemType: e.target.value})}
                    required
                    style={{ borderColor: '#E53935' }}
                  >
                    <option value="Blood">🩸 Blood</option>
                    <option value="Medical Supplies">💊 Medical Supplies</option>
                    <option value="Equipment">🔧 Equipment</option>
                  </select>
                </div>
                
                <div className="form-group">
                  <label className="form-label">Item Name *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={emergencyRequestForm.itemName}
                    onChange={(e) => setEmergencyRequestForm({...emergencyRequestForm, itemName: e.target.value})}
                    placeholder={emergencyRequestForm.itemType === 'Blood' ? 'e.g., O+ Blood' : 'e.g., Ventilator, Oxygen, Masks, etc.'}
                    required
                    style={{ borderColor: '#E53935' }}
                  />
                </div>
                
                <div className="form-group">
                  <label className="form-label">Quantity Needed *</label>
                  <input
                    type="number"
                    className="form-input"
                    value={emergencyRequestForm.quantity}
                    onChange={(e) => setEmergencyRequestForm({...emergencyRequestForm, quantity: parseInt(e.target.value) || 1})}
                    min="1"
                    max="100"
                    required
                    style={{ borderColor: '#E53935' }}
                  />
                  <small style={{ fontSize: '11px', color: '#6B7280' }}>Units needed urgently</small>
                </div>
                
                <div className="form-group">
                  <label className="form-label">Urgency Level *</label>
                  <select
                    className="form-input"
                    value={emergencyRequestForm.urgency}
                    onChange={(e) => setEmergencyRequestForm({...emergencyRequestForm, urgency: e.target.value})}
                    required
                    style={{ background: '#FFEBEE', borderColor: '#E53935', fontWeight: 'bold', color: '#E53935' }}
                  >
                    <option value="Critical">🔴 CRITICAL - Immediate (Within hours)</option>
                    <option value="Urgent">🟠 URGENT - Within 24 hours</option>
                  </select>
                </div>
                
                <div className="form-group">
                  <label className="form-label">Emergency Reason *</label>
                  <textarea
                    className="form-input"
                    value={emergencyRequestForm.reason}
                    onChange={(e) => setEmergencyRequestForm({...emergencyRequestForm, reason: e.target.value})}
                    rows="3"
                    placeholder="Explain the emergency situation..."
                    required
                    style={{ borderColor: '#E53935' }}
                  />
                </div>
                
                <div className="form-group">
                  <label className="form-label">Contact Person *</label>
                  <input
                    type="text"
                    className="form-input"
                    value={emergencyRequestForm.contactPerson}
                    onChange={(e) => setEmergencyRequestForm({...emergencyRequestForm, contactPerson: e.target.value})}
                    placeholder="Doctor or staff name"
                    required
                    style={{ borderColor: '#E53935' }}
                  />
                </div>
                
                <div style={{ display: "flex", gap: "12px", marginTop: "20px" }}>
                  <button
                    type="submit"
                    disabled={isSubmittingEmergency}
                    style={{
                      flex: 1,
                      padding: "14px",
                      background: "linear-gradient(135deg, #E53935 0%, #C62828 100%)",
                      color: "white",
                      border: "none",
                      borderRadius: "10px",
                      fontWeight: "700",
                      cursor: isSubmittingEmergency ? "not-allowed" : "pointer",
                      opacity: isSubmittingEmergency ? 0.7 : 1,
                      fontFamily: "DM Sans,sans-serif",
                      fontSize: "14px",
                      transition: "all 0.2s"
                    }}
                    onMouseEnter={(e) => e.target.style.transform = 'translateY(-1px)'}
                    onMouseLeave={(e) => e.target.style.transform = 'translateY(0)'}
                  >
                    {isSubmittingEmergency ? "Sending Emergency Request..." : "🚨 SEND EMERGENCY REQUEST"}
                  </button>
                  <button
                    type="button"
                    onClick={() => setIsEmergencyRequestModalOpen(false)}
                    style={{
                      padding: "14px 24px",
                      background: "#F3F4F6",
                      color: "#374151",
                      border: "none",
                      borderRadius: "10px",
                      fontWeight: "600",
                      cursor: "pointer",
                      fontFamily: "DM Sans,sans-serif"
                    }}
                  >
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
      
      {/* ── Alert Detail Modal with Hospital Contact Number ── */}
      {isAlertDetailModalOpen && selectedAlert && (
        <div className="modal-overlay" onClick={() => setIsAlertDetailModalOpen(false)}>
          <div className="modal-container" style={{ maxWidth: '600px' }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Alert Details</h2>
              <button className="modal-close" onClick={() => setIsAlertDetailModalOpen(false)}>
                ✕
              </button>
            </div>
            <div className="modal-body">
              <div className="alert-detail">
                {/* Alert Type */}
                <div className="detail-section">
                  <span className="detail-label">Alert Type</span>
                  <span className="detail-value large" style={{ 
                    color: selectedAlert.type === 'urgent' ? '#E53935' : 
                           selectedAlert.type === 'warning' ? '#FB8C00' : 
                           selectedAlert.type === 'success' ? '#43A047' : '#1976D2'
                  }}>
                    {selectedAlert.type === 'urgent' ? '🔴 CRITICAL' : 
                     selectedAlert.type === 'warning' ? '🟠 WARNING' : 
                     selectedAlert.type === 'success' ? '✅ SUCCESS' : 'ℹ️ INFO'}
                  </span>
                </div>
                <div className="divider" />
                
                {/* Message */}
                <div className="detail-section">
                  <span className="detail-label">Message</span>
                  <span className="detail-value">{selectedAlert.message}</span>
                </div>
                <div className="divider" />
                
                {/* Category */}
                <div className="detail-section">
                  <span className="detail-label">Category</span>
                  <span className="detail-value">
                    {getCategoryIcon(selectedAlert.category)} {selectedAlert.category || "General"}
                  </span>
                </div>
                <div className="divider" />
                
                {/* Time */}
                <div className="detail-section">
                  <span className="detail-label">Received</span>
                  <span className="detail-value">{formatTime(selectedAlert.time)}</span>
                </div>
                <div className="divider" />
                
                {/* Status */}
                <div className="detail-section">
                  <span className="detail-label">Status</span>
                  <span className="detail-value" style={{ color: selectedAlert.read ? '#43A047' : '#E53935' }}>
                    {selectedAlert.read ? '✓ Read' : '● Unread'}
                  </span>
                </div>
                
                {/* Additional details based on alert category */}
                {selectedAlert.category === 'hospital_request' && selectedAlert.requestData && (
                  <>
                    <div className="divider" />
                    <div style={{ background: '#F8FAFC', padding: '16px', borderRadius: '12px', marginTop: '8px' }}>
                      <div style={{ fontWeight: '700', marginBottom: '12px', color: '#2563EB', fontSize: '16px' }}>
                        📋 Request Details
                      </div>
                      
                      <div style={{ marginBottom: '12px' }}>
                        <div style={{ fontSize: '12px', color: '#6B7280', marginBottom: '4px' }}>Hospital</div>
                        <div style={{ fontSize: '14px', fontWeight: '600', color: '#0F172A' }}>
                          {selectedAlert.requestData.hospitalName}
                        </div>
                      </div>
                      
                      <div style={{ marginBottom: '12px' }}>
                        <div style={{ fontSize: '12px', color: '#6B7280', marginBottom: '4px' }}>📞 Contact Number</div>
                        <div style={{ 
                          fontSize: '16px', 
                          fontWeight: '700', 
                          color: '#2563EB',
                          background: '#EFF6FF',
                          padding: '8px 12px',
                          borderRadius: '8px',
                          display: 'inline-block'
                        }}>
                          {selectedAlert.requestData.hospitalContact || 'Not provided'}
                        </div>
                      </div>
                      
                      <div style={{ marginBottom: '12px' }}>
                        <div style={{ fontSize: '12px', color: '#6B7280', marginBottom: '4px' }}>Item Required</div>
                        <div style={{ fontSize: '14px', fontWeight: '600', color: '#0F172A' }}>
                          {selectedAlert.requestData.itemType} - {selectedAlert.requestData.itemName}
                        </div>
                      </div>
                      
                      <div style={{ marginBottom: '12px' }}>
                        <div style={{ fontSize: '12px', color: '#6B7280', marginBottom: '4px' }}>Quantity Needed</div>
                        <div style={{ fontSize: '14px', fontWeight: '600', color: '#0F172A' }}>
                          {selectedAlert.requestData.quantityNeeded} units
                        </div>
                      </div>
                      
                      <div style={{ marginBottom: '12px' }}>
                        <div style={{ fontSize: '12px', color: '#6B7280', marginBottom: '4px' }}>Remaining</div>
                        <div style={{ fontSize: '14px', fontWeight: '600', color: '#E53935' }}>
                          {selectedAlert.requestData.remainingQuantity} units
                        </div>
                      </div>
                      
                      <div style={{ marginBottom: '12px' }}>
                        <div style={{ fontSize: '12px', color: '#6B7280', marginBottom: '4px' }}>Contact Person</div>
                        <div style={{ fontSize: '14px', fontWeight: '600', color: '#0F172A' }}>
                          {selectedAlert.requestData.contactPerson}
                        </div>
                      </div>
                      
                      <div style={{ marginBottom: '12px' }}>
                        <div style={{ fontSize: '12px', color: '#6B7280', marginBottom: '4px' }}>Reason</div>
                        <div style={{ fontSize: '13px', color: '#374151', lineHeight: '1.4' }}>
                          {selectedAlert.requestData.reason}
                        </div>
                      </div>
                      
                      {selectedAlert.requestData.urgency === 'Critical' && (
                        <div style={{ marginTop: '12px', padding: '10px', background: '#FFEBEE', borderRadius: '8px', color: '#E53935', fontSize: '13px', fontWeight: '600', textAlign: 'center' }}>
                          🚨 CRITICAL REQUEST - Immediate attention required!
                        </div>
                      )}
                      
                      {/* Call Button */}
                      {selectedAlert.requestData.hospitalContact && (
                        <a 
                          href={`tel:${selectedAlert.requestData.hospitalContact}`}
                          style={{
                            display: 'block',
                            width: '100%',
                            marginTop: '16px',
                            padding: '12px',
                            background: '#10B981',
                            color: 'white',
                            border: 'none',
                            borderRadius: '10px',
                            fontWeight: '700',
                            cursor: 'pointer',
                            textAlign: 'center',
                            textDecoration: 'none',
                            fontFamily: 'DM Sans, sans-serif',
                            fontSize: '14px',
                            transition: 'all 0.2s'
                          }}
                          onMouseEnter={(e) => e.target.style.background = '#059669'}
                          onMouseLeave={(e) => e.target.style.background = '#10B981'}
                        >
                          📞 Call Hospital: {selectedAlert.requestData.hospitalContact}
                        </a>
                      )}
                      
                      <button
                        onClick={() => {
                          setIsAlertDetailModalOpen(false);
                          const quantity = prompt('How many units can you offer?', '1');
                          const message = prompt('Add a message (optional):', 'We can help with this request');
                          if (quantity) {
                            addResponse(selectedAlert.requestData.requestId, parseInt(quantity), message);
                          }
                        }}
                        style={{
                          width: '100%',
                          marginTop: '12px',
                          padding: '12px',
                          background: '#2563EB',
                          color: 'white',
                          border: 'none',
                          borderRadius: '10px',
                          fontWeight: '600',
                          cursor: 'pointer',
                          fontFamily: 'DM Sans, sans-serif',
                          fontSize: '14px',
                          transition: 'all 0.2s'
                        }}
                        onMouseEnter={(e) => e.target.style.background = '#1D4ED8'}
                        onMouseLeave={(e) => e.target.style.background = '#2563EB'}
                      >
                        🤝 Offer Help
                      </button>
                    </div>
                  </>
                )}
                
                {selectedAlert.category === 'inventory' && (
                  <>
                    <div className="divider" />
                    <div style={{ background: '#FFF5F5', padding: '16px', borderRadius: '12px', marginTop: '8px' }}>
                      <div style={{ fontWeight: '700', marginBottom: '8px', color: '#E53935', fontSize: '16px' }}>
                        🩸 Inventory Alert
                      </div>
                      <div style={{ fontSize: '13px', color: '#374151', marginBottom: '12px' }}>
                        This is a blood inventory alert. Please check your stock levels and consider replenishing soon.
                      </div>
                      <button
                        onClick={() => {
                          setIsAlertDetailModalOpen(false);
                          setActiveSection('inventory');
                        }}
                        style={{
                          width: '100%',
                          padding: '12px',
                          background: '#2563EB',
                          color: 'white',
                          border: 'none',
                          borderRadius: '10px',
                          fontWeight: '600',
                          cursor: 'pointer',
                          fontFamily: 'DM Sans, sans-serif'
                        }}
                      >
                        Go to Inventory
                      </button>
                    </div>
                  </>
                )}
                
                {selectedAlert.category === 'request' && (
                  <>
                    <div className="divider" />
                    <div style={{ background: '#E3F2FD', padding: '16px', borderRadius: '12px', marginTop: '8px' }}>
                      <div style={{ fontWeight: '700', marginBottom: '8px', color: '#1976D2', fontSize: '16px' }}>
                        📋 Patient Request Alert
                      </div>
                      <div style={{ fontSize: '13px', color: '#374151', marginBottom: '12px' }}>
                        A patient request requires attention. Please review and take appropriate action.
                      </div>
                      <button
                        onClick={() => {
                          setIsAlertDetailModalOpen(false);
                          navigate('/bloodbank/requests');
                        }}
                        style={{
                          width: '100%',
                          padding: '12px',
                          background: '#2563EB',
                          color: 'white',
                          border: 'none',
                          borderRadius: '10px',
                          fontWeight: '600',
                          cursor: 'pointer',
                          fontFamily: 'DM Sans, sans-serif'
                        }}
                      >
                        View Requests
                      </button>
                    </div>
                  </>
                )}
                
                <div style={{ display: "flex", gap: "12px", marginTop: "20px" }}>
                  <button
                    onClick={() => setIsAlertDetailModalOpen(false)}
                    style={{
                      flex: 1,
                      padding: "12px",
                      background: "#F3F4F6",
                      color: "#374151",
                      border: "none",
                      borderRadius: "8px",
                      fontWeight: "600",
                      cursor: "pointer",
                      fontFamily: "DM Sans,sans-serif"
                    }}
                  >
                    Close
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
      
      {/* ── Instruction Modal Popup ── */}
      {isModalOpen && selectedInstruction && (
        <div className="modal-overlay" onClick={closeInstructionModal}>
          <div className="modal-container" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>📋 Doctor's Instruction</h2>
              <button className="modal-close" onClick={closeInstructionModal}>
                ✕
              </button>
            </div>
            <div className="modal-body">
              <div className="instruction-detail">
                <div className="detail-section">
                  <span className="detail-label">Title</span>
                  <span className="detail-value large">{selectedInstruction.title}</span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Description</span>
                  <span className="detail-value">{selectedInstruction.description}</span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Priority Level</span>
                  <span className="detail-value">
                    {selectedInstruction.priority === "Critical" ? "🔴 Critical - Immediate Action Required" : 
                     selectedInstruction.priority === "High" ? "🟠 High Priority - Urgent" : 
                     selectedInstruction.priority === "Medium" ? "🔵 Medium Priority" : 
                     "🟢 Normal Priority"}
                  </span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Issued By</span>
                  <span className="detail-value">{selectedInstruction.issuedBy}</span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Date Issued</span>
                  <span className="detail-value">{selectedInstruction.date}</span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Applicable Department</span>
                  <span className="detail-value">{selectedInstruction.department}</span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Instruction Type</span>
                  <span className="detail-value">
                    {selectedInstruction.instructionType === "emergency" ? "🚨 Emergency Protocol" :
                     selectedInstruction.instructionType === "alert" ? "⚠️ Critical Alert" :
                     selectedInstruction.instructionType === "scheduled" ? "📅 Scheduled Event" :
                     selectedInstruction.instructionType === "protocol" ? "📋 Standard Protocol" :
                     selectedInstruction.instructionType === "quality" ? "🔬 Quality Control" :
                     selectedInstruction.instructionType === "training" ? "🎓 Training & Development" :
                     selectedInstruction.instructionType === "safety" ? "🛡️ Safety Protocol" :
                     selectedInstruction.instructionType === "inventory" ? "📦 Inventory Management" :
                     selectedInstruction.instructionType === "meeting" ? "📊 Meeting Schedule" :
                     "📄 General Instruction"}
                  </span>
                </div>
                <div className="divider" />
                <div className="detail-section">
                  <span className="detail-label">Additional Notes</span>
                  <span className="detail-value">{selectedInstruction.additionalNotes}</span>
                </div>
                <div className="divider" />
                <div style={{ 
                  marginTop: "16px", 
                  padding: "12px", 
                  background: "#F8FAFC", 
                  borderRadius: "12px",
                  borderLeft: `4px solid ${getPriorityColor(selectedInstruction.priority).color}`
                }}>
                  <div style={{ fontSize: "12px", color: "#6B7280", marginBottom: "8px" }}>
                    ⏱️ Acknowledgment Required
                  </div>
                  <button
                    onClick={closeInstructionModal}
                    style={{
                      width: "100%",
                      padding: "10px",
                      background: "#2563EB",
                      color: "white",
                      border: "none",
                      borderRadius: "8px",
                      fontWeight: "600",
                      cursor: "pointer",
                      fontFamily: "DM Sans,sans-serif"
                    }}
                  >
                    Mark as Read & Acknowledge
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
};

// ── Styles for loading/error screens ─────────────────────────────────────────
const styles = {
  loadingContainer: {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    minHeight: "100vh",
    gap: "16px",
    fontFamily: "DM Sans,sans-serif",
  },
  loadingSpinner: {
    width: "40px",
    height: "40px",
    border: "3px solid #E2E8F0",
    borderTopColor: "#2563EB",
    borderRadius: "50%",
    animation: "spin 1s linear infinite",
  },
  errorContainer: {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    minHeight: "100vh",
    gap: "16px",
    fontFamily: "DM Sans,sans-serif",
    padding: "24px",
  },
  retryButton: {
    padding: "10px 24px",
    background: "#2563EB",
    color: "white",
    border: "none",
    borderRadius: "8px",
    cursor: "pointer",
    fontWeight: "600",
  },
};

// Spin keyframe (injected once)
const _style = document.createElement("style");
_style.textContent =
  "@keyframes spin{0%{transform:rotate(0deg)}100%{transform:rotate(360deg)}}";
document.head.appendChild(_style);

export default BloodBankDashboard;