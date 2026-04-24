import mongoose, { Schema } from "mongoose";

const stepsSchema = new Schema(
    {
        username: {
            type: String,       
            ref: "User",
            required: true,
            unique: true,
            trim: true,
            lowercase: true,
        },
        actualSteps: {
            type: Number,
            default: 0,
            min: [0, "Actual steps cannot be negative"],
        },
        availableSteps: {
            type: Number,
            default: 0,
            min: [0, "Available steps cannot be negative"],
        },
        stepsCount: {
            type: Number,
            default: 0,
            min: [0, "Steps count cannot be negative"],
        },
        distanceKm: {
            type: Number,
            default: 0,
        },
        kcal: {
            type: Number,
            default: 0,
        },
        activeMin: {
            type: Number,
            default: 0,
        },
        lastSyncedOn: {
            type: String,
            default: "",
            trim: true,
        },
        stepGoal: {
            type: Number,
            default: 10000,
        },
        distanceGoal: {
            type: Number,
            default: 8.0,
        },
    },
    {
        timestamps: true,
    }
);

export const Steps = mongoose.model("Steps", stepsSchema);
