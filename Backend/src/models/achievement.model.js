import mongoose, { Schema } from "mongoose";

const achievementSchema = new Schema(
    {
        title: {
            type: String,
            required: true,
            trim: true,
        },
        description: {
            type: String,
            required: true,
        },
        metric: {
            type: String,
            enum: ['STEPS', 'BETS_WON', 'BETS_PLACED'],
            required: true,
        },
        targetValue: {
            type: Number,
            required: true,
        },
        rewardCoins: {
            type: Number,
            default: 0,
        },
        rewardOrbs: {
            type: Number,
            default: 0,
        },
        isActive: {
            type: Boolean,
            default: true,
        }
    },
    {
        timestamps: true,
    }
);

export const Achievement = mongoose.model("Achievement", achievementSchema);
