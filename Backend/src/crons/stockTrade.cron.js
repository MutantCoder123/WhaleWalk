import cron from "node-cron"
import { StockTrade } from "../models/stocktrade.model.js"
import { Stock } from "../models/stock.model.js"
import { matchOrdersForStock } from "../utils/orderMatcher.js"

const stockTradeCron = () => {
    cron.schedule('0 0 * * *', async () => {
        console.log("Running scheduled stock trade execution sweep AND daily price rollover...")

        try {
            // 1. Rollover stock prices for next day's calculations
            const allStocks = await Stock.find({});
            for (const stock of allStocks) {
                stock.history.push(stock.price);
                
                if (stock.previousPrice > 0) {
                    stock.lastDayPercentageChange = ((stock.price - stock.previousPrice) / stock.previousPrice) * 100;
                } else {
                    stock.lastDayPercentageChange = 0;
                }
                
                stock.previousPrice = stock.price;
                await stock.save();
            }

            // 2. get all unique stocks that have pending orders
            const pendingOrders = await StockTrade.find({ status: "pending" })
            const stockIds = [...new Set(pendingOrders.map(o => o.stockId))]

            for (const stockId of stockIds) {
                await matchOrdersForStock(stockId);
            }

            console.log("Scheduled cron tasks done!")

        } catch (error) {
            console.log("Stock trade cron error:", error)
        }
    }, {
        timezone: "Asia/Kolkata"
    })
}

export { stockTradeCron }