const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  fullName: { 
    type: String, 
    required: true, 
    trim: true 
  },
  nic: { 
    type: String, 
    unique: true, 
    sparse: true 
  },
  age: { 
    type: String 
  },
  gender: { 
    type: String 
  },
  phone: { 
    type: String 
  },
  email: { 
    type: String, 
    required: true, 
    unique: true, 
    lowercase: true 
  },
  role: { 
    type: String, 
    enum: ['Donor', 'Patient', 'Admin'], 
    required: true 
  },
  bloodGroup: { 
    type: String 
  },
  donationPref: { 
    type: String 
  },
  city: { 
    type: String 
  },
  password: { 
    type: String, 
    required: true 
  },
  dob: { 
    type: Date 
  },
  street: String,
  zip: String,
  hospital: String,
  avatarUrl: { 
    type: String, 
    default: 'http://192.168.1.2:3000/uploads/avatars/default-user.png' 
  },
  medicalReports: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MedicalReport'
  }],
  isVerified: { 
    type: Boolean, 
    default: true 
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  }
});

module.exports = mongoose.model('User', userSchema);