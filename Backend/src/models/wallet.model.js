import mongoose, { Schema } from "mongoose";

const walletSchema = new Schema(
    {
        username: {
            type: String,       
            ref: "User",
            required: true,
            unique: true,
            trim: true,
            lowercase: true,
        },
        campusCoins: {
            type: Number,
            default: 1000,          
            min: [0, "Balance cannot be negative"],
        },
        lockedCoins: {
            type: Number,
            default: 0,
            min: [0, "Locked balance cannot be negative"],
        },
        orbs: {
            type: Number,
            default: 14,
            min: [0, "Orbs cannot be negative"],
        },
    },
    {
        timestamps: true,
    }
);

export const Wallet = mongoose.model("Wallet", walletSchema);