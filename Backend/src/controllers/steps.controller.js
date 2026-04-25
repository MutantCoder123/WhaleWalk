import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { Steps } from "../models/step.model.js";
import { Activity } from "../models/activity.model.js";
import { checkAndUnlockAchievements } from "../utils/achievement.utils.js";

const getStepInfo = asyncHandler(async (req, res) => {
    const Step = await Steps.findOne({ username: req.user.username })

    if (!Step) {
        throw new ApiError(404, "Steps_Info not found")
    }

    return res
        .status(200)
        .json(new ApiResponse(200, Step, "steps info fetched successfully"))
})

const updateSteps = asyncHandler(async (req, res) => {
    const { stepsCount, distanceKm, kcal, activeMin } = req.body
    const username = req.user.username

    if (typeof stepsCount !== "number" || Number.isNaN(stepsCount) || stepsCount < 0) {
        throw new ApiError(400, "Valid steps count is required")
    }

    const todayKey = new Date().toISOString().slice(0, 10)
    const currentSteps = await Steps.findOne({ username })

    if (!currentSteps) {
        throw new ApiError(404, "Steps record not found")
    }

    const previousActual = currentSteps.actualSteps ?? currentSteps.stepsCount ?? 0
    const previousAvailable = currentSteps.availableSteps ?? currentSteps.stepsCount ?? 0
    const isNewDay = currentSteps.lastSyncedOn !== todayKey

    const earnedDelta = isNewDay
        ? stepsCount
        : Math.max(stepsCount - previousActual, 0)

    const availableSteps = isNewDay
        ? stepsCount
        : previousAvailable + earnedDelta

    const steps = await Steps.findOneAndUpdate(
        { username },
        {
            $set: {
                actualSteps: stepsCount,
                availableSteps,
                stepsCount: availableSteps,
                lastSyncedOn: todayKey,
                distanceKm: distanceKm || 0,
                kcal: kcal || 0,
                activeMin: activeMin || 0,
            }
        },
        { returnDocument: 'after' }
    )

    // Upsert into Activity history
    await Activity.findOneAndUpdate(
        { username, date: todayKey },
        {
            $set: {
                actualSteps: stepsCount,
                distanceKm: distanceKm || 0,
                kcal: kcal || 0,
                activeMin: activeMin || 0,
            }
        },
        { upsert: true }
    )

    // check achievements
    await checkAndUnlockAchievements(username);

    return res
        .status(200)
        .json(new ApiResponse(200, steps, "Steps updated successfully"))
})

const getActivityHistory = asyncHandler(async (req, res) => {
    const username = req.user.username;
    
    // Get last 7 days of activity
    const history = await Activity.find({ username })
        .sort({ date: -1 })
        .limit(7);

    return res
        .status(200)
        .json(new ApiResponse(200, history.reverse(), "Activity history fetched successfully"));
});

const updateGoals = asyncHandler(async (req, res) => {
    const { stepGoal, distanceGoal } = req.body;
    const username = req.user.username;

    if (stepGoal === undefined && distanceGoal === undefined) {
        throw new ApiError(400, "At least one goal (stepGoal or distanceGoal) must be provided");
    }

    const updateFields = {};
    if (stepGoal !== undefined) updateFields.stepGoal = stepGoal;
    if (distanceGoal !== undefined) updateFields.distanceGoal = distanceGoal;

    const steps = await Steps.findOneAndUpdate(
        { username },
        { $set: updateFields },
        { new: true }
    );

    if (!steps) {
        throw new ApiError(404, "Steps record not found");
    }

    return res
        .status(200)
        .json(new ApiResponse(200, steps, "Goals updated successfully"));
});

export { getStepInfo, updateSteps, getActivityHistory, updateGoals }
