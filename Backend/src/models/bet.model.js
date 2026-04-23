import mongoose, { Schema } from "mongoose";

const betSchema = new Schema(
    {
        betId: {
            type: String,
            required: true,
            unique: true,
            trim: true,
            index: true,
        },
        question: {
            type: String,
            required: true,
            trim: true,
        },
        description: {
            type: String,
            trim: true,
        },
        status: {
            type: String,
            enum: ["open", "closed"],
            default: "open",
        },
        result: {
            type: String,
            default: null,
        },
        totalEnrolled: {
            type: Number,
            default: 0,
        },
        totalPool: {
            type: Number,
            default: 0,
        },
        yesPool: {
            type: Number,
            default: 0,
        },
        noPool: {
            type: Number,
            default: 0,
        },
        resultTime: {
            type: Date,
            required: true,
        },
        isTrending: {
            type: Boolean,
            default: false,
        },
        accentColor: {
            type: String,
            default: "orange",
        },
    },
    {
        timestamps: true,
    }
);

export const Bet = mongoose.model("Bet", betSchema);