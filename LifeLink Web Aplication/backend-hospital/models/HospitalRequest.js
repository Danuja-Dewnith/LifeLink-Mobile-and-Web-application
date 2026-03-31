const mongoose = require('mongoose');

const hospitalRequestSchema = new mongoose.Schema({
    // Hospital Information
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

    // Request Details
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
    
    // Urgency
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
    
    // Contact Person
    contactPerson: {
        type: String,
        required: true
    },
    
    // Status
    status: {
        type: String,
        enum: ['Pending', 'Fulfilled', 'Cancelled'],
        default: 'Pending'
    },
    fulfilledQuantity: {
        type: Number,
        default: 0
    },
    
    // Responses from other hospitals
    responses: [{
        hospitalName: String,
        offeredQuantity: Number,
        message: String,
        respondedAt: {
            type: Date,
            default: Date.now
        }
    }],
    
    // Timestamps
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
    }
    
    return this.save();
};

// Method to cancel request
hospitalRequestSchema.methods.cancel = function() {
    this.status = 'Cancelled';
    return this.save();
};

const HospitalRequest = mongoose.model('HospitalRequest', hospitalRequestSchema);
module.exports = HospitalRequest;