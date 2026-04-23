import mongoose from "mongoose";

const transactionSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true
    },
    title: {
        type: String,
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    isPositive: {
        type: Boolean,
        required: true
    }
}, { timestamps: true });

export const Transaction = mongoose.model("Transaction", transactionSchema);
