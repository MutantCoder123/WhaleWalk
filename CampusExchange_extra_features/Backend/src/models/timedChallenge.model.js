import mongoose, { Schema } from "mongoose";

const timedChallengeSchema = new Schema(
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
            enum: ['STEPS', 'COINS_EARNED', 'BETS_WON'],
            required: true,
        },
        targetValue: {
            type: Number,
            required: true,
        },
        duration: {
            type: String,
            enum: ['DAILY', 'WEEKLY'],
            required: true,
        },
        intensity: {
            type: Number,
            min: 1,
            max: 5,
            default: 1,
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

export const TimedChallenge = mongoose.model("TimedChallenge", timedChallengeSchema);
