import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { Bet } from "../models/bet.model.js";
import { Enroll } from "../models/enroll.model.js";
import { Wallet } from "../models/wallet.model.js";
import { UserStats } from "../models/userStats.model.js";
import { checkAndUnlockAchievements } from "../utils/achievement.utils.js";
import { Transaction } from "../models/transaction.model.js";
import { User } from "../models/user.model.js";

const getallBet = asyncHandler(async (req, res) => {
    const bets = await Bet.find()

    if (!bets || bets.length === 0) {
        return res
            .status(200)
            .json(new ApiResponse(200, [], "No bets found"))
    }
    const filteredBets = bets.map(bet => {
        const betObj = bet.toObject()
        if (bet.status === "open") {
            delete betObj.result  // ✅ hide result if bet is open
        }
        return betObj
    })

    return res
        .status(200)
        .json(new ApiResponse(200, filteredBets, "Bets fetched successfully"))
})

const enrolluser = asyncHandler(async (req, res) => {
    const { betId, response, campusCoins } = req.body
    const username = req.user.username

    // check if any field is missing
    if (!betId || !response || !campusCoins) {
        throw new ApiError(400, "betId, response and campusCoins are required")
    }

    // check if bet exists and is open
    const bet = await Bet.findOne({ betId })
    if (!bet) {
        throw new ApiError(404, "Bet not found")
    }
    if (bet.status === "closed") {
        throw new ApiError(400, "Bet is closed")
    }

    // check if user already enrolled in this bet
    const alreadyEnrolled = await Enroll.findOne({ betId, username })
    if (alreadyEnrolled) {
        throw new ApiError(400, "You are already enrolled in this bet")
    }

    // check if user has enough campus coins
    const wallet = await Wallet.findOne({ username })
    if (!wallet || wallet.campusCoins < campusCoins) {
        throw new ApiError(400, "Insufficient campus coins")
    }

    // save enroll
    const enroll = await Enroll.create({
        betId,
        username,
        campusCoins,
        response
    })

    // deduct coins from wallet
    await Wallet.findOneAndUpdate(
        { username },
        { $inc: { campusCoins: -campusCoins } }
    )
    
    // Log transaction
    const userForId = await User.findOne({ username });
    if (userForId) {
        await Transaction.create({
            userId: userForId._id,
            title: `Staked in Bet: ${bet.question}`,
            amount: campusCoins,
            isPositive: false
        });
    }

    // update bet stats — also track pool per side
    const poolUpdate = response.toLowerCase() === 'yes'
        ? { $inc: { totalEnrolled: 1, totalPool: campusCoins, yesPool: campusCoins } }
        : { $inc: { totalEnrolled: 1, totalPool: campusCoins, noPool: campusCoins } }

    await Bet.findOneAndUpdate({ betId }, poolUpdate)

    // increment betsPlaced
    await UserStats.findOneAndUpdate(
        { username },
        { $inc: { betsPlaced: 1 } },
        { upsert: true }
    )
    
    // check achievements
    const newlyUnlocked = await checkAndUnlockAchievements(username);

    return res
        .status(200)
        .json(new ApiResponse(200, { enroll, newlyUnlocked }, "Enrolled successfully"))
})


const getEnrolledBets = asyncHandler(async (req, res) => {
    const username = req.user.username

    // get all enrollments of user
    const enrollments = await Enroll.find({ username })

    if (!enrollments || enrollments.length === 0) {
        throw new ApiError(404, "No enrolled bets found")
    }

    // get all bet details for each enrollment
    const enrolledBets = await Promise.all(
        enrollments.map(async (enroll) => {
            const bet = await Bet.findOne({ betId: enroll.betId })
            const betObj = bet.toObject()

            // hide result if bet is still open
            if (bet.status === "open") {
                delete betObj.result
            }

            return {
                ...betObj,
                myResponse: enroll.response,       // what user answered
                myCoins: enroll.campusCoins,        // how many coins user bet
                enrolledAt: enroll.createdAt        // when user enrolled
            }
        })
    )

    return res
        .status(200)
        .json(new ApiResponse(200, enrolledBets, "Enrolled bets fetched successfully"))
})


const createBet = asyncHandler(async (req, res) => {
    const { betId, question, description, result, resultTime, isTrending, accentColor } = req.body

    if (!betId || !question || !result || !resultTime) {
        throw new ApiError(400, "betId, question, result and resultTime are required")
    }

    // check if betId already exists
    const existingBet = await Bet.findOne({ betId })
    if (existingBet) {
        throw new ApiError(409, "Bet with this betId already exists")
    }

    // convert IST to UTC
    const istDate = new Date(resultTime)
    
    const bet = await Bet.create({
        betId,
        question,
        description,
        result,
        resultTime: istDate,   
        status: "open",
        totalEnrolled: 0,
        totalPool: 0,
        isTrending: isTrending || false,
        accentColor: accentColor || "orange",
    })

    return res
        .status(201)
        .json(new ApiResponse(201, bet, "Bet created successfully"))
})

const resolveBet = asyncHandler(async (req, res) => {
    const { betId, result } = req.body

    if (!betId || !result) {
        throw new ApiError(400, "betId and result are required")
    }

    if (!['YES', 'NO'].includes(result.toUpperCase())) {
        throw new ApiError(400, "result must be YES or NO")
    }

    const uppercaseResult = result.toUpperCase()

    const bet = await Bet.findOne({ betId })
    if (!bet) {
        throw new ApiError(404, "Bet not found")
    }

    if (bet.status === "closed") {
        throw new ApiError(400, "Bet is already closed")
    }

    const winningPool = uppercaseResult === 'YES' ? bet.yesPool : bet.noPool
    console.log(`[ResolveBet] BetId: ${betId}, Result: ${uppercaseResult}`);
    console.log(`[ResolveBet] WinningPool: ${winningPool}, TotalPool: ${bet.totalPool}`);
    
    // Find winning enrollments
    const winningEnrollments = await Enroll.find({ 
        betId, 
        response: { $regex: new RegExp(`^${uppercaseResult}$`, 'i') } 
    })

    console.log(`[ResolveBet] Found ${winningEnrollments.length} winning enrollments`);

    if (winningPool > 0) {
        for (const enroll of winningEnrollments) {
            try {
                const userBetAmount = enroll.campusCoins
                const payout = Math.floor((userBetAmount / winningPool) * bet.totalPool)
                console.log(`[ResolveBet] Paying out ${payout} to ${enroll.username} (staked ${userBetAmount})`);

                const walletUpdate = await Wallet.findOneAndUpdate(
                    { username: enroll.username },
                    { $inc: { campusCoins: payout } },
                    { new: true }
                )
                
                // Log transaction
                const userForIdResolve = await User.findOne({ username: enroll.username });
                if (userForIdResolve) {
                    await Transaction.create({
                        userId: userForIdResolve._id,
                        title: `Staking Payout: ${bet.question}`,
                        amount: payout,
                        isPositive: true
                    });
                }
                
                if (!walletUpdate) {
                    console.error(`[ResolveBet] FAILED to find wallet for ${enroll.username}`);
                } else {
                    console.log(`[ResolveBet] Wallet updated for ${enroll.username}, new balance: ${walletUpdate.campusCoins}`);
                }

                // increment betsWon
                await UserStats.findOneAndUpdate(
                    { username: enroll.username },
                    { $inc: { betsWon: 1 } },
                    { upsert: true }
                )
                await checkAndUnlockAchievements(enroll.username);
            } catch (err) {
                console.error(`[ResolveBet] Error processing payout for ${enroll.username}:`, err);
            }
        }
    } else if (winningEnrollments.length > 0) {
        console.warn(`[ResolveBet] Found winners but winningPool is 0! Data inconsistency check needed.`);
    } else {
        console.log(`[ResolveBet] No winners found for result: ${uppercaseResult}`);
    }

    // Update bet status
    const updatedBet = await Bet.findOneAndUpdate(
        { betId },
        { 
            status: "closed", 
            result: uppercaseResult 
        },
        { new: true }
    )

    return res
        .status(200)
        .json(new ApiResponse(200, updatedBet, "Bet resolved successfully"))
})

export {getallBet,enrolluser,getEnrolledBets,createBet,resolveBet}
