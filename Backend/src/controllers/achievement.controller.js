import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { Achievement } from "../models/achievement.model.js";
import { User } from "../models/user.model.js";

const getAchievements = asyncHandler(async (req, res) => {
    const username = req.user.username;

    const allAchievements = await Achievement.find({ isActive: true });
    console.log(`[getAchievements] Found ${allAchievements.length} active achievements`);
    
    // Lazy evaluation fallback: Check for unlocked achievements just in case
    // an event was missed or they have legacy stats.
    const { checkAndUnlockAchievements } = await import("../utils/achievement.utils.js");
    await checkAndUnlockAchievements(username);

    const user = await User.findOne({ username });

    if (!user) {
        console.log(`[getAchievements] User ${username} not found`);
        return res.status(404).json(new ApiResponse(404, null, "User not found"));
    }

    const unlockedIds = user.unlockedAchievements.map(id => id.toString());
    console.log(`[getAchievements] User ${username} has ${unlockedIds.length} unlocked achievements`);

    const result = allAchievements.map(ach => {
        return {
            ...ach.toObject(),
            isUnlocked: unlockedIds.includes(ach._id.toString())
        };
    });

    console.log(`[getAchievements] Returning ${result.length} achievements`);
    return res.status(200).json(new ApiResponse(200, { achievements: result, newlyUnlocked: user.newlyUnlockedAchievements }, "Achievements fetched"));
});

const acknowledgeAchievements = asyncHandler(async (req, res) => {
    const username = req.user.username;

    await User.findOneAndUpdate(
        { username },
        { $set: { newlyUnlockedAchievements: [] } }
    );

    return res.status(200).json(new ApiResponse(200, [], "Achievements acknowledged"));
});

export { getAchievements, acknowledgeAchievements };
