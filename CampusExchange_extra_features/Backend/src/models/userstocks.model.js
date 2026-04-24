import mongoose, { Schema } from "mongoose";

const userStocksSchema = new Schema(
    {
        username: {
            type: String,
            ref: "User",
            required: true,
            trim: true,
            lowercase: true,
        },
        stockId: {
            type: String,
            ref: "Stock",
            required: true,
            trim: true,
        },
        quantity: {
            type: Number,
            required: true,
            min: [0, "Quantity cannot be negative"],
        },
        lockedQuantity: {
            type: Number,
            default: 0,
            min: [0, "Locked quantity cannot be negative"],
        },
        avgPrice: {
            type: Number,
            required: true,
        },
    },
    {
        timestamps: true,
    }
);

export const UserStocks = mongoose.model("UserStocks", userStocksSchema);