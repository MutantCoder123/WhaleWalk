import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { Wallet } from "../models/wallet.model.js";
import { Steps } from "../models/step.model.js";

const getWalletInfo = asyncHandler(async (req, res) => {
    const wallet = await Wallet.findOne({ username: req.user.username })

    if (!wallet) {
        throw new ApiError(404, "Wallet not found")
    }

    // Also embed current steps count for convenience
    const stepsDoc = await Steps.findOne({ username: req.user.username })

    return res
        .status(200)
        .json(new ApiResponse(200, {
            ...wallet.toObject(),
            stepsCount: stepsDoc?.stepsCount ?? 0
        }, "Wallet fetched successfully"))
})

const convertSteps = asyncHandler(async (req, res) => {
    const { stepsToConvert } = req.body
    const username = req.user.username

    if (!stepsToConvert || stepsToConvert <= 0) {
        throw new ApiError(400, "stepsToConvert must be a positive number")
    }

    // Validate user has enough steps
    const stepsDoc = await Steps.findOne({ username })
    if (!stepsDoc || stepsDoc.stepsCount < stepsToConvert) {
        throw new ApiError(400, `Insufficient steps. You have ${stepsDoc?.stepsCount ?? 0} steps.`)
    }

    // Conversion rate: 100 steps = 1 coin
    const coinsEarned = Math.floor(stepsToConvert / 100)
    if (coinsEarned === 0) {
        throw new ApiError(400, "Need at least 100 steps to convert")
    }

    // Deduct steps and credit coins atomically
    const updatedSteps = await Steps.findOneAndUpdate(
        { username },
        { $inc: { stepsCount: -stepsToConvert } },
        { new: true }
    )

    const updatedWallet = await Wallet.findOneAndUpdate(
        { username },
        { $inc: { campusCoins: coinsEarned } },
        { new: true }
    )

    return res
        .status(200)
        .json(new ApiResponse(200, {
            coinsEarned,
            stepsDeducted: stepsToConvert,
            newStepsCount: updatedSteps.stepsCount,
            newCampusCoins: updatedWallet.campusCoins
        }, `Converted ${stepsToConvert} steps into ${coinsEarned} Campus Coins`))
})

const convertOrbs = asyncHandler(async (req, res) => {
    const { orbsToConvert } = req.body
    const username = req.user.username

    if (!orbsToConvert || orbsToConvert <= 0) {
        throw new ApiError(400, "orbsToConvert must be a positive number")
    }

    const wallet = await Wallet.findOne({ username })
    if (!wallet || wallet.orbs < orbsToConvert) {
        throw new ApiError(400, `Insufficient orbs. You have ${wallet?.orbs ?? 0} orbs.`)
    }

    // 1 orb = 5 coins
    const coinsEarned = orbsToConvert * 5

    const updatedWallet = await Wallet.findOneAndUpdate(
        { username },
        {
            $inc: {
                campusCoins: coinsEarned,
                orbs: -orbsToConvert
            }
        },
        { new: true }
    )

    return res
        .status(200)
        .json(new ApiResponse(200, {
            coinsEarned,
            orbsDeducted: orbsToConvert,
            newOrbs: updatedWallet.orbs,
            newCampusCoins: updatedWallet.campusCoins
        }, `Converted ${orbsToConvert} orbs into ${coinsEarned} Campus Coins`))
})

const getLeaderBoard = asyncHandler(async (req, res) => {
    const leaderboard = await Wallet.find()
        .sort({ campusCoins: -1 })  // highest coins first
        .select("username campusCoins")  // only send needed fields

    if (!leaderboard) {
        throw new ApiError(404, "No wallets found")
    }

    return res
        .status(200)
        .json(new ApiResponse(200, leaderboard, "Leaderboard fetched successfully"))
})

export { getWalletInfo, convertSteps, convertOrbs, getLeaderBoard }