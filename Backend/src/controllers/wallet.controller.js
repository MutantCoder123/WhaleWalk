import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { Wallet } from "../models/wallet.model.js";
import { Steps } from "../models/step.model.js";
import { Transaction } from "../models/transaction.model.js";

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
            actualSteps: stepsDoc?.actualSteps ?? stepsDoc?.stepsCount ?? 0,
            availableSteps: stepsDoc?.availableSteps ?? stepsDoc?.stepsCount ?? 0,
            stepsCount: stepsDoc?.availableSteps ?? stepsDoc?.stepsCount ?? 0,
            distanceKm: stepsDoc?.distanceKm ?? 0,
            kcal: stepsDoc?.kcal ?? 0,
            activeMin: stepsDoc?.activeMin ?? 0
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
    const availableSteps = stepsDoc?.availableSteps ?? stepsDoc?.stepsCount ?? 0
    if (!stepsDoc || availableSteps < stepsToConvert) {
        throw new ApiError(400, `Insufficient steps. You have ${availableSteps} steps.`)
    }

    // Conversion rate: 100 steps = 1 coin
    const coinsEarned = Math.floor(stepsToConvert / 100)
    if (coinsEarned === 0) {
        throw new ApiError(400, "Need at least 100 steps to convert")
    }

    // Deduct steps and credit coins atomically
    const updatedSteps = await Steps.findOneAndUpdate(
        { username },
        {
            $inc: {
                availableSteps: -stepsToConvert,
                stepsCount: -stepsToConvert
            }
        },
        { returnDocument: 'after' }
    )

    const updatedWallet = await Wallet.findOneAndUpdate(
        { username },
        { $inc: { campusCoins: coinsEarned } },
        { returnDocument: 'after' }
    )

    await Transaction.create({
        userId: req.user._id,
        title: "Converted Steps",
        amount: coinsEarned,
        isPositive: true
    })

    return res
        .status(200)
        .json(new ApiResponse(200, {
            coinsEarned,
            stepsDeducted: stepsToConvert,
            newActualSteps: updatedSteps.actualSteps ?? 0,
            newAvailableSteps: updatedSteps.availableSteps ?? updatedSteps.stepsCount ?? 0,
            newStepsCount: updatedSteps.availableSteps ?? updatedSteps.stepsCount ?? 0,
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
        { returnDocument: 'after' }
    )

    await Transaction.create({
        userId: req.user._id,
        title: "Converted Orbs",
        amount: coinsEarned,
        isPositive: true
    })

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

const getTransactions = asyncHandler(async (req, res) => {
    const transactions = await Transaction.find({ userId: req.user._id })
        .sort({ createdAt: -1 })
        .limit(50); // Get latest 50 txns

    return res
        .status(200)
        .json(new ApiResponse(200, transactions, "Transactions fetched successfully"));
})

const farmOrbs = asyncHandler(async (req, res) => {
    const { stepsInZone } = req.body;
    const username = req.user.username;

    if (!stepsInZone || stepsInZone <= 0) {
        throw new ApiError(400, "stepsInZone must be a positive number.");
    }

    // 50 steps = 1 Orb
    const orbsEarned = Math.floor(stepsInZone / 50);

    if (orbsEarned === 0) {
        return res.status(200).json(new ApiResponse(200, {
            orbsEarned: 0,
            orbsDeducted: 0,
            newOrbs: 0,
        }, "Not enough steps to farm an orb."));
    }

    const updatedWallet = await Wallet.findOneAndUpdate(
        { username },
        { $inc: { orbs: orbsEarned } },
        { returnDocument: 'after' }
    );

    return res.status(200).json(new ApiResponse(200, {
        orbsEarned,
        newOrbs: updatedWallet.orbs
    }, `Farmed ${orbsEarned} orbs from ${stepsInZone} zonal steps`));
});

export { getWalletInfo, convertSteps, convertOrbs, getLeaderBoard, getTransactions, farmOrbs }
