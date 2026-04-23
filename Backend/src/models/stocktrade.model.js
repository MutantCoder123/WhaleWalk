import mongoose, { Schema } from "mongoose";

const stocktrade = new Schema(
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
            min: [1, "Quantity must be at least 1"],
        },
        limitPrice: {
            type: Number,
            required: true,  // user's desired price
        },
        type: {
            type: String,
            enum: ["buy", "sell"],
            required: true,
        },
        status: {
            type: String,
            enum: ["pending", "executed", "cancelled"],
            default: "pending",
        },
    },
    {
        timestamps: true,
    }
);

export const StockTrade = mongoose.model("StockTrade", stocktrade);