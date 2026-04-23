import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { Bet } from "../models/bet.model.js";
import { Enroll } from "../models/enroll.model.js";
import { Wallet } from "../models/wallet.model.js";


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

    // getuser info and bet inifo , response , no of coins from req
    // if any feild is missing return error
    // check bet is open or closed  and already enrolled or not 
    // save it into enroll collection and deduct coin from wallet (if dont have enough coin send error )
    // update total enroll and total pool
    // return a success message

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

    // update bet stats — also track pool per side
    const poolUpdate = response.toLowerCase() === 'yes'
        ? { $inc: { totalEnrolled: 1, totalPool: campusCoins, yesPool: campusCoins } }
        : { $inc: { totalEnrolled: 1, totalPool: campusCoins, noPool: campusCoins } }

    await Bet.findOneAndUpdate({ betId }, poolUpdate)

    return res
        .status(200)
        .json(new ApiResponse(200, enroll, "Enrolled successfully"))
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
    // IST = UTC + 5:30, so UTC = IST - 5:30
    const istDate = new Date(resultTime)  // JS automatically handles timezone if passed correctly
    
    const bet = await Bet.create({
        betId,
        question,
        description,
        result,
        resultTime: istDate,   // stored as UTC in MongoDB automatically
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

    // Determine winning pool
    const winningPool = uppercaseResult === 'YES' ? bet.yesPool : bet.noPool
    
    // Find winning enrollments
    const winningEnrollments = await Enroll.find({ 
        betId, 
        response: { $regex: new RegExp(`^${uppercaseResult}$`, 'i') } 
    })

    if (winningPool > 0) {
        // distribute the total pool based on proportion of contribution to winning pool
        for (const enroll of winningEnrollments) {
            const userBetAmount = enroll.campusCoins
            // proportional payout rounded to 2 decimals if needed, but since it's just coins we can round or keep precise
            const payout = Math.floor((userBetAmount / winningPool) * bet.totalPool)

            await Wallet.findOneAndUpdate(
                { username: enroll.username },
                { $inc: { campusCoins: payout } }
            )
        }
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
