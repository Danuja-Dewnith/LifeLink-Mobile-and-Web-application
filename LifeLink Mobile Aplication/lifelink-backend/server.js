const dns = require('dns');
dns.setServers(['8.8.8.8', '8.8.4.4']);

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();

// Enhanced CORS configuration
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'Origin', 'X-Requested-With', 'Hospital-Id'],
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 
// 📁 STATIC FILES
// 
const uploadsDir = path.join(__dirname, 'uploads', 'avatars');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const medicalReportsDir = path.join(__dirname, 'uploads', 'medical-reports');
if (!fs.existsSync(medicalReportsDir)) {
  fs.mkdirSync(medicalReportsDir, { recursive: true });
}

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Serve static HTML files
app.use(express.static(path.join(__dirname, 'public')));

const BASE_URL = process.env.BASE_URL || 'http://10.168.30.196:3000';
const JWT_SECRET = process.env.JWT_SECRET || 'fallback-secret';
const JWT_RESET_SECRET = process.env.JWT_RESET_SECRET || 'reset-secret-key';

// 
// 📧 Email transporter
// 
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// 
// 🛢️ MongoDB
// 
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ MongoDB Connected'))
  .catch(err => console.error('❌ MongoDB Error:', err));

// 
// 🏥 Hospital Schema
// 
const hospitalSchema = new mongoose.Schema({
  name: String,
  regNumber: String,
  address: String,
  contact: String,
  email: String,
  password: String,
  storageCapacity: String,
  selectedBloodTypes: [String],
  avatarUrl: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now },
});
const Hospital = mongoose.model('Hospital', hospitalSchema);

// 
// 👤 User Schema
// 
const userSchema = new mongoose.Schema({
  fullName: String,
  nic: String,
  age: String,
  gender: String,
  phone: String,
  email: String,
  role: String,
  bloodGroup: String,
  donationPref: String,
  city: String,
  password: String,
  dob: { type: Date, default: null },
  street: { type: String, default: '' },
  zip: { type: String, default: '' },
  hospital: { type: String, default: '' },
  avatarUrl: { type: String, default: '' },
  medicalReports: [{
    url: String,
    fileName: String,
    uploadedAt: { type: Date, default: Date.now }
  }],
  createdAt: { type: Date, default: Date.now },
});
const User = mongoose.model('User', userSchema);

// 
// 💰 DONATION Schema
// 
const donationSchema = new mongoose.Schema({
  donorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  donorName: { type: String, required: true },
  requestTitle: { type: String, required: true },
  hospitalName: { type: String, required: true },
  units: { type: String },
  donationType: { type: String, default: 'blood' },
  bloodGroup: String,
  phone: String,
  notes: String,
  status: { type: String, default: 'Pending' },
  createdAt: { type: Date, default: Date.now }
});
const Donation = mongoose.model('Donation', donationSchema);

// 
// 📋 Request Schema
// 
const requestSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  patientName: { type: String, default: '' },
  requestType: { type: String, enum: ['Blood', 'Organ'], required: true },
  bloodGroup: { type: String, enum: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', null], default: null },
  organType: { type: String, enum: ['Kidney', 'Liver', 'Heart', 'Lung', 'Pancreas', null], default: null },
  unitsNeeded: { type: Number, required: true, min: 1, default: 1 },
  urgencyLevel: { type: String, enum: ['Normal', 'Urgent', 'Critical'], required: true },
  hospitalId: { type: mongoose.Schema.Types.ObjectId, ref: 'Hospital', required: true },
  hospitalName: { type: String, required: true },
  additionalNotes: { type: String, default: '' },
  status: { type: String, enum: ['Pending', 'Active', 'Matched', 'Completed', 'Cancelled'], default: 'Active' },
  donorFound: { type: Boolean, default: false },
  donorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  matchedAt: { type: Date, default: null },
  completedAt: { type: Date, default: null },
  cancelledAt: { type: Date, default: null },
  cancellationReason: { type: String, default: '' },
}, { timestamps: true });
const Request = mongoose.model('Request', requestSchema);

// 
// 📊 Request Activity Log Schema
// 
const requestActivitySchema = new mongoose.Schema({
  requestId: { type: mongoose.Schema.Types.ObjectId, ref: 'Request', required: true },
  action: { type: String, enum: ['Created', 'Updated', 'Matched', 'Completed', 'Cancelled', 'DonorAssigned'], required: true },
  description: String,
  performedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  performedByName: { type: String, default: 'System' },
}, { timestamps: true });
const RequestActivity = mongoose.model('RequestActivity', requestActivitySchema);

// 
// 🔔 Alert Schema
// 
const alertSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  requestId: { type: mongoose.Schema.Types.ObjectId, ref: 'Request', required: true },
  donorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  type: { type: String, enum: ['Emergency', 'Donation Match', 'Update', 'Certificate Ready', 'System', 'Hospital Request'], required: true },
  title: { type: String, required: true },
  description: { type: String, required: true },
  isRead: { type: Boolean, default: false },
  isCritical: { type: Boolean, default: false },
  actionData: { type: mongoose.Schema.Types.Mixed, default: {} },
  createdAt: { type: Date, default: Date.now },
});
const Alert = mongoose.model('Alert', alertSchema);

// 
// 🏥 Hospital Request Schema
// 
const hospitalRequestSchema = new mongoose.Schema({
  hospitalId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Hospital',
    required: true
  },
  hospitalName: {
    type: String,
    required: true
  },
  hospitalContact: {
    type: String,
    required: true
  },
  itemType: {
    type: String,
    enum: ['Blood', 'Medical Supplies', 'Equipment'],
    required: true
  },
  itemName: {
    type: String,
    required: true
  },
  quantity: {
    type: Number,
    required: true,
    min: 1
  },
  urgency: {
    type: String,
    enum: ['Critical', 'Urgent', 'Normal'],
    default: 'Normal'
  },
  reason: {
    type: String,
    required: true,
    maxlength: 300
  },
  contactPerson: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['Pending', 'Fulfilled', 'Cancelled', 'Partially Fulfilled'],
    default: 'Pending'
  },
  fulfilledQuantity: {
    type: Number,
    default: 0
  },
  responses: [{
    hospitalName: String,
    offeredQuantity: Number,
    message: String,
    respondedAt: {
      type: Date,
      default: Date.now
    }
  }],
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Virtual for remaining quantity
hospitalRequestSchema.virtual('remainingQuantity').get(function() {
  return this.quantity - this.fulfilledQuantity;
});

// Virtual for completion status
hospitalRequestSchema.virtual('isFullyFulfilled').get(function() {
  return this.fulfilledQuantity >= this.quantity;
});

// Method to add response
hospitalRequestSchema.methods.addResponse = function(hospitalName, offeredQuantity, message) {
  this.responses.push({
    hospitalName,
    offeredQuantity,
    message
  });
  return this.save();
};

// Method to update fulfillment
hospitalRequestSchema.methods.updateFulfillment = function(quantity) {
  this.fulfilledQuantity += quantity;
  
  if (this.fulfilledQuantity >= this.quantity) {
    this.status = 'Fulfilled';
  } else if (this.fulfilledQuantity > 0) {
    this.status = 'Partially Fulfilled';
  }
  
  return this.save();
};

// Method to cancel request
hospitalRequestSchema.methods.cancel = function() {
  this.status = 'Cancelled';
  return this.save();
};

const HospitalRequest = mongoose.model('HospitalRequest', hospitalRequestSchema);

// 
// 🔐 Auth Middleware
// 
const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }
  try {
    req.user = jwt.verify(authHeader.split(' ')[1], JWT_SECRET);
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};

// 
// 📸 Multer configs
// 
const avatarStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `avatar_${req.user?.id ?? 'unknown'}_${Date.now()}${ext}`);
  },
});

const avatarUpload = multer({
  storage: avatarStorage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|webp|heic|heif/;
    const extOk = allowed.test(path.extname(file.originalname).toLowerCase());
    const mimeOk = allowed.test(file.mimetype) || file.mimetype === 'application/octet-stream';
    (extOk && mimeOk) ? cb(null, true) : cb(new Error('Only images are allowed'));
  },
});

const medicalReportStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, medicalReportsDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const userId = req.body.userId || req.user?.id || 'unknown';
    cb(null, `medical_${userId}_${Date.now()}${ext}`);
  },
});

const medicalReportUpload = multer({
  storage: medicalReportStorage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|pdf|heic|heif/;
    const extOk = allowed.test(path.extname(file.originalname).toLowerCase());
    const mimeOk = allowed.test(file.mimetype) || file.mimetype === 'application/pdf' || file.mimetype === 'application/octet-stream';
    (extOk && mimeOk) ? cb(null, true) : cb(new Error('Only PDF and images are allowed'));
  },
});

// 
// Helpers
// 
function deleteOldAvatar(avatarUrl) {
  if (!avatarUrl || !avatarUrl.includes('/uploads/avatars/')) return;
  const filename = avatarUrl.split('/uploads/avatars/')[1];
  const filePath = path.join(uploadsDir, filename);
  if (fs.existsSync(filePath)) {
    try { fs.unlinkSync(filePath); } catch (_) { }
  }
}

// Format date as "Jan 1, 2026" — used for display only
function formatDateDisplay(date) {
  if (!date) return '';
  const d = new Date(date);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return `${months[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()}`;
}

// Format date as "Jan 1, 22:16" — used for alert cards display
function formatDateTimeDisplay(date) {
  if (!date) return '';
  const d = new Date(date);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const hh = d.getHours().toString().padStart(2, '0');
  const mm = d.getMinutes().toString().padStart(2, '0');
  return `${months[d.getMonth()]} ${d.getDate()}, ${hh}:${mm}`;
}

// Format time as "HH:mm"
function formatTime(date) {
  if (!date) return '';
  const d = new Date(date);
  return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}

// Format time ago
function formatTimeAgo(date) {
  if (!date) return 'Just now';
  const now = new Date();
  const diff = now - new Date(date);
  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);
  
  if (minutes < 1) return 'Just now';
  if (minutes < 60) return `${minutes} min ago`;
  if (hours < 24) return `${hours} hours ago`;
  if (days < 7) return `${days} days ago`;
  return `${Math.floor(days / 7)} weeks ago`;
}

// 
// 🌐 HTML ROUTE FOR RESET PASSWORD
// 
app.get('/reset-password', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'reset-password.html'));
});

// 
// 📸 POST /upload-avatar
// 
app.post('/upload-avatar', authMiddleware, avatarUpload.single('avatar'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    const avatarUrl = `${BASE_URL}/uploads/avatars/${req.file.filename}`;
    const account = req.user.collection === 'hospital' ? await Hospital.findById(req.user.id) : await User.findById(req.user.id);
    if (!account) return res.status(404).json({ error: 'Account not found' });
    deleteOldAvatar(account.avatarUrl);
    account.avatarUrl = avatarUrl;
    await account.save();
    res.json({ success: true, avatarUrl });
  } catch (err) {
    console.error('Upload avatar error:', err);
    res.status(500).json({ error: err.message || 'Upload failed' });
  }
});

// 
// 📸 POST /upload-medical-report
// 
app.post('/upload-medical-report', medicalReportUpload.single('medicalReport'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    const fileUrl = `${BASE_URL}/uploads/medical-reports/${req.file.filename}`;
    const userId = req.body.userId;
    if (!userId) return res.status(400).json({ error: 'User ID is required' });
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });
    await User.findByIdAndUpdate(userId, { $push: { medicalReports: { url: fileUrl, fileName: req.file.filename, uploadedAt: new Date() } } });
    res.json({ success: true, message: 'Medical report uploaded successfully', fileUrl, fileName: req.file.filename });
  } catch (err) {
    console.error('Upload medical report error:', err);
    res.status(500).json({ error: err.message || 'Upload failed' });
  }
});

// 
// 📋 GET /api/medical-reports/:userId
// 
app.get('/api/medical-reports/:userId', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.params;
    if (userId !== req.user.id && req.user.role !== 'Hospital') return res.status(403).json({ error: 'Unauthorized' });
    const user = await User.findById(userId).select('medicalReports');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ success: true, medicalReports: user.medicalReports || [] });
  } catch (err) {
    console.error('Error fetching medical reports:', err);
    res.status(500).json({ error: 'Failed to fetch medical reports' });
  }
});

// 
// 🗑️ DELETE /api/medical-reports/:reportId
// 
app.delete('/api/medical-reports/:reportId', authMiddleware, async (req, res) => {
  try {
    const { reportId } = req.params;
    const { userId } = req.body;
    if (!userId) return res.status(400).json({ error: 'User ID is required' });
    if (userId !== req.user.id && req.user.role !== 'Hospital') return res.status(403).json({ error: 'Unauthorized' });
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });
    const report = user.medicalReports.id(reportId);
    if (!report) return res.status(404).json({ error: 'Report not found' });
    const filePath = path.join(medicalReportsDir, report.fileName);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    await User.findByIdAndUpdate(userId, { $pull: { medicalReports: { _id: reportId } } });
    res.json({ success: true, message: 'Medical report deleted successfully' });
  } catch (err) {
    console.error('Error deleting medical report:', err);
    res.status(500).json({ error: err.message || 'Failed to delete report' });
  }
});

// 
// 👤 GET /profile
// 
app.get('/profile', authMiddleware, async (req, res) => {
  try {
    if (req.user.collection === 'hospital') {
      const hospital = await Hospital.findById(req.user.id).select('-password -__v');
      if (!hospital) return res.status(404).json({ error: 'Hospital not found' });
      return res.json({ ...hospital.toObject(), role: 'Hospital', fullName: hospital.name || '' });
    }
    const user = await User.findById(req.user.id).select('-password -__v');
    if (!user) return res.status(404).json({ error: 'User not found' });
    const totalDonations = await Donation.countDocuments({ donorId: req.user.id });
    const lastDonation = await Donation.findOne({ donorId: req.user.id }).sort({ createdAt: -1 }).select('createdAt');
    res.json({
      ...user.toObject(),
      totalDonations,
      lastDonationDate: lastDonation ? formatDateTimeDisplay(lastDonation.createdAt) : "Never"
    });
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// 
// ✏️ PATCH /profile
// 
app.patch('/profile', authMiddleware, avatarUpload.single('avatar'), async (req, res) => {
  try {
    const account = req.user.collection === 'hospital' ? await Hospital.findById(req.user.id) : await User.findById(req.user.id);
    if (!account) return res.status(404).json({ error: 'Account not found' });
    const allowed = ['fullName', 'name', 'age', 'gender', 'phone', 'email', 'bloodGroup', 'donationPref', 'city', 'dob', 'street', 'zip', 'hospital', 'avatarUrl', 'storageCapacity', 'selectedBloodTypes'];
    Object.keys(req.body).forEach(key => {
      if (allowed.includes(key)) account[key] = (key === 'dob' && req.body[key]) ? new Date(req.body[key]) : req.body[key];
    });
    if (req.file) {
      const avatarUrl = `${BASE_URL}/uploads/avatars/${req.file.filename}`;
      deleteOldAvatar(account.avatarUrl);
      account.avatarUrl = avatarUrl;
    }
    await account.save();
    res.json({ message: '✅ Profile updated', user: account });
  } catch (err) {
    console.error('Update profile error:', err);
    res.status(500).json({ error: err.message || 'Update failed' });
  }
});

// 
// 🔐 POST /login
// 
app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    let account = await Hospital.findOne({ email });
    let role = 'Hospital';
    let collection = 'hospital';
    if (!account) {
      account = await User.findOne({ email });
      role = account?.role ?? null;
      collection = 'user';
    }
    if (!account) return res.status(401).json({ error: 'Invalid email or password' });
    let isMatch = await bcrypt.compare(password, account.password);
    if (!isMatch && account.password === password) isMatch = true;
    if (!isMatch) return res.status(401).json({ error: 'Invalid email or password' });
    const token = jwt.sign({ id: account._id, email, role, collection, name: account.name || account.fullName || 'User' }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ success: true, token, role, name: account.fullName || account.name || 'User' });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

// 
// 🔐 POST /forgot-password
// 
app.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  try {
    const user = await User.findOne({ email }) || await Hospital.findOne({ email });
    if (!user) return res.status(404).json({ error: 'No account found with this email' });
    
    const resetToken = jwt.sign({ id: user._id }, JWT_RESET_SECRET, { expiresIn: '1h' });
    
    // This will point to the HTML page
    const resetLink = `${BASE_URL}/reset-password?token=${resetToken}`;
    
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'LifeLink — Reset your password',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #667eea;">LifeLink Password Reset</h2>
          <p>Hello,</p>
          <p>We received a request to reset your password for your LifeLink account.</p>
          <p>Click the button below to reset your password (this link will expire in 1 hour):</p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${resetLink}" 
               style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                      color: white;
                      padding: 12px 24px;
                      text-decoration: none;
                      border-radius: 8px;
                      display: inline-block;
                      font-weight: bold;">
              Reset Password
            </a>
          </div>
          <p>If the button doesn't work, copy and paste this link into your browser:</p>
          <p style="background: #f5f5f5; padding: 10px; border-radius: 5px; word-break: break-all;">
            ${resetLink}
          </p>
          <p>If you didn't request this, please ignore this email.</p>
          <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
          <p style="color: #999; font-size: 12px;">LifeLink - Smart Blood & Organ Management System</p>
        </div>
      `,
    });
    
    res.json({ message: 'Password reset link sent to your email' });
  } catch (err) {
    console.error('Forgot password error:', err);
    res.status(500).json({ error: 'Error sending reset email' });
  }
});

// 
// 🔐 POST /reset-password
// 
app.post('/reset-password', async (req, res) => {
  const { token, newPassword } = req.body;
  try {
    const decoded = jwt.verify(token, JWT_RESET_SECRET);
    const user = await User.findById(decoded.id) || await Hospital.findById(decoded.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    user.password = await bcrypt.hash(newPassword, 12);
    await user.save();
    res.json({ message: 'Password reset successful. Please login.' });
  } catch (err) {
    if (err.name === 'TokenExpiredError') return res.status(400).json({ error: 'Reset link expired' });
    console.error('Reset password error:', err);
    res.status(400).json({ error: 'Invalid or expired token' });
  }
});

// 
// 📝 POST /register-user
// 
app.post('/register-user', async (req, res) => {
  try {
    const { password, ...data } = req.body;
    const user = new User({ ...data, password: await bcrypt.hash(password, 12) });
    await user.save();
    res.status(201).json({ message: `${data.role || 'User'} registered successfully!`, userId: user._id, user: { id: user._id, fullName: user.fullName, email: user.email } });
  } catch (err) {
    console.error('Register user error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 
// 🏥 POST /register-hospital
// 
app.post('/register-hospital', async (req, res) => {
  try {
    const { password, ...data } = req.body;
    const hospital = new Hospital({ ...data, password: await bcrypt.hash(password, 12) });
    await hospital.save();
    res.status(201).json({ message: 'Hospital registered successfully!' });
  } catch (err) {
    console.error('Register hospital error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 
// 💰 POST /donations
// 
app.post('/donations', authMiddleware, async (req, res) => {
  try {
    const { requestTitle, hospitalName, units = '1 Unit', donationType = 'blood' } = req.body;
    const donation = new Donation({ donorId: req.user.id, donorName: req.user.name, requestTitle, hospitalName, units, donationType });
    await donation.save();
    res.status(201).json({ success: true, message: '🎉 Donation recorded successfully!', donation });
  } catch (err) {
    console.error('Donation error:', err);
    res.status(500).json({ error: 'Failed to record donation' });
  }
});

// 
// 💰 GET /donations/my-donations
// 
app.get('/donations/my-donations', authMiddleware, async (req, res) => {
  try {
    const donations = await Donation.find({ donorId: req.user.id }).sort({ createdAt: -1 }).lean();
    if (donations.length === 0) return res.json({ success: true, count: 0, donations: [], message: "No donations found" });
    const formatted = donations.map(d => ({ id: d._id.toString(), date: formatDateTimeDisplay(d.createdAt), requestTitle: d.requestTitle || "Blood Donation", hospitalName: d.hospitalName || "Unknown Hospital", units: d.units || "1 Unit", donationType: d.donationType || "Whole Blood", bloodGroup: d.bloodGroup || "N/A", status: d.status || "Confirmed", notes: d.notes || "", createdAt: d.createdAt }));
    res.json({ success: true, count: formatted.length, donations: formatted });
  } catch (err) {
    console.error('Error fetching my donations:', err);
    res.status(500).json({ success: false, error: 'Failed to fetch donation history' });
  }
});

// 
// 🔔 Function to create alert when a new request is created
// 
async function createRequestAlert(request) {
  try {
    let matchingDonors = [];
    if (request.requestType === 'Blood' && request.bloodGroup) {
      matchingDonors = await User.find({ role: 'Donor', bloodGroup: request.bloodGroup }).limit(10);
    } else if (request.requestType === 'Organ' && request.organType) {
      matchingDonors = await User.find({ role: 'Donor', donationPref: { $regex: request.organType, $options: 'i' } }).limit(10);
    }
    for (const donor of matchingDonors) {
      const alert = new Alert({
        userId: donor._id,
        requestId: request._id,
        type: 'Emergency',
        title: request.requestType === 'Blood' ? `🚨 ${request.bloodGroup} Blood Needed: Immediate!` : `🚨 ${request.organType} Donation Needed`,
        description: request.requestType === 'Blood' ? `${request.hospitalName} needs ${request.unitsNeeded} units of ${request.bloodGroup} blood for patient ${request.patientName}. Your profile is a match.` : `${request.hospitalName} needs a ${request.organType} donation for patient ${request.patientName}. Your profile matches this request.`,
        isCritical: request.urgencyLevel === 'Critical',
        isRead: false,
        actionData: { hospitalName: request.hospitalName, unitsNeeded: request.unitsNeeded, bloodGroup: request.bloodGroup, organType: request.organType, patientName: request.patientName },
      });
      await alert.save();
      console.log(`✅ Alert created for donor ${donor.fullName} (${donor.bloodGroup})`);
    }
    console.log(`Created ${matchingDonors.length} alerts for request ${request._id}`);
  } catch (err) {
    console.error('Error creating request alerts:', err);
  }
}

// 
// 🔍 GET /api/requests/matching-requests - MUST come before /api/requests/:requestId
// 
app.get('/api/requests/matching-requests', authMiddleware, async (req, res) => {
  try {
    const donorId = req.user.id;
    const donor = await User.findById(donorId);
    
    if (!donor) {
      return res.status(404).json({ error: 'Donor not found' });
    }
    
    console.log('🔍 Donor Info:', { id: donorId, name: donor.fullName, bloodGroup: donor.bloodGroup, role: donor.role });
    
    let query = { status: 'Active', donorFound: false, requestType: 'Blood' };
    
    if (donor.bloodGroup && donor.bloodGroup !== '') {
      query.bloodGroup = donor.bloodGroup;
    } else {
      console.log('⚠️ Donor has no blood group set');
      return res.json({ success: true, count: 0, requests: [], message: 'Please update your profile with your blood group' });
    }
    
    console.log('📋 Matching query:', JSON.stringify(query, null, 2));
    
    const matchingRequests = await Request.find(query)
      .sort({ createdAt: -1, urgencyLevel: -1 })
      .populate('userId', 'fullName phone bloodGroup city')
      .populate('hospitalId', 'name address contact');
    
    console.log(`✅ Found ${matchingRequests.length} matching requests for donor blood group ${donor.bloodGroup}`);
    
    res.json({
      success: true,
      count: matchingRequests.length,
      donorBloodGroup: donor.bloodGroup,
      requests: matchingRequests.map(req => ({
        id: req._id,
        patientName: req.patientName || req.userId?.fullName || '',
        requestType: req.requestType,
        bloodGroup: req.bloodGroup,
        organType: req.organType,
        unitsNeeded: req.unitsNeeded,
        urgencyLevel: req.urgencyLevel,
        hospitalName: req.hospitalName,
        hospitalAddress: req.hospitalId?.address,
        hospitalContact: req.hospitalId?.contact,
        additionalNotes: req.additionalNotes,
        createdAt: req.createdAt,
        createdAtFormatted: formatDateTimeDisplay(req.createdAt),
        patient: req.userId ? { name: req.userId.fullName, phone: req.userId.phone, bloodGroup: req.userId.bloodGroup, city: req.userId.city } : null,
      })),
    });
  } catch (err) {
    console.error('Error finding matching requests:', err);
    res.status(500).json({ error: 'Failed to find matching requests' });
  }
});

// 
// 🔍 GET /api/requests/my-requests
// 
app.get('/api/requests/my-requests', authMiddleware, async (req, res) => {
  try {
    const { filter = 'all' } = req.query;
    const query = { userId: req.user.id };
    if (filter === 'active') query.status = { $in: ['Active', 'Pending'] };
    else if (filter === 'completed') query.status = 'Completed';
    else if (filter === 'cancelled') query.status = 'Cancelled';
    const requests = await Request.find(query).sort({ createdAt: -1 }).populate('hospitalId', 'name address contact').populate('donorId', 'fullName bloodGroup phone');
    const formattedRequests = requests.map(r => {
      const isBlood = r.requestType === 'Blood';
      const urgencyMap = { Critical: { color: '#E53935', bg: '#FFE0E0' }, Urgent: { color: '#E65100', bg: '#FFF3E0' }, Normal: { color: '#4CAF50', bg: '#E8F5E9' } };
      const { color: badgeColor, bg: badgeBg } = urgencyMap[r.urgencyLevel] || urgencyMap.Normal;
      let statusText = 'Status: ', statusColor = '#2E7D32', statusIcon = 'check_circle_rounded', statusIconColor = '#2E7D32';
      if (r.status === 'Active') { statusText += r.donorFound ? 'Donor Found' : 'Waiting'; statusColor = r.donorFound ? '#2E7D32' : '#E65100'; statusIcon = r.donorFound ? 'check_circle_rounded' : 'hourglass_bottom_rounded'; statusIconColor = r.donorFound ? '#2E7D32' : '#E65100'; }
      else if (r.status === 'Matched') { statusText += 'Matched'; statusColor = '#2979FF'; statusIcon = 'people_rounded'; statusIconColor = '#2979FF'; }
      else if (r.status === 'Completed') statusText += 'Completed';
      else if (r.status === 'Cancelled') { statusText += 'Cancelled'; statusColor = '#E53935'; statusIcon = 'cancel_rounded'; statusIconColor = '#E53935'; }
      return { id: r._id, patientName: r.patientName || '', type: isBlood ? 'EMERGENCY ACTIVE' : 'STANDARD REQUEST', typeColor: isBlood ? '#E53935' : '#6B7280', typeBg: isBlood ? '#FFF0F0' : '#F4F6F8', typeIcon: isBlood ? 'emergency_rounded' : 'shield_outlined', date: formatDateTimeDisplay(r.createdAt), title: isBlood ? `${r.bloodGroup} Blood Needed` : `${r.organType} Request`, badge: r.urgencyLevel.toUpperCase(), badgeColor, badgeBg, hospital: `${r.hospitalName} • ${r.unitsNeeded} ${isBlood ? 'Units' : 'Organ'} Required`, status: statusText, statusColor, statusIcon, statusIconColor, rawStatus: r.status, donorFound: r.donorFound, createdAt: r.createdAt };
    });
    res.json({ success: true, requests: formattedRequests, count: formattedRequests.length });
  } catch (err) {
    console.error('Error fetching requests:', err);
    res.status(500).json({ error: 'Failed to fetch requests' });
  }
});

// 
// 📊 GET /api/requests/stats
// 
app.get('/api/requests/stats', authMiddleware, async (req, res) => {
  try {
    const uid = new mongoose.Types.ObjectId(req.user.id);
    const [total, active, completed, cancelled, urgencyStats, typeStats] = await Promise.all([
      Request.countDocuments({ userId: req.user.id }),
      Request.countDocuments({ userId: req.user.id, status: { $in: ['Active', 'Pending'] } }),
      Request.countDocuments({ userId: req.user.id, status: 'Completed' }),
      Request.countDocuments({ userId: req.user.id, status: 'Cancelled' }),
      Request.aggregate([{ $match: { userId: uid } }, { $group: { _id: '$urgencyLevel', count: { $sum: 1 } } }]),
      Request.aggregate([{ $match: { userId: uid } }, { $group: { _id: '$requestType', count: { $sum: 1 } } }]),
    ]);
    res.json({ success: true, stats: { total, active, completed, cancelled, byUrgency: urgencyStats, byType: typeStats } });
  } catch (err) {
    console.error('Error fetching stats:', err);
    res.status(500).json({ error: 'Failed to fetch statistics' });
  }
});

// 
// ✅ GET /api/requests/recent - Get latest requests for dashboard
// 
app.get('/api/requests/recent', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const limit = parseInt(req.query.limit) || 3;

    console.log(`📋 Fetching recent ${limit} requests for user ${userId}`);

    const requests = await Request.find({ userId })
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate('hospitalId', 'name address contact')
      .populate('donorId', 'fullName bloodGroup phone');

    console.log(`✅ Found ${requests.length} recent requests`);

    const formattedRequests = requests.map(request => {
      const isBlood = request.requestType === 'Blood';

      let icon = 'Icons.info_rounded';
      let iconBg = '#DDE8FA';
      let iconColor = '#2979FF';
      let statusText = '';

      if (request.status === 'Active') {
        if (request.donorFound) {
          statusText = 'Donor Found';
          icon = 'Icons.check_circle_rounded';
          iconBg = '#DDF6E8'; iconColor = '#2E7D32';
        } else {
          statusText = 'Waiting';
          icon = 'Icons.hourglass_bottom_rounded';
          iconBg = '#FFF3E0'; iconColor = '#E65100';
        }
      } else if (request.status === 'Matched') {
        statusText = 'Matched';
        icon = 'Icons.people_rounded';
        iconBg = '#E3F2FD'; iconColor = '#2979FF';
      } else if (request.status === 'Completed') {
        statusText = 'Completed';
        icon = 'Icons.check_circle_rounded';
        iconBg = '#DDF6E8'; iconColor = '#2E7D32';
      } else if (request.status === 'Cancelled') {
        statusText = 'Cancelled';
        icon = 'Icons.cancel_rounded';
        iconBg = '#FFE0E0'; iconColor = '#E53935';
      }

      const typeDetails = isBlood
        ? `${request.bloodGroup || 'Unknown'} Blood`
        : `${request.organType || 'Unknown'} Donation`;
      const title = `${typeDetails} Request`;

      const urgencyIcon = request.urgencyLevel === 'Critical' ? '🚨'
        : request.urgencyLevel === 'Urgent' ? '⚠️' : 'ℹ️';
      const subtitle = `${request.hospitalName} • ${request.unitsNeeded} ${isBlood ? 'units' : 'organ(s)'} • ${urgencyIcon} ${request.urgencyLevel}`;

      let urgencyBadge = 'NORMAL', urgencyColor = '#4CAF50', urgencyBg = '#E8F5E9';
      if (request.urgencyLevel === 'Critical') {
        urgencyBadge = 'CRITICAL'; urgencyColor = '#E53935'; urgencyBg = '#FFE0E0';
      } else if (request.urgencyLevel === 'Urgent') {
        urgencyBadge = 'URGENT'; urgencyColor = '#E65100'; urgencyBg = '#FFF3E0';
      }

      return {
        id: request._id,
        type: request.requestType,
        icon, iconBg, iconColor,
        title, message: title, subtitle,
        date: formatDateDisplay(request.createdAt),
        time: formatTime(request.createdAt),
        createdAtISO: request.createdAt.toISOString(),
        status: statusText,
        rawStatus: request.status,
        donorFound: request.donorFound || false,
        urgencyBadge, urgencyColor, urgencyBg,
        hospital: request.hospitalName,
        bloodGroup: request.bloodGroup,
        organType: request.organType,
        unitsNeeded: request.unitsNeeded,
        urgencyLevel: request.urgencyLevel,
        historyDetails: {
          date: formatDateDisplay(request.createdAt),
          type: isBlood ? (request.bloodGroup || 'Unknown') : (request.organType || 'Unknown'),
          typeLabel: isBlood ? 'Blood Group' : 'Organ Type',
          units: request.unitsNeeded,
          unitsLabel: isBlood ? 'units' : 'organ(s)',
          urgency: request.urgencyLevel,
          urgencyIcon,
          hospital: request.hospitalName,
          status: statusText,
          requestType: request.requestType
        }
      };
    });

    res.json({ success: true, count: formattedRequests.length, requests: formattedRequests });
  } catch (err) {
    console.error('Error fetching recent requests:', err);
    res.status(500).json({ error: 'Failed to fetch recent requests', details: err.message });
  }
});

// 
// 🔍 GET /api/debug/matching - Debug endpoint
// 
app.get('/api/debug/matching', authMiddleware, async (req, res) => {
  try {
    const donor = await User.findById(req.user.id);
    const activeRequests = await Request.find({ status: 'Active', donorFound: false, requestType: 'Blood' });
    res.json({
      donor: { id: donor._id, name: donor.fullName, bloodGroup: donor.bloodGroup, role: donor.role },
      activeRequests: activeRequests.map(r => ({ id: r._id, patientName: r.patientName, bloodGroup: r.bloodGroup, status: r.status, donorFound: r.donorFound })),
      matchingCount: activeRequests.filter(r => r.bloodGroup === donor.bloodGroup).length,
      matchingRequests: activeRequests.filter(r => r.bloodGroup === donor.bloodGroup)
    });
  } catch (err) {
    console.error('Debug error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 
// 📝 POST /api/requests — Create new request
// 
app.post('/api/requests', authMiddleware, async (req, res) => {
  try {
    const { requestType, bloodGroup, organType, unitsNeeded, urgencyLevel, hospitalId, additionalNotes } = req.body;
    if (!requestType || !unitsNeeded || !urgencyLevel || !hospitalId) return res.status(400).json({ error: 'Missing required fields' });
    if (requestType === 'Blood' && !bloodGroup) return res.status(400).json({ error: 'Blood group is required for blood requests' });
    if (requestType === 'Organ' && !organType) return res.status(400).json({ error: 'Organ type is required for organ requests' });
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    const hospital = await Hospital.findById(hospitalId);
    if (!hospital) return res.status(404).json({ error: 'Hospital not found' });
    const newRequest = new Request({ userId: req.user.id, patientName: user.fullName || '', requestType, bloodGroup: requestType === 'Blood' ? bloodGroup : null, organType: requestType === 'Organ' ? organType : null, unitsNeeded, urgencyLevel, hospitalId, hospitalName: hospital.name, additionalNotes: additionalNotes || '', status: 'Active', donorFound: false });
    await newRequest.save();
    await new RequestActivity({ requestId: newRequest._id, action: 'Created', description: `Request created by ${user.fullName} for ${requestType === 'Blood' ? bloodGroup : organType} — ${urgencyLevel} urgency`, performedBy: req.user.id, performedByName: user.fullName }).save();
    await createRequestAlert(newRequest);
    res.status(201).json({ success: true, message: 'Request created successfully', request: { id: newRequest._id, patientName: newRequest.patientName, requestType: newRequest.requestType, bloodGroup: newRequest.bloodGroup, organType: newRequest.organType, unitsNeeded: newRequest.unitsNeeded, urgencyLevel: newRequest.urgencyLevel, status: newRequest.status, hospitalName: newRequest.hospitalName, createdAt: newRequest.createdAt } });
  } catch (err) {
    console.error('Error creating request:', err);
    res.status(500).json({ error: err.message || 'Failed to create request' });
  }
});

// 
// 🎯 POST /api/requests/:requestId/accept-donor - Donor accepts a request
// 
app.post('/api/requests/:requestId/accept-donor', authMiddleware, async (req, res) => {
  try {
    const requestId = req.params.requestId;
    const donorId = req.user.id;
    const request = await Request.findById(requestId).populate('userId');
    if (!request) return res.status(404).json({ error: 'Request not found' });
    if (request.status !== 'Active') return res.status(400).json({ error: 'This request is no longer active' });
    if (request.donorFound) return res.status(400).json({ error: 'This request already has a donor' });
    const donor = await User.findById(donorId);
    if (!donor) return res.status(404).json({ error: 'Donor not found' });
    if (request.requestType === 'Blood' && request.bloodGroup && donor.bloodGroup !== request.bloodGroup) {
      return res.status(400).json({ error: `Blood group mismatch. Request needs ${request.bloodGroup}, but you are ${donor.bloodGroup}` });
    }
    request.donorFound = true;
    request.donorId = donorId;
    request.status = 'Matched';
    request.matchedAt = new Date();
    await request.save();
    
    // Create alert for the patient
    const patientAlert = new Alert({ 
      userId: request.userId._id, 
      requestId: request._id, 
      donorId: donorId, 
      type: 'Donation Match', 
      title: request.requestType === 'Blood' ? `🩸 Donor Found for ${request.bloodGroup} Blood Request` : `🏥 Donor Found for ${request.organType} Request`, 
      description: request.requestType === 'Blood' ? `${donor.fullName} (${donor.bloodGroup}) has accepted your request at ${request.hospitalName}. Please contact them to coordinate.` : `${donor.fullName} has accepted your ${request.organType} donation request at ${request.hospitalName}. Please review their profile.`, 
      isCritical: request.urgencyLevel === 'Critical', 
      actionData: { donorName: donor.fullName, donorBloodGroup: donor.bloodGroup, donorPhone: donor.phone, donorEmail: donor.email, hospitalName: request.hospitalName, requestType: request.requestType } 
    });
    await patientAlert.save();
    
    // Create alert for the donor
    const donorAlert = new Alert({ 
      userId: donorId, 
      requestId: request._id, 
      donorId: donorId, 
      type: 'Donation Match', 
      title: `✅ You've Accepted a ${request.requestType} Request`, 
      description: `You have successfully accepted the ${request.requestType === 'Blood' ? `${request.bloodGroup} blood` : request.organType} request from ${request.patientName} at ${request.hospitalName}. The patient will contact you shortly.`, 
      isCritical: false, 
      actionData: { patientName: request.patientName, hospitalName: request.hospitalName, requestType: request.requestType } 
    });
    await donorAlert.save();
    
    await new RequestActivity({ 
      requestId: request._id, 
      action: 'DonorAssigned', 
      description: `Donor ${donor.fullName} accepted the request`, 
      performedBy: donorId, 
      performedByName: donor.fullName 
    }).save();
    
    res.json({ 
      success: true, 
      message: 'You have successfully accepted this request', 
      request: { id: request._id, status: request.status, donorFound: true } 
    });
  } catch (err) {
    console.error('Error accepting request:', err);
    res.status(500).json({ error: err.message || 'Failed to accept request' });
  }
});

// 
// ✏️ PATCH /api/requests/:requestId/status
// 
app.patch('/api/requests/:requestId/status', authMiddleware, async (req, res) => {
  try {
    const { status, cancellationReason } = req.body;
    const request = await Request.findById(req.params.requestId);
    if (!request) return res.status(404).json({ error: 'Request not found' });
    if (request.userId.toString() !== req.user.id && req.user.role !== 'Hospital') return res.status(403).json({ error: 'Unauthorized to update this request' });
    if (['Completed', 'Cancelled'].includes(request.status)) return res.status(400).json({ error: 'Cannot update completed or cancelled requests' });
    const oldStatus = request.status;
    request.status = status;
    if (status === 'Cancelled') { request.cancelledAt = new Date(); request.cancellationReason = cancellationReason || 'No reason provided'; }
    else if (status === 'Completed') request.completedAt = new Date();
    else if (status === 'Matched') request.matchedAt = new Date();
    await request.save();
    const user = await User.findById(req.user.id);
    await new RequestActivity({ requestId: request._id, action: status === 'Cancelled' ? 'Cancelled' : 'Updated', description: `Status changed from ${oldStatus} to ${status}`, performedBy: req.user.id, performedByName: user?.fullName || 'System' }).save();
    res.json({ success: true, message: 'Request status updated successfully', request });
  } catch (err) {
    console.error('Error updating request:', err);
    res.status(500).json({ error: 'Failed to update request' });
  }
});

// 
// 🗑️ DELETE /api/requests/:requestId
// 
app.delete('/api/requests/:requestId', authMiddleware, async (req, res) => {
  try {
    const reason = req.body?.reason || 'Cancelled by user';
    const requestId = req.params.requestId;
    const request = await Request.findById(requestId);
    if (!request) return res.status(404).json({ error: 'Request not found' });
    if (request.userId.toString() !== req.user.id) return res.status(403).json({ error: 'You are not authorized to cancel this request' });
    if (request.status === 'Completed') return res.status(400).json({ error: 'Cannot cancel a completed request' });
    if (request.status === 'Cancelled') return res.status(400).json({ error: 'Request is already cancelled' });
    request.status = 'Cancelled';
    request.cancelledAt = new Date();
    request.cancellationReason = reason;
    await request.save();
    const user = await User.findById(req.user.id);
    await new RequestActivity({ requestId: request._id, action: 'Cancelled', description: `Request cancelled. Reason: ${reason}`, performedBy: req.user.id, performedByName: user?.fullName || 'User' }).save();
    res.json({ success: true, message: 'Request cancelled successfully', request: { id: request._id, status: request.status, cancelledAt: request.cancelledAt, cancellationReason: request.cancellationReason } });
  } catch (err) {
    console.error('Error cancelling request:', err);
    res.status(500).json({ error: err.message || 'Failed to cancel request' });
  }
});

// 
// 🔍 GET /api/requests/:requestId — Single request details (MUST COME AFTER specific routes)
// 
app.get('/api/requests/:requestId', authMiddleware, async (req, res) => {
  try {
    const request = await Request.findById(req.params.requestId)
      .populate('userId', 'fullName email phone bloodGroup city dob gender age')
      .populate('hospitalId', 'name address contact email regNumber')
      .populate('donorId', 'fullName email phone bloodGroup donationPref city');
    if (!request) return res.status(404).json({ error: 'Request not found' });
    if (request.userId._id.toString() !== req.user.id && req.user.role !== 'Hospital') return res.status(403).json({ error: 'Unauthorized to view this request' });
    const activities = await RequestActivity.find({ requestId: request._id }).sort({ createdAt: -1 }).limit(20);
    res.json({ success: true, request: { id: request._id, patientName: request.patientName || request.userId?.fullName || '', requestType: request.requestType, bloodGroup: request.bloodGroup, organType: request.organType, unitsNeeded: request.unitsNeeded, urgencyLevel: request.urgencyLevel, status: request.status, donorFound: request.donorFound, additionalNotes: request.additionalNotes, createdAt: request.createdAt, updatedAt: request.updatedAt, matchedAt: request.matchedAt, completedAt: request.completedAt, cancelledAt: request.cancelledAt, cancellationReason: request.cancellationReason, hospital: { id: request.hospitalId._id, name: request.hospitalId.name, address: request.hospitalId.address, contact: request.hospitalId.contact, email: request.hospitalId.email, regNumber: request.hospitalId.regNumber }, patient: { id: request.userId._id, name: request.userId.fullName, email: request.userId.email, phone: request.userId.phone, bloodGroup: request.userId.bloodGroup || 'N/A', city: request.userId.city || 'N/A', age: request.userId.age, gender: request.userId.gender }, donor: request.donorId ? { id: request.donorId._id, name: request.donorId.fullName, email: request.donorId.email, phone: request.donorId.phone, bloodGroup: request.donorId.bloodGroup, donationPref: request.donorId.donationPref } : null, activities: activities.map(a => ({ action: a.action, description: a.description, performedBy: a.performedByName, createdAt: a.createdAt })) } });
  } catch (err) {
    console.error('Error fetching request details:', err);
    res.status(500).json({ error: 'Failed to fetch request details' });
  }
});

// 
// 🔔 GET /api/alerts/recent - Get recent alerts for dashboard (last 2)
// 
app.get('/api/alerts/recent', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const limit = parseInt(req.query.limit) || 2;
    
    console.log(`🔔 Fetching recent ${limit} alerts for user ${userId}`);
    
    // Get the most recent alerts
    const alerts = await Alert.find({ userId: userId })
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate('requestId', 'requestType bloodGroup organType urgencyLevel hospitalName unitsNeeded')
      .populate('donorId', 'fullName bloodGroup phone email');
    
    console.log(`✅ Found ${alerts.length} recent alerts`);
    
    // Format alerts for dashboard display
    const formattedAlerts = alerts.map(alert => {
      let icon = 'Icons.info_rounded';
      let iconBg = '#DDE8FA';
      let iconColor = '#2979FF';
      
      // Set icon based on alert type
      if (alert.type === 'Donation Match') {
        icon = 'Icons.volunteer_activism_rounded';
        iconBg = '#DDF6E8';
        iconColor = '#2E7D32';
      } else if (alert.type === 'Emergency') {
        icon = 'Icons.warning_rounded';
        iconBg = '#FFE0E0';
        iconColor = '#E53935';
      } else if (alert.type === 'Update' || alert.type === 'System') {
        icon = 'Icons.info_rounded';
        iconBg = '#DDE8FA';
        iconColor = '#2979FF';
      }
      
      // Create notification message
      let message = alert.title;
      if (alert.type === 'Donation Match' && alert.requestId && alert.donorId) {
        message = `✅ ${alert.donorId.fullName} accepted your ${alert.requestId.bloodGroup || alert.requestId.organType} request`;
      } else if (alert.type === 'Emergency' && alert.requestId) {
        message = `🚨 Emergency ${alert.requestId.requestType} request - ${alert.requestId.urgencyLevel}`;
      }
      
      return {
        id: alert._id,
        type: alert.type,
        icon: icon,
        iconBg: iconBg,
        iconColor: iconColor,
        message: message,
        description: alert.description,
        time: alert.createdAt.toISOString(),
        createdAt: alert.createdAt.toISOString(),
        isRead: alert.isRead,
        isCritical: alert.isCritical,
        request: alert.requestId ? {
          id: alert.requestId._id,
          type: alert.requestId.requestType,
          bloodGroup: alert.requestId.bloodGroup,
          organType: alert.requestId.organType,
          urgencyLevel: alert.requestId.urgencyLevel,
          hospitalName: alert.requestId.hospitalName,
          unitsNeeded: alert.requestId.unitsNeeded
        } : null,
        donor: alert.donorId ? {
          id: alert.donorId._id,
          name: alert.donorId.fullName,
          bloodGroup: alert.donorId.bloodGroup,
          phone: alert.donorId.phone,
          email: alert.donorId.email
        } : null
      };
    });
    
    res.json({
      success: true,
      count: formattedAlerts.length,
      notifications: formattedAlerts,
      alerts: formattedAlerts,
      unreadCount: await Alert.countDocuments({ userId: userId, isRead: false })
    });
    
  } catch (err) {
    console.error('Error fetching recent alerts:', err);
    res.status(500).json({ error: 'Failed to fetch recent alerts' });
  }
});

// 
// 🔔 POST /api/alerts/mark-read
// 
app.post('/api/alerts/mark-read', authMiddleware, async (req, res) => {
  try {
    const { alertId } = req.body;
    if (alertId) {
      await Alert.findOneAndUpdate({ _id: alertId, userId: req.user.id }, { isRead: true });
      console.log(`✅ Alert ${alertId} marked as read for user ${req.user.id}`);
    } else {
      const result = await Alert.updateMany({ userId: req.user.id, isRead: false }, { isRead: true });
      console.log(`✅ Marked ${result.modifiedCount} alerts as read for user ${req.user.id}`);
    }
    res.json({ success: true, message: 'Alerts marked as read' });
  } catch (err) {
    console.error('Error marking alerts as read:', err);
    res.status(500).json({ error: 'Failed to mark alerts as read' });
  }
});

// 
// 🔔 GET /api/alerts (with filter support)
// 
app.get('/api/alerts', authMiddleware, async (req, res) => {
  try {
    const { filter = 'all', limit = 50 } = req.query;
    let query = { userId: req.user.id };
    
    // Apply filters
    if (filter === 'unread') query.isRead = false;
    else if (filter === 'emergency') query.type = 'Emergency';
    else if (filter === 'updates') query.type = { $in: ['Update', 'System'] };
    else if (filter === 'read') query.isRead = true;
    else if (filter === 'donation_match') query.type = 'Donation Match';
    
    // Get alerts
    const alerts = await Alert.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .populate('requestId', 'requestType bloodGroup organType urgencyLevel hospitalName unitsNeeded')
      .populate('donorId', 'fullName bloodGroup phone email');
    
    const unreadCount = await Alert.countDocuments({ userId: req.user.id, isRead: false });
    
    console.log(`📊 Alerts fetched for user ${req.user.id}: ${alerts.length} alerts, ${unreadCount} unread`);
    
    res.json({ 
      success: true, 
      alerts: alerts.map(alert => ({ 
        id: alert._id, 
        type: alert.type, 
        title: alert.title, 
        description: alert.description, 
        isRead: alert.isRead, 
        isCritical: alert.isCritical, 
        createdAt: alert.createdAt, 
        createdAtFormatted: formatDateTimeDisplay(alert.createdAt),
        request: alert.requestId ? { 
          id: alert.requestId._id, 
          type: alert.requestId.requestType, 
          bloodGroup: alert.requestId.bloodGroup, 
          organType: alert.requestId.organType, 
          urgencyLevel: alert.requestId.urgencyLevel, 
          hospitalName: alert.requestId.hospitalName, 
          unitsNeeded: alert.requestId.unitsNeeded 
        } : null, 
        donor: alert.donorId ? { 
          id: alert.donorId._id, 
          name: alert.donorId.fullName, 
          bloodGroup: alert.donorId.bloodGroup, 
          phone: alert.donorId.phone, 
          email: alert.donorId.email 
        } : null, 
        actionData: alert.actionData 
      })), 
      unreadCount 
    });
  } catch (err) {
    console.error('Error fetching alerts:', err);
    res.status(500).json({ error: 'Failed to fetch alerts' });
  }
});

// 
// 👥 GET /api/hospitals
// 
app.get('/api/hospitals', authMiddleware, async (req, res) => {
  try {
    const hospitals = await Hospital.find({}, 'name address contact email');
    res.json({ success: true, hospitals });
  } catch (err) {
    console.error('Error fetching hospitals:', err);
    res.status(500).json({ error: 'Failed to fetch hospitals' });
  }
});

// 
// 🏥 HOSPITAL REQUEST ROUTES
// 

// ====================== CREATE HOSPITAL REQUEST ======================
app.post('/api/hospital-requests', authMiddleware, async (req, res) => {
  try {
    const {
      itemType,
      itemName,
      quantity,
      urgency,
      reason,
      contactPerson
    } = req.body;

    // Get hospital info from token or headers
    let hospital = null;
    
    // If user is a hospital, find by email
    if (req.user.collection === 'hospital') {
      hospital = await Hospital.findById(req.user.id);
    } else {
      // For donors, we need hospital ID from request body or headers
      const hospitalId = req.headers['hospital-id'];
      if (hospitalId) {
        hospital = await Hospital.findById(hospitalId);
      }
    }
    
    if (!hospital) {
      // Create a fallback for testing
      hospital = { name: 'Test Hospital', contact: '+94 112 345 678' };
    }

    // Validate required fields
    if (!itemType || !itemName || !quantity || !reason || !contactPerson) {
      return res.status(400).json({ 
        success: false, 
        message: 'Missing required fields: itemType, itemName, quantity, reason, contactPerson' 
      });
    }

    // Create new request
    const request = new HospitalRequest({
      hospitalId: hospital._id || new mongoose.Types.ObjectId(),
      hospitalName: hospital.name,
      hospitalContact: hospital.contact || '+94 112 345 678',
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

    // Create alerts for all donors (optional - for future enhancement)
    // This would notify donors about hospital requests

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
app.get('/api/hospital-requests', authMiddleware, async (req, res) => {
  try {
    const { status, urgency, itemType, limit = 50 } = req.query;
    
    const filter = {};
    
    if (status && status !== 'All') filter.status = status;
    if (urgency && urgency !== 'All') filter.urgency = urgency;
    if (itemType && itemType !== 'All') filter.itemType = itemType;
    
    // Get all pending requests (for donors to see)
    // Donors can see all pending requests
    if (filter.status !== 'Fulfilled' && filter.status !== 'Cancelled') {
      filter.status = { $in: ['Pending', 'Partially Fulfilled'] };
    }
    
    const requests = await HospitalRequest.find(filter)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .lean();
    
    const formattedRequests = requests.map(req => ({
      ...req,
      remainingQuantity: req.quantity - (req.fulfilledQuantity || 0),
      isFullyFulfilled: (req.fulfilledQuantity || 0) >= req.quantity,
      timeAgo: formatTimeAgo(req.createdAt)
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

// ====================== GET SINGLE HOSPITAL REQUEST ======================
app.get('/api/hospital-requests/:requestId', authMiddleware, async (req, res) => {
  try {
    const { requestId } = req.params;
    
    const request = await HospitalRequest.findById(requestId);
    
    if (!request) {
      return res.status(404).json({ success: false, message: 'Request not found' });
    }
    
    res.json({
      success: true,
      request: {
        ...request.toObject(),
        remainingQuantity: request.quantity - (request.fulfilledQuantity || 0),
        isFullyFulfilled: (request.fulfilledQuantity || 0) >= request.quantity,
        timeAgo: formatTimeAgo(request.createdAt)
      }
    });
    
  } catch (err) {
    console.error('Get hospital request error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

// ====================== ADD RESPONSE TO HOSPITAL REQUEST ======================
app.post('/api/hospital-requests/:requestId/respond', authMiddleware, async (req, res) => {
  try {
    const { requestId } = req.params;
    const { offeredQuantity, message } = req.body;
    
    // Get responder hospital info
    let responderName = 'Anonymous';
    if (req.user.collection === 'hospital') {
      const hospital = await Hospital.findById(req.user.id);
      if (hospital) responderName = hospital.name;
    } else {
      const user = await User.findById(req.user.id);
      if (user) responderName = user.fullName;
    }
    
    const request = await HospitalRequest.findById(requestId);
    if (!request) {
      return res.status(404).json({ success: false, message: 'Request not found' });
    }
    
    await request.addResponse(responderName, offeredQuantity, message);
    
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

// ====================== UPDATE HOSPITAL REQUEST FULFILLMENT ======================
app.patch('/api/hospital-requests/:requestId/fulfill', authMiddleware, async (req, res) => {
  try {
    const { requestId } = req.params;
    const { quantity } = req.body;
    
    if (!quantity || quantity <= 0) {
      return res.status(400).json({ success: false, message: 'Valid quantity is required' });
    }
    
    const request = await HospitalRequest.findById(requestId);
    
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

// ====================== CANCEL HOSPITAL REQUEST ======================
app.patch('/api/hospital-requests/:requestId/cancel', authMiddleware, async (req, res) => {
  try {
    const { requestId } = req.params;
    
    const request = await HospitalRequest.findById(requestId);
    
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

// ====================== GET HOSPITAL REQUEST STATISTICS ======================
app.get('/api/hospital-requests/stats/summary', authMiddleware, async (req, res) => {
  try {
    const stats = await HospitalRequest.aggregate([
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

// 
// 🏥 GET /api/donors/nearby - Get donors in same city with matching blood group
// 
app.get('/api/donors/nearby', authMiddleware, async (req, res) => {
  try {
    const { city, bloodGroup } = req.query;
    const patientId = req.user.id;
    
    console.log('🔍 Looking for nearby donors:', { city, bloodGroup, patientId });
    
    // Find donors in the same city with matching blood group
    let query = {
      role: 'Donor',
      city: city,
      bloodGroup: bloodGroup,
      _id: { $ne: patientId } // Exclude the patient themselves
    };
    
    const donors = await User.find(query)
      .select('fullName bloodGroup city phone email donationPref avatarUrl')
      .limit(10);
    
    console.log(`✅ Found ${donors.length} nearby donors with matching blood group ${bloodGroup} in ${city}`);
    
    // Format donor data
    const formattedDonors = donors.map(donor => ({
      id: donor._id,
      name: donor.fullName,
      bloodGroup: donor.bloodGroup,
      city: donor.city,
      phone: donor.phone,
      email: donor.email,
      donationPref: donor.donationPref || 'Blood Donor',
      avatarUrl: donor.avatarUrl,
      // Calculate approximate distance 
      distance: _calculateDistance(city, donor.city),
      status: 'Available Now',
    }));
    
    res.json({
      success: true,
      count: formattedDonors.length,
      donors: formattedDonors
    });
    
  } catch (err) {
    console.error('Error fetching nearby donors:', err);
    res.status(500).json({ error: 'Failed to fetch nearby donors' });
  }
});

// Helper function to calculate distance 
function _calculateDistance(patientCity, donorCity) {
  if (patientCity === donorCity) {
    // Random distance between 0.5-5km for same city
    const distances = ['0.8km away', '1.2km away', '2.3km away', '3.1km away', '4.5km away'];
    return distances[Math.floor(Math.random() * distances.length)];
  }
  return 'Different city';
}

// 
// 🏥 GET /api/donors/potential - Get potential donors for patient requests
// 
app.get('/api/donors/potential', authMiddleware, async (req, res) => {
  try {
    const patientId = req.user.id;
    const patient = await User.findById(patientId);
    
    if (!patient) {
      return res.status(404).json({ error: 'Patient not found' });
    }
    
    console.log(`🔍 Finding potential donors for patient ${patient.fullName} (${patient.bloodGroup}) in ${patient.city}`);
    
    // Find active requests for this patient
    const activeRequests = await Request.find({
      userId: patientId,
      status: 'Active',
      donorFound: false
    });
    
    // Find potential donors based on blood group and location
    let query = {
      role: 'Donor',
      _id: { $ne: patientId }
    };
    
    // Add blood group filter if patient has blood group
    if (patient.bloodGroup && patient.bloodGroup !== '') {
      query.bloodGroup = patient.bloodGroup;
    }
    
    // Add city filter if available
    if (patient.city && patient.city !== '') {
      query.city = patient.city;
    }
    
    const potentialDonors = await User.find(query)
      .select('fullName bloodGroup city phone email donationPref avatarUrl')
      .limit(5);
    
    console.log(`✅ Found ${potentialDonors.length} potential donors`);
    
    const formattedDonors = potentialDonors.map(donor => ({
      id: donor._id,
      name: donor.fullName,
      bloodGroup: donor.bloodGroup,
      city: donor.city,
      phone: donor.phone,
      email: donor.email,
      donationPref: donor.donationPref,
      avatarUrl: donor.avatarUrl,
      distance: patient.city === donor.city ? 'Same city' : 'Nearby'
    }));
    
    res.json({
      success: true,
      count: formattedDonors.length,
      donors: formattedDonors,
      patientNeeds: activeRequests.map(req => ({
        type: req.requestType,
        bloodGroup: req.bloodGroup,
        organType: req.organType,
        unitsNeeded: req.unitsNeeded,
        urgencyLevel: req.urgencyLevel
      }))
    });
    
  } catch (err) {
    console.error('Error finding potential donors:', err);
    res.status(500).json({ error: 'Failed to find potential donors' });
  }
});

// 
// 📊 GET /api/dashboard/stats - Get all dashboard data in one call
// 
app.get('/api/dashboard/stats', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Get recent notifications (last 2)
    const recentNotifications = await Alert.find({ userId: userId })
      .sort({ createdAt: -1 })
      .limit(2);
    
    // Get request history (last 3 completed/cancelled)
    const requestHistory = await Request.find({ 
      userId: userId,
      status: { $in: ['Completed', 'Cancelled'] }
    })
    .sort({ createdAt: -1 })
    .limit(3);
    
    // Get active request
    const activeRequest = await Request.findOne({ 
      userId: userId,
      status: 'Active'
    })
    .sort({ createdAt: -1 });
    
    // Get potential donors (same city and blood group)
    let potentialDonors = [];
    if (user.city && user.bloodGroup) {
      potentialDonors = await User.find({
        role: 'Donor',
        city: user.city,
        bloodGroup: user.bloodGroup,
        _id: { $ne: userId }
      })
      .select('fullName bloodGroup city phone email')
      .limit(5);
    }
    
    // Format responses
    const formattedNotifications = recentNotifications.map(alert => ({
      id: alert._id,
      type: alert.type,
      message: alert.title,
      time: alert.createdAt.toISOString(),
      isRead: alert.isRead
    }));
    
    const formattedHistory = requestHistory.map(req => ({
      id: req._id,
      title: req.requestType === 'Blood' ? `${req.bloodGroup} Blood Request` : `${req.organType} Request`,
      date: formatDateDisplay(req.createdAt),
      status: req.status
    }));
    
    const formattedDonors = potentialDonors.map(donor => ({
      id: donor._id,
      name: donor.fullName,
      bloodGroup: donor.bloodGroup,
      city: donor.city,
      phone: donor.phone,
      distance: 'Same city',
      status: 'Available'
    }));
    
    res.json({
      success: true,
      data: {
        patient: {
          id: user._id,
          name: user.fullName,
          bloodGroup: user.bloodGroup,
          city: user.city,
          avatarUrl: user.avatarUrl
        },
        activeRequest: activeRequest ? {
          id: activeRequest._id,
          title: activeRequest.requestType === 'Blood' ? 
            `${activeRequest.bloodGroup} Blood Needed` : 
            `${activeRequest.organType} Request`,
          hospital: activeRequest.hospitalName,
          status: activeRequest.status,
          donorFound: activeRequest.donorFound,
          date: formatDateDisplay(activeRequest.createdAt)
        } : null,
        recentNotifications: formattedNotifications,
        requestHistory: formattedHistory,
        potentialDonors: formattedDonors
      }
    });
    
  } catch (err) {
    console.error('Error fetching dashboard stats:', err);
    res.status(500).json({ error: 'Failed to fetch dashboard data' });
  }
});

// 
// 📊 GET /api/admin/stats (for Admin Dashboard)
// 
app.get('/api/admin/stats', authMiddleware, async (req, res) => {
  try {
    const role = (req.user.role || '').toLowerCase();

    // Allow Admin, Hospital, or any role containing "admin"
    if (!role.includes('admin') && role !== 'hospital') {
      return res.status(403).json({ error: 'Unauthorized - Admin or Hospital access required' });
    }

    const [totalDonors, totalPatients, totalHospitals, activeRequests] = await Promise.all([
      User.countDocuments({ role: 'Donor' }),
      User.countDocuments({ role: { $nin: ['Donor', 'Hospital'] } }),
      Hospital.countDocuments({}),
      Request.countDocuments({ status: 'Active' }),
    ]);

    res.json({
      success: true,
      stats: {
        totalDonors: totalDonors.toString(),
        totalPatients: totalPatients.toString(),
        totalHospitals: totalHospitals.toString(),
        activeRequests: activeRequests.toString(),
      }
    });
  } catch (err) {
    console.error('Admin stats error:', err);
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

// 
// 👥 GET /api/users/all - Get all users for Admin panel
// 
app.get('/api/users/all', authMiddleware, async (req, res) => {
  try {
    const role = (req.user.role || '').toLowerCase();
    if (!role.includes('admin') && role !== 'hospital') {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const users = await User.find({})
      .select('fullName email role bloodGroup city phone nic age gender avatarUrl createdAt')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      count: users.length,
      users: users
    });
  } catch (err) {
    console.error('Error fetching all users:', err);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

// 
// 👥 GET /api/hospitals/all - Get all hospitals with full details
// 
app.get('/api/hospitals/all', authMiddleware, async (req, res) => {
  try {
    const role = (req.user.role || '').toLowerCase();
    if (!role.includes('admin') && role !== 'hospital') {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const hospitals = await Hospital.find({})
      .select('name regNumber address contact email storageCapacity selectedBloodTypes avatarUrl createdAt')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      count: hospitals.length,
      hospitals: hospitals
    });
  } catch (err) {
    console.error('Error fetching hospitals:', err);
    res.status(500).json({ error: 'Failed to fetch hospitals' });
  }
});

// 
// 🧪 TEST ENDPOINT - Create sample alerts for testing
// 
app.post('/api/test/create-sample-alerts', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Get or create a sample request
    let sampleRequest = await Request.findOne({ userId: userId });
    if (!sampleRequest) {
      const hospital = await Hospital.findOne();
      if (!hospital) {
        return res.status(404).json({ error: 'No hospital found. Please create a hospital first.' });
      }
      
      sampleRequest = new Request({
        userId: userId,
        patientName: user.fullName,
        requestType: 'Blood',
        bloodGroup: user.bloodGroup || 'O+',
        unitsNeeded: 2,
        urgencyLevel: 'Critical',
        hospitalId: hospital._id,
        hospitalName: hospital.name,
        status: 'Active',
        donorFound: false
      });
      await sampleRequest.save();
      console.log(`✅ Created sample request for user ${user.fullName}`);
    }
    
    // Get or create a sample donor
    let sampleDonor = await User.findOne({ role: 'Donor' });
    if (!sampleDonor) {
      sampleDonor = new User({
        fullName: 'Test Donor',
        email: 'donor@test.com',
        role: 'Donor',
        bloodGroup: user.bloodGroup || 'O+',
        phone: '+1234567890',
        password: await bcrypt.hash('password123', 12)
      });
      await sampleDonor.save();
      console.log(`✅ Created sample donor: ${sampleDonor.fullName}`);
    }
    
    // Clear existing alerts for this user
    await Alert.deleteMany({ userId: userId });
    console.log(`🗑️ Cleared existing alerts for user ${user.fullName}`);
    
    // Create sample alerts
    const sampleAlerts = [
      {
        userId: userId,
        requestId: sampleRequest._id,
        donorId: sampleDonor._id,
        type: 'Emergency',
        title: '🚨 Emergency Blood Donation Needed!',
        description: `${sampleRequest.hospitalName} urgently needs ${sampleRequest.unitsNeeded} units of ${sampleRequest.bloodGroup} blood. Your profile matches this request.`,
        isCritical: true,
        isRead: false,
        createdAt: new Date()
      },
      {
        userId: userId,
        requestId: sampleRequest._id,
        donorId: sampleDonor._id,
        type: 'Donation Match',
        title: '🩸 Donor Found for Your Request!',
        description: `${sampleDonor.fullName} (${sampleDonor.bloodGroup}) has accepted your blood request at ${sampleRequest.hospitalName}. Please contact them to coordinate.`,
        isCritical: false,
        isRead: false,
        createdAt: new Date(Date.now() - 45 * 60 * 1000)
      },
      {
        userId: userId,
        requestId: sampleRequest._id,
        type: 'Update',
        title: '🏥 New Blood Donation Center Opening',
        description: 'A new donation center is opening in your area. Check the map for location details.',
        isCritical: false,
        isRead: true,
        createdAt: new Date(Date.now() - 3 * 60 * 60 * 1000)
      },
      {
        userId: userId,
        requestId: sampleRequest._id,
        type: 'Certificate Ready',
        title: '🧑‍⚕️ Donation Milestone Reached!',
        description: 'Thank you for your recent contribution. Your digital recognition certificate is now available for download.',
        isCritical: false,
        isRead: false,
        createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000)
      }
    ];
    
    for (const alertData of sampleAlerts) {
      const alert = new Alert(alertData);
      await alert.save();
    }
    
    const alertsCount = await Alert.countDocuments({ userId: userId });
    console.log(`✅ Created ${alertsCount} sample alerts for user ${user.fullName}`);
    
    res.json({
      success: true,
      message: `Created ${alertsCount} sample alerts for user ${user.fullName}`,
      alerts: sampleAlerts.map(a => ({ type: a.type, title: a.title }))
    });
  } catch (err) {
    console.error('Error creating sample alerts:', err);
    res.status(500).json({ error: err.message });
  }
});

// 
// 🚀 START SERVER
// 
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server running on ${BASE_URL}`));