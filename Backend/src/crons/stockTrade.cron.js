import cron from "node-cron"
import { StockTrade } from "../models/stocktrade.model.js"
import { UserStocks } from "../models/userstocks.model.js"
import { Wallet } from "../models/wallet.model.js"
import { Stock } from "../models/stock.model.js"

const stockTradeCron = () => {
    cron.schedule('0 0 * * *', async () => {
        console.log("Running stock trade execution...")

        try {
            // get all unique stocks that have pending orders
            const pendingOrders = await StockTrade.find({ status: "pending" })
            const stockIds = [...new Set(pendingOrders.map(o => o.stockId))]

            for (const stockId of stockIds) {
                // get sell orders — sorted by limitPrice low→high (cheapest seller first)
                const sellOrders = await StockTrade.find({
                    stockId,
                    type: "sell",
                    status: "pending"
                }).sort({ limitPrice: 1, createdAt: 1 })

                // get buy orders — sorted by limitPrice high→low (highest bidder first)
                const buyOrders = await StockTrade.find({
                    stockId,
                    type: "buy",
                    status: "pending"
                }).sort({ limitPrice: -1, createdAt: 1 })

                // match orders
                let buyIndex = 0
                let sellIndex = 0

                while (buyIndex < buyOrders.length && sellIndex < sellOrders.length) {
                    const buyOrder = buyOrders[buyIndex]
                    const sellOrder = sellOrders[sellIndex]

                    // match condition — buyer willing to pay >= seller's asking price
                    if (buyOrder.limitPrice >= sellOrder.limitPrice) {

                        // execute at seller's price (lower price)
                        const executionPrice = sellOrder.limitPrice
                        const matchedQty = Math.min(buyOrder.quantity, sellOrder.quantity)
                        const totalCost = matchedQty * executionPrice

                        // 1. update buyer wallet (refund price difference, deduct locked)
                        const buyerLockDeduction = matchedQty * buyOrder.limitPrice;
                        const buyerRefund = matchedQty * (buyOrder.limitPrice - executionPrice);
                        await Wallet.findOneAndUpdate(
                            { username: buyOrder.username },
                            { $inc: { campusCoins: buyerRefund, lockedCoins: -buyerLockDeduction } }
                        );

                        // 2. add coins to seller
                        await Wallet.findOneAndUpdate(
                            { username: sellOrder.username },
                            { $inc: { campusCoins: totalCost } }
                        );

                        // 3. add shares to buyer
                        const buyerStock = await UserStocks.findOne({
                            username: buyOrder.username,
                            stockId
                        })

                        if (buyerStock) {
                            await UserStocks.findOneAndUpdate(
                                { username: buyOrder.username, stockId },
                                { $inc: { quantity: matchedQty } }
                            )
                        } else {
                            await UserStocks.create({
                                username: buyOrder.username,
                                stockId,
                                quantity: matchedQty,
                                avgPrice: executionPrice
                            })
                        }

                        // 4. deduct locked shares from seller
                        await UserStocks.findOneAndUpdate(
                            { username: sellOrder.username, stockId },
                            { $inc: { lockedQuantity: -matchedQty } }
                        )

                        // 5. update stock price
                        await Stock.findOneAndUpdate(
                            { stockId },
                            { $set: { price: executionPrice } }
                        )

                        // 6. deduct matched quantity from orders locally
                        buyOrder.quantity -= matchedQty;
                        sellOrder.quantity -= matchedQty;

                        // 7. Update DB statuses for orders
                        if (buyOrder.quantity === 0) {
                            await StockTrade.findByIdAndUpdate(buyOrder._id, { status: "executed", quantity: 0 });
                            buyIndex++;
                        } else {
                            await StockTrade.findByIdAndUpdate(buyOrder._id, { quantity: buyOrder.quantity });
                        }

                        if (sellOrder.quantity === 0) {
                            await StockTrade.findByIdAndUpdate(sellOrder._id, { status: "executed", quantity: 0 });
                            sellIndex++;
                        } else {
                            await StockTrade.findByIdAndUpdate(sellOrder._id, { quantity: sellOrder.quantity });
                        }

                        console.log(`Matched: ${buyOrder.username} bought ${matchedQty} ${stockId} from ${sellOrder.username} @ ${executionPrice}`)

                    } else {
                        // no match possible — buyer's price too low
                        break
                    }
                }

                // cancel remaining unmatched orders and refund locks
                const unmatchedOrders = [
                    ...buyOrders.slice(buyIndex),
                    ...sellOrders.slice(sellIndex)
                ]

                if (unmatchedOrders.length > 0) {
                    for (const order of unmatchedOrders) {
                        if (order.type === "buy") {
                            const lockedAmount = order.quantity * order.limitPrice;
                            await Wallet.findOneAndUpdate(
                                { username: order.username },
                                { $inc: { campusCoins: lockedAmount, lockedCoins: -lockedAmount } }
                            );
                        } else {
                            await UserStocks.findOneAndUpdate(
                                { username: order.username, stockId: order.stockId },
                                { $inc: { quantity: order.quantity, lockedQuantity: -order.quantity } }
                            );
                        }
                    }

                    const unmatchedIds = unmatchedOrders.map(o => o._id);
                    await StockTrade.updateMany(
                        { _id: { $in: unmatchedIds } },
                        { status: "cancelled" }
                    )
                }
            }

            console.log("Stock trade execution done!")

        } catch (error) {
            console.log("Stock trade cron error:", error)
        }
    }, {
        timezone: "Asia/Kolkata"
    })
}

export { stockTradeCron }