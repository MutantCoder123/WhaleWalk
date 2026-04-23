import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { Stock } from "../models/stock.model.js";
import { StockTrade } from "../models/stocktrade.model.js";
import { UserStocks } from "../models/userstocks.model.js";
import { Wallet } from "../models/wallet.model.js";

// get all stocks with current price
const getAllStocks = asyncHandler(async (req, res) => {
    const stocks = await Stock.find()

    if (!stocks ) {
        throw new ApiError(404, "No stocks found")
    }

    return res
        .status(200)
        .json(new ApiResponse(200, stocks, "Stocks fetched successfully"))
})

// get user's portfolio
const getUserStocks = asyncHandler(async (req, res) => {
    const username = req.user.username

    // get all executed trades
    const executedTrades = await StockTrade.find({
        username,
        status: "executed"
    })

    if (!executedTrades || executedTrades.length === 0) {
        throw new ApiError(404, "No executed trades found")
    }

    // calculate shares owned per stock
    const stockMap = {}

    for (const trade of executedTrades) {
        if (!stockMap[trade.stockId]) {
            stockMap[trade.stockId] = 0
        }

        if (trade.type === "buy") {
            stockMap[trade.stockId] += trade.quantity   // add shares
        } else {
            stockMap[trade.stockId] -= trade.quantity   // remove shares
        }
    }

    // format response
    const portfolio = Object.entries(stockMap).map(([stockId, quantity]) => ({
        stockId,
        quantity
    }))

    return res
        .status(200)
        .json(new ApiResponse(200, portfolio, "Portfolio fetched successfully"))
})

// place a buy or sell order (type: "market" | "limit")
const placeOrder = asyncHandler(async (req, res) => {
    const { stockId, quantity, type } = req.body
    let { limitPrice } = req.body
    const username = req.user.username

    if (!stockId || !quantity || !type) {
        throw new ApiError(400, "stockId, quantity, and type are required")
    }

    if (!['buy', 'sell'].includes(type)) {
        throw new ApiError(400, "type must be 'buy' or 'sell'")
    }

    // check stock exists
    const stock = await Stock.findOne({ stockId })
    if (!stock) {
        throw new ApiError(404, "Stock not found")
    }

    // For market orders, use the current stock price
    if (!limitPrice || req.body.orderType === 'market') {
        limitPrice = stock.price
    }

    if (type === "sell") {
        // check user has enough shares to sell
        const userStock = await UserStocks.findOne({ username, stockId })
        if (!userStock || userStock.quantity < quantity) {
            throw new ApiError(400, "Insufficient shares to sell")
        }
    }

    if (type === "buy") {
        // check user has enough coins to buy
        const wallet = await Wallet.findOne({ username })
        const totalCost = quantity * limitPrice
        if (!wallet || wallet.campusCoins < totalCost) {
            throw new ApiError(400, `Insufficient campus coins. Need ${totalCost} coins`)
        }
    }

    // place order — immediately execute market orders
    const orderStatus = (!req.body.limitPrice || req.body.orderType === 'market') ? 'executed' : 'pending'

    const order = await StockTrade.create({
        username,
        stockId,
        quantity,
        limitPrice,
        type,
        status: orderStatus
    })

    // If executed (market order): deduct coins for buy, will handle sell coin credit later
    if (orderStatus === 'executed' && type === 'buy') {
        await Wallet.findOneAndUpdate(
            { username },
            { $inc: { campusCoins: -(quantity * limitPrice) } }
        )
        // Update UserStocks
        await UserStocks.findOneAndUpdate(
            { username, stockId },
            { $inc: { quantity } },
            { upsert: true, new: true }
        )
    } else if (orderStatus === 'executed' && type === 'sell') {
        await Wallet.findOneAndUpdate(
            { username },
            { $inc: { campusCoins: quantity * limitPrice } }
        )
        await UserStocks.findOneAndUpdate(
            { username, stockId },
            { $inc: { quantity: -quantity } }
        )
    } else if (orderStatus === 'pending') {
        // Lock collateral for pending limit orders
        if (type === 'buy') {
            await Wallet.findOneAndUpdate(
                { username },
                { $inc: { campusCoins: -(quantity * limitPrice), lockedCoins: (quantity * limitPrice) } }
            )
        } else if (type === 'sell') {
            await UserStocks.findOneAndUpdate(
                { username, stockId },
                { $inc: { quantity: -quantity, lockedQuantity: quantity } }
            )
        }
    }

    return res
        .status(200)
        .json(new ApiResponse(200, order, `${type.toUpperCase()} order placed successfully`))
})

// get user's pending orders
const getMyOrders = asyncHandler(async (req, res) => {
    const orders = await StockTrade.find({
        username: req.user.username,
        status: "pending"
    }).sort({ createdAt: -1 })

    return res
        .status(200)
        .json(new ApiResponse(200, orders, "Orders fetched successfully"))
})

// get user's completed (executed) orders
const getCompletedOrders = asyncHandler(async (req, res) => {
    const orders = await StockTrade.find({
        username: req.user.username,
        status: "executed"
    }).sort({ createdAt: -1 })

    return res
        .status(200)
        .json(new ApiResponse(200, orders, "Completed orders fetched successfully"))
})

const createStock = asyncHandler(async (req, res) => {
    const { stockId, name, price, previousPrice, history } = req.body

    if (!stockId || !name || !price) {
        throw new ApiError(400, "stockId, name and price are required")
    }

    // check if stockId already exists
    const existingStock = await Stock.findOne({ stockId })
    if (existingStock) {
        throw new ApiError(409, "Stock with this stockId already exists")
    }

    const stock = await Stock.create({
        stockId,
        name,
        price,
        previousPrice: previousPrice || price,
        history: history || [price],
        sharesct: 100   // default 100
    })

    return res
        .status(201)
        .json(new ApiResponse(201, stock, "Stock created successfully"))
})

export { getAllStocks, getUserStocks, placeOrder, getMyOrders, getCompletedOrders , createStock}