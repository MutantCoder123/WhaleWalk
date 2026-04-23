import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { Stock } from "../models/stock.model.js";
import { StockTrade } from "../models/stocktrade.model.js";
import { UserStocks } from "../models/userstocks.model.js";
import { Wallet } from "../models/wallet.model.js";
import { Transaction } from "../models/transaction.model.js";
import { matchOrdersForStock } from "../utils/orderMatcher.js";

// get all stocks with current price
const getAllStocks = asyncHandler(async (req, res) => {
    const stocks = await Stock.find()

    if (!stocks ) {
        throw new ApiError(404, "No stocks found")
    }

    const stocksWithPercentages = stocks.map(stock => {
        const stockObj = stock.toObject();
        let percentageChange = 0;
        if (stock.previousPrice && stock.previousPrice > 0) {
            percentageChange = ((stock.price - stock.previousPrice) / stock.previousPrice) * 100;
        }
        return {
            ...stockObj,
            percentageChange: parseFloat(percentageChange.toFixed(2))
        };
    });

    return res
        .status(200)
        .json(new ApiResponse(200, stocksWithPercentages, "Stocks fetched successfully"))
})

// get user's portfolio
const getUserStocks = asyncHandler(async (req, res) => {
    const username = req.user.username

    const userStocks = await UserStocks.find({ username, quantity: { $gt: 0 } })

    if (!userStocks || userStocks.length === 0) {
        throw new ApiError(404, "No stocks found in portfolio")
    }

    const portfolio = await Promise.all(userStocks.map(async (uStock) => {
        const stock = await Stock.findOne({ stockId: uStock.stockId });
        let percentageGain = 0;
        let avgPriceToUse = uStock.avgPrice;
        
        // Fallback for older records missing avgPrice
        if (!avgPriceToUse) {
            const lastTrade = await StockTrade.findOne({ 
                username, 
                stockId: uStock.stockId, 
                type: 'buy', 
                status: 'executed' 
            }).sort({ createdAt: -1 });
            
            if (lastTrade) {
                avgPriceToUse = lastTrade.limitPrice;
                // Opportunistically fix the record in background without waiting
                UserStocks.updateOne({ _id: uStock._id }, { $set: { avgPrice: avgPriceToUse } }).exec();
            }
        }
        
        if (stock && avgPriceToUse && avgPriceToUse > 0) {
            percentageGain = ((stock.price - avgPriceToUse) / avgPriceToUse) * 100;
        }

        return {
            stockId: uStock.stockId,
            quantity: uStock.quantity,
            avgPrice: avgPriceToUse || stock?.price || 0,
            currentPrice: stock ? stock.price : (avgPriceToUse || 0),
            percentageGain: parseFloat(percentageGain.toFixed(2))
        };
    }));

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
        const existingStock = await UserStocks.findOne({ username, stockId });
        
        if (existingStock) {
            const oldTotalCost = existingStock.quantity * existingStock.avgPrice;
            const newTotalCost = quantity * limitPrice;
            const newAvgPrice = (oldTotalCost + newTotalCost) / (existingStock.quantity + quantity);

            await UserStocks.findOneAndUpdate(
                { username, stockId },
                { 
                    $inc: { quantity },
                    $set: { avgPrice: newAvgPrice }
                },
                { returnDocument: 'after' }
            );
        } else {
            await UserStocks.create({
                username,
                stockId,
                quantity,
                avgPrice: limitPrice
            });
        }
        await Transaction.create({
            userId: req.user._id,
            title: `Market Buy ${stock.name}`,
            amount: (quantity * limitPrice),
            isPositive: false
        });
    } else if (orderStatus === 'executed' && type === 'sell') {
        await Wallet.findOneAndUpdate(
            { username },
            { $inc: { campusCoins: quantity * limitPrice } }
        )
        await UserStocks.findOneAndUpdate(
            { username, stockId },
            { $inc: { quantity: -quantity } }
        )
        await Transaction.create({
            userId: req.user._id,
            title: `Market Sell ${stock.name}`,
            amount: (quantity * limitPrice),
            isPositive: true
        });
    } else if (orderStatus === 'pending') {
        // Lock collateral for pending limit orders
        if (type === 'buy') {
            await Wallet.findOneAndUpdate(
                { username },
                { $inc: { campusCoins: -(quantity * limitPrice), lockedCoins: (quantity * limitPrice) } }
            )
            await Transaction.create({
                userId: req.user._id,
                title: `Limit Escrow Lock ${stock.name}`,
                amount: (quantity * limitPrice),
                isPositive: false
            });
        } else if (type === 'sell') {
            await UserStocks.findOneAndUpdate(
                { username, stockId },
                { $inc: { quantity: -quantity, lockedQuantity: quantity } }
            )
        }
    }

    // Try to match the newly placed order
    if (orderStatus === 'pending') {
        await matchOrdersForStock(stockId);
        
        // Fetch the updated order state after matching has occurred
        const updatedOrder = await StockTrade.findById(order._id);
        
        return res
            .status(200)
            .json(new ApiResponse(200, updatedOrder, `${type.toUpperCase()} order processed`))
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