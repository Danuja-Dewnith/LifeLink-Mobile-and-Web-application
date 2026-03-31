const mongoose = require('mongoose');

const donationSchema = new mongoose.Schema({
  donorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  donorName: {
    type: String,
    required: true
  },
  requestTitle: {
    type: String
  },
  hospitalName: {
    type: String
  },
  units: {
    type: String
  },
  donationType: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['Eligible', 'Completed', 'Approved', 'Pending', 'Rejected'],
    default: 'Eligible'
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Donation', donationSchema);