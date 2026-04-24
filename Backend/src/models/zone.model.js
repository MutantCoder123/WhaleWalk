import mongoose, { Schema } from "mongoose";

const zoneSchema = new Schema({
    name: {
        type: String,
        required: true,
        unique: true,
    },
    latitude: {
        type: Number,
        required: true,
    },
    longitude: {
        type: Number,
        required: true,
    },
    radiusMeters: {
        type: Number,
        required: true,
        default: 50.0
    }
}, { timestamps: true });

export const Zone = mongoose.model("Zone", zoneSchema);
