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
        stepsCount: {
            type: Number,
            default: 10000,
            min: [0, "Steps count cannot be negative"],
        },
    },
    {
        timestamps: true,
    }
);

export const Steps = mongoose.model("Steps", stepsSchema);