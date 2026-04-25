import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { Wallet } from "../models/wallet.model.js";
import { Steps } from "../models/step.model.js";
import { UserStats } from "../models/userStats.model.js";
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

    // Look up each user's activeTitle to include in the response
    const { User } = await import("../models/user.model.js");
    const usernames = leaderboard.map(w => w.username);
    const users = await User.find({ username: { $in: usernames } })
        .select("username activeTitle")
        .populate({ path: "activeTitle", select: "name rarity" });

    const userTitleMap = {};
    for (const u of users) {
        if (u.activeTitle) {
            userTitleMap[u.username] = {
                titleName: u.activeTitle.name,
                titleRarity: u.activeTitle.rarity || 'common',
            };
        }
    }

    const enriched = leaderboard.map(w => ({
        username: w.username,
        campusCoins: w.campusCoins,
        activeTitle: userTitleMap[w.username]?.titleName || null,
        titleRarity: userTitleMap[w.username]?.titleRarity || null,
    }));

    return res
        .status(200)
        .json(new ApiResponse(200, enriched, "Leaderboard fetched successfully"))
})

const getStepsLeaderboard = asyncHandler(async (req, res) => {
    const steps = await Steps.find()
        .sort({ totalStepsWalked: -1 })
        .select("username totalStepsWalked stepsCount")

    if (!steps || steps.length === 0) {
        return res.status(200).json(new ApiResponse(200, [], "No steps data"))
    }

    const { User } = await import("../models/user.model.js");
    const usernames = steps.map(s => s.username);
    const users = await User.find({ username: { $in: usernames } })
        .select("username activeTitle")
        .populate({ path: "activeTitle", select: "name rarity" });

    const userTitleMap = {};
    for (const u of users) {
        if (u.activeTitle) {
            userTitleMap[u.username] = {
                titleName: u.activeTitle.name,
                titleRarity: u.activeTitle.rarity || 'common',
            };
        }
    }

    const enriched = steps.map(s => ({
        username: s.username,
        totalStepsWalked: s.totalStepsWalked || s.stepsCount || 0,
        activeTitle: userTitleMap[s.username]?.titleName || null,
        titleRarity: userTitleMap[s.username]?.titleRarity || null,
    }));

    return res.status(200).json(new ApiResponse(200, enriched, "Steps leaderboard fetched"))
})

const getBetsWonLeaderboard = asyncHandler(async (req, res) => {
    const stats = await UserStats.find()
        .sort({ betsWon: -1 })
        .select("username betsWon betsPlaced")

    if (!stats || stats.length === 0) {
        return res.status(200).json(new ApiResponse(200, [], "No bet stats"))
    }

    const { User } = await import("../models/user.model.js");
    const usernames = stats.map(s => s.username);
    const users = await User.find({ username: { $in: usernames } })
        .select("username activeTitle")
        .populate({ path: "activeTitle", select: "name rarity" });

    const userTitleMap = {};
    for (const u of users) {
        if (u.activeTitle) {
            userTitleMap[u.username] = {
                titleName: u.activeTitle.name,
                titleRarity: u.activeTitle.rarity || 'common',
            };
        }
    }

    const enriched = stats.map(s => ({
        username: s.username,
        betsWon: s.betsWon,
        betsPlaced: s.betsPlaced,
        activeTitle: userTitleMap[s.username]?.titleName || null,
        titleRarity: userTitleMap[s.username]?.titleRarity || null,
    }));

    return res.status(200).json(new ApiResponse(200, enriched, "Bets won leaderboard fetched"))
})

const getPortfolioLeaderboard = asyncHandler(async (req, res) => {
    const { UserStocks } = await import("../models/userstocks.model.js");
    const { Stock } = await import("../models/stock.model.js");

    // Fetch all user stock holdings with quantity > 0
    const holdings = await UserStocks.find({ quantity: { $gt: 0 } });
    if (!holdings || holdings.length === 0) {
        return res.status(200).json(new ApiResponse(200, [], "No portfolios found"))
    }

    // Get current stock prices
    const stocks = await Stock.find().select("stockId price");
    const priceMap = {};
    for (const s of stocks) {
        priceMap[s.stockId] = s.price;
    }

    // Aggregate portfolio value per user
    const portfolioMap = {};
    for (const h of holdings) {
        const price = priceMap[h.stockId] || 0;
        const value = h.quantity * price;
        if (!portfolioMap[h.username]) {
            portfolioMap[h.username] = 0;
        }
        portfolioMap[h.username] += value;
    }

    // Sort by portfolio value descending
    const sorted = Object.entries(portfolioMap)
        .map(([username, portfolioValue]) => ({ username, portfolioValue: Math.floor(portfolioValue) }))
        .sort((a, b) => b.portfolioValue - a.portfolioValue);

    // Enrich with active titles
    const { User } = await import("../models/user.model.js");
    const usernames = sorted.map(s => s.username);
    const users = await User.find({ username: { $in: usernames } })
        .select("username activeTitle")
        .populate({ path: "activeTitle", select: "name rarity" });

    const userTitleMap = {};
    for (const u of users) {
        if (u.activeTitle) {
            userTitleMap[u.username] = {
                titleName: u.activeTitle.name,
                titleRarity: u.activeTitle.rarity || 'common',
            };
        }
    }

    const enriched = sorted.map(s => ({
        username: s.username,
        portfolioValue: s.portfolioValue,
        activeTitle: userTitleMap[s.username]?.titleName || null,
        titleRarity: userTitleMap[s.username]?.titleRarity || null,
    }));

    return res.status(200).json(new ApiResponse(200, enriched, "Portfolio leaderboard fetched"))
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

export { getWalletInfo, convertSteps, convertOrbs, getLeaderBoard, getStepsLeaderboard, getBetsWonLeaderboard, getPortfolioLeaderboard, getTransactions, farmOrbs }
