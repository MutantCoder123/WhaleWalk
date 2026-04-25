import mongoose, { Schema } from "mongoose";

const systemSettingsSchema = new Schema(
    {
        marketStatus: {
            type: String,
            enum: ['OPEN', 'CLOSED'],
            default: 'OPEN',
            required: true
        }
    },
    {
        timestamps: true
    }
);

export const SystemSettings = mongoose.model("SystemSettings", systemSettingsSchema);
