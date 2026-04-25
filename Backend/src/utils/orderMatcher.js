import { StockTrade } from "../models/stocktrade.model.js"
import { UserStocks } from "../models/userstocks.model.js"
import { Wallet } from "../models/wallet.model.js"
import { Stock } from "../models/stock.model.js"
import { User } from "../models/user.model.js"
import { Transaction } from "../models/transaction.model.js"

const matchOrdersForStock = async (stockId) => {
    console.log(`Running stock trade execution for stock ${stockId}...`)

    try {
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

                if (buyerRefund > 0) {
                    const buyerUser = await User.findOne({ username: buyOrder.username });
                    if (buyerUser) {
                        await Transaction.create({
                            userId: buyerUser._id,
                            title: `Escrow Refund ${stockId}`,
                            amount: buyerRefund,
                            isPositive: true
                        });
                    }
                }

                // 2. add coins to seller
                await Wallet.findOneAndUpdate(
                    { username: sellOrder.username },
                    { $inc: { campusCoins: totalCost } }
                );

                const sellerUser = await User.findOne({ username: sellOrder.username });
                if (sellerUser) {
                    await Transaction.create({
                        userId: sellerUser._id,
                        title: `Limit Sold ${stockId}`,
                        amount: totalCost,
                        isPositive: true
                    });
                }

                // 3. add shares to buyer
                const buyerStock = await UserStocks.findOne({
                    username: buyOrder.username,
                    stockId
                })

                if (buyerStock) {
                    const oldTotalCost = buyerStock.quantity * buyerStock.avgPrice;
                    const newTotalCost = matchedQty * executionPrice;
                    const newAvgPrice = (oldTotalCost + newTotalCost) / (buyerStock.quantity + matchedQty);

                    await UserStocks.findOneAndUpdate(
                        { username: buyOrder.username, stockId },
                        {
                            $inc: { quantity: matchedQty },
                            $set: { avgPrice: newAvgPrice }
                        },
                        { returnDocument: 'after' }
                    )
                } else {
                    await UserStocks.create({
                        username: buyOrder.username,
                        stockId,
                        quantity: matchedQty,
                        avgPrice: executionPrice
                    })
                }

                // 4. deduct locked shares from seller (restore quantity is already done at placement)
                await UserStocks.findOneAndUpdate(
                    { username: sellOrder.username, stockId },
                    { $inc: { lockedQuantity: -matchedQty } }
                )

                // 5. update stock price to the execution price
                const currentStock = await Stock.findOne({ stockId });
                await Stock.findOneAndUpdate(
                    { stockId },
                    { $set: { price: executionPrice, previousPrice: currentStock?.price || executionPrice } }
                )

                // 6. deduct matched quantity from orders locally
                buyOrder.quantity -= matchedQty;
                sellOrder.quantity -= matchedQty;

                // 7. Update DB statuses for orders
                if (buyOrder.quantity === 0) {
                    await StockTrade.findByIdAndUpdate(buyOrder._id, { status: "executed" });
                    buyIndex++;
                } else {
                    await StockTrade.findByIdAndUpdate(buyOrder._id, { quantity: buyOrder.quantity });
                }

                if (sellOrder.quantity === 0) {
                    await StockTrade.findByIdAndUpdate(sellOrder._id, { status: "executed" });
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

        console.log(`Stock trade execution done for ${stockId}!`)

    } catch (error) {
        console.log("Stock trade matching error:", error)
    }
}

export { matchOrdersForStock }
