// === DNS FIX (for Atlas) ===
const dns = require('node:dns');
dns.setServers(['8.8.8.8', '1.1.1.1']);

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');

dotenv.config();

const app = express();

// Middleware
app.use(cors({ origin: 'http://localhost:3000' }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Create upload folders
const uploadDirs = ['uploads/documents', 'uploads/avatars'];
uploadDirs.forEach(dir => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
});

// Routes
app.use('/api/hospitals', require('./routes/hospitalRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));   // ← New admin route

// MongoDB Connection
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ MongoDB Connected Successfully'))
  .catch(err => console.error('❌ MongoDB Connection Error:', err.message));

const PORT = process.env.PORT || 8083;

app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📌 Hospital Register → http://localhost:${PORT}/api/hospitals/register`);
  console.log(`📌 Hospital Login    → http://localhost:${PORT}/api/hospitals/login`);
  console.log(`📌 Admin Login       → http://localhost:${PORT}/api/admin/login`);
});