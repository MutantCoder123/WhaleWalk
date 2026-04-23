import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { Steps } from "../models/step.model.js";

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
    const { stepsCount } = req.body
    const username = req.user.username

    if (!stepsCount || stepsCount < 0) {
        throw new ApiError(400, "Valid steps count is required")
    }

    const steps = await Steps.findOneAndUpdate(
        { username },
        { $set: { stepsCount } },
        { new: true }
    )

    if (!steps) {
        throw new ApiError(404, "Steps record not found")
    }

    return res
        .status(200)
        .json(new ApiResponse(200, steps, "Steps updated successfully"))
})

/*

The frontend just needs to call this API the moment internet is available:
User turns on data
        │
        ▼
App detects internet connection  ← NetInfo library in React Native
        │
        ▼
Reads steps from pedometer (local)
        │
        ▼
POST /api/v1/steps/update  { stepsCount: 5000 }
        │
        ▼
Backend sets stepsCount = 5000 in DB

*/

export { getStepInfo,updateSteps}