const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

const Hospital = require('../models/Hospital');
const EmergencyRequest = require('../models/EmergencyRequest');  
const Donation = require('../models/Donation');
const HospitalRequest = require('../models/HospitalRequest');

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// ====================== MULTER SETUP ======================
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'uploads/documents/'),
    filename: (req, file, cb) => {
        cb(null, `${Date.now()}-${file.fieldname}${path.extname(file.originalname)}`);
    }
});

const upload = multer({
    storage,
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
        if (/pdf|jpg|jpeg|png/.test(path.extname(file.originalname).toLowerCase())) {
            return cb(null, true);
        }
        cb(new Error('Only PDF, JPG, JPEG, PNG allowed'));
    }
}).fields([
    { name: 'govtCertificate', maxCount: 1 },
    { name: 'medicalLicense', maxCount: 1 },
    { name: 'authorizedId', maxCount: 1 }
]);

// ====================== AUTH MIDDLEWARE ======================
const authenticateHospital = async (req, res, next) => {
    try {
        const token = req.headers.authorization?.replace('Bearer ', '');
        const hospitalId = req.headers['hospital-id'];

        if (!token || !hospitalId) {
            return res.status(401).json({ success: false, message: 'Authentication required' });
        }

        const decoded = jwt.verify(token, JWT_SECRET);
        if (String(decoded.hospitalId) !== String(hospitalId)) {
            return res.status(401).json({ success: false, message: 'Invalid token' });
        }

        req.hospitalId = hospitalId;
        next();
    } catch (err) {
        return res.status(401).json({ success: false, message: 'Invalid or expired token' });
    }
};

// ====================== HELPERS ======================
function getTimeAgo(date) {
    const s = Math.floor((Date.now() - new Date(date)) / 1000);
    if (s < 60) return `${s} seconds ago`;
    if (s < 3600) return `${Math.floor(s / 60)} minutes ago`;
    if (s < 86400) return `${Math.floor(s / 3600)} hours ago`;
    return `${Math.floor(s / 86400)} days ago`;
}

function calculateTimeLeft(createdAt) {
    const mins = Math.floor((Date.now() - new Date(createdAt)) / 60000);
    return `${Math.max(0, 30 - mins)}M`;
}

function getActionLabel(status, urgency) {
    if (status === 'Matched') return urgency === 'Critical' ? '🚨 Urgent — Donor Matched' : '✅ Donor Matched';
    if (status === 'Active') return urgency === 'Critical' || urgency === 'Urgent' ? '⚡ Urgent Processing' : '📋 Process Request';
    if (status === 'Pending') return urgency === 'Critical' || urgency === 'Urgent' ? '⚡ Urgent Processing' : '📋 Review Request';
    if (status === 'Completed') return '✔ View Summary';
    if (status === 'Cancelled') return 'View Details';
    return 'Process Request';
}

// ====================== REGISTER ======================
router.post('/register', upload, async (req, res) => {
    try {
        const { name, email, password, regNumber, address, contact, storageCapacity, bloodInventory, selectedBloodTypes } = req.body;

        const existing = await Hospital.findOne({ 
            $or: [{ email: email.toLowerCase() }, { regNumber }] 
        });

        if (existing) {
            return res.status(400).json({ success: false, message: 'Email or Registration Number already exists' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const documents = {};
        if (req.files?.govtCertificate) documents.govtCertificate = req.files.govtCertificate[0].path;
        if (req.files?.medicalLicense)  documents.medicalLicense = req.files.medicalLicense[0].path;
        if (req.files?.authorizedId)    documents.authorizedId = req.files.authorizedId[0].path;

        const hospital = new Hospital({
            name,
            email: email.toLowerCase(),
            password: hashedPassword,
            regNumber,
            address,
            contact,
            storageCapacity: Number(storageCapacity) || 5000,
            bloodInventory: bloodInventory ? JSON.parse(bloodInventory) : {},
            selectedBloodTypes: selectedBloodTypes ? JSON.parse(selectedBloodTypes) : ['A+','A-','B+','B-','O+','O-','AB+','AB-'],
            documents,
            isVerified: false
        });

        await hospital.save();

        const token = jwt.sign({ hospitalId: hospital._id }, JWT_SECRET, { expiresIn: '7d' });

        res.status(201).json({
            success: true,
            message: 'Hospital registered successfully!',
            token,
            hospitalId: hospital._id,
            name: hospital.name,
            email: hospital.email
        });
    } catch (err) {
        console.error('Register error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// ====================== LOGIN ======================
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ 
                success: false, 
                message: 'Email and password are required' 
            });
        }

        const hospital = await Hospital.findOne({ 
            email: email.toLowerCase() 
        });

        if (!hospital) {
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid email or password' 
            });
        }

        const isMatch = await bcrypt.compare(password, hospital.password);
        if (!isMatch) {
            return res.status(401).json({ 
                success: false, 
                message: 'Invalid email or password' 
            });
        }

        if (!hospital.isVerified) {
            return res.status(403).json({ 
                success: false, 
                message: 'Your hospital account is not yet verified. Please wait for admin approval or contact support.',
                isVerified: false
            });
        }

        const token = jwt.sign({ hospitalId: hospital._id }, JWT_SECRET, { expiresIn: '7d' });

        res.json({
            success: true,
            message: 'Login successful',
            token,
            hospitalId: hospital._id,
            name: hospital.name,
            hospitalName: hospital.name,
            email: hospital.email,
            regNumber: hospital.regNumber,
            address: hospital.address,
            contact: hospital.contact,
            storageCapacity: hospital.storageCapacity,
            isVerified: hospital.isVerified,
            selectedBloodTypes: hospital.selectedBloodTypes,
            bloodInventory: hospital.bloodInventory
        });

    } catch (err) {
        console.error('Login error:', err);
        res.status(500).json({ 
            success: false, 
            message: 'Server error during login' 
        });
    }
});

// ====================== DASHBOARD ======================
router.get('/dashboard', authenticateHospital, async (req, res) => {
    try {
        const hid = new mongoose.Types.ObjectId(req.hospitalId);

        const hospital = await Hospital.findById(hid);
        if (!hospital) {
            return res.status(404).json({ success: false, message: 'Hospital not found' });
        }

        const bloodStocks = Object.entries(hospital.bloodInventory || {}).map(([bloodType, units]) => ({
            bloodType,
            units: units || 0
        }));

        const patientRequests = await EmergencyRequest.find({
            hospitalId: hid,
            status: { $in: ['Active', 'Pending', 'Matched'] }
        }).sort({ createdAt: -1 }).limit(10).lean();

        const formattedPatientRequests = patientRequests.map(r => ({
            id: r._id.toString(),
            name: r.patientName,
            bloodType: r.bloodGroup,
            organType: r.organType || null,
            requestType: r.requestType || 'Blood',
            units: r.unitsNeeded,
            urgency: r.urgencyLevel,
            status: r.status,
            donorFound: r.donorFound || false,
            hospitalName: r.hospitalName || hospital.name,
            notes: r.additionalNotes || '',
            matchedAt: r.matchedAt || null,
            timeAgo: getTimeAgo(r.createdAt),
            actionLabel: getActionLabel(r.status, r.urgencyLevel)
        }));

        const urgentRequests = await EmergencyRequest.find({
            hospitalId: hid,
            urgencyLevel: { $in: ['Critical', 'Urgent'] },
            status: { $in: ['Active', 'Pending', 'Matched'] }
        }).sort({ createdAt: -1 }).limit(10).lean();

        const formattedUrgentRequests = urgentRequests.map(r => ({
            id: r._id.toString(),
            bloodGroup: r.bloodGroup,
            unitsNeeded: r.unitsNeeded,
            timeLeft: calculateTimeLeft(r.createdAt),
            hospitalOrER: r.hospitalName || hospital.name,
            patientName: r.patientName,
            urgency: r.urgencyLevel,
            status: r.status,
            requestType: r.requestType
        }));

        const availableDonorsRes = await fetch(`http://localhost:8083/api/hospitals/available-donors`, {
            headers: {
                Authorization: req.headers.authorization,
                'Hospital-Id': req.hospitalId
            }
        });
        const donorsData = availableDonorsRes.ok ? await availableDonorsRes.json() : { availableDonors: [] };

        res.json({
            success: true,
            hospitalName: hospital.name,
            bloodStocks,
            patientRequests: formattedPatientRequests,
            urgentRequests: formattedUrgentRequests,
            availableDonors: donorsData.availableDonors || [],
            instructions: []
        });
    } catch (err) {
        console.error('Dashboard error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// ====================== GET PATIENT REQUESTS ======================
router.get('/patient-requests', authenticateHospital, async (req, res) => {
    try {
        const { status, urgency, bloodType } = req.query;
        const hid = new mongoose.Types.ObjectId(req.hospitalId);

        const filter = { hospitalId: hid };

        if (status === 'active') {
            filter.status = { $in: ['Active', 'Pending', 'Matched'] };
        } else if (status === 'completed') {
            filter.status = 'Completed';
        } else if (status === 'cancelled') {
            filter.status = 'Cancelled';
        }

        if (urgency && urgency !== 'All') filter.urgencyLevel = urgency;
        if (bloodType && bloodType !== 'All') filter.bloodGroup = bloodType;

        const raw = await EmergencyRequest.find(filter)
            .sort({ createdAt: -1 })
            .lean();

        const requests = raw.map(r => ({
            id: r._id.toString(),
            name: r.patientName || 'Unknown Patient',
            avatarUrl: `https://ui-avatars.com/api/?name=${encodeURIComponent(r.patientName || 'P')}&background=E3F2FD&color=1565C0`,
            hospital: r.hospitalName || 'Your Hospital',
            required: `${r.bloodGroup} ${r.requestType || 'Blood'}`,
            bloodType: r.bloodGroup,
            units: r.unitsNeeded || 0,
            urgency: r.urgencyLevel || 'normal',
            status: r.status === 'Matched' ? 'Donor Matched' :
                    r.status === 'Active' ? 'Searching for Donors' :
                    r.status === 'Pending' ? 'Pending Approval' : r.status,
            rawStatus: r.status,
            statusColor: r.status === 'Matched' || r.status === 'Completed' ? '#43A047' :
                         r.status === 'Active' ? '#1976D2' : '#FB8C00',
            priority: (r.urgencyLevel === 'Critical' || r.urgencyLevel === 'Urgent') ? 'CRITICAL' : 'NORMAL',
            priorityColor: (r.urgencyLevel === 'Critical' || r.urgencyLevel === 'Urgent') ? '#E53935' : '#6B7280',
            donorFound: r.donorFound || false,
            notes: r.additionalNotes || '',
            timeAgo: getTimeAgo(r.createdAt),
            requestType: r.requestType || 'Blood',
            organType: r.organType
        }));

        res.json({
            success: true,
            requests,
            count: requests.length
        });
    } catch (err) {
        console.error('patient-requests error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// ====================== OTHER REQUEST ROUTES ======================
router.get('/requests', authenticateHospital, (req, res) => {
    req.url = '/patient-requests' + (req.url.includes('?') ? req.url.slice(req.url.indexOf('?')) : '');
    router.handle(req, res, () => {});
});

router.get('/urgent-requests', authenticateHospital, async (req, res) => {
    try {
        const hid = new mongoose.Types.ObjectId(req.hospitalId);

        const raw = await EmergencyRequest.find({
            hospitalId: hid,
            urgencyLevel: { $in: ['Critical', 'Urgent'] },
            status: { $in: ['Active', 'Pending', 'Matched'] }
        }).sort({ createdAt: -1 }).limit(10).lean();

        const urgentRequests = raw.map(r => ({
            id: r._id.toString(),
            bloodGroup: r.bloodGroup,
            unitsNeeded: r.unitsNeeded,
            timeLeft: calculateTimeLeft(r.createdAt),
            hospitalOrER: r.hospitalName || 'Emergency Room',
            patientName: r.patientName,
            urgency: r.urgencyLevel,
            status: r.status,
            requestType: r.requestType
        }));

        res.json({ success: true, urgentRequests });
    } catch (err) {
        console.error('urgent-requests error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

router.post('/urgent-requests/:requestId/accept', authenticateHospital, async (req, res) => {
    try {
        const request = await EmergencyRequest.findById(req.params.requestId);
        if (!request) return res.status(404).json({ success: false, message: 'Request not found' });

        request.status = 'Matched';
        request.matchedAt = new Date();
        if (req.body.messageToPatient) request.hospitalResponse = req.body.messageToPatient;

        await request.save();
        res.json({ success: true, message: 'Request accepted' });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

router.post('/requests/:requestId/complete', authenticateHospital, async (req, res) => {
    try {
        const request = await EmergencyRequest.findById(req.params.requestId);
        if (!request) return res.status(404).json({ success: false, message: 'Request not found' });

        request.status = 'Completed';
        request.completedAt = new Date();
        await request.save();
        res.json({ success: true, message: 'Request marked as completed' });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

router.post('/requests/:requestId/cancel', authenticateHospital, async (req, res) => {
    try {
        const request = await EmergencyRequest.findById(req.params.requestId);
        if (!request) return res.status(404).json({ success: false, message: 'Request not found' });

        request.status = 'Cancelled';
        request.cancelledAt = new Date();
        request.cancellationReason = req.body.reason || '';
        await request.save();
        res.json({ success: true, message: 'Request cancelled' });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// ====================== GET AVAILABLE DONORS ======================
router.get('/available-donors', authenticateHospital, async (req, res) => {
    try {
        const hid = new mongoose.Types.ObjectId(req.hospitalId);

        const hospital = await Hospital.findById(hid).select('city');
        const hospitalCity = hospital?.city || '';

        const donors = await mongoose.model('User').find({
            role: 'Donor',
            bloodGroup: { $exists: true, $ne: null },
            isVerified: true,
        })
        .select('fullName bloodGroup city phone avatarUrl dob age lastDonationDate')
        .sort({ createdAt: -1 })
        .limit(12)
        .lean();

        const formattedDonors = donors.map(donor => {
            const age = donor.dob 
                ? new Date().getFullYear() - new Date(donor.dob).getFullYear() 
                : donor.age || '—';

            return {
                id: donor._id.toString(),
                name: donor.fullName || 'Anonymous Donor',
                bloodType: donor.bloodGroup,
                city: donor.city || 'Nearby Area',
                distance: `${Math.floor(Math.random() * 12) + 1} km`,
                avatarUrl: donor.avatarUrl || 'http://192.168.1.2:3000/uploads/avatars/default-user.png',
                age: age,
                phoneLast: donor.phone ? donor.phone.slice(-4) : 'xxxx',
                lastDonation: donor.lastDonationDate 
                    ? getTimeAgo(donor.lastDonationDate) 
                    : 'First time donor'
            };
        });

        res.json({
            success: true,
            availableDonors: formattedDonors,
            count: formattedDonors.length
        });
    } catch (err) {
        console.error('Available donors error:', err);
        res.status(500).json({ 
            success: false, 
            message: 'Failed to load available donors' 
        });
    }
});

// ====================== UPDATE BLOOD INVENTORY ======================
router.post('/inventory/update', authenticateHospital, async (req, res) => {
  try {
    const { bloodInventory, updateReason, bloodType, action, quantity } = req.body;
    const hid = new mongoose.Types.ObjectId(req.hospitalId);

    if (!bloodInventory && (!bloodType || !action)) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please provide inventory data or blood type with action' 
      });
    }

    const hospital = await Hospital.findById(hid);
    if (!hospital) {
      return res.status(404).json({ success: false, message: 'Hospital not found' });
    }

    let updatedInventory = { ...hospital.bloodInventory };

    if (bloodInventory) {
      updatedInventory = bloodInventory;
    } else if (bloodType && action) {
      const currentUnits = updatedInventory[bloodType] || 0;
      let newUnits = currentUnits;

      switch (action) {
        case 'add':
          newUnits = currentUnits + quantity;
          break;
        case 'remove':
          newUnits = Math.max(0, currentUnits - quantity);
          break;
        case 'set':
          newUnits = quantity;
          break;
        default:
          return res.status(400).json({ success: false, message: 'Invalid action' });
      }

      updatedInventory[bloodType] = newUnits;
      
      if (newUnits === 0) {
        delete updatedInventory[bloodType];
      }
    }

    hospital.bloodInventory = updatedInventory;
    await hospital.save();

    const bloodStocks = Object.entries(updatedInventory).map(([bloodType, units]) => ({
      bloodType,
      units: units || 0
    }));

    res.json({
      success: true,
      message: 'Inventory updated successfully',
      bloodStocks,
      inventory: updatedInventory
    });
  } catch (err) {
    console.error('Inventory update error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ====================== BULK UPDATE INVENTORY ======================
router.post('/inventory/bulk-update', authenticateHospital, async (req, res) => {
  try {
    const { inventory } = req.body;
    const hid = new mongoose.Types.ObjectId(req.hospitalId);

    if (!inventory || !Array.isArray(inventory)) {
      return res.status(400).json({ 
        success: false, 
        message: 'Please provide inventory array' 
      });
    }

    const hospital = await Hospital.findById(hid);
    if (!hospital) {
      return res.status(404).json({ success: false, message: 'Hospital not found' });
    }

    const updatedInventory = {};
    inventory.forEach(item => {
      if (item.bloodType && typeof item.units === 'number') {
        updatedInventory[item.bloodType] = item.units;
      }
    });

    hospital.bloodInventory = updatedInventory;
    await hospital.save();

    const bloodStocks = Object.entries(updatedInventory).map(([bloodType, units]) => ({
      bloodType,
      units: units || 0
    }));

    res.json({
      success: true,
      message: 'Bulk inventory update successful',
      bloodStocks
    });
  } catch (err) {
    console.error('Bulk inventory update error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ====================== GET INVENTORY HISTORY ======================
router.get('/inventory/history', authenticateHospital, async (req, res) => {
  try {
    res.json({
      success: true,
      message: 'Inventory history feature coming soon',
      history: []
    });
  } catch (err) {
    console.error('Inventory history error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ====================== CHECK INVENTORY STATUS ======================
router.get('/inventory/status', authenticateHospital, async (req, res) => {
  try {
    const hid = new mongoose.Types.ObjectId(req.hospitalId);
    const hospital = await Hospital.findById(hid);
    
    if (!hospital) {
      return res.status(404).json({ success: false, message: 'Hospital not found' });
    }

    const inventory = hospital.bloodInventory || {};
    const critical = [];
    const low = [];
    const normal = [];

    Object.entries(inventory).forEach(([bloodType, units]) => {
      if (units <= 5) {
        critical.push({ bloodType, units });
      } else if (units <= 10) {
        low.push({ bloodType, units });
      } else {
        normal.push({ bloodType, units });
      }
    });

    res.json({
      success: true,
      status: {
        critical,
        low,
        normal,
        totalUnits: Object.values(inventory).reduce((sum, units) => sum + units, 0),
        bloodTypesCount: Object.keys(inventory).length
      }
    });
  } catch (err) {
    console.error('Inventory status error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ====================== GET ALERTS (Includes Hospital Requests from Other Hospitals) ======================
router.get('/alerts', authenticateHospital, async (req, res) => {
    try {
        const hid = new mongoose.Types.ObjectId(req.hospitalId);
        const hospital = await Hospital.findById(hid);
        if (!hospital) {
            return res.status(404).json({ success: false, message: 'Hospital not found' });
        }

        const alerts = [];

        // 1. Low Blood Stock Alerts
        const bloodInventory = hospital.bloodInventory || {};
        Object.entries(bloodInventory).forEach(([bloodType, units]) => {
            if (units <= 5) {
                alerts.push({
                    id: `blood-low-${bloodType}`,
                    type: "urgent",
                    message: `Blood stock for ${bloodType} is critically low (${units} units)`,
                    time: "Just now",
                    read: false,
                    category: "inventory"
                });
            } else if (units <= 10) {
                alerts.push({
                    id: `blood-low-${bloodType}`,
                    type: "warning",
                    message: `${bloodType} blood stock is running low (${units} units remaining)`,
                    time: "Today",
                    read: false,
                    category: "inventory"
                });
            }
        });

        // 2. Critical Patient Requests from this hospital
        const criticalRequests = await EmergencyRequest.find({
            hospitalId: hid,
            urgencyLevel: { $in: ['Critical', 'Urgent'] },
            status: { $in: ['Active', 'Pending'] }
        }).sort({ createdAt: -1 }).limit(5).lean();

        criticalRequests.forEach(req => {
            alerts.push({
                id: `req-${req._id}`,
                type: "urgent",
                message: `Critical request: ${req.patientName} needs ${req.bloodGroup} (${req.unitsNeeded} units) - ${req.urgencyLevel}`,
                time: getTimeAgo(req.createdAt),
                read: false,
                category: "request"
            });
        });

        // 3. Hospital Requests from OTHER hospitals (not this hospital)
        const otherHospitalRequests = await HospitalRequest.find({
            hospitalId: { $ne: hid },
            status: { $in: ['Pending', 'Partially Fulfilled'] },
            createdAt: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
        })
        .sort({ createdAt: -1 })
        .limit(10)
        .lean();

        otherHospitalRequests.forEach(req => {
            let alertType = "info";
            let urgencyLabel = "";
            
            if (req.urgency === 'Critical') {
                alertType = "urgent";
                urgencyLabel = "🚨 CRITICAL";
            } else if (req.urgency === 'Urgent') {
                alertType = "warning";
                urgencyLabel = "⚡ URGENT";
            } else {
                alertType = "info";
                urgencyLabel = "📌";
            }
            
            const remainingQuantity = req.quantity - (req.fulfilledQuantity || 0);
            
            alerts.push({
                id: `hospital-req-${req._id}`,
                type: alertType,
                message: `${urgencyLabel} Request from ${req.hospitalName}: ${req.itemType} - ${req.itemName} (${remainingQuantity} units needed) - ${req.reason.substring(0, 100)}`,
                time: getTimeAgo(req.createdAt),
                read: false,
                category: "hospital_request",
                requestData: {
                    requestId: req._id,
                    hospitalId: req.hospitalId,
                    hospitalName: req.hospitalName,
                    hospitalContact: req.hospitalContact,
                    itemType: req.itemType,
                    itemName: req.itemName,
                    quantityNeeded: req.quantity,
                    fulfilledQuantity: req.fulfilledQuantity || 0,
                    remainingQuantity: remainingQuantity,
                    urgency: req.urgency,
                    reason: req.reason,
                    contactPerson: req.contactPerson,
                    createdAt: req.createdAt
                }
            });
        });

        // 4. Donor Donation Requests
        const recentDonations = await Donation.find({
            hospitalName: hospital.name,
            status: { $in: ['Eligible', 'Pending', 'Completed'] }
        }).sort({ createdAt: -1 }).limit(8).lean();

        recentDonations.forEach(donation => {
            let message = "";
            let type = "info";

            if (donation.status === 'Completed') {
                message = `Donor ${donation.donorName} successfully donated ${donation.units} of ${donation.donationType}`;
                type = "success";
            } else if (donation.status === 'Pending') {
                message = `New donation request from ${donation.donorName} (${donation.donationType})`;
                type = "info";
            } else {
                message = `${donation.donorName} is eligible for ${donation.donationType} donation`;
                type = "info";
            }

            alerts.push({
                id: `donation-${donation._id}`,
                type: type,
                message: message,
                time: getTimeAgo(donation.createdAt),
                read: false,
                category: "donation"
            });
        });

        alerts.sort((a, b) => {
            const priority = { urgent: 3, warning: 2, info: 1, success: 0 };
            if (priority[a.type] !== priority[b.type]) {
                return priority[b.type] - priority[a.type];
            }
            return 0;
        });

        res.json({
            success: true,
            alerts: alerts.slice(0, 25),
            count: alerts.length,
            unreadCount: alerts.filter(a => !a.read).length
        });

    } catch (err) {
        console.error('Alerts fetch error:', err);
        res.status(500).json({
            success: false,
            message: 'Failed to load alerts'
        });
    }
});

// ====================== MARK ALERT AS READ ======================
router.post('/alerts/:alertId/read', authenticateHospital, async (req, res) => {
    try {
        res.json({
            success: true,
            message: 'Alert marked as read'
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// ====================== MARK ALL ALERTS AS READ ======================
router.post('/alerts/mark-all-read', authenticateHospital, async (req, res) => {
    try {
        res.json({
            success: true,
            message: 'All alerts marked as read'
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// ====================== CREATE HOSPITAL REQUEST ======================
router.post('/hospital-requests', authenticateHospital, async (req, res) => {
    try {
        const {
            itemType,
            itemName,
            quantity,
            urgency,
            reason,
            contactPerson
        } = req.body;

        const hid = new mongoose.Types.ObjectId(req.hospitalId);
        const hospital = await Hospital.findById(hid);
        
        if (!hospital) {
            return res.status(404).json({ success: false, message: 'Hospital not found' });
        }

        if (!itemType || !itemName || !quantity || !reason || !contactPerson) {
            return res.status(400).json({ 
                success: false, 
                message: 'Missing required fields: itemType, itemName, quantity, reason, contactPerson' 
            });
        }

        const request = new HospitalRequest({
            hospitalId: hid,
            hospitalName: hospital.name,
            hospitalContact: hospital.contact,
            itemType,
            itemName,
            quantity,
            urgency: urgency || 'Normal',
            reason,
            contactPerson,
            status: 'Pending',
            fulfilledQuantity: 0,
            responses: []
        });

        await request.save();

        console.log(`New hospital request created: ${request.itemName} from ${hospital.name}`);

        res.status(201).json({
            success: true,
            message: 'Request created successfully',
            request: {
                id: request._id,
                itemType: request.itemType,
                itemName: request.itemName,
                quantity: request.quantity,
                urgency: request.urgency,
                status: request.status,
                createdAt: request.createdAt
            }
        });

    } catch (err) {
        console.error('Create hospital request error:', err);
        res.status(500).json({ 
            success: false, 
            message: 'Failed to create request',
            error: err.message 
        });
    }
});

// ====================== GET ALL HOSPITAL REQUESTS ======================
router.get('/hospital-requests', authenticateHospital, async (req, res) => {
    try {
        const { status, urgency, itemType, limit = 50 } = req.query;
        const hid = new mongoose.Types.ObjectId(req.hospitalId);
        
        const filter = { hospitalId: hid };
        
        if (status && status !== 'All') filter.status = status;
        if (urgency && urgency !== 'All') filter.urgency = urgency;
        if (itemType && itemType !== 'All') filter.itemType = itemType;
        
        const requests = await HospitalRequest.find(filter)
            .sort({ createdAt: -1 })
            .limit(parseInt(limit))
            .lean();
        
        const formattedRequests = requests.map(req => ({
            ...req,
            remainingQuantity: req.quantity - (req.fulfilledQuantity || 0),
            isFullyFulfilled: (req.fulfilledQuantity || 0) >= req.quantity
        }));
        
        res.json({
            success: true,
            requests: formattedRequests,
            count: formattedRequests.length
        });
        
    } catch (err) {
        console.error('Get hospital requests error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// ====================== GET SINGLE REQUEST ======================
router.get('/hospital-requests/:requestId', authenticateHospital, async (req, res) => {
    try {
        const { requestId } = req.params;
        const hid = new mongoose.Types.ObjectId(req.hospitalId);
        
        const request = await HospitalRequest.findOne({
            _id: requestId,
            hospitalId: hid
        });
        
        if (!request) {
            return res.status(404).json({ success: false, message: 'Request not found' });
        }
        
        res.json({
            success: true,
            request: {
                ...request.toObject(),
                remainingQuantity: request.quantity - (request.fulfilledQuantity || 0),
                isFullyFulfilled: (request.fulfilledQuantity || 0) >= request.quantity
            }
        });
        
    } catch (err) {
        console.error('Get hospital request error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// ====================== UPDATE REQUEST FULFILLMENT ======================
router.patch('/hospital-requests/:requestId/fulfill', authenticateHospital, async (req, res) => {
    try {
        const { requestId } = req.params;
        const { quantity } = req.body;
        const hid = new mongoose.Types.ObjectId(req.hospitalId);
        
        if (!quantity || quantity <= 0) {
            return res.status(400).json({ success: false, message: 'Valid quantity is required' });
        }
        
        const request = await HospitalRequest.findOne({
            _id: requestId,
            hospitalId: hid
        });
        
        if (!request) {
            return res.status(404).json({ success: false, message: 'Request not found' });
        }
        
        if (request.status === 'Fulfilled') {
            return res.status(400).json({ success: false, message: 'Request is already fulfilled' });
        }
        
        if (request.status === 'Cancelled') {
            return res.status(400).json({ success: false, message: 'Request is cancelled' });
        }
        
        await request.updateFulfillment(quantity);
        
        res.json({
            success: true,
            message: 'Fulfillment updated successfully',
            request: {
                id: request._id,
                fulfilledQuantity: request.fulfilledQuantity,
                remainingQuantity: request.quantity - request.fulfilledQuantity,
                status: request.status
            }
        });
        
    } catch (err) {
        console.error('Update fulfillment error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// ====================== ADD RESPONSE TO REQUEST ======================
router.post('/hospital-requests/:requestId/respond', authenticateHospital, async (req, res) => {
    try {
        const { requestId } = req.params;
        const { offeredQuantity, message } = req.body;
        const hid = new mongoose.Types.ObjectId(req.hospitalId);
        
        const hospital = await Hospital.findById(hid);
        if (!hospital) {
            return res.status(404).json({ success: false, message: 'Hospital not found' });
        }
        
        const request = await HospitalRequest.findById(requestId);
        if (!request) {
            return res.status(404).json({ success: false, message: 'Request not found' });
        }
        
        await request.addResponse(hospital.name, offeredQuantity, message);
        
        res.json({
            success: true,
            message: 'Response added successfully',
            response: request.responses[request.responses.length - 1]
        });
        
    } catch (err) {
        console.error('Add response error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// ====================== CANCEL REQUEST ======================
router.patch('/hospital-requests/:requestId/cancel', authenticateHospital, async (req, res) => {
    try {
        const { requestId } = req.params;
        const hid = new mongoose.Types.ObjectId(req.hospitalId);
        
        const request = await HospitalRequest.findOne({
            _id: requestId,
            hospitalId: hid
        });
        
        if (!request) {
            return res.status(404).json({ success: false, message: 'Request not found' });
        }
        
        await request.cancel();
        
        res.json({
            success: true,
            message: 'Request cancelled successfully',
            request: {
                id: request._id,
                status: request.status
            }
        });
        
    } catch (err) {
        console.error('Cancel request error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// ====================== GET REQUEST STATISTICS ======================
router.get('/hospital-requests/stats/summary', authenticateHospital, async (req, res) => {
    try {
        const hid = new mongoose.Types.ObjectId(req.hospitalId);
        
        const stats = await HospitalRequest.aggregate([
            { $match: { hospitalId: hid } },
            {
                $group: {
                    _id: null,
                    total: { $sum: 1 },
                    pending: { $sum: { $cond: [{ $eq: ['$status', 'Pending'] }, 1, 0] } },
                    fulfilled: { $sum: { $cond: [{ $eq: ['$status', 'Fulfilled'] }, 1, 0] } },
                    cancelled: { $sum: { $cond: [{ $eq: ['$status', 'Cancelled'] }, 1, 0] } },
                    critical: { $sum: { $cond: [{ $eq: ['$urgency', 'Critical'] }, 1, 0] } },
                    urgent: { $sum: { $cond: [{ $eq: ['$urgency', 'Urgent'] }, 1, 0] } },
                    totalQuantity: { $sum: '$quantity' },
                    fulfilledQuantity: { $sum: '$fulfilledQuantity' }
                }
            }
        ]);
        
        res.json({
            success: true,
            stats: stats[0] || {
                total: 0,
                pending: 0,
                fulfilled: 0,
                cancelled: 0,
                critical: 0,
                urgent: 0,
                totalQuantity: 0,
                fulfilledQuantity: 0
            }
        });
        
    } catch (err) {
        console.error('Get request stats error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// ====================== EMERGENCY ALERT ======================
router.post('/emergency-alert', authenticateHospital, async (req, res) => {
    try {
        const { radius, message } = req.body;
        const hid = new mongoose.Types.ObjectId(req.hospitalId);
        const hospital = await Hospital.findById(hid);
        
        if (!hospital) {
            return res.status(404).json({ success: false, message: 'Hospital not found' });
        }
        
        console.log(`Emergency alert triggered by ${hospital.name}: ${message}`);
        
        res.json({
            success: true,
            message: 'Emergency alert sent to all nearby donors!'
        });
    } catch (err) {
        console.error('Emergency alert error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// ====================== GET PROFILE ======================
router.get('/profile', authenticateHospital, async (req, res) => {
    try {
        const hid = new mongoose.Types.ObjectId(req.hospitalId);
        const hospital = await Hospital.findById(hid).select('-password');
        
        if (!hospital) {
            return res.status(404).json({ success: false, message: 'Hospital not found' });
        }
        
        res.json({
            success: true,
            hospital
        });
    } catch (err) {
        console.error('Profile error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;