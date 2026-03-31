const mongoose = require('mongoose');

const requestSchema = new mongoose.Schema({
  patientName: String,
  hospitalName: String,
  requestType: String,
  bloodGroup: String,
  unitsNeeded: Number,
  urgencyLevel: String,
  status: String,
  additionalNotes: String,
  createdAt: { type: Date, default: Date.now }
}, { collection: 'requests' });   // ← This line is important!

module.exports = mongoose.model('Request', requestSchema);