import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { TimedChallenge } from "../models/timedChallenge.model.js";
import { UserChallengeProgress } from "../models/userChallengeProgress.model.js";
import { Steps } from "../models/step.model.js";
import { UserStats } from "../models/userStats.model.js";
import { Wallet } from "../models/wallet.model.js";
import { User } from "../models/user.model.js";
import { Transaction } from "../models/transaction.model.js";

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
                startValue = userSteps?.stepsCount || 0;
            } else if (challenge.metric === 'BETS_WON') {
                const userStats = await UserStats.findOne({ username });
                startValue = userStats?.betsWon || 0;
            } else if (challenge.metric === 'COINS_EARNED') {
                const wallet = await Wallet.findOne({ username });
                startValue = wallet?.campusCoins || 0;
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
                currentTotal = userSteps?.stepsCount || 0;
            } else if (challenge.metric === 'BETS_WON') {
                const userStats = await UserStats.findOne({ username });
                currentTotal = userStats?.betsWon || 0;
            } else if (challenge.metric === 'COINS_EARNED') {
                const wallet = await Wallet.findOne({ username });
                currentTotal = wallet?.campusCoins || 0;
            }

            const diff = Math.max(0, currentTotal - (progress.startValue || 0));
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
    
    // Log transaction
    await Transaction.create({
        userId,
        title: `Challenge Reward: ${challenge.title}`,
        amount: challenge.rewardCoins,
        isPositive: true
    });

    // If there's an item reward, add it to inventory
    if (challenge.rewardItemId) {
        const user = await User.findById(userId);
        if (user) {
            await user.addToInventory(challenge.rewardItemId);
        }
    }

    progress.status = 'CLAIMED';
    await progress.save();

    return res.status(200).json(new ApiResponse(200, { rewardCoins: challenge.rewardCoins, rewardOrbs: challenge.rewardOrbs }, "Reward claimed successfully"));
});

const createTimedChallenge = asyncHandler(async (req, res) => {
    const { title, description, metric, targetValue, duration, intensity, rewardCoins, rewardOrbs, rewardItemId } = req.body;

    if (!title || !description || !metric || !targetValue || !duration) {
        throw new ApiError(400, "All required fields (title, description, metric, targetValue, duration) must be provided");
    }

    const challenge = await TimedChallenge.create({
        title,
        description,
        metric,
        targetValue,
        duration,
        intensity: intensity || 1,
        rewardCoins: rewardCoins || 0,
        rewardOrbs: rewardOrbs || 0,
        rewardItemId: rewardItemId || null,
        isActive: true
    });

    return res.status(201).json(new ApiResponse(201, challenge, "Timed challenge created successfully"));
});

export { getTimedChallenges, claimChallengeReward, createTimedChallenge };
