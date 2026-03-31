const mongoose = require('mongoose');

const hospitalSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  regNumber: { type: String, required: true, unique: true, trim: true },
  address: { type: String, required: true },
  contact: { type: String, required: true },
  email: { type: String, required: true, unique: true, lowercase: true },
  password: { type: String, required: true },
  storageCapacity: { type: Number, required: true },

  // Blood inventory from your React form
  bloodInventory: { type: Object, default: {} },
  selectedBloodTypes: [{ type: String }],

  // Documents (real file paths saved by Multer)
  documents: {
    govtCertificate: String,
    medicalLicense: String,
    authorizedId: String
  },

  // Avatar (matches your existing collection)
  avatarUrl: { 
    type: String, 
    default: 'http://192.168.1.2:3000/uploads/avatars/default-hospital.png' 
  },

  isVerified: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Hospital', hospitalSchema);