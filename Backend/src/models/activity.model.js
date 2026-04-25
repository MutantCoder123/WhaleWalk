import mongoose, { Schema } from "mongoose";

const activitySchema = new Schema(
    {
        username: {
            type: String,
            ref: "User",
            required: true,
            index: true,
        },
        date: {
            type: String, // YYYY-MM-DD
            required: true,
        },
        actualSteps: {
            type: Number,
            default: 0,
        },
        distanceKm: {
            type: Number,
            default: 0.0,
        },
        kcal: {
            type: Number,
            default: 0.0,
        },
        activeMin: {
            type: Number,
            default: 0,
        },
    },
    {
        timestamps: true,
    }
);

// Compound index to ensure uniqueness of user+date
activitySchema.index({ username: 1, date: 1 }, { unique: true });

export const Activity = mongoose.model("Activity", activitySchema);
