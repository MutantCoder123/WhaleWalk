import mongoose, { Schema } from "mongoose";

const stockSchema = new Schema(
    {
        stockId: {
            type: String,
            required: true,
            unique: true,
            trim: true,
            index: true,
        },
        name: {
            type: String,
            required: true,
            unique: true,
            trim: true,
            index: true,
        },
        sharesct: {
            type: Number,
            required: true,
            default: 100,
        },
        price: {
            type: Number,
            required: true,
        },
        previousPrice: {
            type: Number,
            default: 0,
        },
        history: {
            type: [Number],
            default: [],
        },
    },
    {
        timestamps: true,
    }
);

export const Stock = mongoose.model("Stock", stockSchema);