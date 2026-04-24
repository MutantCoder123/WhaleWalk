import mongoose, { Schema } from "mongoose";

const userChallengeProgressSchema = new Schema(
    {
        user: {
            type: Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
        challenge: {
            type: Schema.Types.ObjectId,
            ref: "TimedChallenge",
            required: true,
        },
        currentValue: {
            type: Number,
            default: 0,
        },
        startValue: {
            type: Number,
            default: 0,
        },
        status: {
            type: String,
            enum: ['ACTIVE', 'COMPLETED', 'CLAIMED', 'EXPIRED'],
            default: 'ACTIVE',
        },
        expiresAt: {
            type: Date,
            required: true,
        },
    },
    {
        timestamps: true,
    }
);

export const UserChallengeProgress = mongoose.model("UserChallengeProgress", userChallengeProgressSchema);
