import mongoose, { Schema } from "mongoose";

const enrollSchema = new Schema(
    {
        betId: {
            type: String,       
            ref: "Bet",
            required: true,
            trim: true,
        },
        username: {
            type: String,
            ref: "User",
            required: true,
            trim: true,
            lowercase: true,
        },
        campusCoins: {
            type: Number,
            required: true,
            min: [1, "Must bet at least 1 campus coin"],
        },
        response: {
            type: String,
            required: true,
            trim: true,
        },
    },
    {
        timestamps: true,
    }
);

export const Enroll = mongoose.model("Enroll", enrollSchema);