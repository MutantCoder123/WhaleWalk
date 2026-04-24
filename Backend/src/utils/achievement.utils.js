import { Achievement } from "../models/achievement.model.js";
import { User } from "../models/user.model.js";
import { UserStats } from "../models/userStats.model.js";
import { Steps } from "../models/step.model.js";
import { Wallet } from "../models/wallet.model.js";

export const checkAndUnlockAchievements = async (username) => {
    try {
        const user = await User.findOne({ username });
        if (!user) return [];

        let userStats = await UserStats.findOne({ username });
        // If older user doesn't have stats, create them
        if (!userStats) {
            userStats = await UserStats.create({ username });
        }

        const stepsData = await Steps.findOne({ username });
        if (!stepsData) return [];

        const allAchievements = await Achievement.find({ isActive: true });
        const newlyUnlocked = [];

        for (const achievement of allAchievements) {
            if (user.unlockedAchievements.includes(achievement._id)) {
                continue;
            }

            let unlocked = false;

            if (achievement.metric === 'STEPS' && stepsData.stepsCount >= achievement.targetValue) {
                unlocked = true;
            } else if (achievement.metric === 'BETS_WON' && userStats.betsWon >= achievement.targetValue) {
                unlocked = true;
            } else if (achievement.metric === 'BETS_PLACED' && userStats.betsPlaced >= achievement.targetValue) {
                unlocked = true;
            }

            if (unlocked) {
                await user.unlockAchievement(achievement._id);
                newlyUnlocked.push(achievement);

                if (achievement.rewardCoins > 0 || achievement.rewardOrbs > 0) {
                    await Wallet.findOneAndUpdate(
                        { username },
                        { $inc: { campusCoins: achievement.rewardCoins, orbs: achievement.rewardOrbs } }
                    );
                }
            }
        }

        // After checking individual achievements, check for total count thresholds for special badges
        const totalUnlocked = user.unlockedAchievements.length;
        const { StoreItem } = await import("../models/store.model.js");

        const checkBadgeReward = async (threshold, badgeName) => {
            if (totalUnlocked >= threshold) {
                const badgeItem = await StoreItem.findOne({ name: badgeName });
                if (badgeItem && !user.inventory.includes(badgeItem._id)) {
                    await user.addToInventory(badgeItem._id);
                }
            }
        };

        await checkBadgeReward(5, "Achievement Master Level 1");
        await checkBadgeReward(15, "Achievement Master Level 2");
        await checkBadgeReward(30, "Achievement Master Level 3");

        return newlyUnlocked;
    } catch (error) {
        console.error("Error checking achievements:", error);
        return [];
    }
};
