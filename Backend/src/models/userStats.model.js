import mongoose, { Schema } from "mongoose";

const userStatsSchema = new Schema(
    {
        username: {
            type: String,       
            ref: "User",
            required: true,
            unique: true,
            trim: true,
            lowercase: true,
        },
        betsPlaced: {
            type: Number,
            default: 0,
        },
        betsWon: {
            type: Number,
            default: 0,
        },
    },
    {
        timestamps: true,
    }
);

export const UserStats = mongoose.model("UserStats", userStatsSchema);
