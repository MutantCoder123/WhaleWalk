import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { TimedChallenge } from "../models/timedChallenge.model.js";
import { UserChallengeProgress } from "../models/userChallengeProgress.model.js";
import { Steps } from "../models/step.model.js";
import { UserStats } from "../models/userStats.model.js";
import { Wallet } from "../models/wallet.model.js";

const getTimedChallenges = asyncHandler(async (req, res) => {
    const userId = req.user._id;
    const username = req.user.username;

    // 1. Get all active challenges
    const challenges = await TimedChallenge.find({ isActive: true });

    // 2. For each challenge, ensure user has a progress record
    const challengeData = await Promise.all(challenges.map(async (challenge) => {
        let progress = await UserChallengeProgress.findOne({ user: userId, challenge: challenge._id });

        if (!progress) {
            // Create new progress record
            // Determine starting value based on metric
            let startValue = 0;
            if (challenge.metric === 'STEPS') {
                const userSteps = await Steps.findOne({ username });
                startValue = userSteps ? userSteps.totalStepsWalked : 0;
            } else if (challenge.metric === 'BETS_WON') {
                const userStats = await UserStats.findOne({ username });
                startValue = userStats ? userStats.betsWon : 0;
            } else if (challenge.metric === 'COINS_EARNED') {
                const wallet = await Wallet.findOne({ username });
                startValue = wallet ? wallet.campusCoins : 0;
            }

            const durationDays = challenge.duration === 'DAILY' ? 1 : 7;
            const expiresAt = new Date();
            expiresAt.setDate(expiresAt.getDate() + durationDays);

            progress = await UserChallengeProgress.create({
                user: userId,
                challenge: challenge._id,
                startValue,
                currentValue: 0,
                status: 'ACTIVE',
                expiresAt
            });
        }

        // 3. Update current progress if ACTIVE
        if (progress.status === 'ACTIVE') {
            let currentTotal = 0;
            if (challenge.metric === 'STEPS') {
                const userSteps = await Steps.findOne({ username });
                currentTotal = userSteps ? userSteps.totalStepsWalked : 0;
            } else if (challenge.metric === 'BETS_WON') {
                const userStats = await UserStats.findOne({ username });
                currentTotal = userStats ? userStats.betsWon : 0;
            } else if (challenge.metric === 'COINS_EARNED') {
                const wallet = await Wallet.findOne({ username });
                currentTotal = wallet ? wallet.campusCoins : 0;
            }

            const diff = Math.max(0, currentTotal - progress.startValue);
            progress.currentValue = diff;

            if (progress.currentValue >= challenge.targetValue) {
                progress.status = 'COMPLETED';
            } else if (new Date() > progress.expiresAt) {
                progress.status = 'EXPIRED';
            }
            await progress.save();
        }

        return {
            ...challenge.toObject(),
            progress: progress.currentValue,
            status: progress.status,
            expiresAt: progress.expiresAt,
            id: challenge._id
        };
    }));

    return res.status(200).json(new ApiResponse(200, challengeData, "Timed challenges fetched successfully"));
});

const claimChallengeReward = asyncHandler(async (req, res) => {
    const { challengeId } = req.body;
    const userId = req.user._id;
    const username = req.user.username;

    const progress = await UserChallengeProgress.findOne({ user: userId, challenge: challengeId });

    if (!progress) {
        throw new ApiError(404, "Challenge progress not found");
    }

    if (progress.status !== 'COMPLETED') {
        throw new ApiError(400, `Challenge is not completed (Current status: ${progress.status})`);
    }

    const challenge = await TimedChallenge.findById(challengeId);
    if (!challenge) {
        throw new ApiError(404, "Challenge not found");
    }

    // Award rewards
    await Wallet.findOneAndUpdate(
        { username },
        {
            $inc: {
                campusCoins: challenge.rewardCoins,
                orbs: challenge.rewardOrbs
            }
        }
    );

    progress.status = 'CLAIMED';
    await progress.save();

    return res.status(200).json(new ApiResponse(200, { rewardCoins: challenge.rewardCoins, rewardOrbs: challenge.rewardOrbs }, "Reward claimed successfully"));
});

export { getTimedChallenges, claimChallengeReward };
